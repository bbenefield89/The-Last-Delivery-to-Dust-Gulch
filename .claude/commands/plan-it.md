Enter Plan Mode to draft an implementation plan for the current feature or ticket. This plan is for Codex to execute — do not begin any implementation yourself.

## Workflow

1. Identify what needs to be planned:
   - If the user named a ticket, read that ticket from `kanban_tasks_data.kanban`.
   - If there is a `Doing` ticket, use that as the default context.
   - If neither, ask the user what they want to plan.
2. Read the relevant sections of the design document for the feature area.
3. Read the current code in the affected vertical slice(s) to understand existing patterns.
4. Enter Plan Mode.
5. Draft an ordered implementation plan:
   - Each step should be scoped to one logical unit of work, small enough to review in isolation.
   - If the scope seems too large for a single ticket, flag it and propose splitting into multiple tickets instead of adding more steps.
   - Include test expectations for each meaningful step.
   - Flag any scope concerns or design document conflicts before the plan is approved.
6. Present the plan for human review.
7. Once the user agrees with the plan, write the ticket immediately without waiting for an explicit instruction to do so.

## Constraints

- Do not write implementation code.
- Do not implement anything — only plan.
- If the feature conflicts with scope from `CLAUDE.md`, call it out before drafting the plan.
- Keep plans focused and sized for the vertical slice. Avoid overbuilding.
