# Implementation - ST0001: Anvil Prompt Management System

## Implementation

The Anvil system has been implemented as a Phoenix LiveView application with Ash Framework for domain modeling.

## Current Implementation Status

### Completed Components

1. **Core Domain Models** - Fully implemented using Ash Framework
2. **Web UI** - Phoenix LiveView pages for all major functionality
3. **Template Engine** - Integrated Solid for Liquid template rendering
4. **Navigation & UX** - Command palette, breadcrumbs, and keyboard shortcuts
5. **Parameter Management** - Dynamic parameter definition with validation

## Actual Implementation Details

### Phase 1: Core Domain Setup (Completed)

1. **Ash Domains and Resources**:
   - `Anvil.Projects` domain with Project resource
   - `Anvil.Prompts` domain with PromptSet, Prompt, and Version resources
   - `Anvil.Accounts` domain with User resource
   - Comprehensive relationships and cascading delete policies
   - Custom changes for atomic slug generation

2. **Database Implementation**:
   - PostgreSQL with proper foreign key constraints
   - Custom `Anvil.Types.ParameterList` for handling jsonb[] arrays
   - Migrations for all resources with indexes
   - Solid gem integrated for Liquid templating

### Phase 2: Web UI (Completed)

1. **Phoenix LiveView Implementation**:
   - Full CRUD for Projects, PromptSets, and Prompts
   - Dynamic parameter management with add/remove functionality
   - Real-time template validation with visual feedback
   - Breadcrumb navigation for all pages
   - Command palette with keyboard shortcuts (Cmd+K)
   - Converted all pages to LiveViews (Dashboard, Account, Settings, Help)

2. **Key UI Features**:
   - Parameter auto-extraction from templates
   - Visual validation showing missing/unused/matched parameters
   - Retro-themed UI with consistent styling
   - Form validation with real-time feedback

### Phase 3: Template Engine (Completed)

1. **Template Processing**:
   - `Anvil.Template.Analyzer` for parsing and validation
   - Variable extraction using regex patterns
   - Parameter validation against template variables
   - Integration with Solid for Liquid rendering

2. **Parameter Management**:
   - Dynamic parameter types (string, number, boolean)
   - Required/optional parameter flags
   - Auto-population of missing parameters
   - Visual feedback for validation status

### Key Technical Decisions

1. **Authentication**: Using phx_gen_auth with LiveView session management
2. **Database**: PostgreSQL with custom type handling for jsonb arrays
3. **UI Framework**: Phoenix LiveView with retro-themed DaisyUI components
4. **Template Engine**: Solid gem for Liquid template support
5. **Navigation**: Command palette pattern with keyboard shortcuts
6. **State Management**: LiveView assigns with proper socket handling

## Actual Implementation Code

### Core Domain Models (As Built)

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
    belongs_to :user, Anvil.Accounts.User do
      allow_nil? false
      attribute_writable? true
    end
    has_many :prompt_sets, Anvil.Prompts.PromptSet
  end

  changes do
    change Anvil.Projects.Changes.GenerateSlug
  end

  policies do
    policy always() do
      authorize_if expr(user_id == ^actor(:id))
    end
  end
end

defmodule Anvil.Prompts.PromptSet do
  use Ash.Resource,
    domain: Anvil.Prompts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "prompt_sets"
    repo Anvil.Repo

    references do
      reference :project, on_delete: :delete
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :slug, :string, allow_nil?: false
    attribute :description, :string
    attribute :metadata, :map, default: %{}
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :project, Anvil.Projects.Project do
      allow_nil? false
      attribute_writable? true
    end
    has_many :prompts, Anvil.Prompts.Prompt
  end

  changes do
    change Anvil.Prompts.Changes.GenerateSlug
  end

  policies do
    policy always() do
      authorize_if expr(project.user_id == ^actor(:id))
    end
  end
end

defmodule Anvil.Prompts.Prompt do
  use Ash.Resource,
    domain: Anvil.Prompts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "prompts"
    repo Anvil.Repo

    references do
      reference :prompt_set, on_delete: :delete
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :slug, :string, allow_nil?: false
    attribute :template, :text, allow_nil?: false
    attribute :parameters, Anvil.Types.ParameterList, default: []
    attribute :metadata, :map, default: %{}
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :prompt_set, Anvil.Prompts.PromptSet do
      allow_nil? false
      attribute_writable? true
    end
  end

  changes do
    change Anvil.Prompts.Changes.GenerateSlug
  end

  policies do
    policy always() do
      authorize_if expr(prompt_set.project.user_id == ^actor(:id))
    end
  end
end
```

### Custom Type for Parameter Handling

```elixir
defmodule Anvil.Types.ParameterList do
  use Ash.Type

  @impl true
  def storage_type(_), do: {:array, :map}

  @impl true
  def cast_input(value, _) when is_list(value) do
    casted = 
      value
      |> Enum.reject(&empty_parameter?/1)
      |> Enum.map(&cast_parameter/1)
    {:ok, casted}
  end

  def cast_input(_, _), do: {:ok, []}

  @impl true
  def cast_stored(value, _) when is_list(value), do: {:ok, value}
  def cast_stored(_, _), do: {:ok, []}

  @impl true
  def dump_to_native(value, _) when is_list(value), do: {:ok, value}
  def dump_to_native(_, _), do: {:ok, []}

  defp empty_parameter?(%{"name" => ""}), do: true
  defp empty_parameter?(%{"name" => nil}), do: true
  defp empty_parameter?(_), do: false

  defp cast_parameter(%{"name" => name, "type" => type, "required" => required}) do
    %{
      "name" => to_string(name),
      "type" => to_string(type),
      "required" => to_boolean(required)
    }
  end

  defp to_boolean("true"), do: true
  defp to_boolean("on"), do: true
  defp to_boolean(true), do: true
  defp to_boolean(_), do: false
end
```

### Template Analysis Implementation

```elixir
defmodule Anvil.Template.Analyzer do
  @moduledoc """
  Analyzes Liquid templates for parameter validation and extraction.
  """

  @variable_regex ~r/\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}\}/

  @doc """
  Extracts all variable names from a Liquid template.
  """
  def extract_variables(template) when is_binary(template) do
    @variable_regex
    |> Regex.scan(template, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  def extract_variables(_), do: []

  @doc """
  Validates template parameters against defined parameters.
  Returns a map with :missing, :unused, and :matched lists.
  """
  def validate_parameters(template, parameters) do
    template_vars = extract_variables(template)
    param_names = extract_parameter_names(parameters)

    %{
      missing: template_vars -- param_names,
      unused: param_names -- template_vars,
      matched: template_vars -- (template_vars -- param_names)
    }
  end

  @doc """
  Creates parameter definitions for a list of variable names.
  """
  def create_parameter_definitions(variable_names) do
    Enum.map(variable_names, fn name ->
      %{
        "name" => name,
        "type" => "string",
        "required" => false
      }
    end)
  end

  defp extract_parameter_names(parameters) when is_list(parameters) do
    parameters
    |> Enum.map(&Map.get(&1, "name", ""))
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp extract_parameter_names(_), do: []
end
```

### LiveView Implementation Example

```elixir
defmodule AnvilWeb.PromptLive.Edit do
  use AnvilWeb, :live_view
  use AnvilWeb.Live.CommandPaletteHandler

  alias Anvil.Projects
  alias Anvil.Prompts

  on_mount {AnvilWeb.LiveUserAuth, :live_user_required}

  @impl true
  def handle_event("validate_template", _, socket) do
    template = get_form_value(socket.assigns.form, :template) || ""
    
    validation_result = 
      Anvil.Template.Analyzer.validate_parameters(template, socket.assigns.parameters)
    
    {:noreply, assign(socket, :validation_result, validation_result)}
  end

  def handle_event("auto_populate_parameters", _, socket) do
    template = get_form_value(socket.assigns.form, :template) || ""
    
    validation_result = 
      Anvil.Template.Analyzer.validate_parameters(template, socket.assigns.parameters)
    
    # Create new parameters for missing variables
    new_params = Anvil.Template.Analyzer.create_parameter_definitions(validation_result.missing)
    
    # Combine with existing parameters
    updated_parameters = socket.assigns.parameters ++ new_params
    
    {:noreply,
     socket
     |> assign(:parameters, updated_parameters)
     |> assign(:validation_result, 
         Anvil.Template.Analyzer.validate_parameters(template, updated_parameters))}
  end

  def handle_event("update_parameter", params, socket) do
    index = String.to_integer(params["index"])
    field = params["field"]
    value = params["value"] || params["checked"] || ""
    
    parameters = 
      socket.assigns.parameters
      |> List.update_at(index, fn param ->
        case field do
          "name" -> Map.put(param, "name", value)
          "type" -> Map.put(param, "type", value)
          "required" -> Map.put(param, "required", value == "on" || value == "true")
          _ -> param
        end
      end)
    
    {:noreply, assign(socket, :parameters, parameters)}
  end
end
```

### Command Palette Implementation

```elixir
defmodule AnvilWeb.Live.CommandPalette do
  use AnvilWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:open, false)
     |> assign(:search, "")
     |> assign(:results, [])
     |> assign(:selected_index, 0)}
  end

  @impl true
  def handle_event("open", _, socket) do
    {:noreply,
     socket
     |> assign(:open, true)
     |> assign(:search, "")
     |> assign(:results, get_all_commands(socket))}
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :open, false)}
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    results = search_commands(query, socket)
    
    {:noreply,
     socket
     |> assign(:search, query)
     |> assign(:results, results)
     |> assign(:selected_index, 0)}
  end

  @impl true
  def handle_event("execute", %{"command-id" => command_id}, socket) do
    command = Enum.find(socket.assigns.results, &(&1.id == command_id))
    
    if command do
      send(self(), {:execute_command, command})
      {:noreply, assign(socket, :open, false)}
    else
      {:noreply, socket}
    end
  end

  defp get_all_commands(socket) do
    [
      %{id: "projects", name: "Go to Projects", action: :navigate, path: "/projects"},
      %{id: "dashboard", name: "Go to Dashboard", action: :navigate, path: "/"},
      %{id: "account", name: "Account Settings", action: :navigate, path: "/account"},
      %{id: "settings", name: "System Settings", action: :navigate, path: "/settings"},
      %{id: "help", name: "Help & Documentation", action: :navigate, path: "/help"},
      %{id: "logout", name: "Sign Out", action: :logout}
    ]
  end
end
```

### Atomic Slug Generation Change

```elixir
defmodule Anvil.Prompts.Changes.GenerateSlug do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _, _) do
    case Ash.Changeset.get_attribute(changeset, :name) do
      nil ->
        changeset

      name ->
        slug = name |> String.downcase() |> String.replace(~r/[^a-z0-9\s-]/, "") |> String.replace(~r/\s+/, "-")
        Ash.Changeset.force_change_attribute(changeset, :slug, slug)
    end
  end

  @impl true
  def atomic(_changeset, _opts, _context) do
    {:ok,
     %{
       slug:
         Ash.Expr.expr(
           fragment("lower(regexp_replace(regexp_replace(?, '[^a-zA-Z0-9\\s-]', '', 'g'), '\\s+', '-', 'g'))", ^ref(:name))
         )
     }}
  end
end
```

## Key Implementation Features

### 1. Dynamic Parameter Management
- Add/remove parameters dynamically through UI
- Type selection (string, number, boolean)
- Required/optional flags
- Real-time validation against template variables

### 2. Template Validation System
- Extracts variables from Liquid templates using regex
- Compares against defined parameters
- Visual feedback for missing, unused, and matched parameters
- Auto-population of missing parameters

### 3. Command Palette Navigation
- Global keyboard shortcut (Cmd+K)
- Searchable command list
- Navigation to any page in the application
- Integrated with all LiveViews

### 4. Atomic Database Operations
- Custom Ash changes for atomic slug generation
- PostgreSQL expression-based updates
- Maintains database consistency

## Current Implementation Status Summary

### Completed Features
1. **Core Domain Models** - All resources defined with Ash Framework
2. **Database Layer** - PostgreSQL with proper migrations and constraints
3. **Web UI** - Full LiveView implementation for all CRUD operations
4. **Template Engine** - Liquid template support via Solid gem
5. **Parameter Management** - Dynamic parameter definition with validation
6. **Navigation** - Breadcrumbs and command palette with keyboard shortcuts
7. **Authentication** - phx_gen_auth integration with protected routes
8. **Custom Types** - PostgreSQL array handling for complex data structures

### Pending Features
1. **Version Management** - Track and manage prompt versions
2. **Bundle Export/Import** - Package and distribute prompt sets
3. **Client Library** - SDK for consuming prompts in applications
4. **Registry Service** - Central repository for prompt distribution
5. **Live Updates** - PubSub-based real-time prompt updates
6. **Search Functionality** - Full-text search across projects and prompts

## Implementation Challenges Encountered

### 1. PostgreSQL Array Type Handling
**Problem**: Form data comes as `text[]` but PostgreSQL expects `jsonb[]` for parameter storage.

**Solution**: Created custom Ash type (`Anvil.Types.ParameterList`) to handle conversion between form representation and database storage.

### 2. Atomic Operations Requirement
**Problem**: Ash changes must be atomic for database operations, but some computations seemed too complex.

**Solution**: Used PostgreSQL fragment expressions within Ash.Expr to maintain atomicity while performing string transformations.

### 3. Checkbox Value Handling
**Problem**: HTML checkboxes send "on" when checked, but code expected "true".

**Solution**: Updated parameter parsing to handle both "on" and "true" values for boolean fields.

### 4. Command Palette Integration
**Problem**: Adding command palette to all LiveViews caused duplicate component ID errors.

**Solution**: Consolidated live sessions and created a shared CommandPaletteHandler behaviour.

## Next Steps

The foundation is solid with core functionality working. The next major features to implement are:

1. **Version Management** - Critical for tracking prompt changes
2. **Bundle Export/Import** - Enable prompt distribution
3. **Client Library** - Allow applications to consume prompts
4. **Search Functionality** - Improve navigation at scale
