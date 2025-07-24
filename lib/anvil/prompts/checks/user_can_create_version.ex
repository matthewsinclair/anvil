defmodule Anvil.Prompts.Checks.UserCanCreateVersion do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "Check if the user has permission to create versions in the target prompt set"
  end

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    # Return false if no actor provided
    if is_nil(actor) do
      false
    else
      case Ash.Changeset.get_attribute(changeset, :prompt_set_id) do
        nil ->
          false

        prompt_set_id ->
          # Check if the prompt set exists and user has access through organisation membership
          # First, get the prompt set with its project
          case Anvil.Prompts.get_prompt_set_by_id(prompt_set_id,
                 actor: actor,
                 authorize?: false,
                 load: [project: :organisation_id]
               ) do
            {:ok, %{project: %{organisation_id: org_id}}} when not is_nil(org_id) ->
              # Now check if user has membership in the project's organisation
              case Anvil.Organisations.list_memberships(
                     query: [
                       filter: [
                         user_id: actor.id,
                         organisation_id: org_id,
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
  end

  def match?(_actor, _context, _opts), do: false
end
