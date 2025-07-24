defmodule Anvil.Projects.ProjectTest do
  use Anvil.DataCase, async: true

  require Ash.Query
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Project creation" do
    test "can create a project within an organisation" do
      {_user, org} = AccountsGen.user_with_personal_org()

      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      assert project.id
      assert project.name
      assert project.slug
      assert project.organisation_id == org.id
    end

    test "generates unique slugs per organisation" do
      {_user, org} = AccountsGen.user_with_personal_org()

      # Create projects with different names (slugs must be unique per org)
      project1 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Test Project 1",
            organisation_id: org.id
          )
        )

      project2 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Test Project 2",
            organisation_id: org.id
          )
        )

      # Slugs should be unique
      assert project1.slug != project2.slug
      assert project1.slug == "test-project-1"
      assert project2.slug == "test-project-2"
    end

    test "same slug can exist in different organisations" do
      {_user1, org1} = AccountsGen.user_with_personal_org()
      {_user2, org2} = AccountsGen.user_with_personal_org()

      # Create projects with same name in different orgs
      project1 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Same Name Project",
            organisation_id: org1.id
          )
        )

      project2 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Same Name Project",
            organisation_id: org2.id
          )
        )

      # Both should have the base slug since they're in different orgs
      assert project1.slug == "same-name-project"
      assert project2.slug == "same-name-project"
      assert project1.organisation_id != project2.organisation_id
    end

    test "project with full context helper" do
      result = ProjectsGen.project_with_full_context()

      assert result.user
      assert result.organisation
      assert result.project

      # Verify relationships
      assert result.project.organisation_id == result.organisation.id

      # User should be owner of the org
      {:ok, memberships} =
        Anvil.Organisations.Membership
        |> Ash.Query.filter(
          user_id: result.user.id,
          organisation_id: result.organisation.id
        )
        |> Ash.read(actor: result.user)

      assert length(memberships) == 1
      assert hd(memberships).role == :owner
    end
  end

  describe "Project queries" do
    test "can list projects in an organisation" do
      {user, org} = AccountsGen.user_with_personal_org()

      # Create multiple projects
      projects =
        ProjectsGen.generate_projects(
          organisation_id: org.id,
          count: 3
        )

      assert length(projects) == 3

      # Query projects
      {:ok, queried_projects} =
        Anvil.Projects.Project
        |> Ash.Query.filter(organisation_id: org.id)
        |> Ash.read(actor: user)

      assert length(queried_projects) == 3

      # All should belong to the same org
      Enum.each(queried_projects, fn p ->
        assert p.organisation_id == org.id
      end)
    end

    test "can filter projects by name" do
      {user, org} = AccountsGen.user_with_personal_org()

      # Create projects with different names
      _project1 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Alpha Project",
            organisation_id: org.id
          )
        )

      _project2 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Beta Project",
            organisation_id: org.id
          )
        )

      _project3 =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Alpha Two Project",
            organisation_id: org.id
          )
        )

      # Search for "Alpha" projects
      {:ok, alpha_projects} =
        Anvil.Projects.Project
        |> Ash.Query.filter(organisation_id: org.id)
        |> Ash.Query.filter(contains(name, "Alpha"))
        |> Ash.read(actor: user)

      assert length(alpha_projects) == 2
      project_names = Enum.map(alpha_projects, & &1.name) |> Enum.sort()
      assert project_names == ["Alpha Project", "Alpha Two Project"]
    end

    test "can get project by slug within organisation" do
      {user, org} = AccountsGen.user_with_personal_org()

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Unique Project Name",
            organisation_id: org.id
          )
        )

      # Find by slug
      {:ok, found_project} =
        Anvil.Projects.Project
        |> Ash.Query.filter(
          organisation_id: org.id,
          slug: project.slug
        )
        |> Ash.read_one(actor: user)

      assert found_project.id == project.id
      assert found_project.name == project.name
    end
  end

  describe "Project updates" do
    test "can update project description" do
      {user, org} = AccountsGen.user_with_personal_org()

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Original Name",
            description: "Original description",
            organisation_id: org.id
          )
        )

      # Update the project description only
      {:ok, updated_project} =
        project
        |> Ash.Changeset.for_update(:update, %{
          description: "Updated description"
        })
        |> Ash.update(actor: user)

      assert updated_project.name == "Original Name"
      assert updated_project.description == "Updated description"
      assert updated_project.slug == project.slug
    end
  end
end
