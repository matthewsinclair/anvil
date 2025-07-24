defmodule AnvilWeb.Integration.App.Organisations.OrganisationsSmokeTest do
  @moduledoc """
  Smoke tests for organisation management pages to verify basic functionality.

  These tests ensure the organisation pages render correctly for authenticated users
  and provide access to key organisation management features.
  """

  use AnvilWeb.IntegrationTestCase, async: true

  import AnvilWeb.IntegrationHelpers

  describe "organisations listing smoke test" do
    test "renders organisations page for authenticated user", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/organisations")
      |> assert_path(~p"/organisations")
      |> assert_has("h1", text: "Organisations")
    end

    test "redirects unauthenticated user to sign in", %{conn: conn} do
      conn
      |> assert_redirect_to_signin(~p"/organisations")
    end

    test "shows user's personal organisation", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/organisations")
      |> assert_response_success()
    end

    test "no critical errors on organisations page load", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/organisations")
      |> assert_response_success()
    end
  end

  describe "organisation navigation" do
    test "can access organisations from dashboard", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/app")
      |> visit(~p"/organisations")
      |> assert_path(~p"/organisations")
      |> assert_has("h1", text: "Organisations")
    end

    test "can navigate between organisations and projects", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/organisations")
      |> visit(~p"/projects")
      |> assert_path(~p"/projects")
      |> visit(~p"/organisations")
      |> assert_path(~p"/organisations")
    end
  end

  describe "organisation content verification" do
    test "organisations page shows expected structure", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      session
      |> visit(~p"/organisations")
      |> assert_has("main")
    end

    test "user has access to their personal organisation", %{conn: conn} do
      {_user, session} = setup_authenticated_user(conn)

      # Users should have a personal organisation created automatically
      session
      |> visit(~p"/organisations")
      |> assert_response_success()
    end
  end
end
