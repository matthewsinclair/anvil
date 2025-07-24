defmodule Anvil.Organisations.Changes.CreateOwnerMembership do
  use Ash.Resource.Change

  @moduledoc """
  Automatically creates an owner membership for the actor when an organisation is created.
  """

  @impl true
  def batch_change(changesets, opts, context) do
    # Handle batch operations by just delegating to individual change
    Enum.map(changesets, fn changeset ->
      change(changeset, opts, context)
    end)
  end

  @impl true
  def change(changeset, _opts, context) do
    # Only add the after_action hook if we have an actor
    if context.actor do
      Ash.Changeset.after_action(changeset, fn _changeset, organisation ->
        # Create the owner membership with the actor from the context
        case Anvil.Organisations.create_membership(
               %{
                 user_id: context.actor.id,
                 organisation_id: organisation.id,
                 role: :owner
               },
               actor: context.actor
             ) do
          {:ok, _membership} ->
            {:ok, organisation}

          {:error, error} ->
            {:error, error}
        end
      end)
    else
      # No actor, don't add the hook (e.g., personal organisations)
      changeset
    end
  end
end
