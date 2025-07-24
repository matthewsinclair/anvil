defmodule AnvilWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use AnvilWeb, :verified_routes

  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {AnvilWeb.LiveUserAuth, :current_user}
  def on_mount(:current_user, _params, session, socket) do
    {:cont, AshAuthentication.Phoenix.LiveSession.assign_new_resources(socket, session)}
  end

  def on_mount(:live_user_optional, _params, session, socket) do
    socket = AshAuthentication.Phoenix.LiveSession.assign_new_resources(socket, session)

    socket =
      if socket.assigns[:current_user] do
        assign_current_organisation(socket, session)
      else
        socket
      end

    {:cont, socket}
  end

  def on_mount(:live_user_required, _params, session, socket) do
    socket = AshAuthentication.Phoenix.LiveSession.assign_new_resources(socket, session)

    if socket.assigns[:current_user] do
      socket = assign_current_organisation(socket, session)
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  defp assign_current_organisation(socket, session) do
    user = socket.assigns.current_user

    # Get the current organisation from session or default to first one
    current_org_id = session["current_organisation_id"]

    # Load user's organisations
    user_with_orgs = Ash.load!(user, [memberships: :organisation], authorize?: false)
    organisations = Enum.map(user_with_orgs.memberships, & &1.organisation)

    current_organisation =
      if current_org_id do
        Enum.find(organisations, fn org -> org.id == current_org_id end)
      end || List.first(organisations)

    socket
    |> assign(:organisations, organisations)
    |> assign(:current_organisation, current_organisation)
    |> assign(:user_memberships, user_with_orgs.memberships)
  end
end
