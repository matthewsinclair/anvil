defmodule AnvilWeb.Components.Common.DashboardHeaderComponent do
  use AnvilWeb, :html

  alias AnvilWeb.Components.Common.UserMenuComponent

  @moduledoc """
  Dashboard header component with 8-bit retro theme.
  """

  @doc """
  Renders the dashboard header.

  ## Examples

      <.dashboard_header current_user={@current_user} title="Dashboard" />
  """
  attr :current_user, :any, default: nil
  attr :title, :string, default: "Dashboard"

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
      
    <!-- Center - Command/Search box -->
      <div class="navbar-center">
        <div class="form-control">
          <div class="flex items-center gap-2">
            <input
              type="text"
              placeholder="Type to search or run commands..."
              class="input input-bordered input-primary input-sm w-64 lg:w-96 font-mono bg-base-200 border-base-content/20 placeholder-base-content/40"
              disabled
            />
            <kbd class="kbd kbd-sm">⌘</kbd>
          </div>
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
