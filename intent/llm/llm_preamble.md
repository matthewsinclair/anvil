---
verblock: "23 Jul 2025:v0.1: Matthew Sinclair - Initial version"
---
# LLM Preamble

This document provides essential context for LLMs working on the anvil project. Share this document at the beginning of each LLM session to establish baseline understanding.

## Project Context

anvil follows the Steel Thread Project (STP) methodology, which organizes development into discrete "steel threads" - self-contained units of functionality that enable incremental progress with clear documentation.

## Navigation Guide

When working with this repository, you should focus on these key documents in this specific order:

1. **START HERE**: `intent/eng/tpd/technical_product_design.md` - Contains comprehensive information about the project vision, architecture, and current state.

2. **NEXT**: `intent/st/steel_threads.md` - Provides a complete index of all steel threads with their status. Review this to understand what work has been completed and what remains.

3. **THEN**: `intent/wip.md` - Details the current work in progress and priorities. This is your guide to what should be worked on now.

## Documentation Structure

The STP methodology organizes project information through a specific directory structure:

- **intent/prj/**: Project management documents
  - **intent/wip.md**: Current work in progress
  - **intent/prj/journal.md**: Historical record of project activities
  - **intent/st/**: Steel thread documents and index
- **intent/eng/**: Engineering documentation
  - **intent/eng/tpd/**: Technical Product Design documents
- **intent/usr/**: User documentation
  - **intent/usr/user_guide.md**: End-user instructions
  - **intent/usr/reference_guide.md**: Complete feature reference∏
  - **intent/usr/deployment_guide.md**: Deployment instructions
- **intent/llm/**: LLM-specific content
  - **intent/llm/llm_preamble.md**: This document

## Steel Thread Process

Work in this project is organized through steel threads:

1. **Definition**: A steel thread is a self-contained unit of work that represents a logical piece of functionality
2. **Workflow**:
   - Steel threads start as "Not Started"
   - When work begins, they move to "In Progress"
   - When completed, they are marked as "Completed"
   - They can also be "On Hold" or "Cancelled" as needed
3. **Documentation**: Each steel thread has its own markdown document in `intent/st/`
4. **Management**: Steel threads are created, tracked, and completed using STP commands

## Code Style and Conventions

The following code style guidelines apply to this project:

- **Indentation**: Use 2-space indentation in all programming languages
- **Documentation**: Add clear documentation for all code components
- **Naming**: Use descriptive variable and function names
- **Error Handling**: Implement robust error handling according to language best practices
- **Testing**: Include appropriate tests for all new functionality
- **Markdown**: Maintain consistent formatting in all markdown documents

[Add specific code style guidelines for the project's primary programming languages]

## Command Usage

The STP system provides these commands for project management:

- `intent init <project_name> [directory]`: Initialize STP in a project
- `intent st new <title>`: Create a new steel thread
- `intent st done <id>`: Mark a steel thread as complete
- `intent st list [--status <status>]`: List all steel threads
- `intent st show <id>`: Display details of a specific steel thread
- `intent st edit <id>`: Open a steel thread in your default editor
- `intent help [command]`: Display help information

## How to Help

When assisting with this project, you should:

1. First, understand the current context by reviewing the documents in the order specified
2. Focus on the work in progress as defined in `intent/wip.md`
3. Maintain consistency with existing patterns and documentation standards
4. Update documentation alongside code changes
5. Use the steel thread model to organize new work
6. Summarize completed work in the journal document

### Elixir Code Style Guide

**Error Handling**

- Use `with` expressions and Railway-Oriented Programming for clean error handling
- Return consistent tuples: `{:ok, result}` or `{:error, reason_type, reason}`

**Function Design**

- Write small, focused functions with single responsibilities
- Make functions pipeline-friendly (data parameter as final argument)
- Use `with_x` naming convention for context-passing functions
- Include `@spec` annotations for all public functions
- Define custom type aliases for common structures
- Create pure functions without side effects

**Functional Programming**

- Use pipe operator (`|>`) for data transformations
- Leverage Enum functions directly instead of manual accumulators
- Avoid unnecessary list reversals
- Write concise code embracing functional principles

**Control Flow**

- Favour pattern matching with multiple function heads over conditionals
- Use guard clauses for type-based decisions
- Apply pattern matching for data destructuring
- Prefer `case`/`with` expressions over imperative if/then/else

**Formatting**

- Use two spaces for indentation in all code

**Philosophy**

- Write clean, idiomatic Elixir without backwards compatibility compromises
- Prioritise pure functional implementations

**Testing**

- Always write tests that test _behaviour_ not implementation details
- Always change tests to meet the state of the framework
- Never _ever_ hardcode numbers into a test or framework code to make it work

### Elixir Testing Style Guide

- ALWAYS WRITE TESTS TO TEST THE APP/FRAMEWORK's BEHAVIOUR
- NEVER WRITE TESTS THAT TEST THE APP/FRAMEWORK's IMPLEMENTATION
- NEVER HACK FRAMEWORK OR APP CODE TO MAKE A TEST WORK
- NEVER HARDOCDE VARIABLES IN FRAMEWORK OR APP CODE TO SATISFY A TEST
- FAVOUR RE-WRITING A TEST TO MEET NEW APP/FRAMEWORK CAPABILITIES
- DO NOT WRITE UNNCESSARY MOCKS, WRITE TESTS THAT TEST THE APP/FRAMEWORK's ACTUAL CODE
- DO NOT WRITE BACKWARDS COMPATIBLE CODE OR TESTS
- ALWAYS WRITE CLEAN, CONCISE, PURE-FUNCTIONAL IDIOMATIC ELIXIR CODE AND FIX FORWARD

## LLM Instructions For

- [AGENTS / usage-rules](./AGENTS.md)
