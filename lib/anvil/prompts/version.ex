defmodule Anvil.Prompts.Version do
  use Ash.Resource,
    domain: Anvil.Prompts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "prompt_set_versions"
    repo Anvil.Repo
  end

  code_interface do
    define :create, args: [:version_number, :snapshot, :prompt_set_id]
    define :read_all, action: :read
    define :by_id, get_by: [:id], action: :read
  end

  actions do
    defaults [:read]

    create :create do
      accept [:version_number, :changelog, :snapshot, :prompt_set_id]

      change set_attribute(:published_at, &DateTime.utc_now/0)
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :version_number, :string, allow_nil?: false
    attribute :changelog, :string
    attribute :snapshot, :map, allow_nil?: false
    attribute :published_at, :utc_datetime
    attribute :published_by_id, :uuid
    create_timestamp :created_at
  end

  relationships do
    belongs_to :prompt_set, Anvil.Prompts.PromptSet do
      allow_nil? false
    end

    belongs_to :published_by, Anvil.Accounts.User do
      define_attribute? false
    end
  end

  identities do
    identity :unique_version, [:prompt_set_id, :version_number]
  end
end
