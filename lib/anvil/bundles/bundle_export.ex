defmodule Anvil.Bundles.BundleExport do
  use Ash.Resource,
    domain: Anvil.Bundles,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "bundle_exports"
    repo Anvil.Repo
  end

  code_interface do
    define :create, args: [:prompt_set_id]
    define :read_all, action: :read
    define :by_id, get_by: [:id], action: :read
    define :start_export
    define :complete_export
    define :fail_export
  end

  actions do
    defaults [:read]

    create :create do
      accept [:prompt_set_id]
    end

    update :start_export do
      change set_attribute(:status, :in_progress)
    end

    update :complete_export do
      argument :bundle_id, :uuid, allow_nil?: false
      argument :file_path, :string, allow_nil?: false

      change set_attribute(:status, :completed)
      change set_attribute(:bundle_id, arg(:bundle_id))
      change set_attribute(:file_path, arg(:file_path))
    end

    update :fail_export do
      argument :error_message, :string, allow_nil?: false

      change set_attribute(:status, :failed)
      change set_attribute(:error_message, arg(:error_message))
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :status, :atom,
      constraints: [one_of: [:pending, :in_progress, :completed, :failed]],
      default: :pending

    attribute :error_message, :string
    attribute :file_path, :string
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :bundle, Anvil.Bundles.Bundle do
      allow_nil? false
    end

    belongs_to :prompt_set, Anvil.Prompts.PromptSet do
      allow_nil? false
    end

    belongs_to :exported_by, Anvil.Accounts.User do
      allow_nil? false
    end
  end
end
