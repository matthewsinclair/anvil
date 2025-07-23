---
verblock: "23 Jul 2025:v0.1: matts - Initial version"
stp_version: 2.0.0
status: Completed
created: 20250723
completed: 20250723
---
# ST0002: Basic Phoenix Web Shell Setup

## Objective

Set up a basic Phoenix web application shell for Anvil with minimal, utilitarian styling using an "8-bit / 80s" theme. This provides the foundational UI structure including home page, authentication flow, header with user menu, and footer.

## Context

The Anvil project needs a clean, functional web interface to serve as the foundation for the prompt management system. Drawing inspiration from the Laksa project's simple structure, we'll create a minimal but complete Phoenix web shell that supports:

- Basic home page with branding
- User authentication flow (login/logout)
- Session-aware UI components
- Retro 8-bit aesthetic theme

## Related Steel Threads

- ST0001: Initial specification - Defines the overall Anvil system architecture

## Context for LLM

This steel thread focuses on basic housekeeping to get the Phoenix web app shell working. The implementation should:

1. Follow patterns from the Laksa project (simpler reference implementation)
2. Use Tailwind CSS with DaisyUI for styling
3. Implement an 8-bit/retro theme (think early terminal UIs)
4. Keep everything minimal and utilitarian
5. No dark mode needed - single theme only

The goal is to have a working web shell where users can visit the home page, log in, access authenticated areas, and log out.
