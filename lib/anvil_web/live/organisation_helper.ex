defmodule AnvilWeb.Live.OrganisationHelper do
  @moduledoc """
  Helper functions for managing organisation context in LiveViews.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  def switch_organisation(socket, organisation_id) do
    # Verify the user has access to this organisation
    if Enum.any?(socket.assigns.organisations, &(&1.id == organisation_id)) do
      socket
      |> assign(
        :current_organisation,
        Enum.find(socket.assigns.organisations, &(&1.id == organisation_id))
      )
      |> push_event("organisation_switched", %{organisation_id: organisation_id})
    else
      socket
    end
  end

  def current_user_role(socket) do
    if membership = current_membership(socket) do
      membership.role
    end
  end

  def current_membership(socket) do
    Enum.find(socket.assigns.user_memberships, fn membership ->
      membership.organisation_id == socket.assigns.current_organisation.id
    end)
  end

  def can_manage_organisation?(socket) do
    current_user_role(socket) == :owner
  end

  def can_manage_projects?(socket) do
    current_user_role(socket) in [:owner, :admin]
  end
end
