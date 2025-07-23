defmodule AnvilWeb.Components.Common.DashboardHeaderComponent do
  use AnvilWeb, :html

  alias AnvilWeb.Components.Common.UserMenuComponent

  @moduledoc """
  Dashboard header component with 8-bit retro theme.
  """

  @doc """
  Renders the dashboard header with command palette.

  ## Examples

      <.dashboard_header current_user={@current_user} />
  """
  attr :current_user, :any, default: nil

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
      
    <!-- Center - Command Palette -->
      <div class="navbar-center">
        <div class="form-control">
          <.live_component
            module={AnvilWeb.Components.Common.CommandPaletteComponent}
            id="global-command-palette"
          />
        </div>
      </div>
      
    <!-- Right side - User Menu -->
      <div class="navbar-end">
        <UserMenuComponent.user_menu current_user={@current_user} />
      </div>
    </header>
    """
  end
end
