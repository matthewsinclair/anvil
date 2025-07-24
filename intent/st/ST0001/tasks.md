# Tasks - ST0001: Anvil Prompt Management System

## Phase 1: Core Infrastructure (Foundation)

### Domain Models & Database

- [x] Create Ash domains for Projects, Prompts, and Accounts
- [x] Define Project resource with relationships
- [x] Define PromptSet resource with versioning attributes
- [x] Define Prompt resource with template and parameters
- [x] Create Version resource for tracking changes
- [x] Set up database migrations
- [x] Add seed data for development

### Authentication & Authorisation

- [x] Implement phx_gen_auth for user authentication
- [ ] Define Anvil.Auth behaviour
- [x] Implement Ash policies for resources (basic auth checks)
- [ ] Create roles (admin, context_engineer, viewer)
- [ ] Add audit logging for all operations

## Phase 2: Web Application (Management UI)

### Phoenix Application Setup

- [x] Create Phoenix LiveView controllers for prompt management
- [x] Build project listing and creation UI
- [x] Create prompt set editor with preview
- [ ] Implement version comparison view
- [x] Add parameter definition interface
- [x] Create template validation UI

### Embedded Mode Support

- [ ] Create mountable route module for /anvil
- [ ] Implement auth delegation to host app
- [ ] Add configuration for edit modes
- [ ] Build review workflow UI
- [ ] Create approval queue interface

### Additional UI Features (Completed)

- [x] Implement breadcrumb navigation component
- [x] Create command palette with keyboard shortcuts (Cmd+K)
- [x] Convert all pages to LiveViews for consistent experience
- [x] Add global search/command functionality
- [x] Create Dashboard, Account, Settings, and Help pages
- [x] Implement parameter validation and auto-extraction
- [x] Add visual validation feedback for templates
- [x] Fix PostgreSQL array type handling for parameters
- [x] Create custom Ash type for parameter lists

## Phase 3: Client Library (Consumer SDK)

### Core Client Functions

- [ ] Implement Anvil.get/2 and Anvil.get!/2
- [ ] Create address parser (Anvil.Resolver)
- [ ] Build local cache (Anvil.Cache)
- [ ] Implement registry client (Anvil.Registry)
- [x] Add template renderer (Anvil.Template) - using Solid

### Mix Tasks

- [ ] Create mix anvil.init task
- [ ] Implement mix anvil.pull task
- [ ] Add mix anvil.push task
- [ ] Create mix anvil.list task
- [ ] Build mix anvil.search task

## Phase 4: Distribution & Updates

### Publishing System

- [ ] Create publish workflow with version validation
- [ ] Implement dependency resolution
- [ ] Build manifest generation
- [ ] Add lock file support
- [ ] Create bundle packaging

### Live Updates

- [ ] Implement PubSub handlers
- [ ] Create update notification system
- [ ] Add cache invalidation logic
- [ ] Build cluster synchronisation
- [ ] Implement fallback mechanisms

## Phase 5: Advanced Features

### Template Engine

- [ ] Integrate Solid (Liquid) templating
- [ ] Create safe filter whitelist
- [ ] Add parameter type validation
- [ ] Implement template composition
- [ ] Build error handling

### Analytics & Monitoring

- [ ] Add usage tracking
- [ ] Create performance metrics
- [ ] Build cost analysis (token counting)
- [ ] Implement A/B test framework
- [ ] Add telemetry integration

## Task Notes

**Priority Order**:

1. Start with Phase 1 to establish data models
2. Build minimal web UI for testing (Phase 2)
3. Create client library for integration (Phase 3)
4. Add distribution once core works (Phase 4)
5. Enhanced features can be added incrementally (Phase 5)

**Testing Strategy**:

- Unit tests for all Ash resources
- Integration tests for client library
- LiveView tests for UI components
- End-to-end tests for workflows

**Documentation Needs**:

- API documentation for client library
- Deployment guide for service
- Context Engineer user guide
- Developer integration guide

## Dependencies

**Phase Dependencies**:

- Phase 2 depends on Phase 1 completion
- Phase 3 can start after Phase 1 core models
- Phase 4 requires Phase 2 & 3 basics
- Phase 5 can be done in parallel after Phase 3

**External Dependencies**:

- Ash Framework 3.5+ (already in project)
- Solid templating library (needs adding)
- Phoenix PubSub (already available)
- PostgreSQL with JSONB support

**Resource Requirements**:

- Development database instance
- Redis for caching (optional for MVP)
- File storage for prompt versions
- Test environment with multiple nodes
