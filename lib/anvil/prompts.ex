defmodule Anvil.Prompts do
  use Ash.Domain

  resources do
    resource Anvil.Prompts.PromptSet do
      define :create_prompt_set, action: :create, args: [:name, :version, :project_id]
      define :list_prompt_sets, action: :read
      define :get_prompt_set_by_id, get_by: [:id], action: :read
      define :update_prompt_set, action: :update
      define :publish_prompt_set, action: :publish
      define :destroy_prompt_set, action: :destroy
    end

    resource Anvil.Prompts.Prompt do
      define :create_prompt, action: :create, args: [:name, :template, :prompt_set_id]
      define :list_prompts, action: :read
      define :get_prompt_by_id, get_by: [:id], action: :read
      define :update_prompt, action: :update
      define :destroy_prompt, action: :destroy
    end

    resource Anvil.Prompts.Version do
      define :create_version, action: :create, args: [:version_number, :snapshot, :prompt_set_id]
      define :list_versions, action: :read
      define :get_version_by_id, get_by: [:id], action: :read
    end
  end
end
