defmodule AnvilWeb.PromptLive.Show do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(
        %{"project_id" => project_id, "prompt_set_id" => prompt_set_id, "id" => id},
        _session,
        socket
      ) do
    project = Projects.get_by_id!(project_id, actor: socket.assigns.current_user)
    prompt_set = Prompts.get_prompt_set_by_id!(prompt_set_id, actor: socket.assigns.current_user)
    prompt = Prompts.get_prompt_by_id!(id, actor: socket.assigns.current_user)

    # Verify the relationships
    if prompt_set.project_id != project.id || prompt.prompt_set_id != prompt_set.id do
      raise Ash.Error.Query.NotFound
    end

    {:ok,
     socket
     |> assign(:page_title, prompt.name)
     |> assign(:current_path, "/projects")
     |> assign(:project, project)
     |> assign(:prompt_set, prompt_set)
     |> assign(:prompt, prompt)
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: project.name, href: ~p"/projects/#{project}"},
       %{label: "Prompt Sets", href: ~p"/projects/#{project}/prompt-sets"},
       %{label: prompt_set.name, href: ~p"/projects/#{project}/prompt-sets/#{prompt_set}"},
       %{label: "Prompts", href: ~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts"},
       %{label: prompt.name, current: true}
     ]), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
