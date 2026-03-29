---
name: write-ticket
description: Repo-local wrapper around the shared `godot-write-ticket` workflow.
---

# Write Ticket

Follow the shared `godot-write-ticket` skill as the base workflow.

## Repo Overrides

- Board file: kanban_tasks_data.kanban

- Ticket titles must begin with `DG-<number>`
- Valid categories: `Task`, `TechDebt`, `Bug`
- Use the repo-local `planner` guidance under `.codex/agents/planner.md`
- Keep all open work tickets in `Todo` or `Doing` from being step-less
