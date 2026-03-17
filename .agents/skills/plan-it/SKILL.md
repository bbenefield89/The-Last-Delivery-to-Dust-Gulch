---
name: plan-it
description: Plan a feature or ticket collaboratively. Reads the GDD and affected code, talks through design options, drafts an ordered implementation plan for human approval, then writes the ticket once agreed. Does not implement anything — only plans and writes the ticket.
---

# Plan It

Follow this workflow when the user wants to plan a feature, ticket, or design decision.

## Workflow

1. Identify what needs to be planned:
   - If the user named a ticket, read that ticket from `kanban_tasks_data.kanban`.
   - If there is a `Doing` ticket, use that as the default context.
   - If neither, ask the user what they want to plan.
2. Read the relevant sections of `Docs/GDD.md` for the feature area.
3. Read the current code in the affected vertical slice(s) to understand existing patterns.
4. **Talk it out before writing anything.** Do not draft a full plan immediately.
   - Ask focused questions one or two at a time to understand intent, constraints, and preferences.
   - Surface design options and tradeoffs in plain language, not walls of text.
   - Get alignment on approach before committing to a plan structure.
   - Only move to drafting once the direction is agreed.
5. Draft an ordered implementation plan:
   - Each step should be scoped to one logical unit of work, small enough to review in isolation.
   - If the scope seems too large for a single ticket, flag it and propose splitting into multiple tickets instead of adding more steps.
   - Include test expectations for each meaningful step.
   - Flag any scope concerns or design document conflicts before the plan is approved.
6. Present the plan for human review.
7. Once the user agrees with the plan, write the ticket immediately using `$write-ticket` without waiting for an explicit instruction to do so.

## Constraints

- Do not write implementation code.
- Do not implement anything — only plan and write the ticket.
- If the feature conflicts with the scope guardrails in `AGENTS.md`, call it out before drafting the plan.
- Keep plans focused and sized for the vertical slice. Avoid overbuilding.

## Required Outcome

- A concrete, ordered implementation plan is agreed with the user before any ticket is written.
- The ticket is written immediately after agreement without a separate prompt.
- No implementation code is produced.
- Scope conflicts are flagged before the plan is approved.
