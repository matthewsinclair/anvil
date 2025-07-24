---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 2. Requirements

## Functional Requirements

### Prompt Management

#### FR-PM-001: Prompt Creation

- Users shall be able to create prompts with Liquid template syntax
- System shall validate template syntax on save
- Users shall define parameters with types (string, number, boolean)
- System shall auto-extract variables from templates

#### FR-PM-002: Prompt Organisation

- Prompts shall be organised into Prompt Sets
- Prompt Sets shall belong to Projects
- Projects shall be owned by Organisations
- Users shall navigate hierarchy via breadcrumbs

#### FR-PM-003: Version Control

- System shall track all changes to prompts
- Users shall create immutable versions
- System shall support version comparison
- Users shall rollback to previous versions

#### FR-PM-004: Template Processing

- System shall support Liquid template syntax
- Variables shall use double curly braces: `{{ variable }}`
- System shall validate parameter completeness
- Templates shall support conditionals and loops

### User Management

#### FR-UM-001: Authentication

- Users shall authenticate via email/password
- System shall support magic link authentication
- API access shall use API keys
- Sessions shall expire after inactivity

#### FR-UM-002: Authorisation

- System shall implement role-based access control
- Roles shall include: Owner, Admin, Member
- Permissions shall cascade through organisation hierarchy
- Personal organisations shall have special protections

#### FR-UM-003: Organisation Management

- Users shall create and manage organisations
- Every user shall have a personal organisation
- Users shall invite others via email
- Owners shall manage member roles

### API Requirements

#### FR-API-001: REST Interface

- System shall provide RESTful API
- API shall support CRUD operations
- Responses shall use JSON format
- API shall implement pagination

#### FR-API-002: SDK Operations

- SDK shall fetch prompts by address
- Address format: `project/prompt_set@version`
- SDK shall cache responses locally
- SDK shall support live updates via PubSub

### Distribution

#### FR-DIST-001: Export/Import

- Users shall export prompt sets as bundles
- System shall validate imports
- Imports shall handle version conflicts
- Bundles shall include dependencies

#### FR-DIST-002: Registry (Future)

- System shall support central registry
- Users shall publish public prompts
- System shall implement search/discovery
- Registry shall enforce namespacing

## Non-Functional Requirements

### Performance

#### NFR-PERF-001: Response Times

- Web pages shall load within 2 seconds
- API responses shall return within 500ms
- Template rendering shall complete within 100ms
- Search results shall return within 1 second

#### NFR-PERF-002: Scalability

- System shall support 10,000 concurrent users
- Database shall handle 1M+ prompts
- System shall scale horizontally
- Cache shall reduce database load by 80%

### Security

#### NFR-SEC-001: Data Protection

- All data shall be encrypted at rest
- HTTPS shall be enforced for all connections
- Passwords shall use bcrypt hashing
- API keys shall have limited scope

#### NFR-SEC-002: Access Control

- Authorisation checks at every layer
- No data leakage between organisations
- Audit logs for all modifications
- Rate limiting on all endpoints

### Reliability

#### NFR-REL-001: Availability

- System shall maintain 99.9% uptime
- Planned maintenance windows allowed
- Graceful degradation under load
- Automatic failover capabilities

#### NFR-REL-002: Data Integrity

- No data loss during operations
- Transactional consistency guaranteed
- Regular automated backups
- Point-in-time recovery capability

### Usability

#### NFR-USE-001: User Interface

- Consistent design language
- Mobile-responsive layouts
- Keyboard navigation support
- Clear error messages

#### NFR-USE-002: Developer Experience

- Comprehensive API documentation
- SDK examples and tutorials
- Clear upgrade paths
- Helpful error responses

### Maintainability

#### NFR-MAIN-001: Code Quality

- 80% test coverage minimum
- Documented architecture decisions
- Consistent coding standards
- Regular dependency updates

#### NFR-MAIN-002: Operations

- Centralised logging
- Performance monitoring
- Alerting for anomalies
- Deployment automation

## Constraints

### Technical Constraints

- Must use Elixir/Phoenix framework
- Must use PostgreSQL database
- Must support Liquid templating
- Must integrate with existing auth systems

### Business Constraints

- Initial release within 6 months
- Must support existing prompt formats
- Zero downtime migrations required
- Open source compatible licensing

## Assumptions

- Users have basic understanding of templates
- Organisations have clear ownership boundaries
- LLM providers handle prompt execution
- Network connectivity is reliable
- Modern browsers are used (Chrome, Firefox, Safari, Edge)
