defmodule Anvil.Prompts.PromptSetPolicyTest do
  use Anvil.DataCase, async: true

  require Ash.Query

  alias Anvil.Prompts
  alias Anvil.Prompts.Generator, as: PromptsGen
  alias Anvil.Organisations.Generator, as: OrgsGen
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "PromptSet Authorization Policies" do
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
        prompt_set1: prompt_set1
      }
    end

    test "read policies - organisation members can read prompt sets", %{
      prompt_set1: prompt_set1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Owner can read
      assert {:ok, prompt_set} = Prompts.get_prompt_set_by_id(prompt_set1.id, actor: owner1)
      assert prompt_set.id == prompt_set1.id

      # Admin can read
      assert {:ok, prompt_set} = Prompts.get_prompt_set_by_id(prompt_set1.id, actor: admin1)
      assert prompt_set.id == prompt_set1.id

      # Member can read
      assert {:ok, prompt_set} = Prompts.get_prompt_set_by_id(prompt_set1.id, actor: member1)
      assert prompt_set.id == prompt_set1.id
    end

    test "read policies - non-members cannot read prompt sets", %{
      prompt_set1: prompt_set1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot read - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_set_by_id(prompt_set1.id, actor: owner2)

      # Non-member cannot read - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_set_by_id(prompt_set1.id, actor: non_member)

      # Anonymous user cannot read - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_set_by_id(prompt_set1.id, actor: nil)
    end

    test "create policies - members can create prompt sets", %{
      project1: project1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Owner can create
      assert {:ok, prompt_set} =
               Anvil.Prompts.PromptSet
               |> Ash.Changeset.for_create(:create, %{
                 name: "Owner's PromptSet",
                 version: "1.0.0",
                 project_id: project1.id
               })
               |> Ash.create(actor: owner1)

      assert prompt_set.name == "Owner's PromptSet"

      # Admin can create
      assert {:ok, prompt_set} =
               Anvil.Prompts.PromptSet
               |> Ash.Changeset.for_create(:create, %{
                 name: "Admin's PromptSet",
                 version: "1.0.0",
                 project_id: project1.id
               })
               |> Ash.create(actor: admin1)

      assert prompt_set.name == "Admin's PromptSet"

      # Member can create
      assert {:ok, prompt_set} =
               Anvil.Prompts.PromptSet
               |> Ash.Changeset.for_create(:create, %{
                 name: "Member's PromptSet",
                 version: "1.0.0",
                 project_id: project1.id
               })
               |> Ash.create(actor: member1)

      assert prompt_set.name == "Member's PromptSet"
    end

    test "create policies - non-members cannot create prompt sets", %{
      project1: project1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot create in project1
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.PromptSet
               |> Ash.Changeset.for_create(:create, %{
                 name: "Other Org PromptSet",
                 version: "1.0.0",
                 project_id: project1.id
               })
               |> Ash.create(actor: owner2)

      # Non-member cannot create
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.PromptSet
               |> Ash.Changeset.for_create(:create, %{
                 name: "Non-member PromptSet",
                 version: "1.0.0",
                 project_id: project1.id
               })
               |> Ash.create(actor: non_member)

      # Anonymous user cannot create
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.PromptSet
               |> Ash.Changeset.for_create(:create, %{
                 name: "Anonymous PromptSet",
                 version: "1.0.0",
                 project_id: project1.id
               })
               |> Ash.create(actor: nil)
    end

    test "update policies - owners, admins, and members can update prompt sets", %{
      prompt_set1: prompt_set1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Owner can update
      assert {:ok, updated} =
               prompt_set1
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Owner"})
               |> Ash.update(actor: owner1)

      assert updated.name == "Updated by Owner"

      # Admin can update
      assert {:ok, updated} =
               updated
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Admin"})
               |> Ash.update(actor: admin1)

      assert updated.name == "Updated by Admin"

      # Member can update
      assert {:ok, updated} =
               updated
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Member"})
               |> Ash.update(actor: member1)

      assert updated.name == "Updated by Member"
    end

    test "update policies - non-members cannot update prompt sets", %{
      prompt_set1: prompt_set1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot update
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt_set1
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Other Org"})
               |> Ash.update(actor: owner2)

      # Non-member cannot update
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt_set1
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Non-member"})
               |> Ash.update(actor: non_member)

      # Anonymous user cannot update
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt_set1
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Anonymous"})
               |> Ash.update(actor: nil)
    end

    test "publish action - owners, admins, and members can publish prompt sets", %{
      project1: project1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Create prompt sets to publish
      prompt_set_for_owner =
        PromptsGen.generate(
          PromptsGen.prompt_set(name: "To be published by owner", project_id: project1.id)
        )

      prompt_set_for_admin =
        PromptsGen.generate(
          PromptsGen.prompt_set(name: "To be published by admin", project_id: project1.id)
        )

      prompt_set_for_member =
        PromptsGen.generate(
          PromptsGen.prompt_set(name: "To be published by member", project_id: project1.id)
        )

      # Owner can publish
      assert {:ok, published} =
               prompt_set_for_owner
               |> Ash.Changeset.for_update(:publish)
               |> Ash.update(actor: owner1)

      assert not is_nil(published.published_at)

      # Admin can publish
      assert {:ok, published} =
               prompt_set_for_admin
               |> Ash.Changeset.for_update(:publish)
               |> Ash.update(actor: admin1)

      assert not is_nil(published.published_at)

      # Member can publish
      assert {:ok, published} =
               prompt_set_for_member
               |> Ash.Changeset.for_update(:publish)
               |> Ash.update(actor: member1)

      assert not is_nil(published.published_at)
    end

    test "publish action - non-members cannot publish prompt sets", %{
      prompt_set1: prompt_set1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot publish
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt_set1
               |> Ash.Changeset.for_update(:publish)
               |> Ash.update(actor: owner2)

      # Non-member cannot publish
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt_set1
               |> Ash.Changeset.for_update(:publish)
               |> Ash.update(actor: non_member)

      # Anonymous user cannot publish
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt_set1
               |> Ash.Changeset.for_update(:publish)
               |> Ash.update(actor: nil)
    end

    # Skip add_dependency tests for now due to action signature issues
    # TODO: Re-enable once action is fixed

    test "destroy policies - owners, admins, and members can destroy prompt sets", %{
      project1: project1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Create prompt sets to destroy
      prompt_set_for_owner =
        PromptsGen.generate(
          PromptsGen.prompt_set(name: "To be destroyed by owner", project_id: project1.id)
        )

      prompt_set_for_admin =
        PromptsGen.generate(
          PromptsGen.prompt_set(name: "To be destroyed by admin", project_id: project1.id)
        )

      prompt_set_for_member =
        PromptsGen.generate(
          PromptsGen.prompt_set(name: "To be destroyed by member", project_id: project1.id)
        )

      # Owner can destroy
      assert :ok = Ash.destroy(prompt_set_for_owner, actor: owner1)

      # Admin can destroy
      assert :ok = Ash.destroy(prompt_set_for_admin, actor: admin1)

      # Member can destroy
      assert :ok = Ash.destroy(prompt_set_for_member, actor: member1)
    end

    test "destroy policies - non-members cannot destroy prompt sets", %{
      prompt_set1: prompt_set1,
      owner2: owner2,
      non_member: non_member,
      owner1: owner1
    } do
      # User from different org cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt_set1, actor: owner2)

      # Non-member cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt_set1, actor: non_member)

      # Anonymous user cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt_set1, actor: nil)

      # Verify prompt set still exists
      assert {:ok, _} = Prompts.get_prompt_set_by_id(prompt_set1.id, actor: owner1)
    end

    test "cross-organisation isolation - users cannot access prompt sets from other organisations",
         %{
           project2: project2,
           owner1: owner1,
           owner2: owner2
         } do
      # Create prompt set in org2's project
      prompt_set2 =
        PromptsGen.generate(
          PromptsGen.prompt_set(name: "Org2 PromptSet", project_id: project2.id)
        )

      # Owner1 cannot read prompt set from org2 - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_set_by_id(prompt_set2.id, actor: owner1)

      # Owner1 cannot update prompt set from org2
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt_set2
               |> Ash.Changeset.for_update(:update, %{name: "Hacked"})
               |> Ash.update(actor: owner1)

      # Owner1 cannot destroy prompt set from org2
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt_set2, actor: owner1)

      # Owner2 can still access their prompt set
      assert {:ok, _} = Prompts.get_prompt_set_by_id(prompt_set2.id, actor: owner2)
    end

    test "list prompt sets respects organisation boundaries", %{
      project1: project1,
      project2: project2,
      owner1: owner1,
      owner2: owner2,
      non_member: non_member
    } do
      # Create additional prompt sets
      PromptsGen.generate(
        PromptsGen.prompt_set(name: "Org1 PromptSet 2", project_id: project1.id)
      )

      # Create prompt set in org2
      PromptsGen.generate(PromptsGen.prompt_set(name: "Org2 PromptSet", project_id: project2.id))

      # Owner1 sees only org1's prompt sets
      {:ok, prompt_sets} = Ash.read(Anvil.Prompts.PromptSet, actor: owner1)
      assert length(prompt_sets) == 2
      # Verify all prompt sets belong to org1
      assert Enum.all?(prompt_sets, fn ps -> ps.project_id == project1.id end)

      # Owner2 sees only org2's prompt sets
      {:ok, prompt_sets} = Ash.read(Anvil.Prompts.PromptSet, actor: owner2)
      assert length(prompt_sets) == 1
      assert Enum.all?(prompt_sets, fn ps -> ps.project_id == project2.id end)

      # Non-member sees no prompt sets
      {:ok, prompt_sets} = Ash.read(Anvil.Prompts.PromptSet, actor: non_member)
      assert prompt_sets == []

      # Anonymous user gets empty list
      {:ok, prompt_sets} = Ash.read(Anvil.Prompts.PromptSet, actor: nil)
      assert prompt_sets == []
    end

    test "removed members lose access to prompt sets", %{
      prompt_set1: prompt_set1,
      org1: org1,
      member1: member1,
      owner1: owner1
    } do
      # Member can initially read the prompt set
      assert {:ok, _} = Prompts.get_prompt_set_by_id(prompt_set1.id, actor: member1)

      # Get and remove member's membership
      {:ok, memberships} =
        Anvil.Organisations.Membership
        |> Ash.Query.filter(user_id == ^member1.id and organisation_id == ^org1.id)
        |> Ash.read(actor: owner1)

      membership = List.first(memberships)
      assert :ok = Ash.destroy(membership, actor: owner1)

      # Member can no longer read the prompt set - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_set_by_id(prompt_set1.id, actor: member1)

      # Member cannot update the prompt set
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt_set1
               |> Ash.Changeset.for_update(:update, %{name: "Updated after removal"})
               |> Ash.update(actor: member1)

      # Member cannot destroy the prompt set
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt_set1, actor: member1)
    end
  end
end
