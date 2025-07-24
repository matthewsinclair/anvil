defmodule AnvilWeb.PromptSetLive.Edit do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    project =
      Projects.by_id!(project_id,
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
        actor: socket.assigns.current_user
      )

    form = build_form(prompt_set, socket.assigns.current_user)

    # Convert metadata map to JSON string for display
    metadata_string =
      case prompt_set.metadata do
        nil -> "{}"
        map when map == %{} -> "{}"
        map -> Jason.encode!(map)
      end

    {:noreply,
     socket
     |> assign(:page_title, "Edit #{prompt_set.name}")
     |> assign(:prompt_set, prompt_set)
     |> assign(:form, form)
     |> assign(:metadata_string, metadata_string)
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: socket.assigns.project.name, href: ~p"/projects/#{socket.assigns.project}"},
       %{label: "Prompt Sets", href: ~p"/projects/#{socket.assigns.project}/prompt-sets"},
       %{
         label: prompt_set.name,
         href: ~p"/projects/#{socket.assigns.project}/prompt-sets/#{prompt_set}"
       },
       %{label: "Edit", current: true}
     ])}
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
         |> put_flash(:info, "Prompt set updated successfully")
         |> push_navigate(to: ~p"/projects/#{socket.assigns.project}/prompt-sets/#{prompt_set}")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  # Delegate other events to the CommandPaletteHandler
  def handle_event(event, params, socket) do
    super(event, params, socket)
  end

  defp build_form(prompt_set, actor) do
    AshPhoenix.Form.for_update(prompt_set, :update,
      as: "form",
      actor: actor
    )
    |> to_form()
  end
end
