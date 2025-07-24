---
verblock: "06 Mar 2025:v0.1: Matthew Sinclair - Initial version"
---
# Work In Progress

## TODO

{{TODO}}

╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ > Ok, we need to take stock now and do the following hygiene steel threads before we go any further:                           │
│                                                                                                                                │
│   1. We need to update all of the docs for steel threads 1 and 3. These are not complete, but they have both had a lot of      │
│   work done on them and they need to be brought up to as-bullt status. There is a dedicated steel thread for this              │
│   documentation update: ST0005.                                                                                                │
│                                                                                                                                │
│   2. As part of #1, we need to update the Technical Product Design document. The TPD here is just a template. The model for    │
│   this document is here: ../MeetZaya/intent/eng/tpd?**/*. In particular, note the multi-file structure with linked markdown    │
│   files. Also for ST0005.                                                                                                      │
│                                                                                                                                │
│   3. We have written a lot of code with zero tests. We need to write comprehensive tests for both lib/anvil anmd               │
│   lib/anvil_web. We should use ../MeetZaya/test/** as a guide for the right way to test things here. We need to be             │
│   espescially conscious of tests for the Ash Resources. I am worried that we have put business logic into the Live Views that  │
│   really should be behind a code interface in an Ash Resource. As we write the tests, we should be on the lookout for that.    │
│   I have created a new steel thread for this work: ST0006.                                                                     │
│                                                                                                                                │
│   4. ST0004 is about "Anvil Peering". This is also a big piece of work that is in two parts. The first part is import/export   │
│   of Project from one Anvil instance to another. And the second part is the ability to "push" a config form an Anvil           │
│   management instance (like a running instance of this project) into a "client user app" of Anvil which just has the           │
│   client-side shim that allows Anvil configs to be injected into it.                                                           │
│                                                                                                                                │
│   Please reflect on these 4 points.                                                                                            │
│                                                                                                                                │
│   THIS IS SOLELY A DOCUMENTATION TASK. DO NOT WRITE OR CHANGE THE CODE AT ALL.                                                 │
│                                                                                                                                │
│   There are two phases of work here:                                                                                           │
│                                                                                                                                │
│   Phase 1: Update the relevant steel threads (ST000{1,3}) with the current as-built state of THIS project.                     │
│   Phase 2: Update the other steel threads (ST000{4,5,6}) with the plan for the new work.                                       │
│                                                                                                                                │
│   Please process this, review the state of the system, and then show me a detailed to get this work done, then wait for        │
│   instructions.                                                                                                                │
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

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
