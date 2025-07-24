# Implementation - ST0001: Anvil Prompt Management System

## Overview

Anvil has been implemented as a Phoenix LiveView application using Ash Framework for domain modeling. The system provides a web-based interface for managing LLM prompts with versioning, template validation, and multi-tenancy support.

## Architecture Decisions

1. **Framework**: Phoenix LiveView + Ash Framework 3.5
2. **Database**: PostgreSQL with custom JSONB array types
3. **Authentication**: phx_gen_auth with magic link support
4. **Template Engine**: Solid gem for Liquid syntax
5. **UI**: Retro-themed with DaisyUI components
6. **Multi-tenancy**: Organisation-based with role-based access control

## Domain Model Implementation

### Core Domains

#### Accounts Domain (`lib/anvil/accounts/`)
- **User Resource**: Authentication with password, magic link, and API keys
- **Token Resource**: JWT token management
- **ApiKey Resource**: API authentication
- **Custom Actions**: `invite_to_organisation` for user invitations

#### Organisations Domain (`lib/anvil/organisations/`)
- **Organisation Resource**: Multi-tenancy support with personal orgs
- **Membership Resource**: Join table with roles (owner/admin/member)
- **Policies**: Ownership-based access control
- **Changes**: Automatic slug generation

#### Projects Domain (`lib/anvil/projects/`)
- **Project Resource**: Belongs to organisations
- **Attributes**: name, slug, description
- **Policies**: Organisation membership required
- **Relationships**: Has many prompt sets

#### Prompts Domain (`lib/anvil/prompts/`)
- **PromptSet Resource**: Container for related prompts
- **Prompt Resource**: Individual prompts with Liquid templates
- **Version Resource**: Immutable snapshots (basic implementation)
- **Custom Type**: `ParameterList` for JSONB array handling

### Key Implementation Features

#### Custom Parameter Type
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
end
```

#### Template Analyzer
```elixir
defmodule Anvil.Template.Analyzer do
  @variable_regex ~r/\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}\}/
  
  def extract_variables(template) when is_binary(template) do
    @variable_regex
    |> Regex.scan(template, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end
  
  def validate_parameters(template, parameters) do
    template_vars = extract_variables(template)
    param_names = extract_parameter_names(parameters)
    
    %{
      missing: template_vars -- param_names,
      unused: param_names -- template_vars,
      matched: template_vars -- (template_vars -- param_names)
    }
  end
end
```

## LiveView Implementation

### Core Features

1. **CRUD Operations**: Full create, read, update, delete for all resources
2. **Dynamic Forms**: Parameter management with add/remove functionality
3. **Real-time Validation**: Template validation with visual feedback
4. **Navigation**: Breadcrumbs and command palette (Cmd+K)
5. **Organisation Context**: Automatic filtering by current organisation

### Key LiveViews

- `ProjectLive.Index/Show/New/Edit`: Project management
- `PromptSetLive.Index/Show/New/Edit`: Prompt set management  
- `PromptLive.Index/Show/New/Edit`: Individual prompt editing
- `VersionLive.Show`: Read-only version viewing
- `OrganisationLive.Index/Show`: Organisation and member management

### UI Components

#### Command Palette
- Global keyboard shortcut (Cmd+K)
- Searchable navigation
- Integrated with all LiveViews via `CommandPaletteHandler`

#### Organisation Switcher
- Dropdown in navigation bar
- Updates session context
- Filters all data by selected organisation

#### Breadcrumb Navigation
- Hierarchical navigation trail
- Context-aware based on current route

## Authentication & Authorization

### Authentication Methods
1. **Password**: Traditional email/password
2. **Magic Link**: Email-based passwordless login
3. **API Keys**: For programmatic access

### Authorization Model
- **Organisation-based**: All resources belong to organisations
- **Role-based**: Owner > Admin > Member permissions
- **Personal Organisations**: Every user gets one automatically
- **Invitation Flow**: Can invite non-existent users

## Template System

### Liquid Integration
- Uses Solid gem for Liquid template parsing
- Variable extraction with regex
- Parameter validation against template variables
- Auto-population of missing parameters

### Parameter Management
- Dynamic parameter definition
- Types: string, number, boolean
- Required/optional flags
- Visual validation feedback

## Database Design

### Custom Types
- `ParameterList`: Handles JSONB array storage for parameters
- Automatic type casting between forms and database

### Migrations
- Proper foreign key constraints
- Cascade deletes for data integrity
- Indexes on slug fields for performance

## Challenges & Solutions

### PostgreSQL Array Types
**Problem**: Form data as `text[]` vs database `jsonb[]`
**Solution**: Custom Ash type with proper casting

### Checkbox Handling
**Problem**: HTML sends "on" instead of "true"
**Solution**: Boolean conversion in parameter casting

### Multi-tenancy
**Problem**: Ensuring data isolation
**Solution**: Organisation context in LiveView assigns

### Personal Organisations
**Problem**: Users invited via email didn't get personal orgs
**Solution**: Auto-creation on first login in `LiveUserAuth`

## Current Limitations

1. **Version Management**: Basic tracking only, no semantic versioning
2. **Search**: No search functionality implemented
3. **Bundle System**: No export/import capabilities
4. **Client Library**: No SDK for consuming prompts
5. **Registry**: No central distribution mechanism
6. **Live Updates**: No PubSub for real-time updates

## Code Statistics

- **Domains**: 4 (Accounts, Organisations, Projects, Prompts)
- **Resources**: 9 Ash resources
- **LiveViews**: 15+ LiveView modules
- **Custom Types**: 1 (ParameterList)
- **Policies**: Role-based across all resources
- **Tests**: None yet (see ST0006)

## Next Implementation Priorities

1. **Testing**: Comprehensive test coverage needed
2. **Business Logic**: Extract from LiveViews to Ash actions
3. **Version Management**: Implement proper semantic versioning
4. **Client Library**: Build SDK for prompt consumption
5. **Search**: Add search across all resources