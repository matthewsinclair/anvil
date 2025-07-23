defmodule AnvilWeb.PromptSetLive.Show do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler
  import AnvilWeb.LiveViewHelpers

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    project =
      Projects.get_by_id!(project_id,
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

  # Helper functions
  defp count_prompts(prompt_set) do
    length(prompt_set.prompts || [])
  end

  defp count_versions(prompt_set) do
    length(prompt_set.versions || [])
  end
end
