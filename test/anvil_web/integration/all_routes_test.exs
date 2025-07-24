defmodule AnvilWeb.Integration.AllRoutesTest do
  @moduledoc """
  Dynamic integration test that validates all production routes are accessible.

  This test automatically discovers routes from the router and validates:
  - Public routes are accessible without authentication
  - Protected routes redirect unauthenticated users to sign-in
  - Protected routes are accessible with authentication
  - No critical errors occur on any production route

  The test dynamically adapts to route changes, ensuring comprehensive
  coverage without hardcoding specific routes.
  """

  use AnvilWeb.IntegrationTestCase, async: true

  import AnvilWeb.IntegrationHelpers

  # Routes to ignore during testing (auth, dev, special routes)
  @ignored_routes [
    "/auth/*",
    "/sign-in",
    "/register",
    "/reset",
    "/password-reset",
    "/sign-out",
    "/dev/*",
    "/admin/*",
    "/storybook",
    "/storybook/*",
    "/ws/*",
    "/live/*",
    "/api/*",
    "/gql/*",
    "/oban"
  ]

  describe "production route accessibility" do
    test "public routes are accessible without authentication", %{conn: conn} do
      testable_routes = get_testable_routes()
      categorized_routes = categorize_routes(testable_routes)

      categorized_routes.public
      |> Enum.each(fn route ->
        test_public_route_access(conn, route)
      end)
    end

    test "protected routes redirect unauthenticated users to sign-in", %{conn: conn} do
      testable_routes = get_testable_routes()
      categorized_routes = categorize_routes(testable_routes)

      categorized_routes.protected
      |> Enum.filter(&get_route?/1)
      |> Enum.each(fn route ->
        test_protected_route_redirect(conn, route)
      end)
    end

    test "protected routes are accessible with authentication", %{conn: conn} do
      {_user, authenticated_session} = setup_authenticated_user(conn)

      testable_routes = get_testable_routes()
      categorized_routes = categorize_routes(testable_routes)

      categorized_routes.protected
      |> Enum.filter(&get_route?/1)
      |> Enum.each(fn route ->
        test_authenticated_route_access(authenticated_session, route)
      end)
    end
  end

  describe "route categorization validation" do
    test "all testable routes are properly categorized" do
      testable_routes = get_testable_routes()
      categorized_routes = categorize_routes(testable_routes)

      total_categorized =
        length(categorized_routes.public) + length(categorized_routes.protected)

      assert total_categorized == length(testable_routes),
             "All testable routes should be categorized as either public or protected"
    end

    test "ignored routes are properly filtered out" do
      all_routes = AnvilWeb.Router.__routes__()
      testable_routes = get_testable_routes()

      assert length(testable_routes) < length(all_routes),
             "Testable routes should be a subset of all routes"
    end

    test "critical app routes are present" do
      testable_routes = get_testable_routes()
      route_paths = Enum.map(testable_routes, & &1.path)

      # Verify essential routes exist
      assert "/" in route_paths, "Home route should be present"
      assert "/app" in route_paths, "Main app route should be present"
    end
  end

  # Helper function to get routes filtered by @ignored_routes
  @spec get_testable_routes() :: [map()]
  defp get_testable_routes do
    AnvilWeb.Router.__routes__()
    |> Enum.reject(&ignored_route?/1)
    |> Enum.filter(&(get_route?(&1) and static_path?(&1)))
  end

  @spec ignored_route?(map()) :: boolean()
  defp ignored_route?(%{path: path}) do
    Enum.any?(@ignored_routes, fn pattern ->
      if String.ends_with?(pattern, "*") do
        prefix = String.trim_trailing(pattern, "*")
        String.starts_with?(path, prefix)
      else
        path == pattern
      end
    end)
  end

  # Private helper functions for route testing

  @spec test_public_route_access(Plug.Conn.t(), map()) :: :ok
  defp test_public_route_access(conn, route) do
    case route do
      %{verb: :get, path: path} when is_binary(path) ->
        try do
          conn
          |> visit(path)
          |> assert_response_success()
        rescue
          error ->
            flunk("Public route #{path} failed: #{inspect(error)}")
        end

      _ ->
        # Skip non-GET routes or routes with parameters
        :ok
    end
  end

  @spec test_protected_route_redirect(Plug.Conn.t(), map()) :: :ok
  defp test_protected_route_redirect(conn, route) do
    case route do
      %{verb: :get, path: path} when is_binary(path) ->
        try do
          conn
          |> visit(path)
          |> assert_path("/sign-in")
        rescue
          error ->
            flunk("Protected route #{path} redirect failed: #{inspect(error)}")
        end

      _ ->
        # Skip non-GET routes
        :ok
    end
  end

  @spec test_authenticated_route_access(any(), map()) :: :ok
  defp test_authenticated_route_access(session, route) do
    case route do
      %{verb: :get, path: path} when is_binary(path) ->
        try do
          session
          |> visit(path)
          |> assert_response_success()
        rescue
          error ->
            flunk("Authenticated route #{path} failed: #{inspect(error)}")
        end

      _ ->
        # Skip non-GET routes
        :ok
    end
  end

  @spec static_path?(map()) :: boolean()
  defp static_path?(%{path: path}) do
    # Only test paths without dynamic segments (no :param or *)
    not (String.contains?(path, ":") or String.contains?(path, "*"))
  end

  @spec get_route?(map()) :: boolean()
  defp get_route?(%{verb: :get}), do: true
  defp get_route?(_), do: false
end
