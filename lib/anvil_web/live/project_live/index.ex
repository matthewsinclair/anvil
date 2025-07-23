defmodule AnvilWeb.ProjectLive.Index do
  use AnvilWeb, :live_view

  alias Anvil.Projects

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    projects = list_projects(socket)

    {:ok,
     socket
     |> assign(:page_title, "Projects")
     |> assign(:current_path, "/projects")
     |> assign(:has_projects, projects != [])
     |> stream(:projects, projects), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    project = Projects.get_by_id!(id, actor: socket.assigns.current_user)
    {:ok, _} = Projects.destroy(project, actor: socket.assigns.current_user)

    # Check if we still have projects after deletion
    remaining_projects = list_projects(socket)

    {:noreply,
     socket
     |> put_flash(:info, "Project deleted successfully")
     |> assign(:has_projects, remaining_projects != [])
     |> stream_delete(:projects, project)}
  end

  defp list_projects(socket) do
    Projects.read_all!(actor: socket.assigns.current_user)
  end
end
