---
name: write-ticket
description: Repo-local wrapper around the shared `godot-write-ticket` workflow.
---

# Write Ticket

Follow the shared `godot-write-ticket` skill as the base workflow.

## Repo Overrides

- Ticket system: Jira
- Jira site: `brandork.atlassian.net`
- Jira cloud id: `39915fce-c9fe-4c9a-8d4d-60399e5d245f`
- Jira project key: `DG`
- Jira board id: `1`
- Jira parent issue types: `Story`, `Feature`, `Bug`
- Jira step issue type: `Subtask`
- Jira workflow statuses:
  `To Do` -> `In Progress` -> `Done`
- Ticket titles must begin with `DG-<number>`
- Valid categories: `Task`, `TechDebt`, `Bug`
- Use the repo-local `planner` guidance under `.codex/agents/planner.md`
- Every open Jira parent issue in `To Do` or `In Progress` must have subtasks for its ordered steps
