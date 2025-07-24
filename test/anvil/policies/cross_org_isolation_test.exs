defmodule Anvil.Policies.CrossOrgIsolationTest do
  use Anvil.DataCase, async: true

  require Ash.Query
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Prompts.Generator, as: PromptsGen
  alias Anvil.Organisations.Generator, as: OrgsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Cross-organisation data isolation" do
    setup do
      # Create two separate organisations with users
      {user1, org1} = AccountsGen.user_with_personal_org()
      {user2, org2} = AccountsGen.user_with_personal_org()

      # Create a third organisation where user1 is owner and user2 is member
      shared_org = OrgsGen.generate(OrgsGen.organisation(name: "Shared Org"))

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: user1.id,
          organisation_id: shared_org.id,
          role: :owner
        )
      )

      OrgsGen.generate(
        OrgsGen.membership(
          user_id: user2.id,
          organisation_id: shared_org.id,
          role: :member
        )
      )

      %{
        user1: user1,
        org1: org1,
        user2: user2,
        org2: org2,
        shared_org: shared_org
      }
    end

    test "users cannot see projects from organisations they don't belong to", %{
      user1: user1,
      org1: org1,
      user2: user2,
      org2: org2
    } do
      # Create projects in each org
      project1 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Org1 Project",
            organisation_id: org1.id
          )
        )

      project2 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Org2 Project",
            organisation_id: org2.id
          )
        )

      # User1 can only see their project
      {:ok, user1_projects} =
        Anvil.Projects.Project
        |> Ash.read(actor: user1)

      assert length(user1_projects) == 1
      assert hd(user1_projects).id == project1.id
      refute project2.id in Enum.map(user1_projects, & &1.id)

      # User2 can only see their project
      {:ok, user2_projects} =
        Anvil.Projects.Project
        |> Ash.read(actor: user2)

      assert length(user2_projects) == 1
      assert hd(user2_projects).id == project2.id
      refute project1.id in Enum.map(user2_projects, & &1.id)
    end

    test "users can see projects in shared organisations", %{
      user1: user1,
      user2: user2,
      shared_org: shared_org
    } do
      # Create project in shared org
      shared_project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Shared Project",
            organisation_id: shared_org.id
          )
        )

      # Both users can see the shared project
      {:ok, user1_projects} =
        Anvil.Projects.Project
        |> Ash.Query.filter(organisation_id: shared_org.id)
        |> Ash.read(actor: user1)

      {:ok, user2_projects} =
        Anvil.Projects.Project
        |> Ash.Query.filter(organisation_id: shared_org.id)
        |> Ash.read(actor: user2)

      assert length(user1_projects) == 1
      assert length(user2_projects) == 1
      assert hd(user1_projects).id == shared_project.id
      assert hd(user2_projects).id == shared_project.id
    end

    test "prompt sets are isolated by project organisation", %{
      user1: user1,
      org1: org1,
      user2: user2,
      org2: org2
    } do
      # Create projects
      project1 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "User1 Project",
            organisation_id: org1.id
          )
        )

      project2 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "User2 Project",
            organisation_id: org2.id
          )
        )

      # Create prompt sets
      prompt_set1 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "User1 Prompts",
            project_id: project1.id
          )
        )

      prompt_set2 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "User2 Prompts",
            project_id: project2.id
          )
        )

      # User1 can only see their prompt sets
      {:ok, user1_prompt_sets} =
        Anvil.Prompts.PromptSet
        |> Ash.read(actor: user1)

      assert length(user1_prompt_sets) == 1
      assert hd(user1_prompt_sets).id == prompt_set1.id

      # User2 can only see their prompt sets
      {:ok, user2_prompt_sets} =
        Anvil.Prompts.PromptSet
        |> Ash.read(actor: user2)

      assert length(user2_prompt_sets) == 1
      assert hd(user2_prompt_sets).id == prompt_set2.id
    end

    test "users cannot modify data in organisations they don't belong to", %{
      user1: user1,
      org1: org1,
      user2: user2
    } do
      # Create project in org1
      project1 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Private Project",
            organisation_id: org1.id
          )
        )

      # User2 cannot update project in org1
      assert {:error, %Ash.Error.Forbidden{}} =
               project1
               |> Ash.Changeset.for_update(:update, %{
                 name: "Hacked Name"
               })
               |> Ash.update(actor: user2)

      # User2 cannot delete project in org1
      assert {:error, %Ash.Error.Forbidden{}} =
               project1
               |> Ash.destroy(actor: user2)

      # Verify project is unchanged
      {:ok, project} =
        Anvil.Projects.Project
        |> Ash.Query.filter(id: project1.id)
        |> Ash.read_one(actor: user1)

      assert project.name == "Private Project"
    end

    test "role-based access works correctly in shared organisations", %{
      user1: user1,
      user2: user2,
      shared_org: shared_org
    } do
      # Create project in shared org (user1 is owner, user2 is member)
      shared_project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Shared Project",
            organisation_id: shared_org.id
          )
        )

      # User1 (owner) can update
      assert {:ok, updated} =
               shared_project
               |> Ash.Changeset.for_update(:update, %{
                 name: "Updated by Owner"
               })
               |> Ash.update(actor: user1)

      assert updated.name == "Updated by Owner"

      # User2 (member) cannot update
      assert {:error, %Ash.Error.Forbidden{}} =
               updated
               |> Ash.Changeset.for_update(:update, %{
                 name: "Should Fail"
               })
               |> Ash.update(actor: user2)
    end

    test "data queries are automatically scoped to user's organisations", %{
      user1: user1,
      org1: org1,
      user2: user2,
      org2: org2,
      shared_org: shared_org
    } do
      # Create projects in all orgs
      ProjectsGen.generate(
        ProjectsGen.project(
          name: "Org1 Project",
          organisation_id: org1.id
        )
      )

      ProjectsGen.generate(
        ProjectsGen.project(
          name: "Org2 Project",
          organisation_id: org2.id
        )
      )

      ProjectsGen.generate(
        ProjectsGen.project(
          name: "Shared Project",
          organisation_id: shared_org.id
        )
      )

      # User1 sees projects from org1 and shared_org
      {:ok, user1_projects} =
        Anvil.Projects.Project
        |> Ash.read(actor: user1)

      assert length(user1_projects) == 2
      org_ids = Enum.map(user1_projects, & &1.organisation_id) |> Enum.sort()
      assert org_ids == Enum.sort([org1.id, shared_org.id])

      # User2 sees projects from org2 and shared_org
      {:ok, user2_projects} =
        Anvil.Projects.Project
        |> Ash.read(actor: user2)

      assert length(user2_projects) == 2
      org_ids = Enum.map(user2_projects, & &1.organisation_id) |> Enum.sort()
      assert org_ids == Enum.sort([org2.id, shared_org.id])
    end

    test "memberships cannot be managed across organisations", %{
      user1: user1,
      user2: user2,
      org2: org2
    } do
      {user3, _} = AccountsGen.user_with_personal_org()

      # User1 cannot add user3 to org2 (user1 is not in org2)
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Organisations.Membership
               |> Ash.Changeset.for_create(:create, %{
                 user_id: user3.id,
                 organisation_id: org2.id,
                 role: :member
               })
               |> Ash.create(actor: user1)

      # Verify user3 is not in org2
      {:ok, org2_members} =
        Anvil.Organisations.Membership
        |> Ash.Query.filter(organisation_id: org2.id)
        |> Ash.read(actor: user2)

      refute user3.id in Enum.map(org2_members, & &1.user_id)
    end
  end
end
