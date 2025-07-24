---
verblock: "06 Mar 2025:v0.1: Matthew Sinclair - Initial version"
---
# Work In Progress

## TODO

Anvil is a prompt management system built with Elixir/Phoenix for managing LLM prompts. It uses Ash Framework for domain modeling, Phoenix LiveView for the UI, and Liquid templates (via Solid gem) for prompt templating.

## Current Status

The MVP is complete with core functionality working. The system allows users to create projects, prompt sets, and prompts with dynamic parameters. Version management has been implemented with a read-only view and delete functionality.

## Tech Stack

- **Backend**: Elixir with Ash Framework 3.0
- **Frontend**: Phoenix LiveView with retro-themed UI
- **Database**: PostgreSQL with custom jsonb array types
- **Auth**: phx_gen_auth with Ash integration
- **Templates**: Liquid via Solid gem

## Key Files and Their Purpose

### Domain Layer

- `/lib/anvil/projects.ex` - Projects domain with Project resource
- `/lib/anvil/prompts.ex` - Prompts domain with PromptSet, Prompt, Version resources
- `/lib/anvil/prompts/prompt.ex` - Core Prompt resource with parameter management
- `/lib/anvil/types/parameter_list.ex` - Custom type for parameter storage

### LiveView Layer

- `/lib/anvil_web/live/prompt_set_live/show.ex` - Prompt set detail with inline version creation
- `/lib/anvil_web/live/prompt_live/edit.ex` - Prompt editor with template validation
- `/lib/anvil_web/live/version_live/show.ex` - Read-only version view with expandable prompts

### Template System

- `/lib/anvil/template/analyzer.ex` - Parses Liquid templates and validates parameters

## Recent Work Completed

### 1. Fixed Required Checkbox

- Issue: HTML checkboxes send "on" but code expected "true"
- Fix: Check for both values in transform_parameters/1

### 2. Template Validation Feature

- Added Validate button to prompt editor
- Extracts {{variables}} from templates
- Shows missing/unused/matched parameters
- Auto-populate parameters from template

### 3. Version Management

- Created Version resource with snapshot storage
- Inline version creation form (replaced modal)
- Read-only version view with expandable prompts
- Delete functionality with confirmation
- Sorted versions by most recent first

### 4. Critical Bug Fixes

- PostgreSQL array type mismatch (jsonb[] vs text[])
- Ash generic action issues (switched to normal create)
- Filter syntax (use query: [filter: ...])

## Known Issues and Pending Work

### Immediate Tasks

1. Version comparison UI - Show diff between versions
2. Rollback functionality - Restore prompt set from version
3. Search implementation - Basic name search at minimum
4. Client library - Anvil.get/2 for consuming prompts

### Technical Debt

1. No test coverage yet
2. No pagination on listing pages
3. Error handling needs improvement
4. Performance optimization needed

### Future Features

1. Bundle export/import for distribution
2. Registry service for sharing
3. Embedded mode for mounting in existing apps
4. Analytics and A/B testing
5. Advanced approval workflows

## Common Commands

```bash
# Start development
iex -S mix phx.server

# Run migrations
mix ash.codegen
mix ecto.migrate

# Seed database
mix run priv/repo/seeds.exs

# Compile and format
mix compile && mix format
```

## Important Context

1. Always use `query: [filter: ...]` not `filter:` directly with Ash
2. HTML checkboxes send "on" when checked, not "true"
3. Use normal CRUD actions, not generic actions unless necessary
4. The unit of versioning is the prompt set, not individual prompts
5. Template variables use {{name}} syntax (Liquid)

## User Preferences

- No modals - use inline forms instead
- Retro ASCII theme with monospace fonts
- British English spelling
- No Claude comments in git commits
- Functional Elixir style (with, pattern matching, pipes)

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
