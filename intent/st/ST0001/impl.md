# Implementation - ST0001: Anvil Prompt Management System

## Implementation

The Anvil system will be implemented as two main components:

1. **Anvil Service** - The main web application for managing prompts
2. **Anvil Client** - Elixir library for consuming prompts in applications

Both components will share common domain models defined using Ash Framework.

## Plan

Based on our design discussion and simplified decisions, here's the implementation plan:

### Phase 1: Core Domain Setup

1. **Create Ash domains and resources**:
   - `Anvil.Projects` domain with Project resource
   - `Anvil.Prompts` domain with PromptSet and Prompt resources
   - `Anvil.Versions` domain for version tracking
   - Basic relationships and policies

2. **Database setup**:
   - Add Solid gem for Liquid templating to mix.exs
   - Create migrations for all resources
   - Add approval_token_hash field for review workflow
   - Create seed data for development

### Phase 2: Basic Web UI

1. **Phoenix LiveView pages**:
   - Project listing and creation
   - PromptSet editor with live preview
   - Simple prompt template editor
   - Version history view

2. **Embedded mode support**:
   - Mountable `/anvil` routes (optional)
   - Auth delegation using `Anvil.Auth` behaviour
   - Edit mode configuration (:live, :review, :locked)

### Phase 3: Client Library Core

1. **Essential client functions**:
   - `Anvil.get/2` for fetching prompts
   - Address parser for `@repo/bundle@version/prompt` format
   - ETS-based cache with PubSub invalidation
   - Liquid template rendering with custom filters

2. **CLI tools**:
   - `mix anvil.pull` - fetch prompts locally
   - `mix anvil.approve` - approve changes with token
   - `mix anvil.list` - show available prompts

### Phase 4: Template Engine

1. **Liquid integration**:
   - Custom filters: `for_model`, `count_tokens`, `compose_with`
   - Parameter validation
   - Safe rendering in isolated processes

### Simplified Decisions from Design Review

- **Registry**: Skip for now, direct connections only
- **Template Syntax**: Liquid + custom filters via Solid
- **Caching**: ETS + PubSub invalidation
- **Version Aliases**: Server-side with client override
- **Review Workflow**: CLI-based with secret token
- **Public/Private**: Single-tenant for Zaya only

### Implementation Benefits

- No registry service complexity
- Single-tenant (Zaya only)  
- CLI-based review approval
- Direct client-to-service connection
- Start with ETS caching only

## Code Examples

### Core Domain Models (Ash Resources)

```elixir
defmodule Anvil.Projects.Project do
  use Ash.Resource,
    domain: Anvil.Projects,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "projects"
    repo Anvil.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :slug, :string, allow_nil?: false
    attribute :description, :string
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :owner, Anvil.Accounts.User
    has_many :prompt_sets, Anvil.Prompts.PromptSet
  end

  identities do
    identity :unique_slug_per_user, [:owner_id, :slug]
  end
end

defmodule Anvil.Prompts.PromptSet do
  use Ash.Resource,
    domain: Anvil.Prompts,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :version, :string, allow_nil?: false
    attribute :metadata, :map, default: %{}
    attribute :dependencies, {:array, :map}, default: []
    attribute :published_at, :utc_datetime
    attribute :edit_mode, :atom, 
      constraints: [one_of: [:live, :review, :locked]],
      default: :review
  end

  relationships do
    belongs_to :project, Anvil.Projects.Project
    has_many :prompts, Anvil.Prompts.Prompt
    has_many :versions, Anvil.Prompts.Version
  end
end

defmodule Anvil.Prompts.Prompt do
  use Ash.Resource,
    domain: Anvil.Prompts,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :slug, :string, allow_nil?: false
    attribute :template, :text, allow_nil?: false
    attribute :parameters, {:array, :map}, default: []
    attribute :metadata, :map, default: %{}
  end

  relationships do
    belongs_to :prompt_set, Anvil.Prompts.PromptSet
  end
end
```

### Client Library API

```elixir
defmodule Anvil do
  @moduledoc """
  Client library for consuming Anvil prompts in applications.
  """

  alias Anvil.{Cache, Registry, Resolver}

  @doc """
  Get a prompt by its address, with parameter interpolation.
  
  ## Examples
  
      iex> Anvil.get("@local/onboarding@stable/welcome", 
      ...>   user_name: "Alice", 
      ...>   product: "Anvil")
      {:ok, "Welcome to Anvil, Alice!"}
      
      iex> Anvil.get("@anvil/core@2.1.0/error_message",
      ...>   error: "Not found")
      {:ok, "Sorry, we couldn't find what you're looking for: Not found"}
  """
  def get(address, params \\ %{}) do
    with {:ok, parsed} <- Resolver.parse_address(address),
         {:ok, prompt} <- fetch_prompt(parsed),
         {:ok, rendered} <- render_template(prompt.template, params) do
      {:ok, rendered}
    end
  end

  @doc """
  Get a prompt, raising on error.
  """
  def get!(address, params \\ %{}) do
    case get(address, params) do
      {:ok, prompt} -> prompt
      {:error, reason} -> raise Anvil.Error, reason: reason
    end
  end

  defp fetch_prompt(parsed_address) do
    case Cache.get(parsed_address) do
      {:ok, prompt} -> 
        {:ok, prompt}
        
      :miss ->
        with {:ok, prompt} <- Registry.fetch(parsed_address) do
          Cache.put(parsed_address, prompt)
          {:ok, prompt}
        end
    end
  end

  defp render_template(template, params) do
    Anvil.Template.render(template, params)
  end
end
```

### Template Rendering with Liquid

```elixir
defmodule Anvil.Template do
  @moduledoc """
  Template rendering using Liquid syntax.
  """

  def render(template, params) do
    context = build_context(params)
    
    case Solid.parse(template) do
      {:ok, parsed} ->
        rendered = Solid.render!(parsed, context, 
          strict_variables: true,
          filters: [Anvil.Template.Filters]
        )
        {:ok, rendered}
        
      {:error, error} ->
        {:error, {:template_error, error}}
    end
  end

  defp build_context(params) do
    params
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Map.new()
  end
end
```

### Mix Tasks for CLI

```elixir
defmodule Mix.Tasks.Anvil.Init do
  use Mix.Task
  
  @shortdoc "Initialize Anvil in your project"
  
  def run([registry_url]) do
    Mix.Task.run("app.start")
    
    with :ok <- validate_url(registry_url),
         :ok <- create_config(registry_url),
         :ok <- create_directories() do
      Mix.shell().info("Anvil initialized successfully!")
      Mix.shell().info("Registry: #{registry_url}")
      Mix.shell().info("Run 'mix anvil.pull' to fetch prompts")
    end
  end
end

defmodule Mix.Tasks.Anvil.Pull do
  use Mix.Task
  
  @shortdoc "Pull prompts from registry"
  
  def run(args) do
    Mix.Task.run("app.start")
    
    opts = OptionParser.parse!(args, 
      strict: [all: :boolean, set: :string]
    )
    
    with {:ok, manifest} <- fetch_manifest(),
         {:ok, updates} <- determine_updates(manifest, opts),
         :ok <- download_updates(updates) do
      Mix.shell().info("Successfully pulled #{length(updates)} prompt sets")
    end
  end
end
```

### PubSub for Live Updates

```elixir
defmodule Anvil.PubSub.Handler do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    edit_mode = Keyword.get(opts, :edit_mode, :review)
    
    # Subscribe to prompt updates if in live mode
    if edit_mode == :live do
      Phoenix.PubSub.subscribe(Anvil.PubSub, "prompts:updates")
    end
    
    {:ok, %{edit_mode: edit_mode}}
  end

  def handle_info({:prompt_updated, prompt_set_id, prompt}, state) do
    if state.edit_mode == :live do
      Logger.info("Live update received for prompt set #{prompt_set_id}")
      Anvil.Cache.invalidate(prompt_set_id)
      broadcast_to_subscribers(prompt_set_id, prompt)
    end
    
    {:noreply, state}
  end

  defp broadcast_to_subscribers(prompt_set_id, prompt) do
    Phoenix.PubSub.broadcast(
      Anvil.PubSub,
      "prompt_set:#{prompt_set_id}",
      {:prompt_updated, prompt}
    )
  end
end
```

## Technical Details

### Version Resolution

```elixir
defmodule Anvil.Resolver do
  @moduledoc """
  Resolves prompt addresses to specific versions.
  """
  
  def parse_address(address) do
    case Regex.run(~r/^@([^\/]+)\/([^@]+)@([^\/]+)\/(.+)$/, address) do
      [_, repo, bundle, version, prompt_name] ->
        {:ok, %{
          repository: repo,
          bundle: bundle,
          version: version,
          prompt_name: prompt_name
        }}
        
      _ ->
        {:error, :invalid_address_format}
    end
  end
  
  def resolve_version(bundle, version_spec) do
    cond do
      version_spec == "stable" ->
        get_stable_version(bundle)
        
      version_spec == "latest" ->
        get_latest_version(bundle)
        
      String.starts_with?(version_spec, "^") ->
        resolve_caret_version(bundle, version_spec)
        
      true ->
        get_exact_version(bundle, version_spec)
    end
  end
end
```

### Authentication Behaviour

```elixir
defmodule Anvil.Auth do
  @callback authenticate(conn :: Plug.Conn.t()) :: 
    {:ok, user} | {:error, reason :: atom()}
    
  @callback authorize(user :: map(), action :: atom(), resource :: map()) :: 
    :ok | {:error, reason :: atom()}
end

# Example implementation in host app
defmodule MyApp.AnvilAuth do
  @behaviour Anvil.Auth
  
  def authenticate(conn) do
    case MyApp.Auth.get_current_user(conn) do
      nil -> {:error, :unauthenticated}
      user -> {:ok, user}
    end
  end
  
  def authorize(user, :edit_prompt, prompt_set) do
    if user.role in [:admin, :context_engineer] do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
```

### Configuration

```elixir
# config/config.exs
config :anvil,
  registry_url: "https://anvil.rocks",
  cache_ttl: :timer.minutes(5),
  mode: :embedded,
  enable_ui: true,
  edit_mode: :review,
  auth_module: MyApp.AnvilAuth

# config/prod.exs  
config :anvil,
  edit_mode: :locked,
  enable_ui: false
```

## Challenges & Solutions

### Challenge 1: Dependency Resolution

**Problem**: Resolving transitive dependencies while preventing circular dependencies and diamond dependency conflicts.

**Solution**: Implement a dependency resolver that:

- Builds a dependency graph
- Detects cycles using DFS
- Resolves conflicts by failing fast with clear error messages
- Allows manual version pinning as an escape hatch

### Challenge 2: Cache Invalidation

**Problem**: Ensuring all nodes in a clustered environment have consistent prompt versions.

**Solution**:

- Use Phoenix.PubSub for cluster-wide notifications
- Implement generation-based caching with atomic updates
- Provide manual cache clearing commands for emergencies

### Challenge 3: Template Security

**Problem**: User-provided templates could contain malicious code.

**Solution**:

- Use Solid (Liquid) templating with strict mode
- Whitelist allowed filters and tags
- Sanitise all parameter inputs
- Run templates in isolated processes with timeouts

### Challenge 4: Version Compatibility

**Problem**: Ensuring prompt compatibility across different LLM models and versions.

**Solution**:

- Include model metadata in version string (e.g., `-gpt4`)
- Add compatibility matrix to prompt set metadata
- Warn when using prompts with untested models
- Allow override with explicit acknowledgment
