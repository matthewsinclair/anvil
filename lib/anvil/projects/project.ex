defmodule Anvil.Projects.Project do
  use Ash.Resource,
    domain: Anvil.Projects,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "projects"
    repo Anvil.Repo

    references do
      reference :organisation, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :description]

      argument :organisation_id, :uuid, allow_nil?: false

      change set_attribute(:organisation_id, arg(:organisation_id))
      change Anvil.Projects.Changes.GenerateSlug
    end

    update :update do
      accept [:name, :description]
      change Anvil.Projects.Changes.GenerateSlug
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(exists(organisation.memberships, user_id == ^actor(:id)))
    end

    # For create, we need a custom check since we can't traverse relationships
    policy action_type(:create) do
      authorize_if Anvil.Projects.Checks.UserCanCreateInOrganisation
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(
                     exists(
                       organisation.memberships,
                       user_id == ^actor(:id) and role in [:owner, :admin]
                     )
                   )
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :slug, :string, allow_nil?: false
    attribute :description, :string
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organisation, Anvil.Organisations.Organisation do
      allow_nil? false
      attribute_writable? true
    end

    has_many :prompt_sets, Anvil.Prompts.PromptSet
  end

  identities do
    identity :unique_slug_per_org, [:organisation_id, :slug]
  end
end
