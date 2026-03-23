---
name: write-ticket
description: Create a new stepped kanban ticket or retrofit an existing open ticket with steps. Reads `kanban_tasks_data.kanban` to determine the next sequential DG number, delegates ticket drafting and board edits to the project's `planner` subagent, reports the exact ticket content, then writes it to the board.
---

# Write Ticket

Follow this workflow when asked to create a ticket, write a ticket, or add steps to an existing ticket.

## Workflow

1. Inspect `kanban_tasks_data.kanban` before proposing any ticket changes.
   - Identify the next sequential `DG-<number>` value from the existing task titles.
   - Identify the current stage order so new tickets are inserted in the requested column position.
2. Determine whether the request is one of these modes:
   - create a new ticket
   - retrofit steps onto an existing open ticket
   - rewrite an existing open ticket's steps or description
3. After the board context and mode are known, use exactly one `planner` subagent for the ticket-authoring pass.
   - Spawn the project-scoped `planner` agent type, not a generic worker.
   - Scope it to ticket-authoring only.
   - Tell it to draft the exact ticket content, then write the approved board edit in `kanban_tasks_data.kanban`.
   - Tell it not to implement gameplay code, not to start task execution, and not to make merge decisions.
   - If the `planner` subagent is unavailable, stop and report that this repo must configure the custom `planner` agent before this skill can continue.
4. For every open work ticket written by this skill, require:
   - a valid `DG-<number>` title
   - a category of `Task`, `Bug`, or `TechDebt`
   - a `description` field written in the ticket description format below
   - an ordered non-empty `steps` array where each step has a description of what to do and a `Done when:` Definition of Done
   - every `Done when:` must be reviewable by a human through normal product use, preferably by playing the game rather than by reading logs, using debug tooling, or running tests directly
   - no standalone test-only steps such as `add unit tests` or `write automated coverage`; test work must be folded into the feature step it validates
5. When creating a new ticket:
   - use the next sequential `DG-<number>`
   - default the new ticket to `Todo` unless the user explicitly requests another stage
   - if the user specifies placement within a stage, honor that position
   - if the user does not provide steps, derive a practical ordered step list before writing the ticket
   - if a natural implementation slice would otherwise end in a non-human-testable outcome, merge it with the next related slice until the step can end in a human-playable verification outcome
6. When retrofitting or rewriting an existing open ticket:
   - preserve the existing title, category, and current stage unless the user explicitly asks to change them
   - replace missing or outdated `steps` with an ordered implementation plan following the step format
   - rewrite vague, internal, or tool-driven `Done when:` language into concrete player-observable outcomes
   - remove standalone test-only steps by merging their test expectations into the relevant feature steps
   - do not modify `Done` tickets unless the user explicitly asks
7. Before mutating the board, report the exact ticket content you are about to write.
8. After the main agent reports the exact content, have the `planner` subagent perform the board mutation.
9. After writing the board update, report the affected ticket titles and where they were placed.

## Ticket Description Format

The `description` field must give the implementor enough context to understand the full problem without reading other files first.

```
<Full problem description. Explain what is broken or needed and why,
with enough context for the implementor to act on it immediately.>

Done when: <Definition of Done for the entire ticket - what does
"complete" look like from end to end, in terms a human can verify by
using the product?>
```

## Step Format

Each step's `details` field must be specific enough to act on in isolation, and must include a Definition of Done.

```
<Description of what to do in this step.>

Done when: <What is true when this step is considered complete, in a way
a human reviewer can confirm by playing or using the product normally?>
```

When a step needs automated coverage, include it inside that same step with wording such as `and write very thorough unit tests for this behavior`. Do not make that its own step.

## Step Guidance

Steps exist to keep each change reviewable in isolation. Use as many steps as the work naturally requires. If the scope of a ticket is too large to express in a small number of steps, split it into multiple tickets instead.

- Every step should end in a player-observable or user-observable outcome.
- Prefer `by playing the game...` or an equivalent normal-use verification pattern in every `Done when:`.
- Avoid internal-only completion language such as `deterministic`, `recorded`, `covered`, `clearly communicates`, `readable`, or `feels right` unless the same sentence also names the concrete in-game outcome a reviewer should verify.
- If one step would only produce an internal state change, data wiring, or tests, merge it into the next feature slice so the combined step ends in a human-testable outcome.
- Require very thorough unit tests for each step, but keep them subordinate to the feature behavior rather than making them the feature.

## Repo Notes

- Open work tickets in `Todo` or `Doing` must not be left without steps.
- `$start-next-task` and `$merge-it` both block on step-less open tickets.
- Ticket title format is `DG-<number>`, numbered sequentially.
- The `planner` subagent is responsible for the ticket draft and board edit. The main agent remains responsible for orchestration and the user-facing report.

## Required Outcome

- New ticket numbers remain sequential.
- Every new or rewritten open work ticket has a rich `description` and a non-empty `steps` array.
- Each step has a description and a `Done when:` definition.
- Every ticket-level and step-level `Done when:` is human-reviewable through normal product use.
- No open ticket contains a standalone test-only step.
- Test expectations are folded into the relevant feature steps and call for very thorough unit coverage.
- Existing open tickets can be backfilled without changing their stage unintentionally.
- The `planner` subagent performs the ticket-authoring and board-write pass.
- The final report states exactly which tickets were created or updated and where they now live on the board.
