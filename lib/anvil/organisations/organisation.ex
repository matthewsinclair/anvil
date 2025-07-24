defmodule Anvil.Organisations.Organisation do
  use Ash.Resource,
    domain: Anvil.Organisations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "organisations"
    repo Anvil.Repo
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:name, :description, :personal?]

      change Anvil.Organisations.Changes.GenerateSlug
    end

    update :update do
      primary? true
      accept [:name, :description]

      change Anvil.Organisations.Changes.GenerateSlug
    end

    destroy :destroy do
      primary? true
    end
  end

  policies do
    # Allow anyone to create an organisation
    bypass action_type(:create) do
      authorize_if always()
    end

    bypass action_type(:read) do
      authorize_if expr(exists(memberships, user_id == ^actor(:id)))
    end

    policy action(:update) do
      authorize_if expr(exists(memberships, user_id == ^actor(:id) and role == :owner))
    end

    policy action(:destroy) do
      forbid_if expr(personal? == true)
      authorize_if expr(exists(memberships, user_id == ^actor(:id) and role == :owner))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    attribute :description, :string do
      public? true
    end

    attribute :personal?, :boolean do
      default false
      allow_nil? false
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :memberships, Anvil.Organisations.Membership do
      destination_attribute :organisation_id
    end

    has_many :projects, Anvil.Projects.Project do
      destination_attribute :organisation_id
    end

    many_to_many :users, Anvil.Accounts.User do
      through Anvil.Organisations.Membership
      source_attribute_on_join_resource :organisation_id
      destination_attribute_on_join_resource :user_id
    end
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_slug, [:slug]
  end
end
