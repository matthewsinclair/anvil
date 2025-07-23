defmodule Anvil.Bundles.BundleImport do
  use Ash.Resource,
    domain: Anvil.Bundles,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "bundle_imports"
    repo Anvil.Repo
  end

  code_interface do
    define :create, args: [:bundle_id, :project_id]
    define :read_all, action: :read
    define :by_id, get_by: [:id], action: :read
    define :start_import
    define :complete_import
    define :fail_import
  end

  actions do
    defaults [:read]

    create :create do
      accept [:bundle_id, :project_id]
    end

    update :start_import do
      change set_attribute(:status, :in_progress)
    end

    update :complete_import do
      argument :import_results, :map, allow_nil?: false

      change set_attribute(:status, :completed)
      change set_attribute(:import_results, arg(:import_results))
    end

    update :fail_import do
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
    attribute :import_results, :map
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :bundle, Anvil.Bundles.Bundle do
      allow_nil? false
    end

    belongs_to :project, Anvil.Projects.Project do
      allow_nil? false
    end

    belongs_to :imported_by, Anvil.Accounts.User do
      allow_nil? false
    end
  end
end
