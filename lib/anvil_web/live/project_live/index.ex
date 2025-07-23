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

    case Projects.destroy(project, actor: socket.assigns.current_user) do
      :ok ->
        # Check if we still have projects after deletion
        remaining_projects = list_projects(socket)

        {:noreply,
         socket
         |> put_flash(:info, "Project deleted successfully")
         |> assign(:has_projects, remaining_projects != [])
         |> stream_delete(:projects, project)}

      {:error, %Ash.Error.Invalid{} = error} ->
        # Check if it's a foreign key constraint error
        foreign_key_error =
          Enum.find(error.errors, fn
            %Ash.Error.Changes.InvalidAttribute{private_vars: private_vars} ->
              Keyword.get(private_vars, :constraint_type) == :foreign_key

            _ ->
              false
          end)

        message =
          if foreign_key_error do
            "Cannot delete project with existing prompt sets"
          else
            "Failed to delete project"
          end

        {:noreply, put_flash(socket, :error, message)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to delete project")}
    end
  end

  defp list_projects(socket) do
    Projects.read_all!(actor: socket.assigns.current_user, load: [:prompt_sets])
  end
end
