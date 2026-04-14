---
name: start-next-task
description: Repo-local wrapper around the shared `godot-start-next-task` workflow.
---

# Start Next Task

Follow the shared `godot-start-next-task` skill as the base workflow.

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
- Ticket key format: `DG-<number>`
- Base branch for starting new tickets: main
- The current branch must match the single active Jira parent issue key when one exists
- Use the repo-local `implementor`, `code-reviewer`, and `architecture-reviewer` under `.codex/agents/`
