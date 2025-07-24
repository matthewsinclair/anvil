# Design - ST0004: Anvil Peering

## Approach

Anvil Peering enables two distinct but related capabilities:
1. **Import/Export**: Transfer complete projects or subsets between Anvil instances
2. **Configuration Push**: Deploy prompts from management instance to lightweight clients

The implementation follows a phased approach, starting with bundle format design, then import/export, and finally the push mechanism.

### Design Principles

1. **Self-Contained Bundles**: Exports include all necessary dependencies
2. **Version Aware**: Handle version conflicts and compatibility
3. **Selective Transfer**: Export at project, prompt set, or prompt level
4. **Security First**: Encrypted bundles, authenticated transfers
5. **Backward Compatible**: Support older bundle formats

## Design Decisions

### 1. Bundle Format

**Decision**: Use ZIP archives with JSON manifest
**Rationale**:
- Human-readable manifest for debugging
- Compression reduces transfer size
- Standard format with broad tooling support
- Can include binary assets if needed

### 2. Dependency Handling

**Decision**: Inline dependencies with deduplication
**Rationale**:
- Self-contained bundles work offline
- Deduplication prevents bloat
- Version resolution at export time
- Simpler than package references

### 3. Push Protocol

**Decision**: HTTP-based with optional WebSocket upgrade
**Rationale**:
- HTTP works through firewalls
- WebSocket enables real-time updates
- Falls back gracefully
- Standard authentication mechanisms

### 4. Client Runtime

**Decision**: Separate hex package `anvil_client`
**Rationale**:
- Minimal dependencies
- Can embed in any Elixir app
- Independent versioning
- Smaller footprint than full Anvil

## Architecture

### Bundle Structure

```
anvil_bundle_v1.zip
├── manifest.json
├── data/
│   ├── projects/
│   │   └── project_uuid.json
│   ├── prompt_sets/
│   │   └── prompt_set_uuid.json
│   ├── prompts/
│   │   └── prompt_uuid.json
│   └── versions/
│       └── version_uuid.json
└── meta/
    ├── checksums.json
    └── signature.json
```

### Manifest Format

```json
{
  "format_version": "1.0",
  "created_at": "2025-07-24T10:00:00Z",
  "created_by": {
    "user_id": "uuid",
    "email": "user@example.com",
    "organisation": "Acme Corp"
  },
  "bundle_type": "project",
  "contents": {
    "projects": ["uuid1"],
    "prompt_sets": ["uuid2", "uuid3"],
    "prompts": ["uuid4", "uuid5", "uuid6"],
    "versions": ["uuid7", "uuid8"]
  },
  "dependencies": {
    "external_refs": [],
    "anvil_version": "1.0.0"
  },
  "metadata": {
    "description": "Customer service prompt templates",
    "tags": ["customer-service", "templates"]
  }
}
```

### Import/Export Flow

```
Export Process:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Select    │     │   Gather    │     │   Create    │
│  Resources  │────▶│Dependencies │────▶│   Bundle    │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                     │
                           ▼                     ▼
                    ┌─────────────┐     ┌─────────────┐
                    │  Resolve    │     │    Sign     │
                    │  Conflicts  │     │   Bundle    │
                    └─────────────┘     └─────────────┘

Import Process:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Verify    │     │   Preview   │     │   Import    │
│   Bundle    │────▶│  Changes    │────▶│    Data     │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                     │
                           ▼                     ▼
                    ┌─────────────┐     ┌─────────────┐
                    │   Conflict  │     │   Update    │
                    │ Resolution  │     │   Indices   │
                    └─────────────┘     └─────────────┘
```

### Push Architecture

```
Management Instance                    Client Application
┌─────────────────┐                   ┌─────────────────┐
│                 │                   │                 │
│  Anvil Full     │                   │  Anvil Client   │
│                 │                   │                 │
│ ┌─────────────┐ │                   │ ┌─────────────┐ │
│ │Push Manager │ │◀─────HTTP(S)─────▶│ │Pull Client  │ │
│ └─────────────┘ │                   │ └─────────────┘ │
│                 │                   │                 │
│ ┌─────────────┐ │                   │ ┌─────────────┐ │
│ │  Database   │ │                   │ │Local Cache  │ │
│ └─────────────┘ │                   │ └─────────────┘ │
└─────────────────┘                   └─────────────────┘

Push Protocol:
1. Client registers with management instance
2. Client polls or subscribes to updates
3. Management pushes configuration changes
4. Client validates and applies changes
5. Client acknowledges receipt
```

### Client Runtime Architecture

```elixir
# anvil_client/lib/anvil_client.ex
defmodule AnvilClient do
  @moduledoc """
  Lightweight Anvil runtime for consuming prompts
  """
  
  # Configuration
  defmodule Config do
    defstruct [
      :management_url,
      :api_key,
      :cache_dir,
      :poll_interval,
      :mode  # :pull or :push
    ]
  end
  
  # Core API
  def start_link(config)
  def get_prompt(address, variables)
  def render(prompt, variables)
  def sync()
  
  # Cache Management
  defmodule Cache do
    def get(key)
    def put(key, value, ttl)
    def invalidate(pattern)
  end
  
  # Sync Engine
  defmodule Sync do
    def pull_updates()
    def apply_bundle(bundle)
    def verify_state()
  end
end
```

## Bundle Operations

### Export Options

```elixir
defmodule Anvil.Bundle.Export do
  defstruct [
    :scope,        # :project | :prompt_set | :selection
    :resource_ids, # List of UUIDs
    :include_deps, # Include dependencies
    :format,       # :bundle_v1
    :encryption,   # :none | :aes256
    :signing_key   # Optional signing key
  ]
  
  def export(options) do
    options
    |> gather_resources()
    |> resolve_dependencies()
    |> create_bundle()
    |> sign_bundle()
    |> encrypt_bundle()
  end
end
```

### Import Options

```elixir
defmodule Anvil.Bundle.Import do
  defstruct [
    :bundle_path,
    :target_org,
    :conflict_resolution, # :skip | :overwrite | :version
    :dry_run,
    :mapping  # Remap resource IDs
  ]
  
  def import(options) do
    options
    |> verify_bundle()
    |> decrypt_bundle()
    |> preview_changes()
    |> resolve_conflicts()
    |> apply_changes()
  end
end
```

### Conflict Resolution

```
Conflict Types:
1. Name Conflicts: Resource with same name exists
2. Version Conflicts: Different versions of same resource
3. Dependency Conflicts: Required dependency missing/different

Resolution Strategies:
┌─────────────────────────────────────────────────┐
│ Strategy  │ Name      │ Version   │ Dependency │
├───────────┼───────────┼───────────┼────────────┤
│ Skip      │ Keep old  │ Keep old  │ Skip import│
│ Overwrite │ Replace   │ Replace   │ Replace    │
│ Version   │ Rename    │ New vers. │ Add missing│
│ Manual    │ User pick │ User pick │ User pick  │
└─────────────────────────────────────────────────┘
```

## Security Considerations

### Bundle Security

1. **Signing**: Ed25519 signatures for authenticity
2. **Encryption**: Optional AES-256 for sensitive data
3. **Checksums**: SHA-256 for integrity verification
4. **Permissions**: Export requires read, import requires write

### Push Security

1. **mTLS**: Mutual TLS for instance communication
2. **API Keys**: Scoped keys for client authentication
3. **Rate Limiting**: Prevent DoS on push endpoints
4. **Audit Trail**: Log all push operations

### Data Validation

```elixir
defmodule Anvil.Bundle.Validator do
  def validate_bundle(bundle) do
    with :ok <- validate_format(bundle),
         :ok <- validate_manifest(bundle),
         :ok <- validate_checksums(bundle),
         :ok <- validate_signature(bundle),
         :ok <- validate_resources(bundle) do
      {:ok, bundle}
    end
  end
  
  def validate_resource(resource) do
    # Ensure no script injection
    # Validate Liquid templates
    # Check parameter types
    # Verify relationships
  end
end
```

## Implementation Patterns

### Bundle Creation

```elixir
def create_bundle(resources, options) do
  with {:ok, temp_dir} <- create_temp_directory(),
       :ok <- write_manifest(temp_dir, resources, options),
       :ok <- write_resources(temp_dir, resources),
       :ok <- calculate_checksums(temp_dir),
       {:ok, zip_path} <- create_zip(temp_dir) do
    {:ok, zip_path}
  end
end
```

### Push Client

```elixir
defmodule AnvilClient.PushClient do
  use GenServer
  
  def init(config) do
    schedule_sync()
    {:ok, %{config: config, last_sync: nil}}
  end
  
  def handle_info(:sync, state) do
    case sync_with_server(state.config) do
      {:ok, updates} ->
        apply_updates(updates)
        schedule_sync()
        {:noreply, %{state | last_sync: DateTime.utc_now()}}
      
      {:error, _reason} ->
        schedule_retry()
        {:noreply, state}
    end
  end
end
```

## Alternatives Considered

### 1. Git-based Sync

**Pros**: Version control, diff tools, existing ecosystem
**Cons**: Requires git, complex conflict resolution, not user-friendly
**Decision**: Bundle format better for non-technical users

### 2. GraphQL Subscriptions for Push

**Pros**: Real-time, standard protocol
**Cons**: Complex client, requires persistent connection
**Decision**: HTTP polling simpler and more reliable

### 3. Embedded SQLite for Client Cache

**Pros**: Full SQL queries, ACID compliance
**Cons**: Larger dependency, overkill for caching
**Decision**: ETS/DETS sufficient for client needs

### 4. Binary Protocol for Bundles

**Pros**: Smaller size, faster parsing
**Cons**: Not human-readable, harder to debug
**Decision**: JSON manifest with binary data offers best balance