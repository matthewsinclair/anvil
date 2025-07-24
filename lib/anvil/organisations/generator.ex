defmodule Anvil.Organisations.Generator do
  @moduledoc """
  Generator module for creating test data for the Organisations domain.

  This module uses Ash.Generator to create test organisations and memberships
  while respecting Ash validations and policies.
  """
  use Ash.Generator

  require Ash.Query

  # Import only specific functions to avoid conflicts
  import Anvil.Accounts.Generator, only: [user: 0]

  @doc """
  Generate a test organisation.

  ## Options
  - `:name` - Override the default name sequence
  - `:slug` - Override the generated slug
  - `:description` - Organisation description
  - `:is_personal` - Whether this is a personal organisation (default: false)

  ## Examples

      iex> org = generate(organisation())
      iex> org = generate(organisation(name: "Test Corp"))
      iex> personal_org = generate(organisation(personal?: true))
  """
  def organisation(opts \\ []) do
    seed_generator(
      %Anvil.Organisations.Organisation{
        name: sequence(:string, &"Organisation #{&1}"),
        description: "Test organisation description",
        personal?: false
      },
      overrides: opts
    )
  end

  @doc """
  Generate a test membership linking a user to an organisation.

  ## Options
  - `:user_id` - The user ID (required if not provided)
  - `:organisation_id` - The organisation ID (required if not provided)
  - `:role` - The user's role in the organisation (default: :member)

  ## Examples

      iex> membership = generate(membership(user_id: user.id, organisation_id: org.id))
      iex> owner_membership = generate(membership(user_id: user.id, organisation_id: org.id, role: :owner))
  """
  def membership(opts \\ []) do
    user_id =
      opts[:user_id] ||
        once(:default_user_id, fn ->
          generate(user()).id
        end)

    organisation_id =
      opts[:organisation_id] ||
        once(:default_organisation_id, fn ->
          generate(organisation()).id
        end)

    seed_generator(
      %Anvil.Organisations.Membership{
        user_id: user_id,
        organisation_id: organisation_id,
        role: :member
      },
      overrides: Keyword.drop(opts, [:user_id, :organisation_id])
    )
  end

  @doc """
  Generate a personal organisation for a user.

  Personal organisations have special properties:
  - is_personal: true
  - Name is typically the user's email
  - Cannot be deleted
  - User is automatically the owner

  ## Examples

      iex> personal_org = generate(personal_organisation(user_id: user.id))
  """
  def personal_organisation(opts \\ []) do
    user_email = opts[:user_email] || sequence(:string, &"user#{&1}@example.com")

    seed_generator(
      %Anvil.Organisations.Organisation{
        name: "Personal - #{user_email}",
        description: "Personal organisation",
        personal?: true
      },
      overrides: Keyword.drop(opts, [:user_email])
    )
  end

  @doc """
  Generate a user with their personal organisation and membership.

  This mimics the production behavior where users get a personal
  organisation on registration.

  Returns a map with :user, :organisation, and :membership keys.

  ## Examples

      iex> result = user_with_personal_org()
      iex> result.user
      iex> result.organisation
      iex> result.membership
  """
  def user_with_personal_org(opts \\ []) do
    # Use the accounts generator function that creates user with org
    {user, org} = Anvil.Accounts.Generator.user_with_personal_org(opts)

    # Get the membership
    {:ok, memberships} =
      Anvil.Organisations.Membership
      |> Ash.Query.filter(user_id: user.id, organisation_id: org.id)
      |> Ash.read(actor: user)

    membership = List.first(memberships)

    %{
      user: user,
      organisation: org,
      membership: membership
    }
  end

  @doc """
  Generate an organisation with a specific owner.

  Creates both the organisation and the owner membership.

  Returns a map with :organisation and :membership keys.

  ## Examples

      iex> result = organisation_with_owner(user_id: user.id)
      iex> result.organisation
      iex> result.membership
  """
  def organisation_with_owner(opts \\ []) do
    user_id = opts[:user_id] || generate(user()).id

    org = generate(organisation(Keyword.drop(opts, [:user_id])))

    membership =
      generate(
        membership(
          user_id: user_id,
          organisation_id: org.id,
          role: :owner
        )
      )

    %{
      organisation: org,
      membership: membership
    }
  end
end
