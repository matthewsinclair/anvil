defmodule Anvil.Prompts.Prompt do
  use Ash.Resource,
    domain: Anvil.Prompts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "prompts"
    repo Anvil.Repo

    references do
      reference :prompt_set, on_delete: :restrict
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :template, :parameters, :metadata, :prompt_set_id]

      change fn changeset, _ ->
        case Ash.Changeset.get_attribute(changeset, :name) do
          nil ->
            changeset

          name ->
            slug = name |> String.downcase() |> String.replace(" ", "-")
            Ash.Changeset.change_attribute(changeset, :slug, slug)
        end
      end
    end

    update :update do
      accept [:name, :template, :parameters, :metadata]
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :slug, :string, allow_nil?: false
    attribute :template, :string, allow_nil?: false
    attribute :parameters, {:array, :map}, default: []
    attribute :metadata, :map, default: %{}
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :prompt_set, Anvil.Prompts.PromptSet do
      allow_nil? false
    end
  end

  identities do
    identity :unique_slug_per_set, [:prompt_set_id, :slug]
  end
end
