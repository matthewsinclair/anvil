defmodule Anvil.Organisations.Checks.UserCanManageOrganisation do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "Check if the user can manage memberships in the organisation"
  end

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    org_id =
      Ash.Changeset.get_argument(changeset, :organisation_id) ||
        Ash.Changeset.get_attribute(changeset, :organisation_id)

    case org_id do
      nil ->
        false

      organisation_id ->
        # First check if there are any memberships at all
        import Ash.Query

        existing_count =
          Anvil.Organisations.Membership
          |> filter(organisation_id == ^organisation_id)
          |> Ash.count!(actor: actor, authorize?: false)

        if existing_count == 0 do
          # No memberships yet - this must be the first one, allow it
          true
        else
          # There are existing memberships, check if user is an owner or admin
          admin_count =
            Anvil.Organisations.Membership
            |> filter(
              organisation_id == ^organisation_id and user_id == ^actor.id and
                role in [:owner, :admin]
            )
            |> Ash.count!(actor: actor, authorize?: false)

          admin_count > 0
        end
    end
  end

  def match?(_actor, _context, _opts), do: false
end
