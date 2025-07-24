defmodule Anvil.Prompts.Checks.UserCanCreateInProject do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "Check if the user has permission to create prompt sets in the target project"
  end

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    case Ash.Changeset.get_attribute(changeset, :project_id) do
      nil ->
        false

      project_id ->
        # First get the project to find its organisation_id
        case Anvil.Projects.by_id(project_id, actor: actor, authorize?: false) do
          {:ok, project} ->
            # Check if the user has the right role in this organisation
            case Anvil.Organisations.list_memberships(
                   query: [
                     filter: [
                       user_id: actor.id,
                       organisation_id: project.organisation_id,
                       role: {:in, [:owner, :admin, :member]}
                     ]
                   ],
                   actor: actor,
                   authorize?: false
                 ) do
              {:ok, [_ | _]} -> true
              _ -> false
            end

          _ ->
            false
        end
    end
  end

  def match?(_actor, _context, _opts), do: false
end
