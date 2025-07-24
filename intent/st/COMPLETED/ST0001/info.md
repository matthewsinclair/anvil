---
verblock: "23 Jul 2025:v0.1: matts - Initial version"
stp_version: 2.0.0
status: Completed
created: 20250723
completed: 20250724
---
# ST0001: Initial specification

## Objective

Build a prompt versioning and management system that allows Context Engineers to externalise, version, and dynamically update LLM prompts without requiring application redeployment. The system will support parameterised prompts with instrumentation, dependency management between prompt sets, and multiple deployment modes for different security requirements.

## Context

Modern LLM-powered applications embed prompts directly in code, making iteration slow and risky. Anvil addresses this by treating prompts as first-class versioned artifacts that can be:

- Edited and tested in production context by Context Engineers
- Versioned using semantic versioning with prompt-specific metadata
- Organised into reusable prompt sets with dependency management
- Distributed as thin bundles with lock files for reproducible deployments
- Updated dynamically or through controlled deployment processes

The system draws inspiration from package managers (mix/hex) rather than source control (git), focusing on distribution and dependency resolution rather than collaborative editing.

## Related Steel Threads

- ST0002: Basic Phoenix Web Shell Setup (Completed) - Provides the web application foundation

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
