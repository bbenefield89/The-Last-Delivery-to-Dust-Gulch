---
name: start-next-task
description: Start or resume the repository's next ticket workflow only when invoked as `$start-next-task <ticket-number>`. Check `Doing` first. If one ticket is already in `Doing` and it has unfinished steps, work only the first unfinished step in order. If `$start-next-task` is invoked again while that stepped ticket remains in `Doing`, treat that as approval to mark the current reviewed step done and advance to the next unfinished step. If a ticket is already in `Doing` and it has no remaining steps, stop and report that the current ticket must be finished or merged before starting a new one. Only when `Doing` is empty should the skill select from `Todo`; if `<ticket-number>` is omitted, select the first ticket in `Todo`, and if `<ticket-number>` is provided, select the matching `DG-<ticket-number>` ticket from `Todo` only.
---

# Start Next Task

Follow this workflow for this repository when invoked as `$start-next-task <ticket-number>`.

## Workflow

1. Inspect the `Doing` column of `kanban_tasks_data.kanban` before looking at `Todo`.
   - If `Doing` contains more than one ticket, stop and report that the board is ambiguous and needs cleanup before the workflow can continue.
   - If `Doing` contains exactly one ticket, treat that ticket as the active ticket and do not start a different `Todo` ticket.
2. If there is an active `Doing` ticket:
   - If it has no `steps` entries, stop and report that open work tickets must have steps before the workflow can continue. Instruct the user to backfill the ticket with the `write-ticket` skill.
   - If it has a `steps` array with any `done: false` entries, work only the first unfinished step in the order shown on the ticket.
   - If `$start-next-task` is invoked again while that same stepped ticket remains in `Doing`, treat the invocation as review approval for the current reviewed step:
     - mark the current first unfinished step `done: true`
     - commit the current ticket work, including the kanban step-state change, with a conventional commit before beginning the next unfinished step
     - if another unfinished step remains, begin that next step only
     - if no unfinished steps remain, stop and report that the ticket is still active and must be finished or merged before another ticket can begin
   - After completing any single step implementation, report the summary as usual and wait for review/confirmation before beginning the next step.
   - If the active `Doing` ticket has no steps, or all steps are already done, stop and report that there is already an active ticket and it must be finished or merged before starting the next ticket.
3. Only if `Doing` is empty, identify the target ticket from the `Todo` column.
   - If `<ticket-number>` is omitted, use the first ticket in `Todo`.
   - If `<ticket-number>` is provided, use the matching `DG-<ticket-number>` ticket in `Todo`.
   - If the specified ticket is not present in `Todo`, stop and report that the ticket does not exist.
   - If the selected `Todo` ticket has no `steps` entries, stop and report that open work tickets must have steps before they can be started. Instruct the user to backfill the ticket with the `write-ticket` skill.
4. Move the selected `Todo` ticket into `Doing`.
5. Create and switch to a git branch named exactly after the ticket title.
6. Review the ticket, the relevant parts of `Docs/GDD.md`, and the current implementation internally. Do not output a plan or analysis before starting — begin implementing immediately.
7. Implement the first unfinished step. Do not stop until actual code or file changes have been made.
8. After completing the step implementation, report what was changed and include a focused `Manual Verification` section in the report for the human reviewer.
   - List only the manual checks needed to validate the changes made in that implementation pass.
   - Write the checks as ordered steps the human can perform in game or in editor.
   - Keep the instructions specific enough to verify the changed behavior or presentation directly.
   - Do not include unrelated regression coverage or broad exploratory testing in this section.

## Repo Notes

- Ticket titles follow the format `DG-<number>`.
- Do not modify files under `/addons` unless explicitly requested.
- Prefer practical vertical-slice changes over abstraction-heavy design.
- Keep the work aligned with the current scope in `Docs/GDD.md`.
- Step order is always the literal order in the ticket's `steps` array.
- For stepped tickets, only one step may be worked at a time.
- Open work tickets without steps are invalid input for this workflow and must be backfilled before they can be started or resumed.
- Do not output a plan or analysis before implementing. Begin making changes immediately.
- After implementing a step, stop and report. Do not mark the step done yet — the next `$start-next-task` invocation signals review approval.
- After a reviewed step is approved (next invocation), mark it `done: true`, commit the work, then implement the next step.
- The implementation report should always tell the human verifier exactly how to manually validate only the new changes from that run.

## Required Outcome

- `Doing` is checked before `Todo`.
- A stepped `Doing` ticket is resumed step-by-step in order, one step at a time.
- A step-less open ticket is blocked until it has been backfilled with steps.
- An approved stepped-ticket increment is committed before the next step begins.
- A new `Todo` ticket is only started when `Doing` is empty.
- The current branch matches the active ticket title exactly.
- The ticket, GDD context, and current implementation are reviewed internally before implementation begins — no plan output before starting.
- Implementation begins immediately and produces actual code or file changes before stopping.
- The implementation report includes a `Manual Verification` section with ordered human test steps for only the changes made in that run.
- After a stepped-ticket implementation, the report stops and waits for the next `$start-next-task` invocation as review approval.
