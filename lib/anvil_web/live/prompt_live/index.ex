defmodule AnvilWeb.PromptLive.Index do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"project_id" => project_id, "prompt_set_id" => prompt_set_id}, _session, socket) do
    project = Projects.get_by_id!(project_id, actor: socket.assigns.current_user)

    prompt_set =
      Prompts.get_prompt_set_by_id!(prompt_set_id,
        actor: socket.assigns.current_user,
        load: [:prompts]
      )

    # Verify the prompt set belongs to the project
    if prompt_set.project_id != project.id do
      raise Ash.Error.Query.NotFound
    end

    prompts = prompt_set.prompts || []

    {:ok,
     socket
     |> assign(:page_title, "Prompts - #{prompt_set.name}")
     |> assign(:current_path, "/projects")
     |> assign(:project, project)
     |> assign(:prompt_set, prompt_set)
     |> assign(:has_prompts, prompts != [])
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: project.name, href: ~p"/projects/#{project}"},
       %{label: "Prompt Sets", href: ~p"/projects/#{project}/prompt-sets"},
       %{label: prompt_set.name, href: ~p"/projects/#{project}/prompt-sets/#{prompt_set}"},
       %{label: "Prompts", current: true}
     ])
     |> stream(:prompts, prompts), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    prompt = Prompts.get_prompt_by_id!(id, actor: socket.assigns.current_user)

    case Prompts.destroy_prompt(prompt, actor: socket.assigns.current_user) do
      :ok ->
        # Reload prompt set to get updated prompts
        prompt_set =
          Prompts.get_prompt_set_by_id!(socket.assigns.prompt_set.id,
            actor: socket.assigns.current_user,
            load: [:prompts]
          )

        remaining_prompts = prompt_set.prompts || []

        {:noreply,
         socket
         |> put_flash(:info, "Prompt deleted successfully")
         |> assign(:has_prompts, remaining_prompts != [])
         |> stream_delete(:prompts, prompt)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to delete prompt")}
    end
  end

  # Delegate other events to the CommandPaletteHandler
  def handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
