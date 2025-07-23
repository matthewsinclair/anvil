defmodule Anvil.Projects do
  use Ash.Domain

  resources do
    resource Anvil.Projects.Project
  end
end
