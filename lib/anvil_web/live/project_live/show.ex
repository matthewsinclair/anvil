defmodule AnvilWeb.ProjectLive.Show do
  use AnvilWeb, :live_view

  alias Anvil.Projects

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_path, "/projects"), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    project =
      Projects.get_by_id!(id,
        actor: socket.assigns.current_user,
        load: [:prompt_sets]
      )

    {:noreply,
     socket
     |> assign(:page_title, project.name)
     |> assign(:project, project)
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: project.name, current: true}
     ])}
  end

  # Helper functions for the template
  defp count_total_prompts(_project) do
    # TODO: Implement actual count when prompts are loaded
    0
  end

  defp count_versions(_project) do
    # TODO: Implement actual count when versions are loaded
    0
  end

  defp recent_prompt_sets(project) do
    (project.prompt_sets || [])
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    |> Enum.take(5)
  end
end
