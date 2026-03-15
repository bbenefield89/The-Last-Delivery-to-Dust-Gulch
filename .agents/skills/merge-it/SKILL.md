---
name: merge-it
description: Complete the repository's "merge it" workflow for the active ticket in `Doing`. Require exactly one ticket in `Doing`, require the current branch to match that ticket title, and validate that all step entries are complete before proceeding for stepped tickets. If the active `Doing` ticket has no steps, stop and report that open work tickets must have steps before they can be merged. If any of those checks fail, stop and report what remains. If they all pass, commit the work, update the kanban board, fast-forward `main` when possible, and report the resulting branch and commit state.
---

# Merge It

Follow this workflow for this repository when the user says `merge it`.

## Workflow

1. Inspect the `Doing` column of `kanban_tasks_data.kanban`.
   - If `Doing` is empty, stop and report that there is no active ticket to merge.
   - If `Doing` contains more than one ticket, stop and report that the board is ambiguous and needs cleanup before merge can continue.
   - If `Doing` contains exactly one ticket, treat it as the active ticket.
2. Confirm the current branch matches the active ticket title exactly.
   - If the branch does not match, stop and report the mismatch.
3. Validate ticket completion before any merge actions.
   - If the active ticket has a `steps` array with entries, confirm every step is marked complete.
   - If any step is incomplete, stop and report that more work remains before merge.
   - If the active ticket has no `steps` entries, stop and report that open work tickets must have steps before they can be merged. Instruct the user to backfill the ticket with the `write-ticket` skill.
4. Inspect the working tree and identify any remaining staged or unstaged changes that belong to the ticket.
   - If any work has not been completed to satisfy the current ticket, stop this skill and report back what needs to be done to accomplish the purpose of the current ticket.
5. Commit the current task work with a conventional commit message if the ticket still has uncommitted implementation changes.
6. Update `kanban_tasks_data.kanban`:
   - move the corresponding ticket from `Doing` to `Done`
7. Fold the kanban move into the intended final feature-branch commit shape before touching `main`.
   - Prefer amending the current final ticket commit so the board move does not land as a standalone `kanban-only` commit.
   - If the branch already contains multiple ticket commits and a squash is needed, rewrite the feature-branch history so the ticket lands as the intended final commit shape before fast-forwarding `main`.
   - Do not leave a separate history entry whose only meaningful purpose is moving the kanban card.
8. Switch to `main`.
9. Fast-forward `main` when possible from the ticket branch.
10. Run a `git push` to sync remote and local `main`.
11. Report the resulting branch and commit state.

## Repo Notes

- The kanban ticket title format is `DG-<number>`.
- The active branch is usually named exactly after the ticket.
- Do not modify files under `/addons`.
- Prefer non-interactive git commands.
- `Doing` must contain exactly one active ticket before merge can proceed.
- For stepped tickets, every step must already be marked complete before `merge-it` can continue.
- Open work tickets without steps are invalid input for this workflow and must be backfilled before merge.
- Avoid landing standalone kanban-only commits on `main`; the board move should be folded into the final ticket commit shape.

## Required Outcome

- The active ticket comes from `Doing`.
- The current branch matches the active ticket title exactly.
- Stepped tickets are blocked from merge until every step is marked complete.
- Step-less open tickets are blocked from merge until they are backfilled with steps.
- The ticket branch work is committed with a conventional commit.
- The kanban ticket is moved from `Doing` to `Done`.
- The final feature-branch history does not contain a standalone kanban-only commit.
- `main` is updated via fast-forward when possible.
- The final report includes the branch state and resulting commit state.

## Reporting

When reporting completion, include:

- the files changed, grouped by slice when relevant
- the final commit hash and message
- the current branch
- whether `main` was fast-forwarded successfully
