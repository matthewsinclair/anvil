defmodule Anvil.Bundles.Bundle do
  use Ash.Resource,
    domain: Anvil.Bundles,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "bundles"
    repo Anvil.Repo
  end

  code_interface do
    define :create
    define :read_all, action: :read
    define :by_id, get_by: [:id], action: :read
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name, :repository, :version, :description, :manifest, :checksum, :size_bytes]
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
    attribute :repository, :string, allow_nil?: false
    attribute :version, :string, allow_nil?: false
    attribute :description, :string
    attribute :manifest, :map, allow_nil?: false
    attribute :checksum, :string, allow_nil?: false
    attribute :size_bytes, :integer, allow_nil?: false
    create_timestamp :created_at
  end

  relationships do
    belongs_to :created_by, Anvil.Accounts.User do
      allow_nil? false
    end

    has_many :imports, Anvil.Bundles.BundleImport
    has_many :exports, Anvil.Bundles.BundleExport
  end

  identities do
    identity :unique_bundle, [:repository, :name, :version]
    identity :by_checksum, [:checksum]
  end
end
