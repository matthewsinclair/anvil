defmodule AnvilWeb.Components.Common.SidebarComponent do
  use AnvilWeb, :html

  @moduledoc """
  Sidebar navigation component for the dashboard with 8-bit retro theme.
  """

  @doc """
  Renders the sidebar navigation.

  ## Examples

      <.sidebar current_path={@conn.request_path} />
  """
  attr :current_path, :string, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="drawer-side">
      <label for="drawer-toggle" class="drawer-overlay"></label>
      <aside class="min-h-full w-64 bg-base-100 flex flex-col">
        <!-- Company Branding - matches header height -->
        <div class="flex items-center px-6 h-16 border-b-2 border-primary">
          <.link navigate={~p"/"} class="flex items-center gap-3 hover:opacity-80 transition-opacity">
            <div class="w-8 h-8 flex-shrink-0">
              <img src={~p"/images/anvil_logo.svg"} alt="Anvil" class="w-full h-full pixelated" />
            </div>
            <div>
              <h1 class="text-lg font-bold uppercase tracking-wider text-primary">Anvil</h1>
              <p class="text-[10px] text-base-content/60 font-mono -mt-1">Context Engineering</p>
            </div>
          </.link>
        </div>
        
    <!-- Navigation Menu -->
        <nav class="p-4 flex-1 overflow-y-auto">
          <ul class="menu menu-vertical w-full space-y-1">
            <li>
              <.nav_item
                href={~p"/app"}
                current_path={@current_path}
                icon={retro_icon(:dashboard)}
                label="Dashboard"
              />
            </li>
            <li>
              <.nav_item
                href={~p"/projects"}
                current_path={@current_path}
                icon={retro_icon(:project)}
                label="Projects"
              />
            </li>
            <li>
              <.nav_item
                href={~p"/account"}
                current_path={@current_path}
                icon={retro_icon(:account)}
                label="Account"
              />
            </li>
            <li>
              <.nav_item
                href={~p"/settings"}
                current_path={@current_path}
                icon={retro_icon(:settings)}
                label="Settings"
              />
            </li>
            <li>
              <.nav_item
                href={~p"/help"}
                current_path={@current_path}
                icon={retro_icon(:help)}
                label="Help"
              />
            </li>
          </ul>
          
    <!-- Divider -->
          <div class="my-4">
            <hr class="border-t-2 border-base-300" />
          </div>
          
    <!-- Logout -->
          <ul class="menu menu-vertical w-full">
            <li>
              <.link
                href={~p"/sign-out"}
                method="get"
                class="flex items-center gap-3 px-3 py-2.5 text-base-content/70 hover:bg-error/20 hover:text-error transition-colors font-mono uppercase tracking-wider"
              >
                <span class="text-lg">{retro_icon(:logout)}</span>
                <span class="text-sm font-medium">Logout</span>
              </.link>
            </li>
          </ul>
        </nav>
        
    <!-- Footer -->
        <div class="py-4 px-4 border-t-2 border-base-300">
          <div class="text-[10px] text-base-content/40 text-center font-mono">
            <div>© 2025 Anvil</div>
            <div class="text-[8px] mt-1">
              Elixir |> Phoenix |> Ash
            </div>
          </div>
        </div>
      </aside>
    </div>
    """
  end

  # Private component for navigation items
  attr :href, :string, required: true
  attr :current_path, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true

  defp nav_item(assigns) do
    active =
      assigns.href == assigns.current_path ||
        (assigns.href == "/app" && assigns.current_path == "/dashboard") ||
        (assigns.href == "/projects" && String.starts_with?(assigns.current_path, "/projects"))

    assigns = assign(assigns, :active, active)

    ~H"""
    <.link
      navigate={@href}
      class={[
        "flex items-center gap-3 px-3 py-2.5 transition-colors font-mono uppercase tracking-wider",
        @active && "bg-primary text-primary-content",
        !@active && "text-base-content/70 hover:bg-base-200 hover:text-base-content"
      ]}
    >
      <span class="text-lg flex-shrink-0">{@icon}</span>
      <span class="text-sm font-medium flex-1">{@label}</span>
    </.link>
    """
  end
end
