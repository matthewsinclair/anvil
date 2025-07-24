---
verblock: "24 Jul 2025:v0.1: matts - Initial version"
stp_version: 2.0.0
status: Completed
created: 20250724
completed: 20250724 
---
# ST0003: Organisations own projects

## Objective

Transform the project ownership model from individual user ownership to organisation-based ownership, enabling team collaboration and enterprise use cases while maintaining simplicity for individual users.

## Context

The initial implementation of Anvil had projects directly owned by users. This worked for MVP but limited collaboration capabilities. By introducing organisations as the primary ownership entity, we enable:

- Team collaboration on prompt management
- Role-based access control (owner, admin, member)
- Clear security boundaries for enterprise deployments
- Billing and resource limits per organisation
- Future multi-tenant capabilities

Every user automatically gets a personal organisation to maintain the simple individual user experience while using the same underlying data model.

## Related Steel Threads

- ST0001: Initial specification - Provides the core domain models that this builds upon
- ST0002: Basic Phoenix Web Shell Setup (Completed) - Provided the web foundation

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.