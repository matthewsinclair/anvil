# Tasks - ST0004: FORGE and LIVE Instance Architecture

## Phase 0: FORGE UI & Context Engineer Experience

### Forges Menu Implementation

- [ ] Add "Forges" menu item to left navigation
  - [ ] Create ForgesLive LiveView component
  - [ ] Design list UI for configured forges
  - [ ] Add configuration loading from config.exs
- [ ] Implement remote FORGE browsing
  - [ ] Bearer token authentication
  - [ ] Fetch remote organisations API call
  - [ ] Fetch remote projects API call
  - [ ] Error handling for connection failures
- [ ] Create project connection UI
  - [ ] "Connect" button on remote projects
  - [ ] Local reference storage (not data copy)
  - [ ] Read-only indicator badges
  - [ ] Source FORGE name display

### ACCESS_TOKEN Management

- [ ] Add token generation to Project settings
  - [ ] Create ProjectTokensLive component
  - [ ] Generate cryptographically secure tokens
  - [ ] Store encrypted in database
  - [ ] Token display with show/hide toggle
- [ ] Implement token UI features
  - [ ] Copy to clipboard functionality
  - [ ] Token revocation with confirmation
  - [ ] Last used timestamp tracking
  - [ ] Active/revoked status display

### Publishing UI

- [ ] Add "Publish to LIVE" button
  - [ ] Only show for LOCKED prompt sets
  - [ ] Disabled state with tooltip for non-LOCKED
  - [ ] Publishing confirmation dialog
- [ ] Create publishing feedback
  - [ ] Show connected LIVE instances
  - [ ] Success/failure status per instance
  - [ ] Error message display
  - [ ] Retry failed publishes

### API Endpoints for Browsing

- [ ] GET /api/v1/forge/organisations
  - [ ] Bearer token authentication
  - [ ] Return org list with metadata
- [ ] GET /api/v1/forge/projects/:org_id
  - [ ] Filter by user permissions
  - [ ] Include prompt set counts
- [ ] GET /api/v1/forge/project/:id/details
  - [ ] Full project metadata
  - [ ] Prompt set list with status

## Phase 1: Basic FORGE-to-LIVE Distribution

### anvil_client Package Creation

- [ ] Initialize hex package structure
  - [ ] mix new anvil_client --module AnvilClient
  - [ ] Configure mix.exs with minimal deps
  - [ ] Add hex metadata
- [ ] Define dependencies
  - [ ] Jason for JSON parsing
  - [ ] Optionally Tesla for HTTP
  - [ ] No heavy dependencies

### Core Client Implementation

- [ ] Create AnvilClient main module
  - [ ] prompt/2 function for runtime access
  - [ ] template/1 for raw template access
  - [ ] status/0 for connection info
- [ ] Implement cache layer
  - [ ] ETS table for in-memory storage
  - [ ] DETS for persistence
  - [ ] Cache warming on startup
  - [ ] TTL handling (optional)
- [ ] Create connection manager
  - [ ] GenServer for connection state
  - [ ] Initial sync on startup
  - [ ] Retry logic for failures
  - [ ] Health check mechanism

### Bundle Format Implementation

- [ ] Define bundle structure
  - [ ] Single PROMPT_SET_VERSION snapshot
  - [ ] Version metadata
  - [ ] Flat prompt ID namespace
  - [ ] JSON serialization
- [ ] Create bundle generator in FORGE
  - [ ] Extract snapshot from database
  - [ ] Add metadata wrapper
  - [ ] JSON encoding
  - [ ] Optional gzip compression

### HTTP Receiver Endpoint

- [ ] Create Plug module for receiving
  - [ ] POST /anvil/receive endpoint
  - [ ] Bearer token validation
  - [ ] Mode checking (ACCEPTING/FROZEN)
  - [ ] Bundle parsing and validation
- [ ] Implement bundle application
  - [ ] Parse incoming bundle
  - [ ] Update ETS cache
  - [ ] Persist to DETS
  - [ ] Log update event

### FORGE Push Implementation

- [ ] Create push manager GenServer
  - [ ] Track LIVE instances by token usage
  - [ ] Queue push operations
  - [ ] Handle failures gracefully
- [ ] Implement push action
  - [ ] Bundle generation
  - [ ] HTTP POST to LIVE instances
  - [ ] Success/failure tracking
  - [ ] Retry logic

### Sync Protocol

- [ ] GET endpoint for manual sync
  - [ ] /api/v1/projects/:id/current_bundle
  - [ ] ETag support for caching
  - [ ] Last-Modified headers
- [ ] Client pull implementation
  - [ ] Check for updates
  - [ ] Download bundle
  - [ ] Apply to cache

## Phase 2: Developer Experience

### Igniter Mix Tasks

- [ ] Create mix anvil.install
  - [ ] Add anvil_client to deps
  - [ ] Generate config template
  - [ ] Add supervisor entry
  - [ ] Create cache directory
- [ ] Create mix anvil.connect
  - [ ] Interactive prompts
  - [ ] Validate connection
  - [ ] Save configuration
  - [ ] Initial sync
- [ ] Create mix anvil.sync
  - [ ] Manual sync trigger
  - [ ] Progress display
  - [ ] Error reporting
- [ ] Create mix anvil.mode
  - [ ] Switch between ACCEPTING/FROZEN
  - [ ] Update configuration
  - [ ] Restart receiver if needed
- [ ] Create mix anvil.status
  - [ ] Display connection info
  - [ ] Show cache statistics
  - [ ] List available prompts

### Configuration Management

- [ ] Create config template
  - [ ] Document all options
  - [ ] Provide sensible defaults
  - [ ] Environment variable support
- [ ] Runtime configuration
  - [ ] Allow runtime mode changes
  - [ ] Dynamic port configuration
  - [ ] Multiple environment support

### Admin UI Component (Optional)

- [ ] Create LiveView component
  - [ ] Display connection status
  - [ ] Mode toggle switch
  - [ ] Manual sync button
  - [ ] Cache statistics
- [ ] Mount in host application
  - [ ] Provide mounting instructions
  - [ ] Style customization options
  - [ ] Authorization integration

## Phase 3: Advanced Features

### Full FORGE-to-FORGE Peering

- [ ] Implement bidirectional browsing
  - [ ] Mutual authentication
  - [ ] Project discovery
  - [ ] Permission negotiation
- [ ] Advanced connection features
  - [ ] Favorite forges
  - [ ] Connection history
  - [ ] Automatic reconnection

### Multi-Environment Support

- [ ] Environment-aware distribution
  - [ ] Tag LIVE instances by environment
  - [ ] Selective publishing
  - [ ] Environment-specific tokens
- [ ] Configuration templates
  - [ ] Dev/staging/prod presets
  - [ ] Environment variables
  - [ ] Automatic mode selection

### Enhanced Monitoring

- [ ] Distribution metrics
  - [ ] Push success rates
  - [ ] Sync frequency
  - [ ] Bundle sizes
  - [ ] Latency measurements
- [ ] Client health monitoring
  - [ ] Last sync times
  - [ ] Error rates
  - [ ] Cache hit rates

## Testing Requirements

### Unit Tests

- [ ] FORGE components
  - [ ] Token generation
  - [ ] Bundle creation
  - [ ] API endpoints
- [ ] Client package
  - [ ] Cache operations
  - [ ] Bundle parsing
  - [ ] Connection management
  - [ ] Template rendering

### Integration Tests

- [ ] Full push flow
  - [ ] LOCKED prompt set → publish → receive
  - [ ] Mode switching behavior
  - [ ] Failure scenarios
- [ ] Sync operations
  - [ ] Initial sync
  - [ ] Update sync
  - [ ] Conflict handling

### End-to-End Tests

- [ ] Context Engineer workflow
  - [ ] Edit prompt
  - [ ] Lock prompt set
  - [ ] Publish to LIVE
  - [ ] Verify in client
- [ ] Developer workflow
  - [ ] Install client
  - [ ] Connect to FORGE
  - [ ] Use prompts in code

## Documentation Tasks

### User Documentation

- [ ] Context Engineer guide
  - [ ] Understanding FORGE/LIVE
  - [ ] Publishing workflow
  - [ ] Status management
- [ ] Developer guide
  - [ ] Installation steps
  - [ ] Configuration options
  - [ ] API reference
  - [ ] Troubleshooting

### Technical Documentation

- [ ] Architecture overview
  - [ ] FORGE components
  - [ ] LIVE components
  - [ ] Communication flow
- [ ] Bundle format specification
- [ ] Security considerations
- [ ] Performance tuning

### Example Applications

- [ ] Simple Phoenix app with anvil_client
- [ ] Multi-environment setup example
- [ ] Custom admin UI integration
- [ ] CI/CD integration patterns

## Performance Considerations

### Targets

- [ ] Bundle generation: < 100ms
- [ ] Push delivery: < 1 second
- [ ] Client prompt access: < 1ms
- [ ] Initial sync: < 5 seconds

### Optimizations

- [ ] Bundle compression
- [ ] Incremental updates (future)
- [ ] Connection pooling
- [ ] Cache warming strategies

## Security Checklist

### FORGE Security

- [ ] Token generation entropy
- [ ] Token storage encryption
- [ ] API rate limiting
- [ ] Audit logging

### Client Security

- [ ] Token transmission over HTTPS only
- [ ] Local token storage security
- [ ] Bundle integrity verification
- [ ] No code execution from bundles

### Communication Security

- [ ] TLS for all connections
- [ ] Certificate pinning (optional)
- [ ] Request signing (future)
- [ ] Replay attack prevention

## Rollback Plan

### Feature Flags

- [ ] Enable/disable peering
- [ ] Gradual rollout by organisation
- [ ] Quick disable mechanism

### Data Safety

- [ ] No destructive operations
- [ ] Forward-only versioning
- [ ] Cache corruption recovery
- [ ] Connection failure handling

## Success Metrics

### Adoption Metrics

- [ ] Number of FORGE instances
- [ ] Number of LIVE instances
- [ ] Prompts distributed per day
- [ ] Context Engineer engagement

### Performance Metrics

- [ ] Distribution latency
- [ ] Cache hit rates
- [ ] Sync frequency
- [ ] Error rates

### User Satisfaction

- [ ] Context Engineer feedback
- [ ] Developer experience survey
- [ ] Support ticket volume
- [ ] Feature request patterns
