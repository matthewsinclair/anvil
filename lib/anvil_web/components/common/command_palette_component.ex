defmodule AnvilWeb.Components.Common.CommandPaletteComponent do
  use AnvilWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:results, [])
     |> assign(:selected_index, 0)
     |> assign(:open, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative" data-open={@open}>
      <div class="flex items-center gap-2">
        <input
          id={"#{@id}-input"}
          type="text"
          value={@query}
          placeholder="Type to search or run commands..."
          class="w-64 lg:w-96 h-8 px-3 font-mono bg-amber-900/20 border-2 border-primary text-amber-100 placeholder-amber-100/60 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] focus:outline-none focus:border-yellow-400"
          style="background-color: rgba(120, 53, 15, 0.2) !important;"
          phx-change="search"
          phx-target={@myself}
          phx-blur="close"
          phx-keydown="navigate"
          phx-key="Enter|ArrowUp|ArrowDown|Escape"
          phx-hook="CommandPalette"
          autofocus={@open}
        />
        <kbd class="kbd kbd-sm bg-base-100 border-2 border-primary shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]">
          ⌘K
        </kbd>
      </div>

      <%= if @open && length(@results) > 0 do %>
        <div class="absolute top-full mt-2 w-full bg-base-100 border-2 border-primary shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] z-50 max-h-96 overflow-y-auto">
          <%= for {result, index} <- Enum.with_index(@results) do %>
            <div
              class={[
                "px-4 py-2 font-mono text-sm cursor-pointer hover:bg-primary hover:text-primary-content",
                @selected_index == index && "bg-primary text-primary-content"
              ]}
              phx-click="execute"
              phx-value-command={result.id}
              phx-target={@myself}
            >
              <div class="flex items-center gap-2">
                <span class="text-lg">{result.icon}</span>
                <div class="flex-1">
                  <div class="font-bold">{result.name}</div>
                  <div class="text-xs opacity-80">{result.description}</div>
                </div>
                <%= if result.shortcut do %>
                  <kbd class="kbd kbd-xs">{result.shortcut}</kbd>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    results = search_commands(query)

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:results, results)
     |> assign(:selected_index, 0)
     |> assign(:open, query != "")}
  end

  @impl true
  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :open, false)}
  end

  @impl true
  def handle_event("navigate", %{"key" => key}, socket) do
    socket =
      case key do
        "ArrowDown" ->
          new_index = rem(socket.assigns.selected_index + 1, length(socket.assigns.results))
          assign(socket, :selected_index, new_index)

        "ArrowUp" ->
          new_index =
            case socket.assigns.selected_index - 1 do
              -1 -> length(socket.assigns.results) - 1
              n -> n
            end

          assign(socket, :selected_index, new_index)

        "Enter" ->
          if length(socket.assigns.results) > 0 do
            result = Enum.at(socket.assigns.results, socket.assigns.selected_index)
            execute_command(socket, result)
          else
            socket
          end

        "Escape" ->
          socket
          |> assign(:open, false)
          |> assign(:query, "")
          |> push_event("blur", %{})

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("execute", %{"command" => command_id}, socket) do
    result = Enum.find(socket.assigns.results, &(&1.id == command_id))
    {:noreply, execute_command(socket, result)}
  end

  # Called from parent component to open the palette
  def open(component_id) do
    send(self(), {:open_command_palette, component_id})
  end

  @impl true
  def update(%{open_palette: true} = assigns, socket) do
    IO.puts("CommandPaletteComponent: Opening palette!")

    socket =
      socket
      |> assign(assigns)
      |> assign(:open, true)
      |> assign(:query, "")
      |> assign(:results, [])
      |> assign(:selected_index, 0)

    # Push focus event to the input element
    socket = push_event(socket, "focus", %{})

    {:ok, socket}
  end

  def update(assigns, socket) do
    IO.puts("CommandPaletteComponent: Regular update with assigns: #{inspect(Map.keys(assigns))}")
    {:ok, assign(socket, assigns)}
  end

  defp search_commands(""), do: []

  defp search_commands(query) do
    commands = get_all_commands()
    query = String.downcase(query)

    commands
    |> Enum.filter(fn cmd ->
      String.contains?(String.downcase(cmd.name), query) or
        String.contains?(String.downcase(cmd.description), query)
    end)
    |> Enum.take(10)
  end

  defp get_all_commands do
    [
      %{
        id: "go-dashboard",
        name: "Go to Dashboard",
        description: "Navigate to the main dashboard",
        icon: "▶",
        action: {:navigate, "/app"}
      },
      %{
        id: "go-projects",
        name: "Go to Projects",
        description: "View all projects",
        icon: "▪",
        action: {:navigate, "/projects"}
      },
      %{
        id: "new-project",
        name: "New Project",
        description: "Create a new project",
        icon: "+",
        action: {:navigate, "/projects/new"},
        shortcut: "⌘N"
      },
      %{
        id: "go-account",
        name: "Go to Account",
        description: "View account settings",
        icon: "◆",
        action: {:navigate, "/account"}
      },
      %{
        id: "go-settings",
        name: "Go to Settings",
        description: "Application settings",
        icon: "⚙",
        action: {:navigate, "/settings"}
      },
      %{
        id: "go-help",
        name: "Go to Help",
        description: "View documentation",
        icon: "?",
        action: {:navigate, "/help"}
      },
      %{
        id: "logout",
        name: "Log Out",
        description: "Sign out of your account",
        icon: "⬅",
        action: {:navigate, "/sign-out"}
      }
    ]
  end

  defp execute_command(socket, %{action: {:navigate, path}}) do
    socket
    |> assign(:open, false)
    |> assign(:query, "")
    |> push_navigate(to: path)
  end

  defp execute_command(socket, _), do: socket
end
