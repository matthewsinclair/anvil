defmodule AnvilWeb.Components.Common.OrganisationSwitcherComponent do
  use AnvilWeb, :live_component

  @moduledoc """
  Organisation switcher dropdown component for switching between organisations.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <label tabindex="0" class="btn btn-ghost normal-case">
        <span class="text-sm font-medium">{@current_organisation.name}</span>
        <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </label>
      <ul
        tabindex="0"
        class="menu menu-compact dropdown-content mt-3 p-2 shadow bg-base-100 rounded-box w-52 border-2 border-primary"
      >
        <%= for org <- @organisations do %>
          <li>
            <a
              href="#"
              phx-click="switch_organisation"
              phx-value-org-id={org.id}
              phx-target={@myself}
              class={if org.id == @current_organisation.id, do: "active", else: ""}
            >
              <span class="flex-1">{org.name}</span>
              <%= if org.personal? do %>
                <span class="badge badge-sm badge-primary">Personal</span>
              <% end %>
            </a>
          </li>
        <% end %>
        <div class="divider my-1"></div>
        <li>
          <.link navigate={~p"/app"} class="font-medium">
            Manage Organisations
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def handle_event("switch_organisation", %{"org-id" => org_id}, socket) do
    # Send the event to the parent LiveView to handle the organisation switch
    send(self(), {:switch_organisation, org_id})
    {:noreply, socket}
  end
end
