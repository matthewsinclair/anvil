defmodule AnvilWeb.Live.CommandPaletteHandler do
  @moduledoc """
  Shared behavior for handling command palette keyboard shortcuts in LiveViews.
  """

  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_event("global_keydown", %{"key" => "k", "metaKey" => true}, socket) do
        send_update(AnvilWeb.Components.Common.CommandPaletteComponent,
          id: "global-command-palette",
          open_palette: true
        )

        {:noreply, socket}
      end

      def handle_event("global_keydown", %{"key" => "k", "ctrlKey" => true}, socket) do
        send_update(AnvilWeb.Components.Common.CommandPaletteComponent,
          id: "global-command-palette",
          open_palette: true
        )

        {:noreply, socket}
      end

      def handle_event("global_keydown", _params, socket), do: {:noreply, socket}

      @impl true
      def handle_info({:open_command_palette, component_id}, socket) do
        send_update(AnvilWeb.Components.Common.CommandPaletteComponent,
          id: component_id,
          open_palette: true
        )

        {:noreply, socket}
      end

      defoverridable handle_event: 3, handle_info: 2
    end
  end
end
