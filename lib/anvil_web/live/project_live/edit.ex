defmodule AnvilWeb.ProjectLive.Edit do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

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
        actor: socket.assigns.current_user
      )

    form = build_form(project, socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:page_title, "Edit #{project.name}")
     |> assign(:project, project)
     |> assign(:form, form)
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: project.name, href: ~p"/projects/#{project}"},
       %{label: "Edit", current: true}
     ])}
  end

  @impl true
  def handle_event("validate", %{"form" => project_params}, socket) do
    form =
      socket.assigns.form
      |> AshPhoenix.Form.validate(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"form" => project_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_navigate(to: ~p"/projects/#{project}")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  # Delegate other events to the CommandPaletteHandler
  def handle_event(event, params, socket) do
    super(event, params, socket)
  end

  defp build_form(project, actor) do
    AshPhoenix.Form.for_update(project, :update,
      as: "form",
      actor: actor
    )
    |> to_form()
  end
end
