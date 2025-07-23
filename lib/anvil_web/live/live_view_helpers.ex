defmodule AnvilWeb.LiveViewHelpers do
  @moduledoc """
  Common helpers for LiveViews, including command palette setup.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  @doc """
  Sets up the command palette for a LiveView.
  Call this in mount/3 after the initial socket setup.
  """
  def setup_command_palette(socket) do
    attach_hook(socket, :setup_command_palette, :handle_params, fn
      _params, _uri, socket ->
        {:cont, push_event(socket, "mount_command_palette", %{})}
    end)
  end

  @doc """
  Renders the command palette component.
  Include this at the top of your LiveView's render function.
  """
  def command_palette(assigns) do
    ~H"""
    <!-- Command Palette - Positioned in header -->
    <div class="fixed top-4 left-1/2 -translate-x-1/2 z-[60]">
      <.live_component
        module={AnvilWeb.Components.Common.CommandPaletteComponent}
        id="global-command-palette"
      />
    </div>
    """
  end
end
