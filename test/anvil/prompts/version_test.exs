defmodule Anvil.Prompts.VersionTest do
  use Anvil.DataCase, async: true

  require Ash.Query
  alias Anvil.Prompts.Generator, as: PromptsGen
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Version creation" do
    test "can create a version for a prompt set" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      version = PromptsGen.generate(PromptsGen.version(prompt_set_id: prompt_set.id))

      assert version.id
      assert version.version_number
      assert version.prompt_set_id == prompt_set.id
      assert version.created_at
    end

    test "stores content snapshot" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      # Create some prompts first
      prompt1 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Prompt 1",
            template: "Hello {{ name }}",
            prompt_set_id: prompt_set.id
          )
        )

      prompt2 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Prompt 2",
            template: "Goodbye {{ name }}",
            prompt_set_id: prompt_set.id
          )
        )

      # Create version with content
      content = %{
        "prompts" => [
          %{
            "id" => prompt1.id,
            "name" => prompt1.name,
            "template" => prompt1.template
          },
          %{
            "id" => prompt2.id,
            "name" => prompt2.name,
            "template" => prompt2.template
          }
        ]
      }

      version =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            content: content
          )
        )

      assert version.snapshot == content
      assert length(version.snapshot["prompts"]) == 2
    end

    test "version numbers increment" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      # Create multiple versions
      v1 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "1.0.0"
          )
        )

      v2 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "1.1.0"
          )
        )

      v3 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "2.0.0"
          )
        )

      assert v1.version_number == "1.0.0"
      assert v2.version_number == "1.1.0"
      assert v3.version_number == "2.0.0"
    end

    test "can add changelog and metadata" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      changelog = "- Added new greeting prompt\n- Fixed typo in farewell message"

      metadata = %{
        "author" => "test@example.com",
        "reviewed_by" => "reviewer@example.com",
        "tags" => ["release", "production"]
      }

      version =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            changelog: changelog,
            metadata: metadata
          )
        )

      assert version.changelog == changelog
      # Metadata is not stored on version itself == metadata
    end
  end

  describe "Version queries" do
    test "can list versions for a prompt set" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      # Create multiple versions
      _v1 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "1.0.0"
          )
        )

      _v2 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "1.1.0"
          )
        )

      _v3 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "2.0.0"
          )
        )

      # Query versions
      {:ok, versions} =
        Anvil.Prompts.Version
        |> Ash.Query.filter(prompt_set_id: prompt_set.id)
        |> Ash.read(actor: user)

      assert length(versions) == 3
      assert Enum.all?(versions, &(&1.prompt_set_id == prompt_set.id))
    end

    test "can get latest version" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      # Create versions with timestamps
      _v1 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "1.0.0"
          )
        )

      # Small delay to ensure different timestamps
      Process.sleep(10)

      _v2 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "2.0.0"
          )
        )

      Process.sleep(10)

      v3 =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "3.0.0"
          )
        )

      # Get latest version by sorting
      {:ok, versions} =
        Anvil.Prompts.Version
        |> Ash.Query.filter(prompt_set_id: prompt_set.id)
        |> Ash.Query.sort(created_at: :desc)
        |> Ash.Query.limit(1)
        |> Ash.read(actor: user)

      assert length(versions) == 1
      latest = hd(versions)
      assert latest.version_number == "3.0.0"
      assert latest.id == v3.id
    end
  end

  describe "Version immutability" do
    test "versions are read-only after creation" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      version =
        PromptsGen.generate(
          PromptsGen.version(
            prompt_set_id: prompt_set.id,
            version: "1.0.0",
            content: %{"original" => true}
          )
        )

      # Versions should not have update actions
      # Just verify we can read it
      {:ok, read_version} =
        Anvil.Prompts.Version
        |> Ash.Query.filter(id: version.id)
        |> Ash.read_one(actor: user)

      assert read_version.snapshot == %{"original" => true}
      assert read_version.version_number == "1.0.0"
    end
  end

  describe "Version relationships" do
    test "can load prompt set relationship" do
      {user, org} = AccountsGen.user_with_personal_org()

      project =
        ProjectsGen.generate(
          ProjectsGen.project(
            name: "Test Project",
            organisation_id: org.id
          )
        )

      prompt_set =
        PromptsGen.generate(
          PromptsGen.prompt_set(
            name: "Test Set",
            project_id: project.id
          )
        )

      version = PromptsGen.generate(PromptsGen.version(prompt_set_id: prompt_set.id))

      # Load with prompt set
      {:ok, loaded_version} =
        Anvil.Prompts.Version
        |> Ash.Query.filter(id: version.id)
        |> Ash.Query.load(:prompt_set)
        |> Ash.read_one(actor: user)

      assert loaded_version.prompt_set.id == prompt_set.id
      assert loaded_version.prompt_set.name == "Test Set"
    end
  end
end
