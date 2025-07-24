defmodule AnvilWeb.OrganisationLive.Index do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  alias Anvil.Organisations
  alias Anvil.Organisations.ListUserOrganisations

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    # Get user's organisations with membership count
    organisations =
      socket.assigns.current_user
      |> ListUserOrganisations.list_user_organisations()
      |> Enum.map(fn org ->
        # Load membership count
        {:ok, memberships} =
          Organisations.list_memberships(
            query: [filter: [organisation_id: org.id]],
            actor: socket.assigns.current_user
          )

        Map.put(org, :member_count, length(memberships))
      end)

    {:ok,
     socket
     |> assign(:page_title, "Organisations")
     |> assign(:organisations, organisations)
     |> assign(:show_new_form, false)
     |> assign(:form, build_form())
     |> assign(:breadcrumb_items, [
       %{label: "Organisations", current: true}
     ])
     |> stream(:organisations, organisations), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  @impl true
  def handle_event("toggle_new_form", _, socket) do
    {:noreply, assign(socket, :show_new_form, !socket.assigns.show_new_form)}
  end

  def handle_event("create_organisation", %{"name" => name, "description" => description}, socket) do
    case Organisations.create_organisation(%{name: name, description: description},
           actor: socket.assigns.current_user
         ) do
      {:ok, _organisation} ->
        # Owner membership is now automatically created by the resource
        # Reload organisations
        organisations = reload_organisations(socket.assigns.current_user)

        {:noreply,
         socket
         |> put_flash(:info, "Organisation created successfully")
         |> assign(:organisations, organisations)
         |> assign(:show_new_form, false)
         |> assign(:form, build_form())
         |> stream(:organisations, organisations, reset: true)}

      {:error, %{errors: errors}} ->
        error_message =
          errors
          |> Enum.map(fn error ->
            case error do
              %{field: :slug} ->
                "Organisation name already taken"

              %{field: :name, message: message} ->
                if String.contains?(message, "already been taken") do
                  "Organisation name already taken"
                else
                  "Organisation name is required"
                end

              %{field: :name} ->
                "Organisation name is required"

              _ ->
                "Failed to create organisation"
            end
          end)
          |> Enum.join(", ")

        {:noreply, put_flash(socket, :error, error_message)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to create organisation")}
    end
  end

  defp reload_organisations(user) do
    user
    |> ListUserOrganisations.list_user_organisations()
    |> Enum.map(fn org ->
      {:ok, memberships} =
        Organisations.list_memberships(
          query: [filter: [organisation_id: org.id]],
          actor: user
        )

      Map.put(org, :member_count, length(memberships))
    end)
  end

  defp build_form do
    %{name: "", description: ""}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="bg-base-100 border-2 border-primary p-6">
        <div class="flex items-start justify-between">
          <div>
            <h1 class="text-3xl font-bold text-primary uppercase tracking-wider font-mono">
              ▪ Organisations
            </h1>
            <p class="text-sm text-base-content/60 font-mono mt-1">
              Manage your organisations and team members
            </p>
          </div>

          <button phx-click="toggle_new_form" class="btn btn-primary btn-sm font-mono uppercase">
            + New Organisation
          </button>
        </div>
      </div>
      
    <!-- New Organisation Form -->
      <div :if={@show_new_form} class="bg-base-100 border-2 border-primary p-6">
        <form phx-submit="create_organisation" class="space-y-4">
          <div>
            <label class="label">
              <span class="label-text font-mono uppercase text-primary">Name</span>
            </label>
            <input
              type="text"
              name="name"
              class="input input-bordered input-primary w-full font-mono"
              placeholder="My Organisation"
              required
            />
          </div>

          <div>
            <label class="label">
              <span class="label-text font-mono uppercase text-primary">Description</span>
              <span class="label-text-alt text-base-content/60 font-mono">(Optional)</span>
            </label>
            <textarea
              name="description"
              class="textarea textarea-bordered textarea-primary w-full font-mono"
              placeholder="What is this organisation for?"
              rows="3"
            ></textarea>
          </div>

          <div class="flex items-center justify-between pt-6 border-t-2 border-base-300">
            <button
              type="button"
              phx-click="toggle_new_form"
              class="btn btn-ghost font-mono uppercase"
            >
              Cancel
            </button>
            <button type="submit" class="btn btn-primary font-mono uppercase">
              Create Organisation
            </button>
          </div>
        </form>
      </div>
      
    <!-- Organisations Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div :for={{id, org} <- @streams.organisations} id={id} class="group">
          <div class="card bg-base-100 border-2 border-base-300 hover:border-primary transition-colors">
            <div class="card-body p-4">
              <!-- Organisation Header -->
              <div class="flex items-start justify-between">
                <.link navigate={~p"/organisations/#{org}"} class="flex-1">
                  <h3 class="card-title text-lg font-mono uppercase text-primary group-hover:underline">
                    {org.name}
                  </h3>
                  <p class="text-xs text-base-content/60 font-mono">
                    {org.member_count} members
                  </p>
                </.link>

                <div :if={org.personal?} class="badge badge-secondary badge-sm font-mono">
                  Personal
                </div>
              </div>
              
    <!-- Description -->
              <p :if={org.description} class="text-sm text-base-content/80 font-mono mt-2">
                {org.description}
              </p>
              
    <!-- Stats -->
              <div class="flex gap-4 mt-4 pt-4 border-t border-base-300">
                <div class="text-xs font-mono">
                  <span class="text-base-content/60">Created:</span>
                  <span class="text-base-content">{format_date(org.created_at)}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
