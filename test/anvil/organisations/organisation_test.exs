defmodule Anvil.Organisations.OrganisationTest do
  use Anvil.DataCase, async: true

  require Ash.Query
  alias Anvil.Organisations.Generator, as: OrgsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Organisation creation" do
    test "can create an organisation" do
      org = OrgsGen.generate(OrgsGen.organisation())

      assert org.id
      assert org.name
      assert org.slug
      assert org.personal? == false
    end

    test "generates unique slugs" do
      # Create orgs - slug is generated automatically
      org1 = OrgsGen.generate(OrgsGen.organisation(name: "Test Organisation 1"))
      org2 = OrgsGen.generate(OrgsGen.organisation(name: "Test Organisation 2"))
      org3 = OrgsGen.generate(OrgsGen.organisation(name: "Test Organisation 3"))

      # All should have unique slugs
      assert org1.slug != org2.slug
      assert org2.slug != org3.slug
      assert org1.slug != org3.slug

      # Slugs should be based on the name
      assert org1.slug == "test-organisation-1"
      assert org2.slug == "test-organisation-2"
      assert org3.slug == "test-organisation-3"
    end

    test "personal organisations are created on user registration" do
      {user, org} = AccountsGen.user_with_personal_org()

      assert org.personal? == true
      assert org.name =~ "Personal"

      # Check membership was created with owner role
      {:ok, memberships} =
        Anvil.Organisations.Membership
        |> Ash.Query.filter(user_id: user.id, organisation_id: org.id)
        |> Ash.read(actor: user)

      assert length(memberships) == 1
      membership = hd(memberships)
      assert membership.role == :owner
    end

    test "can create organisation with custom attributes" do
      org =
        OrgsGen.generate(
          OrgsGen.organisation(
            name: "Custom Corp",
            description: "A custom organisation"
          )
        )

      assert org.name == "Custom Corp"
      assert org.description == "A custom organisation"
      assert org.slug =~ "custom-corp"
    end
  end

  describe "Organisation memberships" do
    test "can add members to organisation" do
      {_owner, org} = AccountsGen.user_with_personal_org()
      {member, _} = AccountsGen.user_with_personal_org()

      # Create membership
      membership =
        OrgsGen.generate(
          OrgsGen.membership(
            user_id: member.id,
            organisation_id: org.id,
            role: :member
          )
        )

      assert membership.user_id == member.id
      assert membership.organisation_id == org.id
      assert membership.role == :member
    end

    test "supports different membership roles" do
      org = OrgsGen.generate(OrgsGen.organisation())
      {user1, _} = AccountsGen.user_with_personal_org()
      {user2, _} = AccountsGen.user_with_personal_org()
      {user3, _} = AccountsGen.user_with_personal_org()

      # Create memberships with different roles
      owner_membership =
        OrgsGen.generate(
          OrgsGen.membership(
            user_id: user1.id,
            organisation_id: org.id,
            role: :owner
          )
        )

      admin_membership =
        OrgsGen.generate(
          OrgsGen.membership(
            user_id: user2.id,
            organisation_id: org.id,
            role: :admin
          )
        )

      member_membership =
        OrgsGen.generate(
          OrgsGen.membership(
            user_id: user3.id,
            organisation_id: org.id,
            role: :member
          )
        )

      assert owner_membership.role == :owner
      assert admin_membership.role == :admin
      assert member_membership.role == :member
    end
  end

  describe "Organisation queries" do
    test "users can list their organisations" do
      {user, personal_org} = AccountsGen.user_with_personal_org()

      # Create another org and add user as member
      other_org = OrgsGen.generate(OrgsGen.organisation(name: "Other Org"))

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: user.id,
          organisation_id: other_org.id,
          role: :member
        )
      )

      # List organisations
      {:ok, orgs} = Anvil.Organisations.list_organisations(%{}, actor: user)

      assert length(orgs) == 2
      org_ids = Enum.map(orgs, & &1.id)
      assert personal_org.id in org_ids
      assert other_org.id in org_ids
    end

    test "can filter personal organisations" do
      {user, personal_org} = AccountsGen.user_with_personal_org()

      # Create another non-personal org
      other_org = OrgsGen.generate(OrgsGen.organisation())

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: user.id,
          organisation_id: other_org.id,
          role: :member
        )
      )

      # Get only personal orgs
      {:ok, personal_orgs} =
        Anvil.Organisations.Organisation
        |> Ash.Query.filter(personal?: true)
        |> Ash.read(actor: user)

      assert length(personal_orgs) == 1
      assert hd(personal_orgs).id == personal_org.id
    end
  end
end
