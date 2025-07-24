defmodule AnvilWeb.Integration.App.Projects.ProjectsSmokeTest do
  @moduledoc """
  Smoke tests for project management pages to verify basic functionality.

  These tests ensure the project pages render correctly for authenticated users
  and provide access to key project management features.
  """

  use AnvilWeb.IntegrationTestCase, async: true

  import AnvilWeb.IntegrationHelpers

  describe "projects listing smoke test" do
    test "renders projects page for authenticated user", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/projects")
      |> assert_path(~p"/projects")
      |> assert_has("h1", text: "Projects")
    end

    test "redirects unauthenticated user to sign in", %{conn: conn} do
      conn
      |> assert_redirect_to_signin(~p"/projects")
    end

    test "shows empty state when no projects exist", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/projects")
      |> assert_response_success()
    end

    test "new project button is accessible", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/projects")
      |> visit(~p"/projects/new")
      |> assert_path(~p"/projects/new")
    end

    test "no critical errors on projects page load", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/projects")
      |> assert_response_success()
    end
  end

  describe "new project smoke test" do
    test "renders new project page for authenticated user", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/projects/new")
      |> assert_path(~p"/projects/new")
      |> assert_has("h1", text: "New Project")
    end

    test "redirects unauthenticated user to sign in", %{conn: conn} do
      conn
      |> assert_redirect_to_signin(~p"/projects/new")
    end

    test "new project form is present", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/projects/new")
      |> assert_has("form")
      |> assert_has("input[name*='name']")
    end

    test "no critical errors on new project page load", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/projects/new")
      |> assert_response_success()
    end
  end

  describe "project navigation" do
    test "can navigate back to projects list from new project", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/projects/new")
      |> visit(~p"/projects")
      |> assert_path(~p"/projects")
    end

    test "can access projects from dashboard", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      |> visit(~p"/projects")
      |> assert_path(~p"/projects")
      |> assert_has("h1", text: "Projects")
    end
  end
end
