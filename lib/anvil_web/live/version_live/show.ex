defmodule AnvilWeb.VersionLive.Show do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler
  import AnvilWeb.ViewHelpers

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"project_id" => project_id, "prompt_set_id" => prompt_set_id}, _session, socket) do
    project = Projects.by_id!(project_id, actor: socket.assigns.current_user)
    prompt_set = Prompts.get_prompt_set_by_id!(prompt_set_id, actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:current_path, "/projects")
     |> assign(:project, project)
     |> assign(:prompt_set, prompt_set)
     |> assign(:expanded_prompts, MapSet.new()), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    version = Prompts.get_version_by_id!(id, actor: socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:page_title, "Version #{version.version_number}")
     |> assign(:version, version)
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: socket.assigns.project.name, href: ~p"/projects/#{socket.assigns.project}"},
       %{label: "Prompt Sets", href: ~p"/projects/#{socket.assigns.project}/prompt-sets"},
       %{
         label: socket.assigns.prompt_set.name,
         href: ~p"/projects/#{socket.assigns.project}/prompt-sets/#{socket.assigns.prompt_set}"
       },
       %{label: "Version #{version.version_number}", current: true}
     ])}
  end

  @impl true
  def handle_event("toggle_prompt", %{"index" => index}, socket) do
    index = String.to_integer(index)
    expanded = socket.assigns.expanded_prompts

    expanded =
      if MapSet.member?(expanded, index) do
        MapSet.delete(expanded, index)
      else
        MapSet.put(expanded, index)
      end

    {:noreply, assign(socket, :expanded_prompts, expanded)}
  end
end
