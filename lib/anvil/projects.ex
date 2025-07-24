defmodule Anvil.Projects do
  use Ash.Domain

  resources do
    resource Anvil.Projects.Project do
      define :create, args: [:name]
      define :read_all, action: :read
      define :by_id, get_by: [:id], action: :read
      define :get_by_id, get_by: [:id], action: :read
      define :update
      define :destroy
    end
  end

  authorization do
    authorize :by_default
  end
end
