defmodule AnvilWeb.FeatureCase do
  @moduledoc """
  Comprehensive test case template for PhoenixTest-based integration testing.

  This case template provides the complete setup for browser-like integration
  testing following PhoenixTest recommended patterns. Use this for end-to-end
  testing of user flows, authentication, and LiveView interactions.

  Features:
  - PhoenixTest for browser-like testing capabilities
  - Verified routes with the `~p` sigil for type-safe routing
  - Authentication helpers for setting up logged-in users
  - Data generation utilities for creating test data
  - Database isolation via SQL sandbox

  For end-to-end authentication testing, follow the patterns documented
  in the testing guide.

  For traditional controller/connection testing, use `AnvilWeb.ConnCase`.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint AnvilWeb.Endpoint

      # PhoenixTest for browser-like integration testing
      import PhoenixTest
      use AnvilWeb, :verified_routes

      # Data generation and test helpers
      import Anvil.Accounts.Generator
      import Anvil.Organisations.Generator
      import Anvil.Projects.Generator
      import Anvil.Prompts.Generator

      # Import FeatureCase helper functions
      import AnvilWeb.FeatureCase
    end
  end

  setup tags do
    Anvil.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that creates and then logs in users.

      setup :insert_and_authenticate_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def insert_and_authenticate_user(%{conn: conn}) do
    # Create user using generator
    user = create_test_user()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> AshAuthentication.Plug.Helpers.store_in_session(user)
  end

  # Temporary helper until generators are available
  defp create_test_user do
    # Create a user with personal organisation
    {:ok, user} =
      Anvil.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: "test-#{System.unique_integer()}@example.com",
        password: "!sixletters!",
        password_confirmation: "!sixletters!"
      })
      |> Ash.create()

    user
  end
end
