---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 9. Testing

## Testing Philosophy

Anvil follows a comprehensive testing strategy that balances thorough coverage with development velocity. Tests serve as living documentation and safety nets for refactoring.

### Testing Principles

1. **Test Behaviour, Not Implementation**: Focus on what the system does, not how
2. **Fast Feedback**: Unit tests run in milliseconds, integration tests in seconds
3. **Reliable Tests**: No flaky tests allowed - deterministic outcomes only
4. **Meaningful Coverage**: Quality over quantity, test critical paths thoroughly
5. **Test as Documentation**: Tests demonstrate how to use the system

## Testing Pyramid

```
                     ^^
                    /  \
                   /    \
                  / E2E  \
                 /  Tests \
                /----------\
               / Integration\
              /    Tests     \
             /----------------\
            /   Unit Tests     \
           /____________________\
```

### Distribution

- **Unit Tests**: 70% - Fast, isolated, numerous
- **Integration Tests**: 25% - Test component interactions
- **E2E Tests**: 5% - Critical user journeys only

## Test Infrastructure

### Test Environment Setup

```elixir
# config/test.exs
import Config

config :anvil, Anvil.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "anvil_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :anvil, AnvilWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base",
  server: false

# Disable external services
config :anvil, :email_adapter, Anvil.Email.TestAdapter
config :anvil, :template_engine, Anvil.Template.MockEngine
```

### Test Helpers

```elixir
# test/support/test_helpers.ex
defmodule Anvil.TestHelpers do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Anvil.Factory
      import Anvil.TestHelpers
      import Anvil.AuthHelpers
      
      alias Anvil.Repo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Anvil.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Anvil.Repo, {:shared, self()})
    end

    :ok
  end
end
```

## Unit Testing

### Ash Resource Testing

```elixir
# test/anvil/prompts/prompt_test.exs
defmodule Anvil.Prompts.PromptTest do
  use Anvil.DataCase, async: true

  alias Anvil.Prompts
  alias Anvil.Prompts.Prompt

  describe "create_prompt/2" do
    test "creates prompt with valid attributes" do
      prompt_set = insert(:prompt_set)
      
      attrs = %{
        name: "Welcome Email",
        template: "Hello {{ name }}",
        parameters: [
          %{name: "name", type: "string", required: true}
        ]
      }

      assert {:ok, %Prompt{} = prompt} = 
        Prompts.create_prompt(prompt_set, attrs, actor: prompt_set.project.organisation.owner)

      assert prompt.name == "Welcome Email"
      assert prompt.slug == "welcome-email"
      assert length(prompt.parameters) == 1
    end

    test "validates Liquid syntax" do
      prompt_set = insert(:prompt_set)
      attrs = %{template: "Hello {{ name"} # Invalid syntax

      assert {:error, changeset} = 
        Prompts.create_prompt(prompt_set, attrs, actor: prompt_set.project.organisation.owner)

      assert "invalid Liquid syntax" in errors_on(changeset).template
    end

    test "auto-extracts template variables" do
      template = "Hello {{ first_name }} {{ last_name }}, welcome to {{ company }}!"
      
      assert ["company", "first_name", "last_name"] == 
        Anvil.Template.Analyzer.extract_variables(template)
    end
  end
end
```

### Custom Type Testing

```elixir
# test/anvil/types/parameter_list_test.exs
defmodule Anvil.Types.ParameterListTest do
  use ExUnit.Case, async: true

  alias Anvil.Types.ParameterList

  describe "cast_input/2" do
    test "casts valid parameter list" do
      input = [
        %{"name" => "user", "type" => "string", "required" => "true"},
        %{"name" => "count", "type" => "number", "required" => "false"}
      ]

      assert {:ok, casted} = ParameterList.cast_input(input, %{})
      
      assert [
        %{name: "user", type: "string", required: true},
        %{name: "count", type: "number", required: false}
      ] = casted
    end

    test "filters out empty parameters" do
      input = [
        %{"name" => "valid", "type" => "string"},
        %{"name" => "", "type" => ""}
      ]

      assert {:ok, [%{name: "valid"}]} = ParameterList.cast_input(input, %{})
    end
  end
end
```

## Integration Testing

### LiveView Testing

```elixir
# test/anvil_web/live/prompt_live_test.exs
defmodule AnvilWeb.PromptLiveTest do
  use AnvilWeb.ConnCase
  
  import Phoenix.LiveViewTest
  import Anvil.PromptsFixtures

  describe "Index" do
    setup [:register_and_log_in_user, :create_prompt]

    test "lists all prompts", %{conn: conn, prompt: prompt} do
      {:ok, _index_live, html} = live(conn, ~p"/prompts")

      assert html =~ "Prompts"
      assert html =~ prompt.name
    end

    test "saves new prompt", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/prompts")

      assert index_live |> element("a", "New Prompt") |> render_click() =~
        "New Prompt"

      assert_patch(index_live, ~p"/prompts/new")

      assert index_live
             |> form("#prompt-form", 
                prompt: %{
                  name: "Test Prompt",
                  template: "Hello {{ name }}"
                }
             )
             |> render_submit()

      assert_patch(index_live, ~p"/prompts")
      html = render(index_live)
      assert html =~ "Test Prompt"
    end

    test "validates template in real-time", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/prompts/new")

      # Invalid template
      assert new_live
             |> form("#prompt-form", prompt: %{template: "{{ invalid"})
             |> render_change() =~ "Invalid Liquid syntax"

      # Valid template  
      refute new_live
             |> form("#prompt-form", prompt: %{template: "{{ valid }}"})
             |> render_change() =~ "Invalid"
    end
  end
end
```

### API Testing

```elixir
# test/anvil_web/api/prompt_controller_test.exs
defmodule AnvilWeb.API.PromptControllerTest do
  use AnvilWeb.ConnCase, async: true

  setup %{conn: conn} do
    api_key = insert(:api_key)
    
    conn = 
      conn
      |> put_req_header("authorization", "Bearer #{api_key.key}")
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn, api_key: api_key}
  end

  describe "GET /api/v1/prompts/:id" do
    test "returns prompt with valid ID", %{conn: conn} do
      prompt = insert(:prompt)

      conn = get(conn, ~p"/api/v1/prompts/#{prompt.id}")
      
      assert %{
        "prompt" => %{
          "id" => ^prompt.id,
          "name" => prompt.name,
          "template" => prompt.template,
          "parameters" => parameters
        }
      } = json_response(conn, 200)
    end

    test "returns 404 for invalid ID", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/prompts/invalid-id")
      
      assert %{"error" => %{"message" => "Not found"}} = 
        json_response(conn, 404)
    end
  end

  describe "POST /api/v1/prompts/:id/render" do
    test "renders template with variables", %{conn: conn} do
      prompt = insert(:prompt, template: "Hello {{ name }}!")

      conn = 
        post(conn, ~p"/api/v1/prompts/#{prompt.id}/render", %{
          "variables" => %{"name" => "World"}
        })

      assert %{
        "rendered" => "Hello World!",
        "metadata" => %{"rendered_at" => _}
      } = json_response(conn, 200)
    end
  end
end
```

## End-to-End Testing

### Critical User Journeys

```elixir
# test/e2e/user_journey_test.exs
defmodule Anvil.E2E.UserJourneyTest do
  use Anvil.FeatureCase
  use Wallaby.Feature

  import Wallaby.Query

  feature "complete prompt workflow", %{session: session} do
    session
    |> visit("/sign-up")
    |> fill_in(text_field("Email"), with: "test@example.com")
    |> fill_in(text_field("Password"), with: "password123456")
    |> click(button("Sign up"))
    |> assert_has(css(".alert-success", text: "Welcome to Anvil"))

    session
    |> click(link("New Project"))
    |> fill_in(text_field("Name"), with: "Customer Support")
    |> click(button("Create"))
    |> assert_has(css("h1", text: "Customer Support"))

    session
    |> click(link("New Prompt Set"))
    |> fill_in(text_field("Name"), with: "Email Templates")
    |> click(button("Create"))
    |> click(link("New Prompt"))
    |> fill_in(text_field("Name"), with: "Welcome Email")
    |> fill_in(text_area("Template"), with: "Hello {{ customer }}!")
    |> click(button("Save"))
    |> assert_has(css(".alert-success", text: "Prompt created"))
  end
end
```

## Test Data Management

### Factory Pattern

```elixir
# test/support/factory.ex
defmodule Anvil.Factory do
  use ExMachina.Ecto, repo: Anvil.Repo

  def user_factory do
    %Anvil.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      hashed_password: Bcrypt.hash_pwd_salt("password123456"),
      confirmed_at: DateTime.utc_now()
    }
  end

  def organisation_factory do
    %Anvil.Organisations.Organisation{
      name: sequence(:name, &"Org #{&1}"),
      slug: sequence(:slug, &"org-#{&1}")
    }
  end

  def project_factory do
    %Anvil.Projects.Project{
      name: sequence(:name, &"Project #{&1}"),
      slug: sequence(:slug, &"project-#{&1}"),
      organisation: build(:organisation)
    }
  end

  def prompt_factory do
    %Anvil.Prompts.Prompt{
      name: sequence(:name, &"Prompt #{&1}"),
      slug: sequence(:slug, &"prompt-#{&1}"),
      template: "Hello {{ name }}!",
      parameters: [
        %{name: "name", type: "string", required: true}
      ],
      prompt_set: build(:prompt_set)
    }
  end
end
```

## Performance Testing

### Load Testing

```elixir
# test/performance/load_test.exs
defmodule Anvil.LoadTest do
  use Anvil.DataCase

  @tag :performance
  test "handles concurrent prompt renders" do
    prompt = insert(:prompt, template: "Hello {{ name }}!")
    
    tasks = 
      for i <- 1..1000 do
        Task.async(fn ->
          start = System.monotonic_time(:millisecond)
          
          {:ok, _} = Anvil.Prompts.render_prompt(prompt, %{name: "User #{i}"})
          
          System.monotonic_time(:millisecond) - start
        end)
      end

    results = Task.await_many(tasks, 30_000)
    
    average = Enum.sum(results) / length(results)
    p95 = Enum.at(Enum.sort(results), round(length(results) * 0.95))
    
    assert average < 50, "Average render time too high: #{average}ms"
    assert p95 < 100, "P95 render time too high: #{p95}ms"
  end
end
```

## Security Testing

### Authorisation Testing

```elixir
# test/anvil/security/authorization_test.exs
defmodule Anvil.Security.AuthorizationTest do
  use Anvil.DataCase, async: true

  describe "cross-organisation access" do
    test "prevents access to other organisation's prompts" do
      org1 = insert(:organisation)
      org2 = insert(:organisation)
      
      user1 = insert(:user)
      user2 = insert(:user)
      
      insert(:membership, user: user1, organisation: org1, role: :owner)
      insert(:membership, user: user2, organisation: org2, role: :owner)
      
      prompt = insert(:prompt, prompt_set: insert(:prompt_set, 
        project: insert(:project, organisation: org1)))

      # User from org2 cannot access org1's prompt
      assert {:error, %Ash.Error.Forbidden{}} = 
        Anvil.Prompts.get_prompt(prompt.id, actor: user2)

      # User from org1 can access
      assert {:ok, ^prompt} = 
        Anvil.Prompts.get_prompt(prompt.id, actor: user1)
    end
  end
end
```

## Test Automation

### CI Pipeline

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Elixir
      uses: erlef/setup-beam@v1
      with:
        elixir-version: '1.15'
        otp-version: '26'
    
    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: |
          deps
          _build
        key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
    
    - name: Install dependencies
      run: mix deps.get
    
    - name: Check formatting
      run: mix format --check-formatted
    
    - name: Run credo
      run: mix credo --strict
    
    - name: Check security
      run: mix sobelow --config
    
    - name: Run tests
      env:
        MIX_ENV: test
        DATABASE_URL: postgres://postgres:postgres@localhost/anvil_test
      run: |
        mix ecto.create
        mix ecto.migrate
        mix test --cover --warnings-as-errors
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./cover/excoveralls.json
```

## Test Best Practices

### Do's

1. **Test in isolation**: Each test should be independent
2. **Use factories**: Consistent test data generation
3. **Test edge cases**: Empty sets, nulls, large data
4. **Mock external services**: No real API calls in tests
5. **Clear assertions**: One logical assertion per test

### Don'ts

1. **Don't test framework code**: Trust Phoenix/Ash
2. **Don't over-mock**: Test real behaviour when possible
3. **Don't ignore flaky tests**: Fix or remove them
4. **Don't test private functions**: Test through public API
5. **Don't share state**: Each test gets fresh data

## Test Coverage Goals

### Coverage Targets

- **Overall**: 80% minimum
- **Business Logic**: 95% (Ash resources, actions)
- **Controllers**: 90% (API and web)
- **LiveViews**: 85%
- **Utilities**: 70%

### Coverage Reporting

```elixir
# mix.exs
def project do
  [
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  ]
end
```
