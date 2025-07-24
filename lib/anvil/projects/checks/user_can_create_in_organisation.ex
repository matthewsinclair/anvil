defmodule Anvil.Projects.Checks.UserCanCreateInOrganisation do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "Check if the user has admin or owner role in the target organisation"
  end

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(actor, %{changeset: changeset}, _opts) do
    case Ash.Changeset.get_argument(changeset, :organisation_id) do
      nil ->
        false

      org_id ->
        # Check if the user has the right role in this organisation
        case Anvil.Organisations.list_memberships(
               query: [
                 filter: [
                   user_id: actor.id,
                   organisation_id: org_id,
                   role: {:in, [:owner, :admin]}
                 ]
               ],
               actor: actor,
               authorize?: false
             ) do
          {:ok, [_ | _]} -> true
          _ -> false
        end
    end
  end

  def match?(_actor, _context, _opts), do: false
end
