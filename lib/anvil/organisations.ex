defmodule Anvil.Organisations do
  use Ash.Domain

  resources do
    resource Anvil.Organisations.Organisation do
      define :create_organisation, action: :create
      define :list_organisations, action: :read
      define :get_organisation_by_id, action: :read, get_by: [:id]
      define :update_organisation, action: :update
      define :delete_organisation, action: :destroy
    end

    resource Anvil.Organisations.Membership do
      define :create_membership, action: :create
      define :list_memberships, action: :read
      define :get_membership_by_id, action: :read, get_by: [:id]
      define :update_membership, action: :update
      define :destroy_membership, action: :destroy
    end
  end

  authorization do
    authorize :by_default
  end
end
