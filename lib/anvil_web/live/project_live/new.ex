defmodule AnvilWeb.ProjectLive.New do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler
  import AnvilWeb.LiveViewHelpers

  alias Anvil.Projects

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    form = build_form(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "New Project")
     |> assign(:current_path, "/projects/new")
     |> assign(:form, form)
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: "New", current: true}
     ]), layout: {AnvilWeb.Layouts, :dashboard}}
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
         |> put_flash(:info, "Project created successfully")
         |> push_navigate(to: ~p"/projects/#{project}")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp build_form(actor) do
    AshPhoenix.Form.for_create(Projects.Project, :create,
      as: "form",
      actor: actor
    )
    |> to_form()
  end
end
