defmodule AnvilWeb.OrganisationLive.Show do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  alias Anvil.Organisations

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"id" => org_id}, _session, socket) do
    organisation =
      Organisations.get_organisation_by_id!(org_id, actor: socket.assigns.current_user)

    # Get user's membership to check permissions
    user_membership = get_user_membership(organisation.id, socket.assigns.current_user)

    # Load all memberships with user data
    memberships = load_memberships(organisation.id, socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, organisation.name)
     |> assign(:current_path, "/organisations")
     |> assign(:organisation, organisation)
     |> assign(:user_membership, user_membership)
     |> assign(:can_manage_members, can_manage_members?(user_membership))
     |> stream(:memberships, memberships)
     |> assign(:show_invite_form, false)
     |> assign(:invite_form, build_invite_form())
     |> assign(:breadcrumb_items, [
       %{label: "Organisations", href: ~p"/organisations"},
       %{label: organisation.name, current: true}
     ]), layout: {AnvilWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  @impl true
  def handle_event("toggle_invite_form", _, socket) do
    {:noreply, assign(socket, :show_invite_form, !socket.assigns.show_invite_form)}
  end

  def handle_event("invite_member", %{"email" => email, "role" => role}, socket) do
    role = String.to_existing_atom(role)

    case invite_member(email, role, socket.assigns.organisation, socket.assigns.current_user) do
      {:ok, :invite_sent} ->
        memberships =
          load_memberships(socket.assigns.organisation.id, socket.assigns.current_user)

        {:noreply,
         socket
         |> put_flash(:info, "Invitation sent successfully!")
         |> stream(:memberships, memberships, reset: true)
         |> assign(:show_invite_form, false)
         |> assign(:invite_form, build_invite_form())}

      {:error, :already_member} ->
        {:noreply, put_flash(socket, :error, "User is already a member of this organisation")}

      {:error, message} when is_binary(message) ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, reason} ->
        IO.inspect(reason, label: "Invite error")
        {:noreply, put_flash(socket, :error, "Failed to invite member")}
    end
  end

  def handle_event("update_role", %{"membership_id" => membership_id, "role" => role}, socket) do
    role = String.to_existing_atom(role)

    case update_member_role(membership_id, role, socket.assigns.current_user) do
      {:ok, _} ->
        memberships =
          load_memberships(socket.assigns.organisation.id, socket.assigns.current_user)

        {:noreply,
         socket
         |> put_flash(:info, "Role updated successfully")
         |> stream(:memberships, memberships, reset: true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update role")}
    end
  end

  def handle_event("remove_member", %{"membership_id" => membership_id}, socket) do
    case remove_member(membership_id, socket.assigns.current_user) do
      {:ok, _} ->
        memberships =
          load_memberships(socket.assigns.organisation.id, socket.assigns.current_user)

        {:noreply,
         socket
         |> put_flash(:info, "Member removed successfully")
         |> stream(:memberships, memberships, reset: true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove member")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="bg-base-100 border-2 border-primary p-6">
        <div class="flex items-start justify-between">
          <div>
            <h1 class="text-3xl font-bold text-primary uppercase tracking-wider font-mono">
              {@organisation.name}
            </h1>
            <p :if={@organisation.description} class="text-sm text-base-content/60 font-mono mt-1">
              {@organisation.description}
            </p>
          </div>

          <div :if={@organisation.personal?} class="badge badge-secondary badge-lg font-mono">
            Personal Organisation
          </div>
        </div>
      </div>
      
    <!-- Members Section -->
      <div class="bg-base-100 border-2 border-primary">
        <div class="px-6 py-4 border-b-2 border-primary flex items-center justify-between">
          <h3 class="text-lg font-bold font-mono uppercase">» Members</h3>

          <button
            :if={@can_manage_members && !@organisation.personal?}
            phx-click="toggle_invite_form"
            class="btn btn-primary btn-sm font-mono uppercase"
          >
            + Invite Member
          </button>
        </div>
        
    <!-- Invite Form -->
        <div :if={@show_invite_form} class="p-6 border-b-2 border-base-300 bg-base-200">
          <form phx-submit="invite_member" class="flex gap-4">
            <input
              type="email"
              name="email"
              placeholder="Email address"
              class="input input-bordered input-primary flex-1 font-mono"
              required
            />
            <select name="role" class="select select-bordered select-primary font-mono" required>
              <option value="member">Member</option>
              <option value="admin">Admin</option>
              <option value="owner">Owner</option>
            </select>
            <button type="submit" class="btn btn-primary font-mono uppercase">
              Send Invite
            </button>
            <button
              type="button"
              phx-click="toggle_invite_form"
              class="btn btn-ghost font-mono uppercase"
            >
              Cancel
            </button>
          </form>
        </div>
        
    <!-- Members List -->
        <div class="divide-y-2 divide-base-300">
          <div
            :for={{id, membership} <- @streams.memberships}
            id={id}
            class="p-4 hover:bg-base-200 transition-colors"
          >
            <div class="flex items-center justify-between">
              <div>
                <div class="font-mono font-bold">
                  {membership.user.email}
                </div>
                <div class="text-xs text-base-content/60 font-mono">
                  Joined {format_date(membership.created_at)}
                </div>
              </div>

              <div class="flex items-center gap-4">
                <!-- Role Badge/Selector -->
                <form
                  :if={
                    @can_manage_members && membership.user_id != @current_user.id &&
                      !@organisation.personal?
                  }
                  phx-change="update_role"
                  phx-value-membership_id={membership.id}
                >
                  <select name="role" class="select select-bordered select-sm font-mono">
                    <option value="member" selected={membership.role == :member}>Member</option>
                    <option value="admin" selected={membership.role == :admin}>Admin</option>
                    <option value="owner" selected={membership.role == :owner}>Owner</option>
                  </select>
                </form>
                <div
                  :if={
                    !@can_manage_members || membership.user_id == @current_user.id ||
                      @organisation.personal?
                  }
                  class={[
                    "badge badge-lg font-mono uppercase",
                    role_badge_class(membership.role)
                  ]}
                >
                  {membership.role}
                </div>
                
    <!-- Remove Button -->
                <button
                  :if={
                    @can_manage_members && membership.user_id != @current_user.id &&
                      !@organisation.personal?
                  }
                  phx-click="remove_member"
                  phx-value-membership_id={membership.id}
                  data-confirm="Are you sure you want to remove this member?"
                  class="btn btn-ghost btn-sm text-error"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Danger Zone -->
      <div
        :if={@user_membership && @user_membership.role == :owner && !@organisation.personal?}
        class="bg-base-100 border-2 border-error"
      >
        <div class="px-6 py-4 border-b-2 border-error">
          <h3 class="text-lg font-bold font-mono uppercase text-error">⚠ Danger Zone</h3>
        </div>
        <div class="p-6">
          <p class="text-sm text-base-content/80 font-mono mb-4">
            Once you delete an organisation, there is no going back. All projects and data will be permanently deleted.
          </p>
          <button class="btn btn-error font-mono uppercase" disabled>
            Delete Organisation (Coming Soon)
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp get_user_membership(org_id, user) do
    import Ash.Query

    Anvil.Organisations.Membership
    |> filter(organisation_id == ^org_id and user_id == ^user.id)
    |> Ash.read_one(actor: user, authorize?: false)
    |> case do
      {:ok, membership} -> membership
      _ -> nil
    end
  end

  defp can_manage_members?(nil), do: false
  defp can_manage_members?(%{role: :owner}), do: true
  defp can_manage_members?(%{role: :admin}), do: false
  defp can_manage_members?(%{role: :member}), do: false

  defp load_memberships(org_id, actor) do
    import Ash.Query

    # Build a query to get memberships for this organisation
    Anvil.Organisations.Membership
    |> filter(organisation_id == ^org_id)
    |> Ash.read!(actor: actor, authorize?: false)
    |> Enum.map(fn membership ->
      case Ash.load(membership, [:user], actor: actor, authorize?: false) do
        {:ok, loaded} -> loaded
        _ -> nil
      end
    end)
    |> Enum.filter(& &1)
  rescue
    _ -> []
  end

  defp invite_member(email, role, organisation, actor) do
    # Use the new invite_to_organisation action
    action_input =
      Anvil.Accounts.User
      |> Ash.ActionInput.for_action(:invite_to_organisation, %{
        email: email,
        organisation_id: organisation.id,
        role: role
      })

    case Ash.run_action(action_input, actor: actor) do
      :ok ->
        # Successfully invited
        {:ok, :invite_sent}

      {:error, message} when is_binary(message) ->
        if String.contains?(message, "already a member") do
          {:error, :already_member}
        else
          {:error, message}
        end

      {:error, %{errors: [%{message: message} | _]}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  defp update_member_role(membership_id, new_role, actor) do
    case Organisations.get_membership_by_id(membership_id, actor: actor) do
      {:ok, membership} ->
        Organisations.update_membership(membership, %{role: new_role}, actor: actor)

      error ->
        error
    end
  end

  defp remove_member(membership_id, actor) do
    case Organisations.get_membership_by_id(membership_id, actor: actor) do
      {:ok, membership} ->
        Organisations.destroy_membership(membership, actor: actor)

      error ->
        error
    end
  end

  defp build_invite_form do
    %{email: "", role: "member"}
  end

  defp role_badge_class(:owner), do: "badge-error"
  defp role_badge_class(:admin), do: "badge-warning"
  defp role_badge_class(:member), do: "badge-info"
end
