defmodule Anvil.Projects.Project do
  use Ash.Resource,
    domain: Anvil.Projects,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "projects"
    repo Anvil.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :description, :repository]

      change relate_actor(:owner)

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
      accept [:name, :description]
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
    attribute :description, :string
    attribute :repository, :string, allow_nil?: false
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :owner, Anvil.Accounts.User do
      allow_nil? false
    end

    has_many :prompt_sets, Anvil.Prompts.PromptSet
  end

  identities do
    identity :unique_slug_per_user, [:owner_id, :slug]
    identity :unique_repository, [:repository]
  end
end
