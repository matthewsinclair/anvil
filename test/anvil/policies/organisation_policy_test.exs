defmodule Anvil.Policies.OrganisationPolicyTest do
  use Anvil.DataCase, async: true

  require Ash.Query
  alias Anvil.Organisations.Generator, as: OrgsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Organisation read policies" do
    test "users can only see organisations they are members of" do
      # Create two users
      {user1, org1} = AccountsGen.user_with_personal_org()
      {user2, org2} = AccountsGen.user_with_personal_org()

      # Create an additional org for user1
      extra_org = OrgsGen.generate(OrgsGen.organisation(name: "Extra Org"))

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: user1.id,
          organisation_id: extra_org.id,
          role: :member
        )
      )

      # User1 can see their orgs
      {:ok, user1_orgs} =
        Anvil.Organisations.Organisation
        |> Ash.read(actor: user1)

      user1_org_ids = Enum.map(user1_orgs, & &1.id) |> Enum.sort()
      expected_user1_ids = [org1.id, extra_org.id] |> Enum.sort()
      assert user1_org_ids == expected_user1_ids

      # User2 can only see their own org
      {:ok, user2_orgs} =
        Anvil.Organisations.Organisation
        |> Ash.read(actor: user2)

      assert length(user2_orgs) == 1
      assert hd(user2_orgs).id == org2.id

      # User2 cannot see user1's orgs
      refute org1.id in Enum.map(user2_orgs, & &1.id)
      refute extra_org.id in Enum.map(user2_orgs, & &1.id)
    end

    test "anonymous users cannot see any organisations" do
      {_user, _org} = AccountsGen.user_with_personal_org()

      # Anonymous users should get an empty list, not an error
      assert {:ok, []} = Anvil.Organisations.list_organisations(authorize?: true)
    end

    test "users can read specific organisation they belong to" do
      {user, org} = AccountsGen.user_with_personal_org()

      {:ok, read_org} =
        Anvil.Organisations.Organisation
        |> Ash.Query.filter(id: org.id)
        |> Ash.read_one(actor: user)

      assert read_org.id == org.id
    end

    test "users cannot read organisation they don't belong to" do
      {user1, _org1} = AccountsGen.user_with_personal_org()
      {_user2, org2} = AccountsGen.user_with_personal_org()

      {:ok, result} =
        Anvil.Organisations.Organisation
        |> Ash.Query.filter(id: org2.id)
        |> Ash.read_one(actor: user1)

      # Policy should filter out the org, returning nil
      assert result == nil
    end
  end

  describe "Organisation create policies" do
    test "authenticated users can create organisations" do
      {user, _personal_org} = AccountsGen.user_with_personal_org()

      assert {:ok, new_org} =
               Anvil.Organisations.create_organisation(
                 %{
                   name: "New Organisation"
                 },
                 actor: user
               )

      assert new_org.name == "New Organisation"

      # Check user is owner of the new org (membership created automatically)
      {:ok, memberships} =
        Anvil.Organisations.Membership
        |> Ash.Query.filter(organisation_id: new_org.id)
        |> Ash.read(actor: user)

      assert length(memberships) == 1
      membership = hd(memberships)
      assert membership.role == :owner
      assert membership.user_id == user.id
    end

    test "anonymous users cannot create organisations" do
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Organisations.Organisation
               |> Ash.Changeset.for_create(:create, %{
                 name: "Should Fail"
               })
               |> Ash.create()
    end
  end

  describe "Organisation update policies" do
    test "owners can update their organisations" do
      {owner, org} = AccountsGen.user_with_personal_org()

      assert {:ok, updated_org} =
               org
               |> Ash.Changeset.for_update(:update, %{
                 name: "Updated Name"
               })
               |> Ash.update(actor: owner)

      assert updated_org.name == "Updated Name"
    end

    test "admins can update organisations" do
      {_owner, org} = AccountsGen.user_with_personal_org()
      {admin, _} = AccountsGen.user_with_personal_org()

      # Add admin to org
      OrgsGen.generate(
        OrgsGen.membership(
          user_id: admin.id,
          organisation_id: org.id,
          role: :admin
        )
      )

      assert {:ok, updated_org} =
               org
               |> Ash.Changeset.for_update(:update, %{
                 name: "Admin Updated"
               })
               |> Ash.update(actor: admin)

      assert updated_org.name == "Admin Updated"
    end

    test "members cannot update organisations" do
      {_owner, org} = AccountsGen.user_with_personal_org()
      {member, _} = AccountsGen.user_with_personal_org()

      # Add member to org
      OrgsGen.generate(
        OrgsGen.membership(
          user_id: member.id,
          organisation_id: org.id,
          role: :member
        )
      )

      assert {:error, %Ash.Error.Forbidden{}} =
               org
               |> Ash.Changeset.for_update(:update, %{
                 name: "Should Fail"
               })
               |> Ash.update(actor: member)
    end

    test "non-members cannot update organisations" do
      {_owner, org} = AccountsGen.user_with_personal_org()
      {other_user, _} = AccountsGen.user_with_personal_org()

      assert {:error, %Ash.Error.Forbidden{}} =
               org
               |> Ash.Changeset.for_update(:update, %{
                 name: "Should Fail"
               })
               |> Ash.update(actor: other_user)
    end
  end

  describe "Organisation delete policies" do
    test "personal organisations cannot be deleted" do
      {owner, personal_org} = AccountsGen.user_with_personal_org()

      assert personal_org.personal? == true

      assert {:error, %Ash.Error.Forbidden{}} =
               personal_org
               |> Ash.destroy(actor: owner)
    end

    test "owners can delete non-personal organisations" do
      {owner, _personal_org} = AccountsGen.user_with_personal_org()

      # Create a non-personal org
      org = OrgsGen.generate(OrgsGen.organisation(name: "Deletable Org"))

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: owner.id,
          organisation_id: org.id,
          role: :owner
        )
      )

      assert org.personal? == false

      assert :ok =
               org
               |> Ash.destroy(actor: owner)

      # Verify it's gone
      {:ok, result} =
        Anvil.Organisations.Organisation
        |> Ash.Query.filter(id: org.id)
        |> Ash.read_one(actor: owner)

      assert result == nil
    end

    test "admins can delete non-personal organisations" do
      {owner, _} = AccountsGen.user_with_personal_org()
      {admin, _} = AccountsGen.user_with_personal_org()

      # Create a non-personal org
      org = OrgsGen.generate(OrgsGen.organisation(name: "Admin Deletable"))

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: owner.id,
          organisation_id: org.id,
          role: :owner
        )
      )

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: admin.id,
          organisation_id: org.id,
          role: :admin
        )
      )

      assert :ok =
               org
               |> Ash.destroy(actor: admin)
    end

    test "members cannot delete organisations" do
      {owner, _} = AccountsGen.user_with_personal_org()
      {member, _} = AccountsGen.user_with_personal_org()

      # Create a non-personal org
      org = OrgsGen.generate(OrgsGen.organisation(name: "Not Deletable by Member"))

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: owner.id,
          organisation_id: org.id,
          role: :owner
        )
      )

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: member.id,
          organisation_id: org.id,
          role: :member
        )
      )

      assert {:error, %Ash.Error.Forbidden{}} =
               org
               |> Ash.destroy(actor: member)
    end
  end

  describe "Membership management policies" do
    test "owners can add members to their organisations" do
      {owner, org} = AccountsGen.user_with_personal_org()
      {new_user, _} = AccountsGen.user_with_personal_org()

      assert {:ok, membership} =
               Anvil.Organisations.Membership
               |> Ash.Changeset.for_create(:create, %{
                 user_id: new_user.id,
                 organisation_id: org.id,
                 role: :member
               })
               |> Ash.create(actor: owner)

      assert membership.user_id == new_user.id
      assert membership.role == :member
    end

    test "admins can add members to organisations" do
      {_owner, org} = AccountsGen.user_with_personal_org()
      {admin, _} = AccountsGen.user_with_personal_org()
      {new_user, _} = AccountsGen.user_with_personal_org()

      # Add admin
      OrgsGen.generate(
        OrgsGen.membership(
          user_id: admin.id,
          organisation_id: org.id,
          role: :admin
        )
      )

      assert {:ok, membership} =
               Anvil.Organisations.Membership
               |> Ash.Changeset.for_create(:create, %{
                 user_id: new_user.id,
                 organisation_id: org.id,
                 role: :member
               })
               |> Ash.create(actor: admin)

      assert membership.user_id == new_user.id
    end

    test "members cannot add other members" do
      {_owner, org} = AccountsGen.user_with_personal_org()
      {member, _} = AccountsGen.user_with_personal_org()
      {new_user, _} = AccountsGen.user_with_personal_org()

      # Add member
      OrgsGen.generate(
        OrgsGen.membership(
          user_id: member.id,
          organisation_id: org.id,
          role: :member
        )
      )

      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Organisations.Membership
               |> Ash.Changeset.for_create(:create, %{
                 user_id: new_user.id,
                 organisation_id: org.id,
                 role: :member
               })
               |> Ash.create(actor: member)
    end
  end
end
