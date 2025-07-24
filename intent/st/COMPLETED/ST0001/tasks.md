# Tasks - ST0001: Anvil Prompt Management System

## Completed Work

### Core Infrastructure
- [x] Ash domains for Projects, Prompts, Organisations, and Accounts
- [x] Project, PromptSet, Prompt, and Version resources with relationships
- [x] Authentication with phx_gen_auth and magic links
- [x] Multi-tenancy with Organisations (see ST0003)
- [x] Role-based access control (owner/admin/member)
- [x] Database migrations and seed data
- [x] Custom PostgreSQL types for parameter storage

### Web Application
- [x] Phoenix LiveView UI for all CRUD operations
- [x] Project listing and creation
- [x] Prompt set editor with dynamic parameters
- [x] Template validation with Liquid syntax
- [x] Parameter auto-extraction from templates
- [x] Breadcrumb navigation
- [x] Command palette (Cmd+K)
- [x] Organisation switcher
- [x] Dashboard, Account, Settings, Help pages

### Template System
- [x] Solid (Liquid) integration
- [x] Template analyzer for variable extraction
- [x] Parameter validation UI

## Remaining Tasks

### Version Management System
- [ ] Implement semantic versioning with major/minor/patch
- [ ] Create version comparison UI showing diffs
- [ ] Build rollback functionality to restore from versions
- [ ] Add version resolution for dependencies
- [ ] Implement version conflict detection

### Client Library (Anvil SDK)
- [ ] Create Anvil.get/2 and Anvil.get!/2 functions
- [ ] Build address parser for "project/prompt_set@version" syntax
- [ ] Implement local caching with TTL
- [ ] Add PubSub for live updates
- [ ] Create mix tasks (anvil.init, anvil.pull, anvil.push)

### Bundle & Distribution System
- [ ] Design bundle format (thin packages + lock files)
- [ ] Implement export functionality for prompt sets
- [ ] Create import with validation and conflict resolution
- [ ] Build dependency resolver
- [ ] Add manifest generation

### Registry Service
- [ ] Create central registry for sharing prompts
- [ ] Implement publish workflow with validation
- [ ] Build search and discovery features
- [ ] Add versioned API for registry access
- [ ] Create organisation-scoped registries

### Deployment Modes
- [ ] Implement "live" mode with real-time updates
- [ ] Create "review" mode with approval workflow
- [ ] Build "locked" mode for production stability
- [ ] Add mode configuration per environment
- [ ] Create approval queue interface

### Embedded Mode Support
- [ ] Create mountable route module for /anvil
- [ ] Implement auth delegation to host app
- [ ] Build configuration API for host apps
- [ ] Add theme customisation support

### Advanced Features
- [ ] Analytics and usage tracking
- [ ] Performance metrics and monitoring
- [ ] Token usage and cost analysis
- [ ] A/B testing framework
- [ ] Telemetry integration
- [ ] Audit logging for all operations
- [ ] Search functionality across all resources

### Security & Performance
- [ ] API rate limiting
- [ ] Multi-tier caching strategy
- [ ] Horizontal scaling support
- [ ] Backup and recovery procedures
- [ ] Security audit and penetration testing

## Implementation Priority

1. **Version Management** - Critical for the "package manager" concept
2. **Client Library** - Essential for consuming prompts in applications
3. **Bundle System** - Enables distribution and sharing
4. **Registry Service** - Creates the ecosystem for prompt sharing
5. **Advanced Features** - Nice-to-have enhancements

## Technical Debt to Address

- [ ] Extract business logic from LiveViews to Ash actions
- [ ] Add comprehensive test coverage (see ST0006)
- [ ] Implement pagination on listing pages
- [ ] Improve error handling and user feedback
- [ ] Add database indexes for performance
- [ ] Document API endpoints and client usage
