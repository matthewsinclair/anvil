defmodule Anvil.Prompts do
  use Ash.Domain

  resources do
    resource Anvil.Prompts.PromptSet
    resource Anvil.Prompts.Prompt
    resource Anvil.Prompts.Version
  end
end
