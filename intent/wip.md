---
verblock: "06 Mar 2025:v0.1: Matthew Sinclair - Initial version"
---
# Work In Progress

## TODO

⏺ Detailed Restart Prompt for ST0004 Implementation

  I'm working on Anvil, a prompt versioning and management system built with Phoenix/Elixir and Ash Framework. I need to
  implement ST0004, which adds distributed architecture with FORGE (full Anvil instances) and LIVE (lightweight client)
  capabilities.

## Context

- Project location: /Users/matts/Devel/prj/Anvil
- Current state: ST0001 (core functionality) is complete, ST0004 design is complete
- Tech stack: Elixir, Phoenix LiveView, Ash Framework, PostgreSQL

## ST0004 Overview

  The goal is to enable Context Engineers to update prompts in production without code deployment:

- FORGE instances: Full Anvil web apps where prompts are managed
- LIVE instances: Lightweight `anvil_client` package embedded in production apps
- Distribution: Push prompt updates from FORGE to LIVE with fine-grained control

## Key Design Decisions

  1. Bundle format: Single PROMPT_SET_VERSION snapshot as JSONB
  2. Authentication: Project-level ACCESS_TOKENs
  3. Status control: LOCKED prompt sets are production-ready
  4. Client modes: ACCEPTING (receives updates) or FROZEN (no updates)
  5. API: Simple `Anvil.prompt("prompt.id", variables)`

## Implementation Phases

  Please help me implement Phase 0, starting with:

  1. Add "Forges" menu to left navigation
  2. Create ForgesLive LiveView component
  3. Load forge configuration from config.exs
  4. Implement remote FORGE browsing with bearer token auth

  The complete design is in:

- intent/st/ST0004/info.md (objectives)
- intent/st/ST0004/design.md (technical design)
- intent/st/ST0004/tasks.md (implementation tasks)

  Please read these files first, then help me start implementing the Forges menu functionality.

  Process the above, read the relevant referenced documents and then wait for instructions. 

## Notes

[Any additional notes about the current work]

## Context for LLM

This document captures the current state of development on the project. When beginning work with an LLM assistant, start by sharing this document to provide context about what's currently being worked on.

### How to use this document

1. Update the "Current Focus" section with what you're currently working on
2. List active steel threads with their IDs and brief descriptions
3. Keep track of upcoming work items
4. Add any relevant notes that might be helpful for yourself or the LLM

When starting a new steel thread, describe it here first, then ask the LLM to create the appropriate steel thread document using the STP commands.
