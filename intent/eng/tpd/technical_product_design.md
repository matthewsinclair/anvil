---
verblock: "2025-07-24:v1.0: matts - Restructured as multi-file TPD"
---
# Anvil Technical Product Design

Version: 1.0.0  
Status: In Progress  
Last Updated: 2025-07-24

## Overview

This document provides the comprehensive technical design for Anvil, a prompt management system for Large Language Models (LLMs). Anvil serves as a "package manager for prompts," enabling teams to manage, version, and distribute LLM prompts with the same rigour as software dependencies.

## Document Structure

This Technical Product Design is organised into the following sections:

1. [Introduction](./1_introduction.md) - Project overview and objectives
2. [Requirements](./2_requirements.md) - Functional and non-functional requirements
3. [Architecture](./3_architecture.md) - System architecture and design decisions
4. [Data Model](./4_data_model.md) - Database schema and domain models
5. [API Design](./5_api_design.md) - REST API and SDK specifications
6. [User Interface](./6_user_interface.md) - Web application design
7. [Security](./7_security.md) - Authentication, authorization, and data protection
8. [Deployment](./8_deployment.md) - Deployment strategies and operations
9. [Testing](./9_testing.md) - Testing strategy and quality assurance
10. [Future Considerations](./10_future_considerations.md) - Roadmap and extensibility

## Quick Links

- [Steel Threads](../../st/) - Implementation work packages
- [LLM Guidelines](../../llm/) - AI assistant instructions
- [Project Structure](../../../README.md) - Repository overview

## Status

This document reflects the as-built state of Anvil as of July 2025. Key implemented features include:

- Multi-tenant architecture with organisation support
- Prompt management with Liquid templating
- Basic versioning (without semantic versioning)
- Role-based access control
- Web-based management interface

## Contributing

When updating this document:

1. Update individual chapter files
2. Increment the version number in this index
3. Update the Last Updated date
4. Ensure consistency across chapters
5. Update the verblock in individual files
