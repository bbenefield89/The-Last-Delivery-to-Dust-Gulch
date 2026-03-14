Follow this workflow when asked to create a ticket, write a ticket, or add steps to an existing ticket.

## Workflow

1. Inspect `kanban_tasks_data.kanban` before proposing any ticket changes.
   - Identify the next sequential `DG-<number>` value from the existing task titles.
   - Identify the current stage order so new tickets are inserted in the requested column position.
2. Determine whether the request is one of these modes:
   - create a new ticket
   - retrofit steps onto an existing open ticket
   - rewrite an existing open ticket's steps or description
3. For every open work ticket written by this command, require:
   - a valid `DG-<number>` title
   - a category of `Task`, `Bug`, or `TechDebt`
   - a `description` field written in the ticket description format below
   - an ordered non-empty `steps` array where each step has a description of what to do and a `Done when:` Definition of Done
4. When creating a new ticket:
   - use the next sequential `DG-<number>`
   - default the new ticket to `Todo` unless the user explicitly requests another stage
   - if the user specifies placement within a stage, honor that position
   - if the user does not provide steps, derive a practical ordered step list before writing the ticket
5. When retrofitting or rewriting an existing open ticket:
   - preserve the existing title, category, and current stage unless the user explicitly asks to change them
   - replace missing or outdated `steps` with an ordered implementation plan following the step format
   - do not modify `Done` tickets unless the user explicitly asks
6. Before mutating the board, report the exact ticket content you are about to write.
7. After writing the board update, report the affected ticket titles and where they were placed.

## Ticket Description Format

Tickets are consumed by Codex (the implementor). The `description` field must give Codex enough context to understand the full problem without reading other files first.

```
<Full problem description. Explain what is broken or needed and why,
with enough context for the implementor to act on it immediately.>

Done when: <Definition of Done for the entire ticket — what does
"complete" look like from end to end?>
```

## Step Format

Each step's `details` field must be specific enough for Codex to act on in isolation, and must include a Definition of Done.

```
<Description of what to do in this step.>

Done when: <What is true when this step is considered complete?>
```

## Step Guidance

Steps exist to keep each change reviewable in isolation. Use as many steps as the work naturally requires. If the scope of a ticket is too large to express in a small number of steps, split it into multiple tickets instead.

## Repo Notes

- Open work tickets in `Todo` or `Doing` must not be left without steps.
- `start-next-task` and `merge-it` (Codex skills) both block on step-less open tickets.

## Required Outcome

- New ticket numbers remain sequential.
- Every new or rewritten open work ticket has a rich `description` and a non-empty `steps` array.
- Each step has a description and a `Done when:` definition.
- Existing open tickets can be backfilled without changing their stage unintentionally.
- The final report states exactly which tickets were created or updated and where they now live on the board.
