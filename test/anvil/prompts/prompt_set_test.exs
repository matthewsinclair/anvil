defmodule Anvil.Prompts.PromptSetTest do
  use Anvil.DataCase, async: true

  require Ash.Query
  alias Anvil.Prompts.Generator, as: PromptsGen
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "PromptSet creation" do
    test "can create a prompt set within a project" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      assert prompt_set.id
      assert prompt_set.name
      assert prompt_set.slug
      assert prompt_set.project_id == project.id
    end

    test "generates unique slugs per project" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      # Create prompt sets with different names
      prompt_set1 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Test Prompt Set 1",
            project_id: project.id
          )
        )

      prompt_set2 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Test Prompt Set 2",
            project_id: project.id
          )
        )

      # Slugs should be unique
      assert prompt_set1.slug != prompt_set2.slug
      assert prompt_set1.slug == "test-prompt-set-1"
      assert prompt_set2.slug == "test-prompt-set-2"
    end

    test "same slug can exist in different projects" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project1 = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      project2 = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      # Create prompt sets with same name in different projects
      prompt_set1 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Same Name",
            project_id: project1.id
          )
        )

      prompt_set2 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Same Name",
            project_id: project2.id
          )
        )

      # Both should have the base slug since they're in different projects
      assert prompt_set1.slug == "same-name"
      assert prompt_set2.slug == "same-name"
      assert prompt_set1.project_id != prompt_set2.project_id
    end

    test "can set metadata and version" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      prompt_set =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Detailed Prompt Set",
            version: "2.0.0",
            project_id: project.id
          )
        )

      assert prompt_set.name == "Detailed Prompt Set"
      assert prompt_set.version == "2.0.0"
      # Metadata defaults to empty map
      assert prompt_set.metadata == %{}
    end
  end

  describe "PromptSet queries" do
    test "can list prompt sets in a project" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      # Create multiple prompt sets
      _ps1 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Prompt Set 1",
            project_id: project.id
          )
        )

      _ps2 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Prompt Set 2",
            project_id: project.id
          )
        )

      _ps3 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Prompt Set 3",
            project_id: project.id
          )
        )

      # Query prompt sets
      {:ok, prompt_sets} =
        Anvil.Prompts.PromptSet
        |> Ash.Query.filter(project_id: project.id)
        |> Ash.read(actor: user)

      assert length(prompt_sets) == 3

      # All should belong to the same project
      Enum.each(prompt_sets, fn ps ->
        assert ps.project_id == project.id
      end)
    end

    test "can filter by version" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      # Create prompt sets with different versions
      _v1 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Version 1",
            version: "1.0.0",
            project_id: project.id
          )
        )

      _v2 =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Version 2",
            version: "2.0.0",
            project_id: project.id
          )
        )

      _v1_patch =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Version 1 Patch",
            version: "1.0.1",
            project_id: project.id
          )
        )

      # Query version 1.x prompt sets
      {:ok, v1_sets} =
        Anvil.Prompts.PromptSet
        |> Ash.Query.filter(project_id: project.id)
        |> Ash.Query.filter(like(version, "1.%"))
        |> Ash.read(actor: user)

      assert length(v1_sets) == 2
      assert Enum.all?(v1_sets, fn ps -> String.starts_with?(ps.version, "1.") end)
    end

    test "can get prompt set by slug within project" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      prompt_set =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Unique Name Set",
            project_id: project.id
          )
        )

      # Find by slug
      {:ok, found_set} =
        Anvil.Prompts.PromptSet
        |> Ash.Query.filter(
          project_id: project.id,
          slug: prompt_set.slug
        )
        |> Ash.read_one(actor: user)

      assert found_set.id == prompt_set.id
      assert found_set.name == prompt_set.name
    end
  end

  describe "PromptSet relationships" do
    test "can load project relationship" do
      {user, org} = AccountsGen.user_with_personal_org()

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Test Project",
            organisation_id: org.id
          )
        )

      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      # Load with project
      {:ok, loaded_set} =
        Anvil.Prompts.PromptSet
        |> Ash.Query.filter(id: prompt_set.id)
        |> Ash.Query.load(:project)
        |> Ash.read_one(actor: user)

      assert loaded_set.project.id == project.id
      assert loaded_set.project.name == "Test Project"
    end

    test "can count prompts in a prompt set" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))

      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      # Create some prompts
      _prompt1 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Prompt 1",
            prompt_set_id: prompt_set.id
          )
        )

      _prompt2 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Prompt 2",
            prompt_set_id: prompt_set.id
          )
        )

      _prompt3 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Prompt 3",
            prompt_set_id: prompt_set.id
          )
        )

      # Load with prompts
      {:ok, loaded_set} =
        Anvil.Prompts.PromptSet
        |> Ash.Query.filter(id: prompt_set.id)
        |> Ash.Query.load(:prompts)
        |> Ash.read_one(actor: user)

      assert length(loaded_set.prompts) == 3
    end
  end
end
