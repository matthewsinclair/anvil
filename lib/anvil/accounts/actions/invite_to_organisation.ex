defmodule Anvil.Accounts.Actions.InviteToOrganisation do
  alias Anvil.Organisations

  def run(input, _opts, context) do
    email = input.arguments.email
    organisation_id = input.arguments.organisation_id
    role = input.arguments.role
    actor = context.actor

    # First, try to find the user
    query = Ash.Query.for_read(Anvil.Accounts.User, :get_by_email, %{email: email})

    case Ash.read_one(query, actor: actor, authorize?: false) do
      {:ok, user} when not is_nil(user) ->
        # User exists, create membership
        create_membership(user, organisation_id, role, actor)

      {:ok, nil} ->
        # User doesn't exist, create them with a temporary account and send magic link
        create_user_and_invite(email, organisation_id, role, actor)

      {:error, error} ->
        {:error, error}
    end
  end

  defp create_membership(user, organisation_id, role, actor) do
    # Check if already a member
    import Ash.Query

    existing_membership =
      Anvil.Organisations.Membership
      |> filter(organisation_id == ^organisation_id and user_id == ^user.id)
      |> Ash.read_one(actor: actor, authorize?: false)

    case existing_membership do
      {:ok, nil} ->
        # Create membership
        Organisations.create_membership(
          %{
            user_id: user.id,
            organisation_id: organisation_id,
            role: role
          },
          actor: actor
        )
        |> case do
          {:ok, _membership} ->
            # Return :ok for Ash action compliance
            :ok

          error ->
            error
        end

      {:ok, _} ->
        {:error, "User is already a member of this organisation"}
    end
  end

  defp create_user_and_invite(email, organisation_id, role, actor) do
    # Generate a secure random password (user won't use it, they'll use magic link)
    temp_password = :crypto.strong_rand_bytes(20) |> Base.encode64()

    # Create the user account
    case Anvil.Accounts.User
         |> Ash.Changeset.for_create(:register_with_password, %{
           email: email,
           password: temp_password,
           password_confirmation: temp_password
         })
         |> Ash.create(authorize?: false) do
      {:ok, user} ->
        # Create membership
        case Organisations.create_membership(
               %{
                 user_id: user.id,
                 organisation_id: organisation_id,
                 role: role
               },
               actor: actor
             ) do
          {:ok, _membership} ->
            # Request magic link for the new user
            # Build an action input for the request_magic_link action
            action_input =
              Anvil.Accounts.User
              |> Ash.ActionInput.for_action(:request_magic_link, %{email: email})

            case Ash.run_action(action_input, authorize?: false) do
              :ok ->
                # Return :ok for Ash action compliance
                :ok

              {:error, error} ->
                # Clean up: delete the user if magic link fails
                Ash.destroy(user, authorize?: false)
                {:error, error}
            end

          {:error, error} ->
            # Clean up: delete the user if membership creation fails
            Ash.destroy(user, authorize?: false)
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end
end
