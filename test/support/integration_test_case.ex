defmodule AnvilWeb.IntegrationTestCase do
  @moduledoc """
  Test case for integration tests that can be conditionally disabled.

  Integration tests only run when TEST_ANVIL_INTEGRATIONS=true is set in the environment.
  Otherwise, tests are skipped with a clear message.

  This module extends AnvilWeb.FeatureCase with conditional execution logic.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use AnvilWeb.FeatureCase

      # Add skip tag to all tests when integration tests are disabled
      unless System.get_env("TEST_ANVIL_INTEGRATIONS") == "true" do
        @moduletag skip:
                     "Integration tests disabled. Set TEST_ANVIL_INTEGRATIONS=true to run integration tests."
      end
    end
  end
end
