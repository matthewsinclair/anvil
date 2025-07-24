defmodule Anvil.Policies.ProjectPolicyTest do
  use Anvil.DataCase, async: true

  require Ash.Query
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Organisations.Generator, as: OrgsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Project read policies" do
    test "users can only see projects in organisations they are members of" do
      # Create two users with their personal orgs
      {user1, org1} = AccountsGen.user_with_personal_org()
      {user2, org2} = AccountsGen.user_with_personal_org()

      # Create projects in each org
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

      # User1 can see their projects
      {:ok, user1_projects} =
        Anvil.Projects.Project
        |> Ash.read(actor: user1)

      assert length(user1_projects) == 1
      assert hd(user1_projects).id == project1.id

      # User2 can see their projects
      {:ok, user2_projects} =
        Anvil.Projects.Project
        |> Ash.read(actor: user2)

      assert length(user2_projects) == 1
      assert hd(user2_projects).id == project2.id

      # User1 cannot see user2's projects
      refute project2.id in Enum.map(user1_projects, & &1.id)

      # User2 cannot see user1's projects
      refute project1.id in Enum.map(user2_projects, & &1.id)
    end

    test "anonymous users cannot see any projects" do
      {_user, org} = AccountsGen.user_with_personal_org()

      # Create a project
      ProjectsGen.generate(
        ProjectsGen.project(
          name: "Some Project",
          organisation_id: org.id
        )
      )

      # Anonymous users should get an empty list
      assert {:ok, []} = Anvil.Projects.read_all(authorize?: true)
    end

    test "organisation members can see all projects in their organisation" do
      {owner, org} = AccountsGen.user_with_personal_org()
      {member, _} = AccountsGen.user_with_personal_org()

      # Add member to owner's org
      OrgsGen.generate(
        OrgsGen.membership(
          user_id: member.id,
          organisation_id: org.id,
          role: :member
        )
      )

      # Create multiple projects in the org
      project1 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Project 1",
            organisation_id: org.id
          )
        )

      project2 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Project 2",
            organisation_id: org.id
          )
        )

      # Both owner and member can see all projects
      {:ok, owner_projects} =
        Anvil.Projects.Project
        |> Ash.read(actor: owner)

      {:ok, member_projects} =
        Anvil.Projects.Project
        |> Ash.read(actor: member)

      assert length(owner_projects) == 2
      assert length(member_projects) == 2

      project_ids = [project1.id, project2.id]
      owner_project_ids = Enum.map(owner_projects, fn p -> p.id end)
      member_project_ids = Enum.map(member_projects, fn p -> p.id end)

      assert Enum.all?(project_ids, &(&1 in owner_project_ids))
      assert Enum.all?(project_ids, &(&1 in member_project_ids))
    end
  end

  describe "Project create policies" do
    test "organisation owners can create projects" do
      {owner, org} = AccountsGen.user_with_personal_org()

      assert {:ok, project} =
               Anvil.Projects.create(
                 "Owner's Project",
                 %{organisation_id: org.id},
                 actor: owner
               )

      assert project.name == "Owner's Project"
      assert project.organisation_id == org.id
    end

    test "organisation admins can create projects" do
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

      assert {:ok, project} =
               Anvil.Projects.create(
                 "Admin's Project",
                 %{organisation_id: org.id},
                 actor: admin
               )

      assert project.name == "Admin's Project"
    end

    test "organisation members cannot create projects" do
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
               Anvil.Projects.create(
                 "Member's Project",
                 %{organisation_id: org.id},
                 actor: member
               )
    end

    test "users cannot create projects in organisations they don't belong to" do
      {user1, _org1} = AccountsGen.user_with_personal_org()
      {_user2, org2} = AccountsGen.user_with_personal_org()

      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Projects.create(
                 "Unauthorized Project",
                 %{organisation_id: org2.id},
                 actor: user1
               )
    end

    test "anonymous users cannot create projects" do
      {_user, org} = AccountsGen.user_with_personal_org()

      # For anonymous users, we need to pass all parameters in the attributes map
      assert {:error, %Ash.Error.Forbidden{}} =
               Anvil.Projects.Project
               |> Ash.Changeset.for_create(:create, %{
                 name: "Anonymous Project",
                 organisation_id: org.id
               })
               |> Ash.create()
    end
  end

  describe "Project update policies" do
    test "organisation owners can update projects" do
      {owner, org} = AccountsGen.user_with_personal_org()

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Original Name",
            organisation_id: org.id
          )
        )

      assert {:ok, updated_project} =
               project
               |> Ash.Changeset.for_update(:update, %{
                 name: "Updated by Owner"
               })
               |> Ash.update(actor: owner)

      assert updated_project.name == "Updated by Owner"
    end

    test "organisation admins can update projects" do
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

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Original Name",
            organisation_id: org.id
          )
        )

      assert {:ok, updated_project} =
               project
               |> Ash.Changeset.for_update(:update, %{
                 name: "Updated by Admin"
               })
               |> Ash.update(actor: admin)

      assert updated_project.name == "Updated by Admin"
    end

    test "organisation members cannot update projects" do
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

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Original Name",
            organisation_id: org.id
          )
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               project
               |> Ash.Changeset.for_update(:update, %{
                 name: "Should Fail"
               })
               |> Ash.update(actor: member)
    end

    test "users cannot update projects in other organisations" do
      {user1, _org1} = AccountsGen.user_with_personal_org()
      {_user2, org2} = AccountsGen.user_with_personal_org()

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Other Org Project",
            organisation_id: org2.id
          )
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               project
               |> Ash.Changeset.for_update(:update, %{
                 name: "Should Fail"
               })
               |> Ash.update(actor: user1)
    end
  end

  describe "Project delete policies" do
    test "organisation owners can delete projects" do
      {owner, org} = AccountsGen.user_with_personal_org()

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "To Delete",
            organisation_id: org.id
          )
        )

      assert :ok =
               project
               |> Ash.destroy(actor: owner)

      # Verify it's gone
      {:ok, projects} =
        Anvil.Projects.Project
        |> Ash.Query.filter(id: project.id)
        |> Ash.read(actor: owner)

      assert projects == []
    end

    test "organisation admins can delete projects" do
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

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "To Delete",
            organisation_id: org.id
          )
        )

      assert :ok =
               project
               |> Ash.destroy(actor: admin)
    end

    test "organisation members cannot delete projects" do
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

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Cannot Delete",
            organisation_id: org.id
          )
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               project
               |> Ash.destroy(actor: member)
    end

    test "users cannot delete projects in other organisations" do
      {user1, _org1} = AccountsGen.user_with_personal_org()
      {_user2, org2} = AccountsGen.user_with_personal_org()

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Other Org Project",
            organisation_id: org2.id
          )
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               project
               |> Ash.destroy(actor: user1)
    end
  end
end
