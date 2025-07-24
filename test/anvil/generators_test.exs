defmodule Anvil.GeneratorsTest do
  use Anvil.DataCase, async: true

  describe "generators infrastructure" do
    test "can generate a user with personal organisation" do
      {user, org} = Anvil.Accounts.Generator.user_with_personal_org()

      assert user.id
      assert to_string(user.email) =~ ~r/user.*@example.com/
      assert user.hashed_password

      assert org.id
      assert org.personal? == true
      assert org.name =~ "Personal"
    end

    test "can generate a complete project hierarchy" do
      result = Anvil.Prompts.Generator.prompt_hierarchy()

      assert result.user.id
      assert result.organisation.id
      assert result.project.id
      assert result.project.organisation_id == result.organisation.id
      assert result.prompt_set.id
      assert result.prompt_set.project_id == result.project.id
      assert length(result.prompts) == 3

      # Verify prompts have valid templates
      for prompt <- result.prompts do
        assert prompt.template =~ "{{"
        assert is_list(prompt.parameters)
      end
    end

    test "can generate multiple projects for an organisation" do
      {_user, org} = Anvil.Accounts.Generator.user_with_personal_org()
      projects = Anvil.Projects.Generator.generate_projects(organisation_id: org.id, count: 5)

      assert length(projects) == 5

      for project <- projects do
        assert project.organisation_id == org.id
        assert project.name
      end
    end
  end
end
