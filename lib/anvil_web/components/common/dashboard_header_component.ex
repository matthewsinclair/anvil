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
      
    <!-- Page Title -->
      <div class="navbar-start hidden lg:flex">
        <h1 class="text-xl font-bold uppercase tracking-wider text-primary font-mono">
          {@title}
        </h1>
      </div>
      
    <!-- Center - could add search here later -->
      <div class="navbar-center hidden md:flex">
        <!-- Reserved for future search functionality -->
      </div>
      
    <!-- Right side - User Menu -->
      <div class="navbar-end">
        <UserMenuComponent.user_menu current_user={@current_user} />
      </div>
    </header>
    """
  end
end
