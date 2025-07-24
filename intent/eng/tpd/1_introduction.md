---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 1. Introduction

## Project Overview

Anvil is a prompt management system designed to bring software engineering discipline to the management of Large Language Model (LLM) prompts. As organisations increasingly rely on LLMs for critical business functions, the need for systematic prompt management has become paramount.

## The Problem

Current approaches to LLM prompt management suffer from several critical issues:

1. **Version Control**: Prompts are often hardcoded in applications or stored in configuration files without proper versioning
2. **Collaboration**: Teams struggle to share and collaborate on prompt development
3. **Testing**: No standardised approach to testing prompt effectiveness
4. **Distribution**: No mechanism for sharing prompts across projects or organisations
5. **Governance**: Lack of access control and audit trails for prompt changes

## The Solution

Anvil addresses these challenges by providing:

- **Centralised Management**: A single source of truth for all organisational prompts
- **Version Control**: Git-like versioning for prompts with rollback capabilities
- **Collaboration Tools**: Team-based development with role-based access control
- **Distribution System**: Package manager approach for sharing and consuming prompts
- **Template System**: Liquid-based templating for dynamic prompt generation

## Core Concepts

### Projects

Top-level containers that group related prompt sets, similar to repositories in version control systems.

### Prompt Sets

Collections of related prompts that work together, analogous to packages or modules.

### Prompts

Individual LLM prompts with:

- Liquid template syntax for variable substitution
- Parameter definitions with types and validation
- Version tracking

### Organisations

Multi-tenant containers that own projects and manage team access.

## Target Users

1. **AI Engineers**: Primary users who create and maintain prompts
2. **Software Developers**: Consumers of prompts through the Anvil SDK
3. **Team Leads**: Managers who oversee prompt quality and access
4. **DevOps Teams**: Administrators who deploy and maintain Anvil

## Success Metrics

- Reduction in prompt-related production incidents
- Increased prompt reuse across projects
- Faster prompt iteration cycles
- Improved collaboration between AI and engineering teams
- Standardised prompt management practices

## Scope

### In Scope

- Web-based prompt management interface
- REST API for programmatic access
- SDK for consuming prompts in applications
- Basic version control and rollback
- Organisation-based multi-tenancy
- Role-based access control

### Out of Scope

- LLM execution or hosting
- Prompt effectiveness analytics
- Automated prompt optimisation
- Integration with specific LLM providers
- Real-time collaborative editing
