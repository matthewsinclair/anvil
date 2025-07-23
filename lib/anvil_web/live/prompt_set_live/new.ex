defmodule AnvilWeb.PromptSetLive.New do
  use AnvilWeb, :live_view

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    project =
      Projects.get_by_id!(project_id,
        actor: socket.assigns.current_user
      )

    form = build_form(project, socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "New Prompt Set")
     |> assign(:current_path, "/projects")
     |> assign(:project, project)
     |> assign(:form, form)
     |> assign(:metadata_string, "{}")
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: project.name, href: ~p"/projects/#{project}"},
       %{label: "Prompt Sets", href: ~p"/projects/#{project}/prompt-sets"},
       %{label: "New", current: true}
     ]), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("validate", %{"form" => prompt_set_params}, socket) do
    # Store the metadata string separately
    metadata_string = Map.get(prompt_set_params, "metadata", "{}")

    # Parse JSON for validation
    params =
      case metadata_string do
        "" ->
          Map.put(prompt_set_params, "metadata", %{})

        json_str ->
          case Jason.decode(json_str) do
            {:ok, decoded} -> Map.put(prompt_set_params, "metadata", decoded)
            # Keep original for form to show error
            {:error, _} -> prompt_set_params
          end
      end

    form =
      socket.assigns.form
      |> AshPhoenix.Form.validate(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(form: form)
     |> assign(metadata_string: metadata_string)}
  end

  def handle_event("save", %{"form" => prompt_set_params}, socket) do
    # Parse metadata JSON before submission
    params =
      case Map.get(prompt_set_params, "metadata") do
        nil ->
          prompt_set_params

        "" ->
          Map.put(prompt_set_params, "metadata", %{})

        json_str ->
          case Jason.decode(json_str) do
            {:ok, decoded} ->
              Map.put(prompt_set_params, "metadata", decoded)

            {:error, _} ->
              # Invalid JSON - let form validation handle it
              prompt_set_params
          end
      end

    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, prompt_set} ->
        {:noreply,
         socket
         |> put_flash(:info, "Prompt set created successfully")
         |> push_navigate(to: ~p"/projects/#{socket.assigns.project}/prompt-sets/#{prompt_set}")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp build_form(project, actor) do
    AshPhoenix.Form.for_create(Prompts.PromptSet, :create,
      as: "form",
      actor: actor,
      transform_params: fn params, _ ->
        Map.put(params, "project_id", project.id)
      end
    )
    |> to_form()
  end
end
