defmodule Anvil.Organisations.Membership do
  use Ash.Resource,
    domain: Anvil.Organisations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "organisation_memberships"
    repo Anvil.Repo

    references do
      reference :organisation, on_delete: :delete
      reference :user, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:role]
      argument :organisation_id, :uuid, allow_nil?: false
      argument :user_id, :uuid, allow_nil?: false

      change set_attribute(:organisation_id, arg(:organisation_id))
      change set_attribute(:user_id, arg(:user_id))
    end

    update :update do
      primary? true
      accept [:role]
    end
  end

  policies do
    policy action_type(:read) do
      # Allow reading memberships if you're a member of the organisation
      authorize_if expr(exists(organisation.memberships, user_id == ^actor(:id)))
    end

    policy action_type(:create) do
      authorize_if Anvil.Organisations.Checks.UserCanManageOrganisation
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(
                     exists(organisation.memberships, user_id == ^actor(:id) and role == :owner)
                   )
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      constraints one_of: [:owner, :admin, :member]
      allow_nil? false
      default :member
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organisation, Anvil.Organisations.Organisation do
      allow_nil? false
      attribute_writable? true
      primary_key? true
    end

    belongs_to :user, Anvil.Accounts.User do
      allow_nil? false
      attribute_writable? true
      primary_key? true
    end
  end

  identities do
    identity :unique_user_org, [:user_id, :organisation_id]
  end
end
