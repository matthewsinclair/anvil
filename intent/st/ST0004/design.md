# Design - ST0004: FORGE and LIVE Instance Architecture

## Executive Summary

This design document details the implementation of Anvil's distributed architecture, enabling Context Engineers to update prompts in production applications without code deployment. The system consists of FORGE instances (full Anvil web applications) and LIVE instances (lightweight client libraries) that communicate through a controlled distribution mechanism.

## Core Concepts

### FORGE Instance

A **FORGE instance** is a complete Anvil web application where Context Engineers manage prompts. Key characteristics:

- Full Phoenix LiveView UI for prompt management
- Hosts multiple projects with prompt sets
- Generates ACCESS_TOKENs for project distribution
- Can peer with other FORGE instances for browsing/sharing
- Controls distribution through prompt set status (LIVE/REVIEW/LOCKED)

### LIVE Instance

A **LIVE instance** is the `anvil_client` library embedded in production applications. Key characteristics:

- Lightweight hex package with minimal dependencies
- Connects to exactly one FORGE instance
- Caches prompt data locally (ETS/DETS)
- Provides simple API: `Anvil.prompt("prompt.id", variables)`
- Two reception modes: ACCEPTING (receives updates) or FROZEN (no updates)

### Bundle

A **bundle** is the unit of distribution - a single PROMPT_SET_VERSION snapshot containing:

- The complete JSONB snapshot from the database
- Version metadata
- Flat namespace of prompt IDs (e.g., "welcome.message", "error.not_found")

## Architecture Overview

```
┌─────────────────────────────────────┐     ┌─────────────────────────────────────┐
│          FORGE Instance             │     │          LIVE Instance              │
│    (promptwithanvil.com)            │     │    (Production Application)         │
├─────────────────────────────────────┤     ├─────────────────────────────────────┤
│                                     │     │                                     │
│  Context Engineers ──▶ Web UI       │     │  Application Code                   │
│           │                         │     │       │                             │
│           ▼                         │     │       ▼                             │
│    Edit Prompts                     │     │  Anvil.prompt("welcome.message")    │
│           │                         │     │       │                             │
│           ▼                         │     │       ▼                             │
│    Status: LIVE/REVIEW/LOCKED       │     │  Local Cache (ETS)                  │
│           │                         │     │       ▲                             │
│           ▼                         │     │       │                             │
│    [Publish to LIVE]                │     │   HTTP Endpoint                     │
│           │                         │     │       ▲                             │
│           └─────────────────────────┼─────┼───────┘                             │
│                                     │     │                                     │
│  ACCESS_TOKEN: xxx-yyy-zzz          │     │  Mode: ACCEPTING/FROZEN             │
│                                     │     │                                     │
└─────────────────────────────────────┘     └─────────────────────────────────────┘
```

## Detailed Design

### 1. FORGE Instance Components

#### 1.1 Forges Menu

New left-navigation menu item that provides:

- List of configured FORGE instances from application config
- Browse interface for remote Organisations and Projects
- "Connect" action to subscribe to remote projects
- Visual indicators for connected/read-only projects

Configuration example:

```elixir
config :anvil, :known_forges, [
  %{
    name: "Production Forge",
    url: "https://forge.production.com",
    bearer_token: System.get_env("FORGE_PROD_BEARER_TOKEN")
  },
  %{
    name: "Partner Forge",
    url: "https://partner.forge.com",
    bearer_token: System.get_env("FORGE_PARTNER_BEARER_TOKEN")
  }
]
```

#### 1.2 Project ACCESS_TOKEN Management

Each project can generate ACCESS_TOKENs for distribution:

- Generated through project settings UI
- Stored encrypted in database
- Revocable at any time
- Used by LIVE instances for authentication

UI features:

- "Generate New Token" button
- Token display with show/hide toggle
- "Copy to Clipboard" functionality
- Token revocation with confirmation
- Last used timestamp display

#### 1.3 Status-Based Distribution Control

Prompt Set Status determines distribution eligibility:

**LOCKED** - Production Ready

- No edits allowed in FORGE
- Safe for distribution to production LIVE instances
- Represents stable, tested prompts

**REVIEW** - Pending Approval

- Changes require approval
- Could be distributed to staging/test environments
- Not recommended for production

**LIVE** - Active Development

- Freely editable by Context Engineers
- Should NOT be distributed to production
- For experimentation and development

#### 1.4 Publishing Mechanism

Publishing workflow:

1. Context Engineer navigates to LOCKED prompt set
2. Clicks "Publish to LIVE" button
3. System shows connected LIVE instances (based on ACCESS_TOKEN usage)
4. Confirms publication
5. FORGE pushes bundle to all ACCEPTING LIVE instances
6. UI shows success/failure status for each instance

### 2. LIVE Instance (`anvil_client`) Design

#### 2.1 Package Structure

```
anvil_client/
├── lib/
│   ├── anvil_client.ex          # Main API
│   ├── anvil_client/
│   │   ├── cache.ex             # ETS/DETS caching
│   │   ├── connection.ex        # FORGE connection management
│   │   ├── receiver.ex          # HTTP endpoint for pushes
│   │   └── config.ex            # Configuration handling
├── mix.exs
└── README.md
```

#### 2.2 Configuration

Client configuration in host application:

```elixir
config :anvil_client,
  forge_url: "https://promptwithanvil.com",
  project_id: "uuid-of-project",
  access_token: System.get_env("ANVIL_ACCESS_TOKEN"),
  mode: :accepting,  # or :frozen
  cache_dir: "priv/anvil_cache",
  port: 4001  # Port for receiving pushes
```

#### 2.3 Core API

Simple runtime API:

```elixir
# Get a prompt with variables
prompt = Anvil.prompt("welcome.message", name: "John", role: "admin")
# => "Welcome John! As an admin, you have full access."

# Get raw prompt template
template = Anvil.template("welcome.message")
# => "Welcome {{name}}! As {{role}}, you have {{access_level}} access."

# Check connection status
Anvil.status()
# => %{mode: :accepting, last_sync: ~U[2024-01-15 10:30:00Z], version: "1.2.3"}
```

#### 2.4 Caching Strategy

Two-tier cache:

1. **ETS** - In-memory cache for fast access
2. **DETS** - Disk persistence for restart survival

Cache population:

- Initial sync on application start
- Updates received via push (when ACCEPTING)
- Manual sync via `mix anvil.sync` (when FROZEN)

#### 2.5 Reception Modes

**ACCEPTING Mode**:

- HTTP endpoint active on configured port
- Receives and applies pushed updates automatically
- Logs all received updates
- Suitable for development/staging

**FROZEN Mode**:

- HTTP endpoint disabled
- No automatic updates accepted
- Manual sync only via `mix anvil.sync`
- Suitable for production stability

Mode can be changed:

- Via configuration
- Via admin UI component (optional)
- Via mix task: `mix anvil.mode frozen`

### 3. Bundle Format Specification

#### 3.1 Structure

A bundle is a single PROMPT_SET_VERSION snapshot:

```json
{
  "version": "1.2.3",
  "prompt_set_id": "uuid",
  "project_id": "uuid",
  "created_at": "2024-01-15T10:30:00Z",
  "snapshot": {
    "welcome.message": {
      "template": "Welcome {{name}}!",
      "metadata": {...}
    },
    "error.not_found": {
      "template": "Sorry, {{resource}} was not found.",
      "metadata": {...}
    }
  }
}
```

#### 3.2 Delivery Format

Bundles are delivered as:

- JSON payload over HTTPS
- Optional compression (gzip)
- Checksum for integrity verification
- Signed with FORGE's private key (future enhancement)

### 4. Communication Protocol

#### 4.1 FORGE to LIVE Push

```
POST /anvil/receive
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "bundle": { <bundle_data> },
  "forge_url": "https://promptwithanvil.com",
  "project_id": "uuid",
  "pushed_at": "2024-01-15T10:30:00Z"
}

Response:
200 OK - Bundle accepted and applied
401 Unauthorized - Invalid ACCESS_TOKEN
409 Conflict - LIVE instance in FROZEN mode
```

#### 4.2 LIVE to FORGE Sync (Pull)

```
GET /api/v1/projects/<project_id>/current_bundle
Authorization: Bearer <access_token>

Response:
{
  "bundle": { <bundle_data> },
  "etag": "abc123",
  "last_modified": "2024-01-15T10:30:00Z"
}
```

### 5. Security Considerations

#### 5.1 Authentication

- ACCESS_TOKENs are generated per project
- Tokens are cryptographically secure random strings
- Transmitted only over HTTPS
- Stored encrypted in FORGE database

#### 5.2 Authorization

- FORGE verifies prompt set is LOCKED before distribution
- LIVE instances verify ACCESS_TOKEN on every request
- Project isolation enforced at database level

#### 5.3 Data Protection

- All communication over HTTPS
- Optional bundle encryption (future enhancement)
- No sensitive data in bundles (only prompt templates)

### 6. Mix Tasks for Developer Experience

#### 6.1 Installation

```bash
# Add dependency and initial setup
mix anvil.install

This will:
1. Add anvil_client to mix.exs
2. Create config/anvil.exs
3. Add HTTP endpoint to your router
4. Create cache directory
```

#### 6.2 Connection Setup

```bash
# Interactive connection wizard
mix anvil.connect

> Enter FORGE URL: https://promptwithanvil.com
> Enter Project ID: abc-123-def
> Enter ACCESS_TOKEN: xxx-yyy-zzz
> Initial mode (accepting/frozen) [accepting]: frozen

Configuration saved to config/anvil.exs
```

#### 6.3 Management Tasks

```bash
# Manual sync (useful in FROZEN mode)
mix anvil.sync

# Change reception mode
mix anvil.mode accepting
mix anvil.mode frozen

# View status
mix anvil.status
# => FORGE: https://promptwithanvil.com
# => Project: abc-123-def
# => Mode: FROZEN
# => Last sync: 2024-01-15 10:30:00
# => Version: 1.2.3
# => Prompts: 42
```

### 7. FORGE Browsing and Peering

#### 7.1 Remote FORGE Browsing

When browsing a remote FORGE:

1. Authenticate using configured bearer token
2. Fetch organisation list
3. For each org, fetch project list (filtered by permissions)
4. Display projects with metadata (name, prompt count, last updated)

#### 7.2 Project Connection

"Connecting" to a remote project:

1. Creates a local reference to the remote project
2. Marks it as read-only in the UI
3. Does NOT copy data (remains on remote FORGE)
4. Allows browsing prompts for reference/inspiration

#### 7.3 Visual Indicators

Connected remote projects show:

- 🔗 Link icon indicating remote source
- "Read-only" badge
- Source FORGE name in subtitle
- Different background color in project list

### 8. Future Enhancements

#### 8.1 LLM Proxy Features

Building towards Anvil as an LLM proxy:

- Token usage tracking per prompt
- A/B testing different prompt versions
- Automatic prompt optimization
- Multi-LLM routing based on prompt type

#### 8.2 Advanced Distribution

- Scheduled publishing
- Gradual rollout (percentage-based)
- Environment-specific distribution
- Automatic rollback on error thresholds

#### 8.3 Enhanced Security

- Asymmetric cryptography for bundle signing
- End-to-end encryption for sensitive prompts
- Audit logging with immutable trail
- SOC2 compliance features

## Implementation Patterns

### GenServer for Connection Management

```elixir
defmodule AnvilClient.Connection do
  use GenServer
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(opts) do
    # Schedule initial sync
    Process.send_after(self(), :sync, 0)
    
    {:ok, %{
      forge_url: opts[:forge_url],
      access_token: opts[:access_token],
      mode: opts[:mode] || :accepting,
      last_sync: nil
    }}
  end
  
  def handle_info(:sync, state) do
    case sync_with_forge(state) do
      {:ok, bundle} ->
        Cache.update(bundle)
        {:noreply, %{state | last_sync: DateTime.utc_now()}}
      {:error, reason} ->
        Logger.error("Sync failed: #{inspect(reason)}")
        # Retry after delay
        Process.send_after(self(), :sync, :timer.minutes(5))
        {:noreply, state}
    end
  end
end
```

### Plug for Receiving Pushes

```elixir
defmodule AnvilClient.Receiver do
  use Plug.Router
  
  plug :match
  plug :dispatch
  
  post "/anvil/receive" do
    with :accepting <- AnvilClient.mode(),
         {:ok, token} <- get_bearer_token(conn),
         :ok <- verify_token(token),
         {:ok, body, conn} <- read_body(conn),
         {:ok, bundle} <- decode_bundle(body) do
      
      AnvilClient.Cache.update(bundle)
      send_resp(conn, 200, "Bundle accepted")
    else
      :frozen ->
        send_resp(conn, 409, "LIVE instance is frozen")
      {:error, :unauthorized} ->
        send_resp(conn, 401, "Unauthorized")
      error ->
        send_resp(conn, 400, "Bad request")
    end
  end
end
```

## Testing Strategy

### Unit Tests

- Bundle parsing and validation
- Cache operations
- Template rendering
- Configuration handling

### Integration Tests

- Full FORGE to LIVE push flow
- Sync operations
- Mode switching
- Error handling

### Load Tests

- Multiple LIVE instances receiving pushes
- Large bundle handling
- Cache performance under load
- Network failure recovery

## Rollout Plan

### Phase 0: Foundation (Week 1-2)

- Implement Forges menu in existing Anvil
- Add ACCESS_TOKEN generation to projects
- Create browsing UI for remote FORGEs
- Test with Context Engineers

### Phase 1: Basic Distribution (Week 3-4)

- Create anvil_client package
- Implement basic push/receive
- Add caching layer
- Manual testing with sample app

### Phase 2: Developer Experience (Week 5-6)

- Create Igniter-based mix tasks
- Add comprehensive documentation
- Build example applications
- Beta testing with partner teams

### Phase 3: Production Hardening (Week 7-8)

- Add monitoring and metrics
- Implement retry logic
- Performance optimization
- Security audit

This design provides a solid foundation for distributed prompt management while maintaining simplicity for both Context Engineers and developers. The architecture supports future expansion into a full LLM proxy platform while solving the immediate need for zero-deployment prompt updates.
