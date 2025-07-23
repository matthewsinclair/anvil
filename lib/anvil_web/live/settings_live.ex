defmodule AnvilWeb.SettingsLive do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:current_path, "/settings"), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="bg-base-100 border-2 border-primary p-6">
        <div>
          <h1 class="text-3xl font-bold text-primary uppercase tracking-wider font-mono">
            >> Settings
          </h1>
          <p class="text-sm text-base-content/60 font-mono mt-1">
            Configure your Anvil experience
          </p>
        </div>
      </div>
      
    <!-- Settings Content -->
      <div class="bg-base-100 border-2 border-primary shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
        <div class="px-6 py-4 border-b-2 border-primary">
          <h3 class="text-lg font-bold font-mono uppercase">» Application Settings</h3>
        </div>
        <div class="p-6">
          <p class="text-base-content/80 font-mono mb-4">
            Customize your context engineering workflow.
          </p>
          <p class="text-sm text-base-content/60 font-mono">[Under Construction]</p>
        </div>
      </div>
      
    <!-- ASCII Art -->
      <div class="text-center py-4">
        <pre class="text-xs text-base-content/40 font-mono inline-block">
        ╭─────────────╮
        │  CONFIGURE  │
        ╰─────────────╯
        </pre>
      </div>
    </div>
    """
  end
end
