defmodule Anvil.Prompts.PromptSet do
  use Ash.Resource,
    domain: Anvil.Prompts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "prompt_sets"
    repo Anvil.Repo

    references do
      reference :project, on_delete: :restrict
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :version, :metadata, :edit_mode, :project_id]

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
      accept [:name, :metadata, :edit_mode]
    end

    update :publish do
      change set_attribute(:published_at, &DateTime.utc_now/0)
    end

    update :add_dependency do
      argument :dependency, :map, allow_nil?: false
      require_atomic? false

      change fn changeset, %{arguments: %{dependency: dependency}} ->
        current = Ash.Changeset.get_attribute(changeset, :dependencies) || []
        Ash.Changeset.change_attribute(changeset, :dependencies, current ++ [dependency])
      end
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
    attribute :version, :string, allow_nil?: false
    attribute :metadata, :map, default: %{}
    attribute :dependencies, {:array, :map}, default: []
    attribute :published_at, :utc_datetime

    attribute :edit_mode, :atom,
      constraints: [one_of: [:live, :review, :locked]],
      default: :review

    attribute :approval_token_hash, :string
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :project, Anvil.Projects.Project do
      allow_nil? false
    end

    has_many :prompts, Anvil.Prompts.Prompt do
      destination_attribute :prompt_set_id
    end

    has_many :versions, Anvil.Prompts.Version do
      destination_attribute :prompt_set_id
    end
  end

  identities do
    identity :unique_version_per_project, [:project_id, :slug, :version]
  end
end
