defmodule Anvil.Prompts.PromptPolicyTest do
  use Anvil.DataCase, async: true

  require Ash.Query

  alias Anvil.Prompts
  alias Anvil.Prompts.Generator, as: PromptsGen
  alias Anvil.Organisations.Generator, as: OrgsGen
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Prompt Authorization Policies" do
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

      # Create a prompt in org1's prompt set
      prompt1 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Test Prompt 1",
            template: "Test template {{ name }}",
            prompt_set_id: prompt_set1.id
          )
        )

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
        prompt1: prompt1
      }
    end

    test "read policies - organisation members can read prompts", %{
      prompt1: prompt1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Owner can read
      assert {:ok, prompt} = Prompts.get_prompt_by_id(prompt1.id, actor: owner1)
      assert prompt.id == prompt1.id

      # Admin can read
      assert {:ok, prompt} = Prompts.get_prompt_by_id(prompt1.id, actor: admin1)
      assert prompt.id == prompt1.id

      # Member can read
      assert {:ok, prompt} = Prompts.get_prompt_by_id(prompt1.id, actor: member1)
      assert prompt.id == prompt1.id
    end

    test "read policies - non-members cannot read prompts", %{
      prompt1: prompt1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot read - gets nil/not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_by_id(prompt1.id, actor: owner2)

      # Non-member cannot read - gets nil/not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_by_id(prompt1.id, actor: non_member)

      # Anonymous user cannot read - gets nil/not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_by_id(prompt1.id, actor: nil)
    end

    test "create policies - members can create prompts", %{
      prompt_set1: prompt_set1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Owner can create
      assert {:ok, prompt} =
               Anvil.Prompts.Prompt
               |> Ash.Changeset.for_create(:create, %{
                 name: "Owner's Prompt",
                 template: "Template {{ test }}",
                 prompt_set_id: prompt_set1.id
               })
               |> Ash.create(actor: owner1)

      assert prompt.name == "Owner's Prompt"

      # Admin can create
      assert {:ok, prompt} =
               Anvil.Prompts.Prompt
               |> Ash.Changeset.for_create(:create, %{
                 name: "Admin's Prompt",
                 template: "Template {{ test }}",
                 prompt_set_id: prompt_set1.id
               })
               |> Ash.create(actor: admin1)

      assert prompt.name == "Admin's Prompt"

      # Member can create
      assert {:ok, prompt} =
               Anvil.Prompts.Prompt
               |> Ash.Changeset.for_create(:create, %{
                 name: "Member's Prompt",
                 template: "Template {{ test }}",
                 prompt_set_id: prompt_set1.id
               })
               |> Ash.create(actor: member1)

      assert prompt.name == "Member's Prompt"
    end

    test "create policies - non-members cannot create prompts", %{
      prompt_set1: prompt_set1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot create in project1's prompt set
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.Prompt
               |> Ash.Changeset.for_create(:create, %{
                 name: "Other Org Prompt",
                 template: "Template {{ test }}",
                 prompt_set_id: prompt_set1.id
               })
               |> Ash.create(actor: owner2)

      # Non-member cannot create
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.Prompt
               |> Ash.Changeset.for_create(:create, %{
                 name: "Non-member Prompt",
                 template: "Template {{ test }}",
                 prompt_set_id: prompt_set1.id
               })
               |> Ash.create(actor: non_member)

      # Anonymous user cannot create - but need to handle nil actor in check
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Prompts.Prompt
               |> Ash.Changeset.for_create(:create, %{
                 name: "Anonymous Prompt",
                 template: "Template {{ test }}",
                 prompt_set_id: prompt_set1.id
               })
               |> Ash.create(actor: nil)
    end

    test "update policies - owners, admins, and members can update prompts", %{
      prompt1: prompt1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Owner can update
      assert {:ok, updated} =
               prompt1
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

    test "update policies - non-members cannot update prompts", %{
      prompt1: prompt1,
      owner2: owner2,
      non_member: non_member
    } do
      # User from different org cannot update
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt1
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Other Org"})
               |> Ash.update(actor: owner2)

      # Non-member cannot update
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt1
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Non-member"})
               |> Ash.update(actor: non_member)

      # Anonymous user cannot update
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt1
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Anonymous"})
               |> Ash.update(actor: nil)
    end

    test "destroy policies - owners, admins, and members can destroy prompts", %{
      prompt_set1: prompt_set1,
      owner1: owner1,
      admin1: admin1,
      member1: member1
    } do
      # Create prompts to destroy
      prompt_for_owner =
        PromptsGen.generate(
          PromptsGen.prompt(name: "To be destroyed by owner", prompt_set_id: prompt_set1.id)
        )

      prompt_for_admin =
        PromptsGen.generate(
          PromptsGen.prompt(name: "To be destroyed by admin", prompt_set_id: prompt_set1.id)
        )

      prompt_for_member =
        PromptsGen.generate(
          PromptsGen.prompt(name: "To be destroyed by member", prompt_set_id: prompt_set1.id)
        )

      # Owner can destroy
      assert :ok = Ash.destroy(prompt_for_owner, actor: owner1)

      # Admin can destroy
      assert :ok = Ash.destroy(prompt_for_admin, actor: admin1)

      # Member can destroy
      assert :ok = Ash.destroy(prompt_for_member, actor: member1)
    end

    test "destroy policies - non-members cannot destroy prompts", %{
      prompt1: prompt1,
      owner2: owner2,
      non_member: non_member,
      owner1: owner1
    } do
      # User from different org cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt1, actor: owner2)

      # Non-member cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt1, actor: non_member)

      # Anonymous user cannot destroy
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt1, actor: nil)

      # Verify prompt still exists
      assert {:ok, _} = Prompts.get_prompt_by_id(prompt1.id, actor: owner1)
    end

    test "cross-organisation isolation - users cannot access prompts from other organisations", %{
      project2: project2,
      owner1: owner1,
      owner2: owner2
    } do
      # Create prompt set and prompt in org2's project
      prompt_set2 = PromptsGen.generate(PromptsGen.prompt_set(project_id: project2.id))

      prompt2 =
        PromptsGen.generate(PromptsGen.prompt(name: "Org2 Prompt", prompt_set_id: prompt_set2.id))

      # Owner1 cannot read prompt from org2 - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_by_id(prompt2.id, actor: owner1)

      # Owner1 cannot update prompt from org2
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt2
               |> Ash.Changeset.for_update(:update, %{name: "Hacked"})
               |> Ash.update(actor: owner1)

      # Owner1 cannot destroy prompt from org2
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt2, actor: owner1)

      # Owner2 can still access their prompt
      assert {:ok, _} = Prompts.get_prompt_by_id(prompt2.id, actor: owner2)
    end

    test "list prompts respects organisation boundaries", %{
      project1: project1,
      project2: project2,
      prompt_set1: prompt_set1,
      owner1: owner1,
      owner2: owner2,
      non_member: non_member
    } do
      # Create additional prompts
      PromptsGen.generate(PromptsGen.prompt(name: "Org1 Prompt 2", prompt_set_id: prompt_set1.id))

      # Create prompt set and prompt in org2
      prompt_set2 = PromptsGen.generate(PromptsGen.prompt_set(project_id: project2.id))
      PromptsGen.generate(PromptsGen.prompt(name: "Org2 Prompt", prompt_set_id: prompt_set2.id))

      # Owner1 sees only org1's prompts
      {:ok, prompts} = Ash.read(Anvil.Prompts.Prompt, actor: owner1)
      assert length(prompts) == 2
      # Verify all prompts belong to org1 through their prompt sets
      assert Enum.all?(prompts, fn p ->
               {:ok, prompt_set} = Prompts.get_prompt_set_by_id(p.prompt_set_id, actor: owner1)
               prompt_set.project_id == project1.id
             end)

      # Owner2 sees only org2's prompts
      {:ok, prompts} = Ash.read(Anvil.Prompts.Prompt, actor: owner2)
      assert length(prompts) == 1

      assert Enum.all?(prompts, fn p ->
               {:ok, prompt_set} = Prompts.get_prompt_set_by_id(p.prompt_set_id, actor: owner2)
               prompt_set.project_id == project2.id
             end)

      # Non-member sees no prompts
      {:ok, prompts} = Ash.read(Anvil.Prompts.Prompt, actor: non_member)
      assert prompts == []

      # Anonymous user gets empty list
      {:ok, prompts} = Ash.read(Anvil.Prompts.Prompt, actor: nil)
      assert prompts == []
    end

    test "removed members lose access to prompts", %{
      prompt1: prompt1,
      org1: org1,
      member1: member1,
      owner1: owner1
    } do
      # Member can initially read the prompt
      assert {:ok, _} = Prompts.get_prompt_by_id(prompt1.id, actor: member1)

      # Get and remove member's membership
      {:ok, memberships} =
        Anvil.Organisations.Membership
        |> Ash.Query.filter(user_id == ^member1.id and organisation_id == ^org1.id)
        |> Ash.read(actor: owner1)

      membership = List.first(memberships)
      assert :ok = Ash.destroy(membership, actor: owner1)

      # Member can no longer read the prompt - gets not found
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Prompts.get_prompt_by_id(prompt1.id, actor: member1)

      # Member cannot update the prompt
      assert {:error, %Ash.Error.Forbidden{}} =
               prompt1
               |> Ash.Changeset.for_update(:update, %{name: "Updated after removal"})
               |> Ash.update(actor: member1)

      # Member cannot destroy the prompt
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(prompt1, actor: member1)
    end
  end
end
