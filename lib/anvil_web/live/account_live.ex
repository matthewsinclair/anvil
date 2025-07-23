defmodule AnvilWeb.AccountLive do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler
  import AnvilWeb.LiveViewHelpers

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Account")
     |> assign(:current_path, "/account"), layout: {AnvilWeb.Layouts, :dashboard}}
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
            >> Account
          </h1>
          <p class="text-sm text-base-content/60 font-mono mt-1">
            Manage your profile and authentication settings.
          </p>
        </div>
      </div>
      
    <!-- Profile Section -->
      <div class="bg-base-100 border-2 border-primary shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
        <div class="px-6 py-4 border-b-2 border-primary">
          <h3 class="text-lg font-bold font-mono uppercase">» Profile Information</h3>
        </div>
        <div class="p-6 space-y-6">
          <!-- Avatar -->
          <div class="flex items-center gap-6">
            <div class="avatar">
              <div class="w-24 ring ring-primary ring-offset-base-100 ring-offset-2">
                <img
                  src={
                    AnvilWeb.Components.ComponentHelpers.gravatar_url(
                      if(assigns[:current_user], do: assigns[:current_user].email, else: nil),
                      200
                    )
                  }
                  alt="User avatar"
                  class="pixelated"
                />
              </div>
            </div>
            <div>
              <p class="font-mono text-sm text-base-content/60">GRAVATAR</p>
              <p class="font-mono text-xs text-base-content/40">Change at gravatar.com</p>
            </div>
          </div>
          
    <!-- Email -->
          <div>
            <label class="text-sm font-mono text-base-content/60 uppercase">Email Address</label>
            <p class="font-mono text-lg mt-1">
              {if assigns[:current_user], do: assigns[:current_user].email, else: "user@example.com"}
            </p>
          </div>
          
    <!-- Member Since -->
          <div>
            <label class="text-sm font-mono text-base-content/60 uppercase">Member Since</label>
            <p class="font-mono text-lg mt-1">
              <%= if assigns[:current_user] && Map.get(assigns[:current_user], :inserted_at) do %>
                {Calendar.strftime(assigns[:current_user].inserted_at, "%B %d, %Y")}
              <% else %>
                January 1, 2025
              <% end %>
            </p>
          </div>
        </div>
      </div>
      
    <!-- Security Section -->
      <div class="bg-base-100 border-2 border-primary shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
        <div class="px-6 py-4 border-b-2 border-primary">
          <h3 class="text-lg font-bold font-mono uppercase">» Security Settings</h3>
        </div>
        <div class="p-6 space-y-4">
          <button class="btn btn-primary btn-sm uppercase font-mono tracking-wider">
            >> Change Password
          </button>
          <p class="text-sm font-mono text-base-content/60">
            Last password change: Never
          </p>
        </div>
      </div>
      
    <!-- ASCII Art -->
      <div class="text-center py-4">
        <pre class="text-xs text-base-content/40 font-mono inline-block">
        ╭─────────────╮
        │ USER SECURE │
        ╰─────────────╯
        </pre>
      </div>
    </div>
    """
  end
end
