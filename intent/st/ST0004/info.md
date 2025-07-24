---
verblock: "24 Jul 2025:v1.0: matts - Defined peering objectives"
stp_version: 2.0.0
status: In Progress
created: 20250724
completed: 
---
# ST0004: Anvil Peering - Import/Export and Configuration Push

## Objective

Implement peering capabilities for Anvil that enable two critical workflows:

1. **Import/Export**: Transfer projects, prompt sets, and configurations between Anvil instances
2. **Configuration Push**: Deploy prompt configurations from a management instance to lightweight client applications

This functionality transforms Anvil from a standalone prompt management system into a distributed prompt infrastructure platform.

## Context

As organisations adopt Anvil for prompt management, they need capabilities beyond single-instance usage:

### Import/Export Use Cases

- **Development to Production**: Move prompts from dev/staging to production environments
- **Cross-team Collaboration**: Share prompt sets between different teams or departments
- **Backup and Recovery**: Export projects for backup or migration purposes
- **Template Sharing**: Distribute reusable prompt templates across organisations

### Configuration Push Use Cases

- **Edge Deployment**: Push prompts to client applications without full Anvil installation
- **Lightweight Clients**: Embedded Anvil runtime that only consumes prompts
- **Real-time Updates**: Push configuration changes to running applications
- **Multi-environment Management**: Manage dev/staging/prod from a central instance

This steel thread establishes the foundation for Anvil as a distributed prompt management platform, enabling enterprise-scale deployments and ecosystem growth.

## Related Steel Threads

- ST0001: Anvil prompt management system - Core functionality being distributed
- ST0003: Organisations own projects - Multi-tenancy considerations for peering
- ST0005: Documentation update - Bundle format documented in TPD
- Future: Registry service will build on import/export capabilities

## Context for LLM

This steel thread implements two major features:

### 1. Import/Export System

- Bundle format for packaging projects with dependencies
- Conflict resolution for imports
- Version compatibility checking
- Selective export (project, prompt set, or individual prompts)

### 2. Configuration Push

- Lightweight Anvil runtime for client apps
- Push protocol (HTTP/WebSocket)
- Authentication between instances
- Configuration versioning and rollback

Key technical considerations:

- Bundle format should be self-contained but not bloated
- Must handle version conflicts gracefully
- Security is critical for inter-instance communication
- Client runtime should have minimal dependencies

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
