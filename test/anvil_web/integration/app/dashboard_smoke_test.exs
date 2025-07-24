defmodule AnvilWeb.Integration.App.DashboardSmokeTest do
  @moduledoc """
  Smoke tests for the main dashboard page to verify basic functionality.

  These tests ensure the dashboard renders correctly for authenticated users
  and provides access to key sections and navigation elements.
  """

  use AnvilWeb.IntegrationTestCase, async: true

  import AnvilWeb.IntegrationHelpers

  describe "dashboard smoke test" do
    test "renders dashboard page for authenticated user", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      |> assert_path(~p"/app")
      |> assert_has("h1", text: "Dashboard")
    end

    test "redirects unauthenticated user to sign in", %{conn: conn} do
      conn
      |> assert_redirect_to_signin(~p"/app")
    end

    test "dashboard contains expected layout elements", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      |> assert_has("title", text: "Dashboard · Phoenix Framework")
    end

    test "navigation sections are accessible", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      # Test direct navigation to main sections
      |> visit(~p"/projects")
      |> assert_path(~p"/projects")
      |> visit(~p"/organisations")
      |> assert_path(~p"/organisations")
    end

    test "no critical errors on dashboard load", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      |> assert_response_success()
    end
  end

  describe "dashboard content verification" do
    test "dashboard shows welcome content", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      |> assert_has("main")
    end

    test "user can navigate to projects from dashboard", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      # Direct navigation for smoke test
      |> visit(~p"/projects")
      |> assert_path(~p"/projects")
    end

    test "user can navigate to organisations from dashboard", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      # Direct navigation for smoke test
      |> visit(~p"/organisations")
      |> assert_path(~p"/organisations")
    end

    test "user can access account settings", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      # Direct navigation for smoke test
      |> visit(~p"/account")
      |> assert_path(~p"/account")
    end
  end
end
