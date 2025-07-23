defmodule AnvilWeb.PromptSetLive.Index do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    project =
      Projects.get_by_id!(project_id,
        actor: socket.assigns.current_user,
        load: [prompt_sets: [:prompts, :versions]]
      )

    prompt_sets = project.prompt_sets || []

    {:ok,
     socket
     |> assign(:page_title, "Prompt Sets - #{project.name}")
     |> assign(:current_path, "/projects")
     |> assign(:project, project)
     |> assign(:has_prompt_sets, prompt_sets != [])
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: project.name, href: ~p"/projects/#{project}"},
       %{label: "Prompt Sets", current: true}
     ])
     |> stream(:prompt_sets, prompt_sets), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    prompt_set = Prompts.get_prompt_set_by_id!(id, actor: socket.assigns.current_user)

    case Prompts.destroy_prompt_set(prompt_set, actor: socket.assigns.current_user) do
      :ok ->
        # Reload project to get updated prompt sets
        project =
          Projects.get_by_id!(socket.assigns.project.id,
            actor: socket.assigns.current_user,
            load: [prompt_sets: [:prompts, :versions]]
          )

        remaining_prompt_sets = project.prompt_sets || []

        {:noreply,
         socket
         |> put_flash(:info, "Prompt set deleted successfully")
         |> assign(:has_prompt_sets, remaining_prompt_sets != [])
         |> stream_delete(:prompt_sets, prompt_set)}

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
            "Cannot delete prompt set with existing prompts"
          else
            "Failed to delete prompt set"
          end

        {:noreply, put_flash(socket, :error, message)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to delete prompt set")}
    end
  end
end
