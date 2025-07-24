defmodule AnvilWeb.Integration.App.Prompts.PromptsSmokeTest do
  @moduledoc """
  Smoke tests for prompt management pages to verify basic functionality.

  These tests ensure the prompt management pages render correctly for authenticated users
  and provide access to key prompt management features.
  """

  use AnvilWeb.IntegrationTestCase, async: true

  import AnvilWeb.IntegrationHelpers

  describe "prompt sets smoke test" do
    setup do
      {user, org} = create_user_with_org()
      project = create_project_for_user(user)

      %{user: user, org: org, project: project}
    end

    test "renders prompt sets page for authenticated user", %{
      conn: conn,
      project: project,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets")
      |> assert_path(~p"/projects/#{project}/prompt-sets")
      |> assert_has("h1", text: "Prompt Sets")
    end

    test "redirects unauthenticated user to sign in", %{conn: conn, project: project} do
      conn
      |> assert_redirect_to_signin(~p"/projects/#{project}/prompt-sets")
    end

    test "new prompt set page is accessible", %{conn: conn, project: project, user: user} do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/new")
      |> assert_path(~p"/projects/#{project}/prompt-sets/new")
      |> assert_has("h1", text: "New Prompt Set")
    end

    test "no critical errors on prompt sets page load", %{
      conn: conn,
      project: project,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets")
      |> assert_response_success()
    end
  end

  describe "prompt sets with data smoke test" do
    setup do
      {user, org} = create_user_with_org()
      project = create_project_for_user(user)
      prompt_set = create_prompt_set_for_project(project, user)

      %{user: user, org: org, project: project, prompt_set: prompt_set}
    end

    test "shows prompt set in listing", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets")
      |> assert_has("a", text: prompt_set.name)
    end

    test "prompt set show page is accessible", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/#{prompt_set}")
      |> assert_path(~p"/projects/#{project}/prompt-sets/#{prompt_set}")
      |> assert_has("h1", text: prompt_set.name)
    end

    test "prompt set edit page is accessible", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/#{prompt_set}/edit")
      |> assert_path(~p"/projects/#{project}/prompt-sets/#{prompt_set}/edit")
      |> assert_has("h1", text: "Edit Prompt Set")
    end
  end

  describe "prompts smoke test" do
    setup do
      {user, org} = create_user_with_org()
      project = create_project_for_user(user)
      prompt_set = create_prompt_set_for_project(project, user)

      %{user: user, org: org, project: project, prompt_set: prompt_set}
    end

    test "renders prompts page for authenticated user", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts")
      |> assert_path(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts")
      |> assert_has("h1", text: "Prompts")
    end

    test "new prompt page is accessible", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts/new")
      |> assert_path(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts/new")
      |> assert_has("h1", text: "New Prompt")
    end

    test "no critical errors on prompts page load", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts")
      |> assert_response_success()
    end
  end

  describe "prompts with data smoke test" do
    setup do
      {user, org} = create_user_with_org()
      project = create_project_for_user(user)
      prompt_set = create_prompt_set_for_project(project, user)
      prompt = create_prompt_for_prompt_set(prompt_set, user)

      %{user: user, org: org, project: project, prompt_set: prompt_set, prompt: prompt}
    end

    test "shows prompt in listing", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      prompt: prompt,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts")
      |> assert_has("a", text: prompt.name)
    end

    test "prompt show page is accessible", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      prompt: prompt,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts/#{prompt}")
      |> assert_path(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts/#{prompt}")
      |> assert_has("h1", text: prompt.name)
    end

    test "prompt edit page is accessible", %{
      conn: conn,
      project: project,
      prompt_set: prompt_set,
      prompt: prompt,
      user: user
    } do
      session = sign_in_user(conn, user)

      session
      |> visit(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts/#{prompt}/edit")
      |> assert_path(~p"/projects/#{project}/prompt-sets/#{prompt_set}/prompts/#{prompt}/edit")
      |> assert_has("h1", text: "Edit Prompt")
    end
  end

  # Helper functions for creating test data using generators
  defp create_prompt_set_for_project(project, user) do
    {:ok, prompt_set} =
      Anvil.Prompts.PromptSet
      |> Ash.Changeset.for_create(
        :create,
        %{
          name: "Test Prompt Set #{System.unique_integer()}",
          version: "1.0.0",
          project_id: project.id
        },
        actor: user
      )
      |> Ash.create()

    prompt_set
  end

  defp create_prompt_for_prompt_set(prompt_set, user) do
    {:ok, prompt} =
      Anvil.Prompts.Prompt
      |> Ash.Changeset.for_create(
        :create,
        %{
          name: "Test Prompt #{System.unique_integer()}",
          template: "This is a test prompt template",
          prompt_set_id: prompt_set.id
        },
        actor: user
      )
      |> Ash.create()

    prompt
  end
end
