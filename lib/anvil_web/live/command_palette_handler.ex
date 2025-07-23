defmodule AnvilWeb.Live.CommandPaletteHandler do
  @moduledoc """
  Shared behaviour for handling command palette keyboard shortcuts in LiveViews.
  """

  defmacro __using__(_opts) do
    quote do
      # Always catch the global_keydown event and delegate to command palette handler
      @impl true
      def handle_event("global_keydown", params, socket) do
        case params do
          %{"key" => "k", "metaKey" => true} ->
            send(self(), :open_command_palette)
            {:noreply, socket}

          %{"key" => "k", "ctrlKey" => true} ->
            send(self(), :open_command_palette)
            {:noreply, socket}

          _ ->
            {:noreply, socket}
        end
      end

      @impl true
      def handle_info(:open_command_palette, socket) do
        send_update(AnvilWeb.Components.Common.CommandPaletteComponent,
          id: "global-command-palette",
          open_palette: true
        )

        {:noreply, socket}
      end

      def handle_info({:focus_input, component_id}, socket) do
        {:noreply, push_event(socket, "focus", %{target: "##{component_id}-input"})}
      end

      # Make both functions overridable so LiveViews can add their own handlers
      defoverridable handle_event: 3, handle_info: 2
    end
  end
end
