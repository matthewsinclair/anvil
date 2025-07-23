defmodule Anvil.Bundles do
  use Ash.Domain

  resources do
    resource Anvil.Bundles.Bundle
    resource Anvil.Bundles.BundleImport
    resource Anvil.Bundles.BundleExport
  end
end
