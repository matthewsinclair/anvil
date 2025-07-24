# Design - ST0001: Anvil Prompt Management System

## Approach

Build Anvil as a prompt management system that treats prompts as versioned, distributable packages. The implementation will follow these principles:

1. **Package Manager Mental Model**: Think "hex for prompts" not "git for prompts"
2. **Progressive Enhancement**: Start with core functionality, add advanced features incrementally
3. **Security First**: Authentication and authorisation built in from the start
4. **Developer Experience**: Simple CLI and API for common operations

## Design Decisions

### Core Architecture

**Hierarchical Organisation**

- User → Projects → Prompt Sets → Prompts
- Rationale: Provides clear ownership and logical grouping without multi-tenant complexity

**Versioning at Prompt Set Level**

- Prompt sets are the unit of versioning, not individual prompts
- Semantic versioning with prompt-specific metadata: `2.1.0-gpt4+tokens.1500`
- Rationale: Individual prompt versioning would create dependency chaos

**Addressing Scheme**

```
@repository/bundle@version/prompt_name
```

- Examples:
  - `@anvil/core-prompts@2.1.0/welcome_message`
  - `@local/onboarding@stable/first_login`
- Rationale: Clear separation of concerns, familiar to developers

### Distribution Model

**Thin Bundles + Lock Files**

- Publish minimal metadata with dependency specifications
- Lock files ensure reproducible deployments
- Local materialisation for runtime efficiency
- Rationale: Balances efficiency with certainty

**Dependency Management**

- Prompt sets can depend on other prompt sets
- Acyclic dependencies only (circular deps are an error)
- Dependencies resolved at publish time
- Rationale: Enables reuse while maintaining predictability

### Deployment Modes

**Embedded Mode Options**

```elixir
config :anvil,
  mode: :embedded,        # Optional /anvil routes in app
  enable_ui: true,        # Enable web UI
  auth_module: MyApp.AnvilAuth
```

**Edit Modes**

- `:live` - Immediate updates via PubSub
- `:review` - Changes require approval
- `:locked` - Deploy-time updates only
- Rationale: Different environments need different safety levels

### Security Model

**Application-Controlled Authentication**

- Apps implement AnvilAuth behaviour
- Anvil enforces authorisation (roles, permissions)
- Audit trail for all operations
- Rationale: Leverages existing app auth while maintaining control

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Client Applications                  │
├─────────────────────────────────────────────────────────┤
│                    Anvil Client Library                 │
│  - Anvil.get/2          - Local cache management        │
│  - Mix tasks            - PubSub subscriptions          │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────┴───────────────────────────────────────┐
│                    Anvil Service                        │
├─────────────────────────────────────────────────────────┤
│  Web UI             │  API             │  CLI Support   │
├─────────────────────┼──────────────────┼────────────────┤
│  Phoenix LiveView   │  REST + GraphQL  │  Mix Tasks     │
├─────────────────────┴──────────────────┴────────────────┤
│                 Core Domain (Ash Resources)             │
│  - Projects         - Prompt Sets      - Versions       │
│  - Dependencies     - Deployments      - Analytics      │
├─────────────────────────────────────────────────────────┤
│              Infrastructure Services                    │
│  - Anvil.Cache      - Anvil.Registry   - Anvil.PubSub   │
│  - Anvil.Storage    - Anvil.Auth       - Anvil.Audit    │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

**Development Workflow**

1. Context Engineer creates/edits prompts in Anvil UI
2. Changes saved to draft versions
3. CE tests prompts with preview feature
4. CE publishes prompt set with new version
5. Published versions immutable

**Runtime Flow**

1. App requests prompt via `Anvil.get/2`
2. Client checks local cache
3. If miss, fetches from registry
4. Applies parameter interpolation
5. Returns materialised prompt

**Update Propagation**

- `:live` mode: PubSub broadcasts changes immediately
- `:review` mode: Changes queued until approved
- `:locked` mode: Requires deployment or CLI command

## Alternatives Considered

### Git-Based Versioning

- **Considered**: Full git integration with branches, commits, PRs
- **Rejected**: Overly complex for prompt management; package manager model simpler

### Individual Prompt Versioning

- **Considered**: Version each prompt independently
- **Rejected**: Dependency resolution becomes intractable; prompt sets provide better cohesion

### Multi-Tenant Architecture

- **Considered**: Full isolation between organisations
- **Rejected**: Unnecessary complexity for MVP; project-based separation sufficient

### Fat Bundles Only

- **Considered**: Inline all dependencies at publish time
- **Rejected**: Storage bloat and update propagation issues; thin bundles + lock files better

### Workflow Engine in MVP

- **Considered**: IFTTT-style automation from the start
- **Rejected**: Scope creep; can be added later if needed

## Implementation Decisions Made

### Template Syntax

- **Decision**: Used Liquid syntax via Solid gem
- **Rationale**: Familiar syntax with extensive documentation and community support
- **Implementation**: Integrated Solid Ruby gem with custom Anvil.Template.Analyzer for variable extraction

### Authentication Model

- **Decision**: Used phx_gen_auth for MVP instead of custom Anvil.Auth behaviour
- **Rationale**: Faster to implement, well-tested, can be replaced with custom auth later for embedded mode
- **Implementation**: Standard phx_gen_auth with LiveView session management

### Parameter Storage

- **Decision**: Custom Ash type for PostgreSQL jsonb[] arrays
- **Rationale**: Allows flexible parameter metadata while maintaining type safety
- **Implementation**: Anvil.Types.ParameterList handles conversion between forms and database

### UI Framework

- **Decision**: Phoenix LiveView with DaisyUI components and retro theme
- **Rationale**: LiveView provides real-time updates without JavaScript complexity
- **Implementation**: All pages converted to LiveView with command palette integration

### Slug Generation

- **Decision**: Atomic database operations using PostgreSQL fragments
- **Rationale**: Ensures consistency and prevents race conditions
- **Implementation**: Custom Ash changes with atomic methods

## Open Questions & Design Points

### Registry Implementation

- **Question**: Should we build our own registry or adapt existing package registry code?
- **Options**:
  - Fork Hex.pm for prompt-specific needs
  - Build minimal custom registry
  - Use S3/CDN for simple file hosting
- **Recommendation**: Start with simple S3/CDN approach, evolve as needed

### Template Filters for LLMs

- **Question**: What custom Liquid filters should we add for LLM-specific needs?
- **Considerations**:
  - Token counting filters
  - Format conversion filters (markdown, JSON, etc.)
  - Context window management
- **Recommendation**: Start with basic filters, add based on user feedback

### Caching Strategy

- **Question**: Local ETS vs Redis vs hybrid approach?
- **Trade-offs**:
  - ETS: Fast but not distributed
  - Redis: Distributed but additional dependency
  - Hybrid: Complex but flexible
- **Status**: Not yet implemented - will start with ETS when building client library

### Version Aliases

- **Question**: Where should version aliases (stable, latest) be resolved?
- **Options**:
  - Client-side in project config
  - Server-side in registry
  - Both with precedence rules
- **Recommendation**: Server-side with client override capability

### Review Workflow Implementation

- **Question**: How to implement approval workflow for :review mode?
- **Options**:
  - Simple database state machine
  - Full workflow engine (Oban)
  - External service integration
- **Recommendation**: Database state machine for MVP, consider Oban later

### Public vs Private Registries

- **Question**: How to handle registry visibility and access control?
- **Considerations**:
  - Need both public shared prompts and private project prompts
  - Authentication complexity
  - Discovery mechanisms
- **Recommendation**: Single registry with visibility flags and project scoping
