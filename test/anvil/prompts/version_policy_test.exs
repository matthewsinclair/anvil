defmodule Anvil.Prompts.VersionPolicyTest do
  use Anvil.DataCase, async: true

  require Ash.Query

  alias Anvil.Prompts
  alias Anvil.Prompts.Generator, as: PromptsGen
  alias Anvil.Organisations.Generator, as: OrgsGen
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Version Authorization Policies" do
    setup do
      # Create two organisations with users
      {owner1, org1} = AccountsGen.user_with_personal_org(username: "owner1")
      {owner2, org2} = AccountsGen.user_with_personal_org(username: "owner2")

      # Create additional users for org1
      admin1 = AccountsGen.generate(AccountsGen.user(username: "admin1"))
      member1 = AccountsGen.generate(AccountsGen.user(username: "member1"))
      non_member = AccountsGen.generate(AccountsGen.user(username: "non_member"))

      # Add users to org1 using membership generator
      OrgsGen.generate(
        OrgsGen.membership(user_id: admin1.id, organisation_id: org1.id, role: :admin)
      )

      OrgsGen.generate(
        OrgsGen.membership(user_id: member1.id, organisation_id: org1.id, role: :member)
      )

      # Create projects
      project1 =
        ProjectsGen.generate(ProjectsGen.project(name: "Project1", organisation_id: org1.id))

      project2 =
        ProjectsGen.generate(ProjectsGen.project(name: "Project2", organisation_id: org2.id))

      # Create prompt set in org1's project
      prompt_set1 = PromptsGen.generate(PromptsGen.prompt_set(project_id: project1.id))

      # Create version in org1's prompt set
      version1 = PromptsGen.generate(PromptsGen.version(prompt_set_id: prompt_set1.id))

      %{
        org1: org1,
        org2: org2,
        owner1: owner1,
        admin1: admin1,
        member1: member1,
        owner2: owner2,
        non_member: non_member,
        project1: project1,
        project2: project2,
        prompt_set1: prompt_set1,
        version1: version1
      }
    end

    test "read policies - organisation members can read versions", %{
      version1: version1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Owner can read
      assert {:ok, version} = Prompts.get_version_by_id(version1.id, actor: owner1)
      assert version.id == version1.id

      # Admin can read
      assert {:ok, version} = Prompts.get_version_by_id(version1.id, actor: admin1)
      assert version.id == version1.id

      # Member can read
      assert {:ok, version} = Prompts.get_version_by_id(version1.id, actor: member1)
      assert version.id == version1.id
    end

    test "read policies - non-members cannot read versions", %{
      version1: version1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot read - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_version_by_id(version1.id, actor: owner2)

      # Non-member cannot read - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_version_by_id(version1.id, actor: non_member)

      # Anonymous user cannot read - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_version_by_id(version1.id, actor: nil)
    end

    test "create policies - members can create versions", %{
      prompt_set1: prompt_set1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Owner can create
      assert {:ok, version} =
               Anvil.Prompts.Version
               |> Ash.Changeset.for_create(:create, %{
                 version_number: "2.0.0",
                 changelog: "Version by owner",
                 snapshot: %{test: "data"},
                 prompt_set_id: prompt_set1.id,
                 published_by_id: owner1.id
               })
               |> Ash.create(actor: owner1)

      assert version.version_number == "2.0.0"

      # Admin can create
      assert {:ok, version} =
               Anvil.Prompts.Version
               |> Ash.Changeset.for_create(:create, %{
                 version_number: "2.1.0",
                 changelog: "Version by admin",
                 snapshot: %{test: "data"},
                 prompt_set_id: prompt_set1.id,
                 published_by_id: admin1.id
               })
               |> Ash.create(actor: admin1)

      assert version.version_number == "2.1.0"

      # Member can create
      assert {:ok, version} =
               Anvil.Prompts.Version
               |> Ash.Changeset.for_create(:create, %{
                 version_number: "2.2.0",
                 changelog: "Version by member",
                 snapshot: %{test: "data"},
                 prompt_set_id: prompt_set1.id,
                 published_by_id: member1.id
               })
               |> Ash.create(actor: member1)

      assert version.version_number == "2.2.0"
    end

    test "create policies - non-members cannot create versions", %{
      prompt_set1: prompt_set1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot create version in prompt_set1
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.Version
               |> Ash.Changeset.for_create(:create, %{
                 version_number: "3.0.0",
                 changelog: "Other org version",
                 snapshot: %{test: "data"},
                 prompt_set_id: prompt_set1.id,
                 published_by_id: owner2.id
               })
               |> Ash.create(actor: owner2)

      # Non-member cannot create
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.Version
               |> Ash.Changeset.for_create(:create, %{
                 version_number: "3.1.0",
                 changelog: "Non-member version",
                 snapshot: %{test: "data"},
                 prompt_set_id: prompt_set1.id,
                 published_by_id: non_member.id
               })
               |> Ash.create(actor: non_member)

      # Anonymous user cannot create
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.Version
               |> Ash.Changeset.for_create(:create, %{
                 version_number: "3.2.0",
                 changelog: "Anonymous version",
                 snapshot: %{test: "data"},
                 prompt_set_id: prompt_set1.id
               })
               |> Ash.create(actor: nil)
    end

    test "destroy policies - only owners and admins can destroy versions", %{
      prompt_set1: prompt_set1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Create versions to destroy
      version_for_owner =
        PromptsGen.generate(
          PromptsGen.version(
            version: "2.0.0",
            prompt_set_id: prompt_set1.id
          )
        )

      version_for_admin =
        PromptsGen.generate(
          PromptsGen.version(
            version: "2.1.0",
            prompt_set_id: prompt_set1.id
          )
        )

      version_for_member_test =
        PromptsGen.generate(
          PromptsGen.version(
            version: "2.2.0",
            prompt_set_id: prompt_set1.id
          )
        )

      # Owner can destroy
      assert :ok = Ash.destroy(version_for_owner, actor: owner1)

      # Admin can destroy
      assert :ok = Ash.destroy(version_for_admin, actor: admin1)

      # Member CANNOT destroy (more restrictive than prompts/prompt_sets)
      assert {:error, %Ash.Error.Forbidden{}} =
               Ash.destroy(version_for_member_test, actor: member1)
    end

    test "destroy policies - non-members cannot destroy versions", %{
      version1: version1,
      owner2: owner2,
      non_member: non_member,
      owner1: owner1
    } do
      # User from different org cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(version1, actor: owner2)

      # Non-member cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(version1, actor: non_member)

      # Anonymous user cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(version1, actor: nil)

      # Verify version still exists
      assert {:ok, _} = Prompts.get_version_by_id(version1.id, actor: owner1)
    end

    test "cross-organisation isolation - users cannot access versions from other organisations",
         %{
           project2: project2,
           owner1: owner1,
           owner2: owner2
         } do
      # Create prompt set and version in org2's project
      prompt_set2 = PromptsGen.generate(PromptsGen.prompt_set(project_id: project2.id))
      version2 = PromptsGen.generate(PromptsGen.version(prompt_set_id: prompt_set2.id))

      # Owner1 cannot read version from org2 - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_version_by_id(version2.id, actor: owner1)

      # Owner1 cannot destroy version from org2
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(version2, actor: owner1)

      # Owner2 can still access their version
      assert {:ok, _} = Prompts.get_version_by_id(version2.id, actor: owner2)
    end

    test "list versions respects organisation boundaries", %{
      project1: project1,
      project2: project2,
      prompt_set1: prompt_set1,
      owner1: owner1,
      owner2: owner2,
      non_member: non_member
    } do
      # Create additional versions
      PromptsGen.generate(PromptsGen.version(version: "2.0.0", prompt_set_id: prompt_set1.id))

      # Create version in org2
      prompt_set2 = PromptsGen.generate(PromptsGen.prompt_set(project_id: project2.id))
      PromptsGen.generate(PromptsGen.version(prompt_set_id: prompt_set2.id))

      # Owner1 sees only org1's versions
      {:ok, versions} = Ash.read(Anvil.Prompts.Version, actor: owner1)
      assert length(versions) == 2
      # Verify all versions belong to org1 through their prompt sets
      assert Enum.all?(versions, fn v ->
               {:ok, prompt_set} = Prompts.get_prompt_set_by_id(v.prompt_set_id, actor: owner1)
               prompt_set.project_id == project1.id
             end)

      # Owner2 sees only org2's versions
      {:ok, versions} = Ash.read(Anvil.Prompts.Version, actor: owner2)
      assert length(versions) == 1

      assert Enum.all?(versions, fn v ->
               {:ok, prompt_set} = Prompts.get_prompt_set_by_id(v.prompt_set_id, actor: owner2)
               prompt_set.project_id == project2.id
             end)

      # Non-member sees no versions
      {:ok, versions} = Ash.read(Anvil.Prompts.Version, actor: non_member)
      assert versions == []

      # Anonymous user gets empty list
      {:ok, versions} = Ash.read(Anvil.Prompts.Version, actor: nil)
      assert versions == []
    end

    test "removed members lose access to versions", %{
      version1: version1,
      org1: org1,
      member1: member1,
      owner1: owner1
    } do
      # Member can initially read the version
      assert {:ok, _} = Prompts.get_version_by_id(version1.id, actor: member1)

      # Get and remove member's membership
      {:ok, memberships} =
        Anvil.Organisations.Membership
        |> Ash.Query.filter(user_id == ^member1.id and organisation_id == ^org1.id)
        |> Ash.read(actor: owner1)

      membership = List.first(memberships)
      assert :ok = Ash.destroy(membership, actor: owner1)

      # Member can no longer read the version - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_version_by_id(version1.id, actor: member1)

      # Member cannot destroy the version (was already forbidden before removal)
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(version1, actor: member1)
    end

    test "versions are read-only after creation - no update action available" do
      # This test verifies that versions cannot be updated after creation
      # The Version resource intentionally does not define an update action

      # Verify that the Version resource does not have update in its actions
      actions = Anvil.Prompts.Version |> Ash.Resource.Info.actions()
      action_names = Enum.map(actions, & &1.name)

      refute :update in action_names,
             "Version resource should not have update action for immutability"
    end
  end
end
