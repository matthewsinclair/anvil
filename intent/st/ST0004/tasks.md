# Tasks - ST0004: Anvil Peering

## Phase 1: Bundle Format Design and Infrastructure

### Bundle Format Specification
- [ ] Define bundle format version 1.0 specification
  - [ ] Manifest JSON schema
  - [ ] Directory structure
  - [ ] Metadata requirements
  - [ ] Compression format (ZIP)
- [ ] Create bundle validation schemas
  - [ ] JSON Schema for manifest
  - [ ] Resource validation rules
  - [ ] Checksum format
- [ ] Design security specifications
  - [ ] Ed25519 signature format
  - [ ] AES-256 encryption spec
  - [ ] Key management approach

### Core Bundle Modules
- [ ] Create lib/anvil/bundle.ex module structure
- [ ] Implement Anvil.Bundle.Manifest
  - [ ] Manifest creation
  - [ ] Manifest validation
  - [ ] Version compatibility checking
- [ ] Implement Anvil.Bundle.Resource
  - [ ] Resource serialization
  - [ ] Resource deserialization
  - [ ] Relationship preservation
- [ ] Implement Anvil.Bundle.Security
  - [ ] Signature generation
  - [ ] Signature verification
  - [ ] Encryption/decryption helpers

## Phase 2: Export Functionality

### Export UI
- [ ] Create export LiveView (BundleExportLive)
  - [ ] Resource selection interface
  - [ ] Dependency preview
  - [ ] Export options form
  - [ ] Progress indicator
- [ ] Add export buttons to existing views
  - [ ] Project page export
  - [ ] Prompt set export
  - [ ] Individual prompt export
- [ ] Create export preview modal
  - [ ] Show what will be included
  - [ ] Dependency tree visualization

### Export Implementation
- [ ] Implement Anvil.Bundle.Export module
  - [ ] gather_resources/2 function
  - [ ] resolve_dependencies/1 function
  - [ ] create_bundle/2 function
- [ ] Create export actions in Ash
  - [ ] Project.export_bundle action
  - [ ] PromptSet.export_bundle action
  - [ ] Prompt.export_bundle action
- [ ] Implement dependency resolver
  - [ ] Find all referenced resources
  - [ ] Handle circular dependencies
  - [ ] Version pinning
- [ ] Create bundle writer
  - [ ] Write manifest.json
  - [ ] Write resource files
  - [ ] Calculate checksums
  - [ ] Create ZIP archive

### Export Security
- [ ] Implement bundle signing
  - [ ] Generate signing keys
  - [ ] Sign manifest
  - [ ] Include public key
- [ ] Implement optional encryption
  - [ ] Encrypt sensitive data
  - [ ] Key exchange mechanism
  - [ ] Decryption instructions

## Phase 3: Import Functionality

### Import UI
- [ ] Create import LiveView (BundleImportLive)
  - [ ] File upload interface
  - [ ] Bundle validation display
  - [ ] Preview changes screen
  - [ ] Conflict resolution UI
  - [ ] Import progress
- [ ] Create conflict resolution modal
  - [ ] Show conflicts clearly
  - [ ] Provide resolution options
  - [ ] Preview resolution results
- [ ] Add import navigation
  - [ ] Import button on projects page
  - [ ] Drag-and-drop support

### Import Implementation
- [ ] Implement Anvil.Bundle.Import module
  - [ ] verify_bundle/1 function
  - [ ] preview_changes/2 function
  - [ ] resolve_conflicts/2 function
  - [ ] apply_changes/2 function
- [ ] Create import actions in Ash
  - [ ] Organisation.import_bundle action
  - [ ] Conflict resolution helpers
- [ ] Implement bundle reader
  - [ ] Extract ZIP safely
  - [ ] Validate manifest
  - [ ] Verify checksums
  - [ ] Load resources
- [ ] Implement conflict detection
  - [ ] Name conflicts
  - [ ] Version conflicts
  - [ ] ID conflicts
  - [ ] Dependency conflicts
- [ ] Implement conflict resolution
  - [ ] Skip strategy
  - [ ] Overwrite strategy
  - [ ] Version strategy
  - [ ] Manual resolution

### Import Security
- [ ] Verify bundle signatures
- [ ] Handle encrypted bundles
- [ ] Validate resource content
- [ ] Prevent malicious imports

## Phase 4: Configuration Push - Client Package

### Create anvil_client package
- [ ] Initialize new Hex package
  - [ ] mix new anvil_client
  - [ ] Configure mix.exs
  - [ ] Set up documentation
- [ ] Define minimal dependencies
  - [ ] Jason for JSON
  - [ ] Tesla for HTTP
  - [ ] Solid for template rendering
  - [ ] ETS for caching

### Client Core Modules
- [ ] Implement AnvilClient module
  - [ ] start_link/1 for supervision
  - [ ] get_prompt/2 public API
  - [ ] render/2 for templates
  - [ ] sync/0 for updates
- [ ] Implement AnvilClient.Config
  - [ ] Configuration struct
  - [ ] Validation
  - [ ] Default values
- [ ] Implement AnvilClient.Cache
  - [ ] ETS-based cache
  - [ ] TTL support
  - [ ] Cache invalidation
  - [ ] Persistence with DETS

### Client Sync Engine
- [ ] Implement AnvilClient.Sync
  - [ ] HTTP polling mechanism
  - [ ] Version checking
  - [ ] Delta updates
  - [ ] Full sync fallback
- [ ] Implement AnvilClient.Registry
  - [ ] Local prompt registry
  - [ ] Fast lookups
  - [ ] Relationship handling
- [ ] Create sync protocol
  - [ ] Version negotiation
  - [ ] Change detection
  - [ ] Efficient updates

## Phase 5: Configuration Push - Server Side

### Push Management UI
- [ ] Create push configuration LiveView
  - [ ] Client registration list
  - [ ] Push history
  - [ ] Manual push triggers
  - [ ] Client status monitoring
- [ ] Add push settings to projects
  - [ ] Enable/disable push
  - [ ] Client whitelist
  - [ ] Push scheduling

### Push API Endpoints
- [ ] Create push controller
  - [ ] POST /api/v1/push/register
  - [ ] GET /api/v1/push/check
  - [ ] GET /api/v1/push/bundle
  - [ ] POST /api/v1/push/acknowledge
- [ ] Implement authentication
  - [ ] Special push API keys
  - [ ] Client identification
  - [ ] Rate limiting
- [ ] Create push actions
  - [ ] Project.prepare_push_bundle
  - [ ] Track client versions
  - [ ] Generate deltas

### Push Infrastructure
- [ ] Implement push manager GenServer
  - [ ] Track registered clients
  - [ ] Monitor client health
  - [ ] Queue push operations
  - [ ] Handle failures
- [ ] Create push notifications
  - [ ] WebSocket support (future)
  - [ ] HTTP long-polling
  - [ ] Webhook callbacks
- [ ] Implement push audit log
  - [ ] Track all push events
  - [ ] Client acknowledgments
  - [ ] Error tracking

## Phase 6: Testing and Documentation

### Testing
- [ ] Unit tests for bundle format
  - [ ] Manifest validation
  - [ ] Resource serialization
  - [ ] Security functions
- [ ] Integration tests for import/export
  - [ ] Full cycle tests
  - [ ] Conflict scenarios
  - [ ] Large bundle handling
- [ ] Client package tests
  - [ ] Sync mechanism
  - [ ] Cache behavior
  - [ ] Error handling
- [ ] End-to-end push tests
  - [ ] Registration flow
  - [ ] Update propagation
  - [ ] Failure recovery

### Documentation
- [ ] Bundle format specification doc
- [ ] Import/export user guide
- [ ] Client integration guide
- [ ] Push configuration guide
- [ ] Security best practices
- [ ] API documentation updates

### Examples
- [ ] Example export scripts
- [ ] Example import workflows
- [ ] Client integration example
- [ ] Push setup tutorial

## Task Notes

### Critical Path
1. Bundle format must be finalized first
2. Export implementation before import
3. Client package can be developed in parallel
4. Push server requires client package

### Security Considerations
- All imports must be validated
- Signing should be mandatory for production
- Client authentication is critical
- Rate limiting on all endpoints

### Performance Targets
- Export: < 5 seconds for typical project
- Import: < 10 seconds including validation
- Push check: < 100ms response time
- Client sync: < 2 seconds for full sync

## Dependencies

### Technical Dependencies
- Erlang :zip module for archives
- :crypto for signatures
- Jason for JSON handling
- Tesla for HTTP client

### Knowledge Dependencies
- Understanding of Ash actions
- LiveView for UI components
- GenServer for push manager
- ETS for client caching

### Infrastructure Dependencies
- File storage for temporary bundles
- Increased API rate limits
- Client package hosting (Hex)

### Completion Order
1. Phase 1 (Bundle Format) - Foundation for all features
2. Phase 2 & 3 (Import/Export) - Can be done together
3. Phase 4 (Client Package) - Can start after Phase 1
4. Phase 5 (Push Server) - Requires client package
5. Phase 6 (Testing/Docs) - Throughout development