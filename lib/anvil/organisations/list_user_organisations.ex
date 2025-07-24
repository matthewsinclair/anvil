defmodule Anvil.Organisations.ListUserOrganisations do
  @moduledoc """
  Lists all organisations that a user is a member of.
  """

  def list_user_organisations(user) do
    case Anvil.Organisations.list_memberships(
           query: [
             filter: [user_id: user.id],
             load: [:organisation]
           ],
           actor: user
         ) do
      {:ok, memberships} ->
        Enum.map(memberships, & &1.organisation)

      _ ->
        []
    end
  end
end
