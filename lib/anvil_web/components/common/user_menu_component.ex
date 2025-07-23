defmodule AnvilWeb.Components.Common.UserMenuComponent do
  use AnvilWeb, :html

  @moduledoc """
  A component that renders different UIs based on user authentication state.
  When logged in, shows the user's avatar with a dropdown menu.
  When logged out, the header just shows the logo.
  """

  alias AnvilWeb.Components.ComponentHelpers

  @doc """
  Renders a user menu that changes based on authentication state.

  ## Examples

      <.user_menu current_user={@current_user} />
  """
  attr :current_user, :any, default: nil, doc: "the current user, if logged in"

  def user_menu(assigns) do
    ~H"""
    <%= if @current_user do %>
      <div class="dropdown dropdown-end">
        <div tabindex="0" role="button" class="btn btn-ghost gap-1 normal-case p-1 sm:p-2">
          <div class="avatar">
            <div class="w-8 ring ring-primary ring-offset-base-100 ring-offset-1">
              <img src={get_avatar_url(@current_user)} alt="User avatar" class="pixelated" />
            </div>
          </div>
          <!-- Arrow indicator -->
          <span class="text-xs">▼</span>
        </div>
        <div
          tabindex="0"
          class="dropdown-content z-50 w-52 bg-base-100 shadow-lg border-2 border-primary text-left"
        >
          <ul class="menu p-2">
            <!-- NAVIGATION SECTION -->
            <li>
              <.link navigate={~p"/app"} class="flex items-center gap-2">
                <span>▶</span>
                <span>Dashboard</span>
              </.link>
            </li>
          </ul>

          <div class="py-1 px-4 pointer-events-none">
            <hr class="border-t-2 border-base-300" />
          </div>

          <ul class="menu p-2">
            <li>
              <.link navigate={~p"/account"} class="flex items-center gap-2">
                <span>◆</span>
                <span>Account</span>
              </.link>
            </li>
            <li>
              <.link navigate={~p"/settings"} class="flex items-center gap-2">
                <span>⚙</span>
                <span>Settings</span>
              </.link>
            </li>
            <li>
              <.link navigate={~p"/help"} class="flex items-center gap-2">
                <span>?</span>
                <span>Help</span>
              </.link>
            </li>
          </ul>

          <div class="py-1 px-4 pointer-events-none">
            <hr class="border-t-2 border-base-300" />
          </div>

          <ul class="menu p-2">
            <li>
              <.link href={~p"/sign-out"} method="get">
                <span class="flex items-center gap-2">
                  <span>⬅</span>
                  <span>Log out</span>
                </span>
              </.link>
            </li>
          </ul>
        </div>
      </div>
    <% else %>
      <.link navigate={~p"/sign-in"} class="btn btn-primary btn-sm uppercase font-mono tracking-wider">
        >> Login
      </.link>
    <% end %>
    """
  end

  # Private helper function for avatar
  defp get_avatar_url(user) do
    if user && user.email do
      ComponentHelpers.gravatar_url(user.email, 200)
    else
      ComponentHelpers.gravatar_url(nil, 200)
    end
  end
end
