---
name: start-next-task
description: Repo-local wrapper around the shared `godot-start-next-task` workflow.
---

# Start Next Task

Follow the shared `godot-start-next-task` skill as the base workflow.

## Repo Overrides

- Board file: kanban_tasks_data.kanban

- Ticket key format: `DG-<number>`
- Base branch for starting new tickets: main
- The current branch must match the active `Doing` ticket key when one exists
- Use the repo-local `implementor`, `code-reviewer`, and `architecture-reviewer` under `.codex/agents/`
