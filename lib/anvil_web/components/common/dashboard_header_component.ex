defmodule AnvilWeb.Components.Common.DashboardHeaderComponent do
  use AnvilWeb, :html

  alias AnvilWeb.Components.Common.UserMenuComponent
  alias AnvilWeb.Components.Common.OrganisationSwitcherComponent

  @moduledoc """
  Dashboard header component with 8-bit retro theme.
  """

  @doc """
  Renders the dashboard header with command palette.

  ## Examples

      <.dashboard_header current_user={@current_user} />
  """
  attr :current_user, :any, default: nil
  attr :current_organisation, :any, default: nil
  attr :organisations, :list, default: []
  attr :is_live_view, :boolean, default: false

  def dashboard_header(assigns) do
    ~H"""
    <header class="navbar bg-base-100 border-b-2 border-primary px-4 sm:px-6 lg:px-8 sticky top-0 z-50">
      <!-- Mobile menu button -->
      <div class="navbar-start lg:hidden">
        <label for="drawer-toggle" class="btn btn-square btn-ghost">
          <span class="text-2xl">☰</span>
        </label>
      </div>
      
    <!-- Left side spacer for desktop -->
      <div class="navbar-start hidden lg:flex">
        <!-- Spacer to balance the layout -->
      </div>
      
    <!-- Center - Spacer -->
      <div class="navbar-center">
        <!-- Empty spacer for layout balance -->
      </div>
      
    <!-- Right side - Organisation Switcher and User Menu -->
      <div class="navbar-end">
        <%= if @current_organisation && @organisations != [] do %>
          <.live_component
            module={OrganisationSwitcherComponent}
            id="organisation-switcher"
            current_organisation={@current_organisation}
            organisations={@organisations}
          />
          <div class="divider divider-horizontal mx-2"></div>
        <% end %>
        <UserMenuComponent.user_menu current_user={@current_user} />
      </div>
    </header>
    """
  end
end
