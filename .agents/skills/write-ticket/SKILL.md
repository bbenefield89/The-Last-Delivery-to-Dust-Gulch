---
name: write-ticket
description: Dust Gulch wrapper for the shared `godot-kanban-write-ticket` workflow. Uses this repo's `kanban_tasks_data.kanban` board, exact `DG-<number>` title format, and project-scoped `planner` subagent expectations.
---

# Write Ticket

Follow the shared global skill at `C:\Users\bsqua\.codex\skills\godot-kanban-write-ticket\SKILL.md` as the base
workflow.

## Dust Gulch Overrides

- Board file: `kanban_tasks_data.kanban`
- Ticket titles must be exactly `DG-<number>`
- Valid categories are `Task`, `Bug`, and `TechDebt`
- Prefer `Done when:` language that a human can verify by playing the game normally
- Open work tickets in `Todo` or `Doing` must not be left without steps
- `$start-next-task` and `$merge-it` both block on step-less open tickets
- Use the project-scoped `planner` subagent and the detailed ticket-authoring guidance in `.codex/agents/planner.md`
