defmodule AnvilWeb.Live.OrganisationAware do
  @moduledoc """
  Shared behaviour for LiveViews that need to handle organisation switching.
  """

  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_info({:switch_organisation, org_id}, socket) do
        # For now, just redirect to refresh the page with the new organisation
        # In a production app, you'd update the session here
        {:noreply, push_navigate(socket, to: socket.assigns.current_path || "/")}
      end
    end
  end
end
