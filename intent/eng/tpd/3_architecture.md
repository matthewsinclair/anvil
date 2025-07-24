---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 3. Architecture

## System Overview

Anvil follows a modern web application architecture built on the Elixir/Phoenix stack, leveraging the BEAM VM's strengths for concurrent, fault-tolerant systems.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Web Browser   │     │   Anvil SDK     │     │   REST Client   │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┴───────────────────────┘
                                 │
                        ┌────────▼────────┐
                        │  Load Balancer  │
                        └────────┬────────┘
                                 │
                 ┌───────────────┴──────────────┐
                 │                              │
         ┌───────▼────────┐             ┌───────▼────────┐
         │  Phoenix App   │             │  Phoenix App   │
         │   Instance 1   │             │   Instance N   │
         └───────┬────────┘             └───────┬────────┘
                 │                              │
                 └───────────────┬──────────────┘
                                 │
                        ┌────────▼────────┐
                        │   PostgreSQL    │
                        │    Database     │
                        └─────────────────┘
```

## Architectural Patterns

### Domain-Driven Design

Anvil uses Ash Framework to implement domain-driven design with clear bounded contexts:

- **Accounts Domain**: User management and authentication
- **Organisations Domain**: Multi-tenancy and team management
- **Projects Domain**: Project containers and metadata
- **Prompts Domain**: Core prompt management functionality

### CQRS Pattern

Command Query Responsibility Segregation implemented through:

- Ash Actions for commands (create, update, delete)
- Ash Queries for read operations
- Clear separation of write and read models

### Event Sourcing (Future)

While not fully implemented, the version system lays groundwork for event sourcing:

- Immutable version records
- Change tracking
- Potential for event replay

## Technology Stack

### Core Technologies

#### Elixir/Phoenix

- **Version**: Elixir 1.15+, Phoenix 1.7+
- **Rationale**: Excellent concurrency, fault tolerance, and real-time features
- **Usage**: Application server, business logic, API endpoints

#### Ash Framework 3.5

- **Purpose**: Domain modeling and business logic
- **Benefits**: Declarative resources, built-in policies, action framework
- **Integration**: Deep integration with Phoenix and Ecto

#### PostgreSQL

- **Version**: 14+
- **Features Used**: JSONB, UUID, full-text search
- **Rationale**: Robust, feature-rich, excellent JSON support

#### Phoenix LiveView

- **Purpose**: Interactive UI without JavaScript framework
- **Benefits**: Server-side rendering, real-time updates, simplified stack
- **Usage**: All web UI components

### Supporting Technologies

#### Solid (Liquid Template Engine)

- **Language**: Ruby (via Elixir port)
- **Purpose**: Template parsing and rendering
- **Integration**: Called from Elixir for template validation

#### Tailwind CSS + DaisyUI

- **Purpose**: Styling and UI components
- **Theme**: Retro/cyberpunk aesthetic
- **Benefits**: Rapid development, consistent design

## System Components

### Web Layer

#### Phoenix Router

- RESTful routes for web interface
- API routes under `/api/v1`
- LiveView routes for interactive pages
- Authentication pipelines

#### LiveView Controllers

- Project management (CRUD)
- Prompt set operations
- Organisation administration
- Real-time validation

#### Authentication

- Session-based for web
- API key for programmatic access
- Magic links for passwordless login
- phx_gen_auth integration

### Business Logic Layer

#### Ash Resources

- Declarative domain models
- Built-in validations
- Policy-based authorisation
- Action handlers for complex operations

#### Ash Policies

- Row-level security
- Organisation isolation
- Role-based permissions
- Automatic enforcement

#### Custom Actions

- User invitation flow
- Template validation
- Version creation
- Bundle export/import

### Data Layer

#### Ecto/AshPostgres

- Database abstraction
- Migration management
- Query composition
- Connection pooling

#### Custom Types

- ParameterList for JSONB arrays
- Proper casting between forms and database
- Type safety

### Integration Layer

#### Template Engine

- Liquid syntax parsing
- Variable extraction
- Syntax validation
- Rendering pipeline

#### Future: PubSub

- Phoenix.PubSub for real-time updates
- WebSocket connections
- Live prompt updates
- Collaboration features

## Deployment Architecture

### Container Strategy

- Docker containers for applications
- Kubernetes orchestration (future)
- Health checks and readiness probes
- Rolling deployments

### Database Architecture

- Primary-replica setup
- Connection pooling
- Automated backups
- Point-in-time recovery

### Caching Strategy

- ETS for in-memory caching
- Redis for distributed cache (future)
- CDN for static assets
- API response caching

## Security Architecture

### Defence in Depth

1. **Network Layer**: HTTPS only, firewall rules
2. **Application Layer**: Input validation, CSRF protection
3. **Business Layer**: Ash policies, role checks
4. **Data Layer**: Encryption at rest, secure connections

### Authentication Flow

```
User Login → Password/Magic Link → Session Creation → Organisation Context → Authorised Requests
```

### Authorisation Model

- Policy-based (Ash.Policy)
- Organisation isolation
- Role inheritance
- Audit logging

## Performance Architecture

### Optimisation Strategies

- Database indexing on foreign keys
- N+1 query prevention
- Lazy loading where appropriate
- Connection pooling

### Scaling Approach

- Horizontal scaling of app servers
- Read replicas for database
- Load balancer distribution
- Stateless application design

## Error Handling

### Application Errors

- Consistent error format
- User-friendly messages
- Developer-friendly details
- Proper HTTP status codes

### System Errors

- Supervisor trees for fault tolerance
- Automatic process restart
- Circuit breakers for external services
- Graceful degradation

## Monitoring and Observability

### Logging

- Structured JSON logs
- Request ID tracking
- Error aggregation
- Security event logging

### Metrics

- Response time tracking
- Error rate monitoring
- Resource utilisation
- Business metrics

### Tracing (Future)

- Distributed tracing
- Request flow visualisation
- Performance bottleneck identification
- OpenTelemetry integration
