defmodule Anvil.Accounts.Changes.CreatePersonalOrganisation do
  use Ash.Resource.Change
  require Ash.Query

  @moduledoc """
  Creates a personal organisation for a newly registered user.
  """

  @impl true
  def change(changeset, _, _) do
    changeset
    |> Ash.Changeset.after_action(fn changeset, user ->
      # Only create organisation if this is a new user (not an update/upsert of existing)
      if changeset.action_type == :create do
        with {:ok, organisation} <- create_personal_organisation(user),
             {:ok, _membership} <- create_owner_membership(user, organisation) do
          {:ok, user}
        else
          {:error, error} ->
            {:error, error}
        end
      else
        {:ok, user}
      end
    end)
  end

  defp create_personal_organisation(user) do
    Anvil.Organisations.create_organisation(
      %{
        name: "Personal",
        description: "Personal organisation for #{user.email}",
        personal?: true
      },
      authorize?: false
    )
  end

  defp create_owner_membership(user, organisation) do
    Anvil.Organisations.create_membership(
      %{
        user_id: user.id,
        organisation_id: organisation.id,
        role: :owner
      },
      authorize?: false
    )
  end
end
