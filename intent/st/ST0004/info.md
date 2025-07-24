---
verblock: "24 Jul 2025:v1.0: matts - Defined peering objectives"
verblock: "24 Jul 2025:v2.0: matts - Refined to FORGE/LIVE architecture"
stp_version: 2.0.0
status: In Progress
created: 20250724
completed: 
---
# ST0004: Anvil Peering - FORGE and LIVE Instance Architecture

## Objective

Enable Context Engineers to update prompts in production applications without requiring code deployment, through a distributed architecture of FORGE (full Anvil instances) and LIVE (lightweight client) instances.

### Primary Goals

1. **FORGE Instances**: Full Anvil web applications where Context Engineers manage and edit prompts
2. **LIVE Instances**: Lightweight client libraries (`anvil_client`) embedded in production applications
3. **Controlled Distribution**: Push prompt updates from FORGE to LIVE instances with fine-grained control
4. **Zero-Downtime Updates**: Update prompts in production without application restart or deployment

## Context

The driving use case: A SaaS application with extensive LLM prompt usage needs to allow non-technical Context Engineers to iterate on prompts in production based on user feedback, without involving developers or deployment processes.

### Key Design Principles

- **Simplicity**: Context Engineers can publish updates with a single button click
- **Control**: Both FORGE (via status) and LIVE (via mode) control what gets distributed
- **Safety**: LOCKED prompt sets ensure production stability
- **Transparency**: Clear visual indicators of prompt set status and distribution state

### Architecture Overview

**FORGE Instance** (e.g., promptwithanvil.com):

- Full Anvil web application
- Context Engineers edit prompts through UI
- Prompt sets have status: LIVE (editing), REVIEW (approval needed), LOCKED (production-ready)
- Can peer with other FORGE instances for browsing/sharing
- Generates ACCESS_TOKENs for project distribution

**LIVE Instance** (embedded in production apps):

- Lightweight `anvil_client` hex package
- Connects to exactly one FORGE instance
- Two modes: ACCEPTING (receives updates) or FROZEN (no updates)
- Prompts accessed via simple API: `Anvil.prompt("welcome.message", vars)`
- Local caching means no runtime network calls

This transforms Anvil from a standalone system into a distributed prompt infrastructure, enabling real-time prompt optimization without deployment complexity.

## Expected Outcomes

1. **For Context Engineers**:
   - Browse and connect to remote FORGE instances through new "Forges" menu
   - Publish LOCKED prompt sets to production with one click
   - See clear status indicators for prompt set distribution state
   - Manage prompt updates without developer involvement

2. **For Developers**:
   - Simple setup: `mix anvil.install` and `mix anvil.connect`
   - Clean API: `Anvil.prompt("prompt.id", variables)`
   - Control over update acceptance (ACCEPTING/FROZEN modes)
   - No runtime network dependencies

3. **For Operations**:
   - Zero-downtime prompt updates
   - Version pinning for stability
   - Audit trail of all prompt distributions
   - Rollback through forward-versioning

## Related Steel Threads

- ST0001: Core Anvil functionality - Base system being extended
- ST0003: Organisations own projects - Project-level ACCESS_TOKENs
- Future: Anvil as LLM proxy - Token tracking, multi-LLM routing

## Implementation Approach

### Phase 0: FORGE UI & Context Engineer Experience

- Add "Forges" menu for peering UI
- Browse remote FORGE instances and projects
- Generate and manage ACCESS_TOKENs
- Test UX with actual Context Engineers

### Phase 1: Basic FORGE-to-LIVE Distribution

- Create `anvil_client` hex package
- Implement bundle format (PROMPT_SET_VERSION snapshots)
- Build push/receive infrastructure
- Local caching with ETS/DETS

### Phase 2: Developer Experience

- Igniter-based setup tasks
- Configuration management
- Admin UI for ACCEPTING/FROZEN toggle

### Phase 3: Advanced Features

- Full FORGE-to-FORGE peering
- Multi-environment management
- Advanced distribution strategies

## Technical Decisions

- **Bundle Format**: Single PROMPT_SET_VERSION snapshot as JSONB
- **Authentication**: Project-level ACCESS_TOKENs, manual distribution
- **Namespace**: Flat text IDs (e.g., "welcome.message") within snapshots
- **Versioning**: Pin to specific versions, roll forward only
- **Architecture**: 1:1 FORGE-LIVE relationships for simplicity

This design prioritises simplicity and control while laying groundwork for future expansion into a full LLM proxy platform.
