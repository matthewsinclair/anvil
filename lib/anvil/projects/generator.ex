defmodule Anvil.Projects.Generator do
  @moduledoc """
  Generator module for creating test data for the Projects domain.

  This module uses Ash.Generator to create test projects
  while respecting Ash validations and policies.
  """
  use Ash.Generator

  # Import only specific functions to avoid conflicts
  import Anvil.Organisations.Generator, only: [organisation: 0]
  import Anvil.Accounts.Generator, only: [user_with_personal_org: 1]

  @doc """
  Generate a test project.

  ## Options
  - `:name` - Override the default name sequence
  - `:slug` - Override the generated slug
  - `:description` - Project description
  - `:organisation_id` - The organisation this project belongs to (required if not provided)

  ## Examples

      iex> project = generate(project(organisation_id: org.id))
      iex> project = generate(project(name: "My Test Project", organisation_id: org.id))
  """
  def project(opts \\ []) do
    organisation_id =
      opts[:organisation_id] ||
        once(:default_organisation_id, fn ->
          generate(organisation()).id
        end)

    # Use a counter for unique project names
    project_num = System.unique_integer([:positive])
    name = opts[:name] || "Project #{project_num}"

    # Create through the action to trigger slug generation
    Anvil.Projects.Project
    |> Ash.Changeset.for_create(:create, %{
      name: name,
      description: opts[:description] || "Test project description",
      organisation_id: organisation_id
    })
    |> Ash.create!(authorize?: false)
  end

  @doc """
  Generate a project with full context (user, organisation, project).

  This is useful for tests that need a complete setup.

  Returns a map with :user, :organisation, and :project keys.

  ## Examples

      iex> result = project_with_full_context()
      iex> result.user
      iex> result.organisation
      iex> result.project
  """
  def project_with_full_context(opts \\ []) do
    # Create user with personal org
    {user, org} = user_with_personal_org(opts)

    # Create project in the organisation
    project_opts =
      Keyword.merge(
        [organisation_id: org.id],
        Keyword.get(opts, :project, [])
      )

    project = generate(project(project_opts))

    %{
      user: user,
      organisation: org,
      project: project
    }
  end

  @doc """
  Generate multiple projects for an organisation.

  ## Options
  - `:count` - Number of projects to create (default: 3)
  - `:organisation_id` - The organisation ID (required)

  ## Examples

      iex> projects = generate_projects(organisation_id: org.id, count: 5)
  """
  def generate_projects(opts \\ []) do
    count = Keyword.get(opts, :count, 3)
    organisation_id = Keyword.fetch!(opts, :organisation_id)

    Enum.map(1..count, fn i ->
      generate(
        project(
          name: "Project #{i}",
          organisation_id: organisation_id
        )
      )
    end)
  end
end
