defmodule AnvilWeb.IntegrationHelpers do
  @moduledoc """
  Shared utilities for integration testing across the Anvil application.

  This module provides common patterns and utilities for PhoenixTest-based
  integration testing, including route introspection, authentication helpers,
  and assertion patterns that follow the project's functional programming
  principles.
  """

  import PhoenixTest

  @doc """
  Gets all production routes from the router, filtering out development-only routes.

  Returns a list of route maps with keys: :verb, :path, :plug, :plug_opts, etc.

  ## Examples

      iex> get_production_routes()
      [
        %{verb: :get, path: "/", plug: AnvilWeb.PageController, plug_opts: :home},
        %{verb: :get, path: "/app", plug: AnvilWeb.DashboardLive, plug_opts: :index},
        ...
      ]
  """
  @spec get_production_routes() :: [map()]
  def get_production_routes do
    AnvilWeb.Router.__routes__()
    |> Enum.reject(&(development_route?(&1) or api_route?(&1)))
  end

  @doc """
  Categorizes routes by authentication requirements.

  Returns a map with :public and :protected keys containing lists of routes.

  ## Examples

      iex> categorize_routes(get_production_routes())
      %{
        public: [%{path: "/"}, %{path: "/sign-in"}],
        protected: [%{path: "/app"}, %{path: "/app/settings"}]
      }
  """
  @spec categorize_routes([map()]) :: %{public: [map()], protected: [map()]}
  def categorize_routes(routes) do
    routes
    |> Enum.group_by(fn route ->
      if protected_route?(route), do: :protected, else: :public
    end)
    |> Map.put_new(:public, [])
    |> Map.put_new(:protected, [])
  end

  @doc """
  Creates an authenticated user and returns both the user and a session
  that has gone through the actual sign-in process.

  This follows the same pattern as MeetZaya by actually going through
  the authentication flow rather than manipulating sessions.

  ## Examples

      iex> {user, session} = setup_authenticated_user(conn)
  """
  @spec setup_authenticated_user(Plug.Conn.t()) :: {Anvil.Accounts.User.t(), any()}
  def setup_authenticated_user(conn) do
    # Create user with known password
    user = create_test_user_with_password()

    # Actually sign in through the UI
    session =
      conn
      |> visit("/")
      |> click_link("Sign In")
      |> fill_in("Email", with: user.email)
      |> fill_in("Password", with: test_password())
      |> click_button("Sign in")

    {user, session}
  end

  @doc """
  Asserts that an authenticated user can successfully access a protected route.

  This is a common pattern for smoke tests to verify basic page accessibility.

  ## Examples

      iex> conn
      ...> |> setup_authenticated_user()
      ...> |> elem(1)
      ...> |> assert_authenticated_access("/app/projects")
  """
  @spec assert_authenticated_access(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def assert_authenticated_access(conn, path) do
    conn
    |> visit(path)
    |> assert_path(path)
  end

  @doc """
  Asserts that an unauthenticated user is redirected to the sign-in page
  when attempting to access a protected route.

  ## Examples

      iex> conn |> assert_redirect_to_signin("/app/settings")
  """
  @spec assert_redirect_to_signin(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def assert_redirect_to_signin(conn, protected_path) do
    conn
    |> visit(protected_path)
    |> assert_path("/sign-in")
  end

  @doc """
  Asserts that a page contains the expected navigation elements.

  This is useful for smoke tests to verify basic page structure.
  """
  @spec assert_page_structure(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def assert_page_structure(session, opts \\ []) do
    title = Keyword.get(opts, :title)
    nav_element = Keyword.get(opts, :nav_element)

    session = if title, do: assert_has(session, "h1", text: title), else: session
    session = if nav_element, do: assert_has(session, nav_element), else: session

    session
  end

  @doc """
  Creates a user with a specific organisation context for testing.

  Returns {user, organisation} tuple.

  ## Examples

      iex> {user, org} = create_user_with_org()
  """
  @spec create_user_with_org() :: {Anvil.Accounts.User.t(), Anvil.Organisations.Organisation.t()}
  def create_user_with_org do
    user = create_test_user()
    # User should have a personal organisation created automatically
    {:ok, orgs} = Anvil.Organisations.list_organisations(%{}, actor: user)
    org = List.first(orgs)
    {user, org}
  end

  @doc """
  Creates a project for a user in their personal organisation.

  ## Examples

      iex> project = create_project_for_user(user)
  """
  @spec create_project_for_user(Anvil.Accounts.User.t()) :: Anvil.Projects.Project.t()
  def create_project_for_user(user) do
    {:ok, orgs} = Anvil.Organisations.list_organisations(%{}, actor: user)
    org = List.first(orgs)

    {:ok, project} =
      Anvil.Projects.Project
      |> Ash.Changeset.for_create(
        :create,
        %{
          name: "Test Project #{System.unique_integer()}",
          organisation_id: org.id
        },
        actor: user
      )
      |> Ash.create()

    project
  end

  @doc """
  Default password used for test users.
  """
  def test_password, do: "!sixletters!"

  @doc """
  Sign in a user through the actual authentication flow.
  """
  @spec sign_in_user(Plug.Conn.t(), Anvil.Accounts.User.t()) :: Plug.Conn.t()
  def sign_in_user(conn, user) do
    conn
    |> visit("/")
    |> click_link("Sign In")
    |> fill_in("Email", with: user.email)
    |> fill_in("Password", with: test_password())
    |> click_button("Sign in")
  end

  # Private helper functions

  defp create_test_user do
    {:ok, user} =
      Anvil.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: "test-#{System.unique_integer()}@example.com",
        password: test_password(),
        password_confirmation: test_password()
      })
      |> Ash.create()

    user
  end

  defp create_test_user_with_password do
    create_test_user()
  end

  @spec development_route?(map()) :: boolean()
  defp development_route?(%{path: path}) do
    String.starts_with?(path, "/dev/") or
      String.starts_with?(path, "/storybook") or
      String.contains?(path, "ash_admin") or
      String.contains?(path, "live_dashboard") or
      String.contains?(path, "mailbox") or
      problematic_auth_route?(path)
  end

  @spec problematic_auth_route?(String.t()) :: boolean()
  defp problematic_auth_route?(path) do
    # Filter out auth routes that require special handling or tokens
    String.contains?(path, "/auth/user/email") or
      String.contains?(path, "/auth/user/magic_link") or
      String.contains?(path, "/reset") or
      (String.starts_with?(path, "/auth/") and String.contains?(path, ":"))
  end

  @spec api_route?(map()) :: boolean()
  defp api_route?(%{path: path}) do
    String.starts_with?(path, "/api/") or
      String.starts_with?(path, "/gql/")
  end

  @spec protected_route?(map()) :: boolean()
  defp protected_route?(%{path: path}) do
    String.starts_with?(path, "/app")
  end
end
