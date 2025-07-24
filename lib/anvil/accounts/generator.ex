defmodule Anvil.Accounts.Generator do
  @moduledoc """
  Generator module for creating test data for the Accounts domain.

  This module uses Ash.Generator to create test users, tokens, and API keys
  while respecting Ash validations and policies.
  """
  use Ash.Generator

  # Default password and password hash for all generated users
  @default_password "!sixletters!"
  def default_password, do: @default_password

  # Pre-hashed version of the default password using bcrypt
  # This speeds up tests by avoiding repeated hashing
  @default_hashed_password "$2b$12$KfYLwjFATWirCky9Y2VCC.lJrfbUR72p1PPQ56mvCoviI/NI.S/h2"
  def default_hashed_password, do: @default_hashed_password

  @doc """
  Generate a test user.

  ## Options
  - `:email` - Override the default email sequence
  - `:hashed_password` - Override the default password hash
  - `:confirmed_at` - Set email confirmation timestamp

  ## Examples

      iex> user = generate(user())
      iex> user = generate(user(email: "custom@example.com"))
  """
  def user(opts \\ []) do
    seed_generator(
      %Anvil.Accounts.User{
        email: sequence(:string, &"user#{&1}@example.com"),
        hashed_password: default_hashed_password(),
        confirmed_at: DateTime.utc_now()
      },
      overrides: opts
    )
  end

  @doc """
  Generate a user with a personal organisation already created.

  This is a convenience function that mimics the production behavior
  where users get a personal organisation on registration.

  ## Examples

      iex> {user, org} = user_with_personal_org()
  """
  def user_with_personal_org(opts \\ []) do
    # Create user through the registration action to trigger
    # the personal organisation creation
    email = opts[:email] || "user-#{System.unique_integer([:positive])}@example.com"

    {:ok, user} =
      Anvil.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: email,
        password: default_password(),
        password_confirmation: default_password()
      })
      |> Ash.create(authorize?: false)

    # Confirm the user if requested (default true for testing)
    user =
      if Keyword.get(opts, :confirmed, true) do
        # Use Ecto to directly update the user
        {:ok, confirmed_user} =
          user
          |> Ecto.Changeset.change(confirmed_at: DateTime.utc_now())
          |> Anvil.Repo.update()

        confirmed_user
      else
        user
      end

    # Get the personal organisation
    {:ok, orgs} = Anvil.Organisations.list_organisations(%{}, actor: user)
    personal_org = Enum.find(orgs, & &1.personal?)

    {user, personal_org}
  end
end
