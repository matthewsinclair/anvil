defmodule AnvilWeb.HelpLive do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler
  import AnvilWeb.LiveViewHelpers

  # Help page can be accessed by anyone, not just authenticated users
  on_mount {AnvilWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Help")
     |> assign(:current_path, "/help"), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.command_palette />
    <div class="space-y-6">
      <!-- Header -->
      <div class="bg-base-100 border-2 border-primary p-6">
        <div>
          <h1 class="text-3xl font-bold text-primary uppercase tracking-wider font-mono">
            >> Help
          </h1>
          <p class="text-sm text-base-content/60 font-mono mt-1">
            Learn how to use Anvil for context engineering and prompt management
          </p>
        </div>
      </div>
      
    <!-- Documentation Section -->
      <div class="bg-base-100 border-2 border-primary shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
        <div class="px-6 py-4 border-b-2 border-primary">
          <h3 class="text-lg font-bold font-mono uppercase">» Documentation</h3>
        </div>
        <div class="p-6 space-y-6">
          <!-- Quick Links -->
          <div>
            <h4 class="text-sm font-bold font-mono uppercase text-primary mb-3">Quick Links</h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <a
                href="#"
                class="block p-3 bg-base-200 border border-base-300 hover:border-primary transition-colors font-mono text-sm"
              >
                >> Getting Started Guide
              </a>
              <a
                href="#"
                class="block p-3 bg-base-200 border border-base-300 hover:border-primary transition-colors font-mono text-sm"
              >
                >> API Documentation
              </a>
              <a
                href="#"
                class="block p-3 bg-base-200 border border-base-300 hover:border-primary transition-colors font-mono text-sm"
              >
                >> Best Practices
              </a>
              <a
                href="#"
                class="block p-3 bg-base-200 border border-base-300 hover:border-primary transition-colors font-mono text-sm"
              >
                >> FAQ
              </a>
            </div>
          </div>

          <p class="text-sm text-base-content/60 font-mono">[Full documentation coming soon]</p>
        </div>
      </div>
      
    <!-- Contact Support -->
      <div class="bg-base-100 border-2 border-primary shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
        <div class="px-6 py-4 border-b-2 border-primary">
          <h3 class="text-lg font-bold font-mono uppercase">» Need Help?</h3>
        </div>
        <div class="p-6">
          <p class="text-sm text-base-content/80 font-mono mb-4">
            Can't find what you're looking for? Get in touch with our support team.
          </p>
          <button class="btn btn-primary btn-sm font-mono uppercase">
            >> Contact Support
          </button>
        </div>
      </div>
      
    <!-- ASCII Art -->
      <div class="text-center py-4">
        <pre class="text-xs text-base-content/40 font-mono inline-block">
        ╭───────────╮
        │   HELP    │
        ╰───────────╯
        </pre>
      </div>
    </div>
    """
  end
end
