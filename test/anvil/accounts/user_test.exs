defmodule Anvil.Accounts.UserTest do
  use Anvil.DataCase, async: true

  require Ash.Query

  # Alias to avoid conflicts with DataCase imports
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "User creation" do
    test "can create a user with personal organisation" do
      {user, org} = AccountsGen.user_with_personal_org(confirmed: false)

      assert user
      assert user.id
      assert user.email
      assert user.hashed_password
      # User is not confirmed when confirmed: false
      refute user.confirmed_at

      assert org
      assert org.id
      assert org.personal? == true
      assert org.name =~ "Personal"
    end

    test "can create a user with custom email" do
      custom_email = "custom@example.com"
      {user, org} = AccountsGen.user_with_personal_org(email: custom_email)

      assert to_string(user.email) == custom_email
      assert org.personal? == true
    end

    test "validates email uniqueness" do
      email = "unique@example.com"
      {_user1, _org1} = AccountsGen.user_with_personal_org(email: email)

      # Try to create another user with same email
      assert {:error, _} =
               Anvil.Accounts.User
               |> Ash.Changeset.for_create(:register_with_password, %{
                 email: email,
                 password: AccountsGen.default_password(),
                 password_confirmation: AccountsGen.default_password()
               })
               |> Ash.create(authorize?: false)
    end

    test "creates user with membership to personal org" do
      {user, org} = AccountsGen.user_with_personal_org()

      # Check membership was created
      {:ok, memberships} =
        Anvil.Organisations.Membership
        |> Ash.Query.filter(user_id: user.id)
        |> Ash.read(actor: user)

      assert length(memberships) == 1
      membership = hd(memberships)
      assert membership.role == :owner
      assert membership.organisation_id == org.id
      assert membership.user_id == user.id
    end
  end

  describe "User authentication" do
    test "can sign in with valid password" do
      {user, _org} = AccountsGen.user_with_personal_org()

      # Debug: check the user was created and confirmed
      assert user.confirmed_at != nil

      # Debug: verify we can find the user directly
      {:ok, found_user} =
        Anvil.Accounts.User
        |> Ash.Query.filter(id: user.id)
        |> Ash.read_one(authorize?: false)

      assert found_user.id == user.id
      assert to_string(found_user.email) == to_string(user.email)
      assert found_user.confirmed_at != nil

      # Sign in with password
      assert {:ok, signed_in_user} =
               Anvil.Accounts.User
               |> Ash.Query.for_read(:sign_in_with_password, %{
                 email: user.email,
                 password: AccountsGen.default_password()
               })
               |> Ash.read_one(authorize?: false)

      assert signed_in_user.id == user.id
    end

    test "cannot sign in with invalid password" do
      {user, _org} = AccountsGen.user_with_personal_org()

      assert {:error, _} =
               Anvil.Accounts.User
               |> Ash.Query.for_read(:sign_in_with_password, %{
                 email: user.email,
                 password: "wrongpassword"
               })
               |> Ash.read_one(authorize?: false)
    end

    test "can change password" do
      {user, _org} = AccountsGen.user_with_personal_org()
      old_hash = user.hashed_password

      assert {:ok, updated_user} =
               user
               |> Ash.Changeset.for_update(
                 :change_password,
                 %{
                   current_password: AccountsGen.default_password(),
                   password: "newpassword123",
                   password_confirmation: "newpassword123"
                 },
                 actor: user
               )
               |> Ash.update(authorize?: false)

      assert updated_user.hashed_password != old_hash
    end
  end

  describe "API keys" do
    test "can create an API key" do
      {user, _org} = AccountsGen.user_with_personal_org()
      expires_at = DateTime.add(DateTime.utc_now(), 30, :day)

      assert {:ok, api_key} =
               Anvil.Accounts.ApiKey
               |> Ash.Changeset.for_create(
                 :create,
                 %{
                   user_id: user.id,
                   expires_at: expires_at
                 },
                 authorize?: false
               )
               |> Ash.create()

      assert api_key.user_id == user.id
      assert api_key.api_key_hash
      assert api_key.expires_at
    end

    test "can list user's API keys" do
      {user, _org} = AccountsGen.user_with_personal_org()
      expires_at = DateTime.add(DateTime.utc_now(), 30, :day)

      # Create two keys
      {:ok, _key1} =
        Anvil.Accounts.ApiKey
        |> Ash.Changeset.for_create(
          :create,
          %{
            user_id: user.id,
            expires_at: expires_at
          },
          authorize?: false
        )
        |> Ash.create()

      {:ok, _key2} =
        Anvil.Accounts.ApiKey
        |> Ash.Changeset.for_create(
          :create,
          %{
            user_id: user.id,
            expires_at: expires_at
          },
          authorize?: false
        )
        |> Ash.create()

      # List keys
      {:ok, keys} =
        Anvil.Accounts.ApiKey
        |> Ash.Query.filter(user_id: user.id)
        |> Ash.read(authorize?: false)

      assert length(keys) == 2
    end

    test "expired keys are filtered from valid_api_keys" do
      {user, _org} = AccountsGen.user_with_personal_org()

      # Create expired key
      past_date = DateTime.add(DateTime.utc_now(), -1, :day)

      {:ok, _expired_key} =
        Anvil.Accounts.ApiKey
        |> Ash.Changeset.for_create(
          :create,
          %{
            user_id: user.id,
            expires_at: past_date
          },
          authorize?: false
        )
        |> Ash.create()

      # Create valid key
      future_date = DateTime.add(DateTime.utc_now(), 30, :day)

      {:ok, valid_key} =
        Anvil.Accounts.ApiKey
        |> Ash.Changeset.for_create(
          :create,
          %{
            user_id: user.id,
            expires_at: future_date
          },
          authorize?: false
        )
        |> Ash.create()

      # Load valid keys
      {:ok, user_with_keys} =
        Anvil.Accounts.User
        |> Ash.Query.filter(id: user.id)
        |> Ash.Query.load(:valid_api_keys)
        |> Ash.read_one(authorize?: false)

      assert length(user_with_keys.valid_api_keys) == 1
      assert hd(user_with_keys.valid_api_keys).id == valid_key.id
    end
  end
end
