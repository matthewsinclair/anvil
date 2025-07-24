defmodule AnvilWeb.PromptLive.New do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"project_id" => project_id, "prompt_set_id" => prompt_set_id}, _session, socket) do
    project = Projects.by_id!(project_id, actor: socket.assigns.current_user)
    prompt_set = Prompts.get_prompt_set_by_id!(prompt_set_id, actor: socket.assigns.current_user)

    # Verify the prompt set belongs to the project
    if prompt_set.project_id != project.id do
      raise Ash.Error.Query.NotFound
    end

    form = build_form(prompt_set.id, socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "New Prompt")
     |> assign(:current_path, "/projects")
     |> assign(:project, project)
     |> assign(:prompt_set, prompt_set)
     |> assign(:form, form)
     |> assign(:parameters, [])
     |> assign(:validation_result, nil)
     |> assign(:breadcrumb_items, [
       %{label: "Projects", href: ~p"/projects"},
       %{label: project.name, href: ~p"/projects/#{project}"},
       %{label: "Prompt Sets", href: ~p"/projects/#{project}/prompt-sets"},
       %{label: prompt_set.name, href: ~p"/projects/#{project}/prompt-sets/#{prompt_set}"},
       %{label: "Prompts", href: ~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts"},
       %{label: "New", current: true}
     ]), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("validate", %{"form" => prompt_params}, socket) do
    form =
      socket.assigns.form
      |> AshPhoenix.Form.validate(prompt_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"form" => prompt_params}, socket) do
    # Parse parameters before submission
    parameters = parse_parameters(Map.get(prompt_params, "parameters", []))

    # Ensure parameters is always a list
    params =
      prompt_params
      |> Map.put("parameters", parameters || [])

    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, prompt} ->
        {:noreply,
         socket
         |> put_flash(:info, "Prompt created successfully")
         |> push_navigate(
           to:
             ~p"/projects/#{socket.assigns.project}/prompt-sets/#{socket.assigns.prompt_set}/prompts/#{prompt}"
         )}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("add_parameter", _, socket) do
    parameters =
      socket.assigns.parameters ++ [%{"name" => "", "type" => "string", "required" => false}]

    {:noreply, assign(socket, :parameters, parameters)}
  end

  def handle_event("remove_parameter", %{"index" => index}, socket) do
    {index, _} = Integer.parse(index)
    parameters = List.delete_at(socket.assigns.parameters, index)
    {:noreply, assign(socket, :parameters, parameters)}
  end

  def handle_event("update_parameter", params, socket) do
    index = String.to_integer(params["index"])
    field = params["field"]
    value = params["value"] || params["checked"] || ""

    parameters =
      socket.assigns.parameters
      |> List.update_at(index, fn param ->
        case field do
          "name" -> Map.put(param, "name", value)
          "type" -> Map.put(param, "type", value)
          "required" -> Map.put(param, "required", value == "on" || value == "true")
          _ -> param
        end
      end)

    {:noreply, assign(socket, :parameters, parameters)}
  end

  def handle_event("validate_template", _, socket) do
    template = get_form_value(socket.assigns.form, :template) || ""

    validation_result =
      Anvil.Template.Analyzer.validate_parameters(template, socket.assigns.parameters)

    {:noreply, assign(socket, :validation_result, validation_result)}
  end

  def handle_event("auto_populate_parameters", _, socket) do
    template = get_form_value(socket.assigns.form, :template) || ""

    validation_result =
      Anvil.Template.Analyzer.validate_parameters(template, socket.assigns.parameters)

    # Create new parameters for missing variables
    new_params = Anvil.Template.Analyzer.create_parameter_definitions(validation_result.missing)

    # Combine with existing parameters
    updated_parameters = socket.assigns.parameters ++ new_params

    {:noreply,
     socket
     |> assign(:parameters, updated_parameters)
     |> assign(
       :validation_result,
       Anvil.Template.Analyzer.validate_parameters(template, updated_parameters)
     )}
  end

  # Delegate other events to the CommandPaletteHandler
  def handle_event(event, params, socket) do
    super(event, params, socket)
  end

  defp build_form(prompt_set_id, actor) do
    AshPhoenix.Form.for_create(Prompts.Prompt, :create,
      as: "form",
      actor: actor,
      transform_params: fn params, _ ->
        Map.put(params, "prompt_set_id", prompt_set_id)
      end
    )
    |> to_form()
  end

  defp parse_parameters(params) when is_map(params) do
    params
    |> Enum.sort_by(fn {key, _} -> key end)
    |> Enum.map(fn {_, param} -> param end)
    |> parse_parameters()
  end

  defp parse_parameters(params) when is_list(params) do
    params
    |> Enum.reject(fn param ->
      Map.get(param, "name", "") == ""
    end)
    |> Enum.map(fn param ->
      %{
        "name" => Map.get(param, "name", ""),
        "type" => Map.get(param, "type", "string"),
        "required" =>
          case Map.get(param, "required") do
            "true" -> true
            true -> true
            _ -> false
          end
      }
    end)
  end

  defp parse_parameters(_), do: []

  defp get_form_value(form, field) do
    case AshPhoenix.Form.value(form, field) do
      nil -> nil
      value -> value
    end
  end
end
