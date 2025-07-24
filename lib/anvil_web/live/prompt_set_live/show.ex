defmodule AnvilWeb.PromptSetLive.Show do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler
  import AnvilWeb.ViewHelpers

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    project =
      Projects.by_id!(project_id,
        actor: socket.assigns.current_user
      )

    {:ok,
     socket
     |> assign(:current_path, "/projects")
     |> assign(:project, project), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    prompt_set =
      Prompts.get_prompt_set_by_id!(id,
        actor: socket.assigns.current_user,
        load: [:prompts, :versions]
      )

    {:noreply,
     socket
     |> assign(:page_title, prompt_set.name)
     |> assign(:prompt_set, prompt_set)
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: socket.assigns.project.name, href: ~p"/projects/#{socket.assigns.project}"},
       %{label: "Prompt Sets", href: ~p"/projects/#{socket.assigns.project}/prompt-sets"},
       %{label: prompt_set.name, current: true}
     ])}
  end

  @impl true
  def handle_event("delete_version", %{"id" => id}, socket) do
    case Prompts.get_version_by_id(id, actor: socket.assigns.current_user) do
      {:ok, version} ->
        case Ash.destroy(version, actor: socket.assigns.current_user) do
          :ok ->
            # Reload the prompt set to get updated versions list
            prompt_set =
              Prompts.get_prompt_set_by_id!(socket.assigns.prompt_set.id,
                actor: socket.assigns.current_user,
                load: [:prompts, :versions]
              )

            {:noreply,
             socket
             |> assign(:prompt_set, prompt_set)
             |> put_flash(:info, "Version #{version.version_number} deleted")}

          {:error, _} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to delete version")}
        end

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Version not found")}
    end
  end

  @impl true
  def handle_event("create_version", params, socket) do
    IO.inspect(params, label: "Version creation params")

    version_number = params["version_number"] || ""
    changelog = if params["changelog"] == "", do: nil, else: params["changelog"]

    if version_number == "" do
      {:noreply,
       socket
       |> put_flash(:error, "Version number is required")}
    else
      # Just create a version directly - much simpler!
      # First, load the prompts to create the snapshot
      {:ok, prompts} =
        Prompts.list_prompts(
          query: [filter: [prompt_set_id: socket.assigns.prompt_set.id]],
          actor: socket.assigns.current_user
        )

      # Create the snapshot
      snapshot = %{
        name: socket.assigns.prompt_set.name,
        slug: socket.assigns.prompt_set.slug,
        metadata: socket.assigns.prompt_set.metadata,
        dependencies: socket.assigns.prompt_set.dependencies,
        edit_mode: socket.assigns.prompt_set.edit_mode,
        prompts:
          Enum.map(prompts, fn prompt ->
            %{
              name: prompt.name,
              slug: prompt.slug,
              template: prompt.template,
              parameters: prompt.parameters,
              metadata: prompt.metadata
            }
          end)
      }

      # Create the version using the normal create action
      case Prompts.create_version(
             version_number,
             snapshot,
             socket.assigns.prompt_set.id,
             %{
               changelog: changelog,
               published_by_id: socket.assigns.current_user.id
             },
             actor: socket.assigns.current_user
           ) do
        {:ok, _result} ->
          # Reload the prompt set to get the new version
          prompt_set =
            Prompts.get_prompt_set_by_id!(socket.assigns.prompt_set.id,
              actor: socket.assigns.current_user,
              load: [:prompts, :versions]
            )

          {:noreply,
           socket
           |> assign(:prompt_set, prompt_set)
           |> put_flash(:info, "Version #{version_number} created successfully")}

        {:error, error} ->
          IO.inspect(error, label: "Version creation error")

          {:noreply,
           socket
           |> put_flash(:error, "Failed to create version")}
      end
    end
  end

  # Helper functions
  defp count_prompts(prompt_set) do
    length(prompt_set.prompts || [])
  end

  defp count_versions(prompt_set) do
    length(prompt_set.versions || [])
  end

  defp next_version(prompt_set) do
    case prompt_set.versions do
      [] ->
        # No versions yet, default to current prompt set version with patch increment
        increment_patch(prompt_set.version)

      versions ->
        # Get the latest version and increment patch
        latest = Enum.max_by(versions, & &1.created_at)
        increment_patch(latest.version_number)
    end
  end

  defp increment_patch(version_string) do
    case String.split(version_string, ".") do
      [major, minor, patch] ->
        patch_num = String.to_integer(patch) + 1
        "#{major}.#{minor}.#{patch_num}"

      _ ->
        # If version format is unexpected, default to 0.1.0
        "0.1.0"
    end
  end
end
