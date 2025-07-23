defmodule AnvilWeb.Components.Common.DashboardHeaderComponent do
  use AnvilWeb, :html

  alias AnvilWeb.Components.Common.UserMenuComponent

  @moduledoc """
  Dashboard header component with 8-bit retro theme.
  """

  @doc """
  Renders the dashboard header.

  ## Examples

      <.dashboard_header current_user={@current_user} is_live_view={true} />
  """
  attr :current_user, :any, default: nil
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
      
    <!-- Center - Command Palette -->
      <div class="navbar-center">
        <div class="form-control">
          <%= if @is_live_view do %>
            <.live_component
              module={AnvilWeb.Components.Common.CommandPaletteComponent}
              id="global-command-palette"
            />
          <% else %>
            <div class="flex items-center gap-2">
              <input
                type="text"
                placeholder="Type to search or run commands..."
                class="w-64 lg:w-96 h-8 px-3 font-mono bg-amber-900/20 border-2 border-primary text-amber-100 placeholder-amber-100/60 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] focus:outline-none focus:border-yellow-400"
                style="background-color: rgba(120, 53, 15, 0.2) !important;"
                disabled
              />
              <kbd class="kbd kbd-sm bg-base-100 border-2 border-primary shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]">
                ⌘K
              </kbd>
            </div>
          <% end %>
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
