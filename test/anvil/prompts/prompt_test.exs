defmodule Anvil.Prompts.PromptTest do
  use Anvil.DataCase, async: true

  require Ash.Query
  alias Anvil.Prompts.Generator, as: PromptsGen
  alias Anvil.Projects.Generator, as: ProjectsGen
  alias Anvil.Accounts.Generator, as: AccountsGen

  describe "Prompt creation" do
    test "can create a prompt within a prompt set" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      prompt = PromptsGen.generate(PromptsGen.prompt(prompt_set_id: prompt_set.id))

      assert prompt.id
      assert prompt.name
      assert prompt.template
      assert prompt.prompt_set_id == prompt_set.id
    end

    test "creates prompt with valid Liquid template" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      custom_template = "Hello {{ user_name }}, welcome to {{ app_name }}!"

      prompt =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Welcome Message",
            template: custom_template,
            prompt_set_id: prompt_set.id
          )
        )

      assert prompt.name == "Welcome Message"
      assert prompt.template == custom_template
    end

    test "stores parameters configuration" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      parameters = [
        %{
          "name" => "user_name",
          "type" => "string",
          "required" => true
        },
        %{
          "name" => "age",
          "type" => "integer",
          "required" => false,
          "default" => 18
        }
      ]

      prompt =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "User Greeting",
            parameters: parameters,
            prompt_set_id: prompt_set.id
          )
        )

      # Parameters might not include defaults
      assert length(prompt.parameters) == 2
      assert Enum.find(prompt.parameters, &(&1["name"] == "user_name"))
      assert Enum.find(prompt.parameters, &(&1["name"] == "age"))
    end

    test "supports metadata storage" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      metadata = %{
        "category" => "greeting",
        "tags" => ["welcome", "onboarding"],
        "author" => "test@example.com"
      }

      prompt =
        PromptsGen.generate(
          PromptsGen.prompt(
            metadata: metadata,
            prompt_set_id: prompt_set.id
          )
        )

      assert prompt.metadata == metadata
    end
  end

  describe "Prompt queries" do
    test "can list prompts in a prompt set" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      # Create multiple prompts
      _p1 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Prompt 1",
            prompt_set_id: prompt_set.id
          )
        )

      _p2 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Prompt 2",
            prompt_set_id: prompt_set.id
          )
        )

      _p3 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Prompt 3",
            prompt_set_id: prompt_set.id
          )
        )

      # Query prompts
      {:ok, prompts} =
        Anvil.Prompts.Prompt
        |> Ash.Query.filter(prompt_set_id: prompt_set.id)
        |> Ash.read(actor: user)

      assert length(prompts) == 3
      assert Enum.all?(prompts, &(&1.prompt_set_id == prompt_set.id))
    end

    test "can filter prompts by name" do
      {user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      # Create prompts with different names
      _greeting =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Welcome Greeting",
            prompt_set_id: prompt_set.id
          )
        )

      _farewell =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Farewell Message",
            prompt_set_id: prompt_set.id
          )
        )

      _greeting2 =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Holiday Greeting",
            prompt_set_id: prompt_set.id
          )
        )

      # Search for "Greeting" prompts
      {:ok, greeting_prompts} =
        Anvil.Prompts.Prompt
        |> Ash.Query.filter(prompt_set_id: prompt_set.id)
        |> Ash.Query.filter(contains(name, "Greeting"))
        |> Ash.read(actor: user)

      assert length(greeting_prompts) == 2
      assert Enum.all?(greeting_prompts, fn p -> String.contains?(p.name, "Greeting") end)
    end
  end

  describe "Prompt template validation" do
    test "accepts valid Liquid templates" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      valid_templates = [
        "Hello {{ name }}!",
        "{% if age > 18 %}Adult{% else %}Minor{% endif %}",
        "{% for item in items %}{{ item }}{% endfor %}",
        "{{ 'hello' | upcase }}",
        "Plain text with no variables"
      ]

      Enum.each(valid_templates, fn template ->
        prompt =
          PromptsGen.generate(
            PromptsGen.prompt(
              template: template,
              prompt_set_id: prompt_set.id
            )
          )

        assert prompt.template == template
      end)
    end

    test "template with complex Liquid constructs" do
      {_user, org} = AccountsGen.user_with_personal_org()
      project = ProjectsGen.generate(ProjectsGen.project(organisation_id: org.id))
      prompt_set = PromptsGen.generate(PromptsGen.prompt_set(project_id: project.id))

      complex_template = ~S"""
      {% assign greeting = "Hello" %}
      {{ greeting }}, {{ user.name }}!

      {% if user.preferences %}
        Your preferences:
        {% for pref in user.preferences %}
          - {{ pref.key }}: {{ pref.value }}
        {% endfor %}
      {% endif %}

      {% case user.status %}
        {% when 'active' %}
          Welcome back!
        {% when 'new' %}
          Welcome to our platform!
        {% else %}
          Please contact support.
      {% endcase %}
      """

      prompt =
        PromptsGen.generate(
          PromptsGen.prompt(
            name: "Complex Template",
            template: complex_template,
            prompt_set_id: prompt_set.id
          )
        )

      assert String.trim(prompt.template) == String.trim(complex_template)
    end
  end

  describe "Prompt relationships" do
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

      prompt = PromptsGen.generate(PromptsGen.prompt(prompt_set_id: prompt_set.id))

      # Load with prompt set
      {:ok, loaded_prompt} =
        Anvil.Prompts.Prompt
        |> Ash.Query.filter(id: prompt.id)
        |> Ash.Query.load(:prompt_set)
        |> Ash.read_one(actor: user)

      assert loaded_prompt.prompt_set.id == prompt_set.id
      assert loaded_prompt.prompt_set.name == "Test Set"
    end
  end
end
