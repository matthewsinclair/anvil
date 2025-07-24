---
verblock: "24 Jul 2025:v1.0: matts - Defined testing objectives"
stp_version: 2.0.0
status: In Progress
created: 20250724
completed: 
---
# ST0006: Testing Core Functionality

## Objective

Implement comprehensive testing infrastructure for Anvil, covering unit tests for Ash resources, integration tests for LiveView flows, and API tests for REST endpoints. The testing framework should ensure data integrity, policy enforcement, and proper user experience across all features.

## Context

Anvil currently has minimal test coverage, with only basic controller tests from the Phoenix generator. As the application has grown to include complex features like multi-tenancy, role-based access control, and template validation, comprehensive testing is critical for:

- Preventing regressions during development
- Ensuring data isolation between organisations
- Validating policy enforcement
- Documenting expected behaviour
- Enabling confident refactoring
- Supporting continuous deployment

This steel thread will establish testing patterns based on MeetZaya's proven approach, adapted for Anvil's specific architecture using Ash Framework and Phoenix LiveView.

## Related Steel Threads

- ST0001: Anvil prompt management system - Core functionality to be tested
- ST0003: Organisations own projects - Multi-tenancy features requiring isolation testing
- ST0005: Documentation update - Test strategy documented in TPD Chapter 9

## Context for LLM

This steel thread focuses on creating a comprehensive testing framework. Key considerations:

1. **Testing Stack**: ExUnit + PhoenixTest + Ash.Generator
2. **Test Types**: Unit (70%), Integration (25%), E2E (5%)
3. **Key Areas**: Authentication, authorisation, data isolation, CRUD operations
4. **Patterns**: Follow MeetZaya's structure with DataCase, FeatureCase, and Generators

### Implementation Priorities

1. Set up testing infrastructure (cases, helpers, generators)
2. Create unit tests for Ash resources
3. Implement integration tests for critical user flows
4. Add API tests for the prompt retrieval endpoint
5. Establish CI/CD integration

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.