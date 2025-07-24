defmodule Anvil.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Anvil.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Anvil.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Anvil.DataCase

      # Import domain generators
      import Anvil.Accounts.Generator
      import Anvil.Organisations.Generator
      import Anvil.Projects.Generator
      import Anvil.Prompts.Generator
    end
  end

  setup tags do
    Anvil.DataCase.setup_sandbox(tags)
    Anvil.DataCase.setup_ets_tables(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Anvil.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  Sets up ETS tables for Ash resources before each test.
  Cleans up ETS tables after each test to ensure isolation.
  """
  def setup_ets_tables(_tags) do
    # Clear existing ETS data for clean test isolation
    clear_ets_tables()

    # Ensure ETS tables exist for all ETS-backed resources
    ensure_ets_tables()

    # Clean up after test
    on_exit(fn -> clear_ets_tables() end)
  end

  defp ensure_ets_tables do
    # List all domains that might have ETS-backed resources
    domains = [Anvil.Accounts, Anvil.Organisations, Anvil.Projects, Anvil.Prompts]

    for domain <- domains do
      resources = Ash.Domain.Info.resources(domain)

      for resource <- resources do
        data_layer = Ash.Resource.Info.data_layer(resource)

        if data_layer == Ash.DataLayer.Ets do
          # Ensure the ETS table exists by attempting a simple read
          # This will create the table if it doesn't exist
          try do
            Ash.read(resource, authorize?: false)
          rescue
            _ -> :ok
          end
        end
      end
    end
  end

  defp clear_ets_tables do
    domains = [Anvil.Accounts, Anvil.Organisations, Anvil.Projects, Anvil.Prompts]

    for domain <- domains do
      resources = Ash.Domain.Info.resources(domain)

      for resource <- resources do
        data_layer = Ash.Resource.Info.data_layer(resource)

        if data_layer == Ash.DataLayer.Ets do
          # Clear all data from ETS table by deleting all records
          try do
            Ash.bulk_destroy(resource, :destroy, %{}, authorize?: false, return_errors?: false)
          rescue
            _ -> :ok
          end
        end
      end
    end
  end
end
