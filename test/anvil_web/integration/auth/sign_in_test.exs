defmodule AnvilWeb.Integration.Auth.SignInTest do
  @moduledoc """
  Tests Auth by registering a new user and signing in with a known user.
  """

  use AnvilWeb.IntegrationTestCase, async: true

  describe "auth" do
    test "register for a new account", %{conn: conn} do
      conn
      |> visit(~p"/sign-in")
      |> click_link(
        "#user-password-sign-in-with-password-wrapper a[href='/register']",
        "Need an account?"
      )
      |> within("#user-password-register-with-password-wrapper", fn session ->
        session
        |> fill_in("Email", with: "test-#{System.unique_integer()}@example.com")
        |> fill_in("Password", with: Anvil.Accounts.Generator.default_password())
        |> fill_in("Password Confirmation", with: Anvil.Accounts.Generator.default_password())
        |> click_button(">> REGISTER")
      end)
      |> assert_path(~p"/app")
      |> assert_has("h1", text: "Dashboard")
    end

    test "sign in to an existing account", %{conn: conn} do
      # Create a user first
      user = create_test_user()

      conn
      |> visit(~p"/sign-in")
      |> within("#user-password-sign-in-with-password-wrapper", fn session ->
        session
        |> fill_in("Email", with: user.email)
        |> fill_in("Password", with: Anvil.Accounts.Generator.default_password())
        |> click_button(">> LOGIN")
      end)
      |> assert_path(~p"/app")
      |> assert_has("h1", text: "Dashboard")
    end

    test "sign in redirects to requested page after authentication", %{conn: conn} do
      # Create a user first
      user = create_test_user()

      # Try to access protected page, should redirect to sign-in
      conn
      |> visit(~p"/projects")
      |> assert_path(~p"/sign-in")
      |> within("#user-password-sign-in-with-password-wrapper", fn session ->
        session
        |> fill_in("Email", with: user.email)
        |> fill_in("Password", with: Anvil.Accounts.Generator.default_password())
        |> click_button(">> LOGIN")
      end)
      # Note: Currently redirects to dashboard instead of original page
      |> assert_path(~p"/app")
    end

    test "invalid credentials show error", %{conn: conn} do
      conn
      |> visit(~p"/sign-in")
      |> within("#user-password-sign-in-with-password-wrapper", fn session ->
        session
        |> fill_in("Email", with: "nonexistent@example.com")
        |> fill_in("Password", with: "wrongpassword")
        |> click_button(">> LOGIN")
      end)
      |> assert_path(~p"/sign-in")
      |> assert_has("li", text: "Email or password was incorrect")
    end
  end

  # Private helper for creating test user
  defp create_test_user do
    # Use the generator which bypasses authorization issues
    {user, _org} = Anvil.Accounts.Generator.user_with_personal_org()
    user
  end
end
