defmodule Anvil.Registry do
  @moduledoc """
  Registry for fetching prompts from the database.
  """

  require Ash.Query

  @spec fetch(map()) :: {:ok, map()} | {:error, term()}
  def fetch(%{repository: repo, bundle: bundle, version: version, prompt_name: prompt_name}) do
    with {:ok, project} <- get_project(repo),
         {:ok, prompt_set} <- get_prompt_set(project.id, bundle, version),
         {:ok, prompt} <- get_prompt(prompt_set.id, prompt_name) do
      {:ok,
       %{
         template: prompt.template,
         parameters: prompt.parameters,
         metadata: prompt.metadata,
         prompt_set_id: prompt_set.id
       }}
    end
  end

  defp get_project(repository) do
    case Anvil.Projects.Project
         |> Ash.Query.filter(repository == ^repository)
         |> Ash.read_one() do
      {:ok, nil} -> {:error, :project_not_found}
      {:ok, project} -> {:ok, project}
      {:error, error} -> {:error, error}
    end
  end

  defp get_prompt_set(project_id, bundle_slug, version) do
    # First resolve version aliases if needed
    resolved_version = resolve_version_alias(project_id, bundle_slug, version)

    case Anvil.Prompts.PromptSet
         |> Ash.Query.filter(
           project_id == ^project_id and slug == ^bundle_slug and version == ^resolved_version
         )
         |> Ash.read_one() do
      {:ok, nil} -> {:error, :prompt_set_not_found}
      {:ok, prompt_set} -> {:ok, prompt_set}
      {:error, error} -> {:error, error}
    end
  end

  defp get_prompt(prompt_set_id, prompt_slug) do
    case Anvil.Prompts.Prompt
         |> Ash.Query.filter(prompt_set_id == ^prompt_set_id and slug == ^prompt_slug)
         |> Ash.read_one() do
      {:ok, nil} -> {:error, :prompt_not_found}
      {:ok, prompt} -> {:ok, prompt}
      {:error, error} -> {:error, error}
    end
  end

  defp resolve_version_alias(_project_id, _bundle_slug, "stable") do
    # TODO: Implement stable version lookup
    "1.0.0"
  end

  defp resolve_version_alias(_project_id, _bundle_slug, "latest") do
    # TODO: Implement latest version lookup
    "1.0.0"
  end

  defp resolve_version_alias(_project_id, _bundle_slug, version) do
    version
  end
end
