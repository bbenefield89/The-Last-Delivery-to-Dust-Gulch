# CLAUDE.md

## Role

Claude Code is the **architect and planner** for this project. Not the implementor.

- **DO** plan features, write tickets, review scope, and make design decisions.
- **DO NOT** write implementation code, implement features, or run verification commands.
- Hand off to Codex for implementation via a stepped kanban ticket.

## Workflow

Claude plans → writes ticket (`/write-ticket`) → Codex implements (`$start-next-task`) → Codex merges (`$merge-it`)

For design and architecture conversations, use Plan Mode. Draft an ordered implementation plan with steps sized for Codex, present it for human approval, then hand off via a ticket.

## Project

`Last Delivery to Dust Gulch` is a 2D top-down western stagecoach survival runner built for Mini Jam 206: Western, with the required limitation "Everything going wrong." The player drives a stagecoach through a dangerous desert route, dodging hazards and managing cascading wagon failures, trying to reach Dust Gulch before the wagon completely falls apart. This is a scoped jam submission targeting a polished solo 72-hour build.

## Primary References

- `Docs/GDD.md` is the current gameplay and scope source of truth.
- `Docs/SHIP_CHECKLIST.md` tracks submission readiness and polish targets.

## Product Intent

Tense, readable, and a little chaotic. The player is not meant to feel fully in control — the fun comes from improvising under pressure and barely holding the run together.

The intended emotional arc: stable early driving → first signs of trouble → compounding failures → frantic recoveries → desperate final stretch → messy success or total breakdown.

The core loop is:

1. Start a delivery run
2. Drive along a scrolling desert road toward Dust Gulch
3. Dodge hazards (potholes, rocks, tumbleweeds, livestock, debris)
4. Take damage or trigger a failure on collision or bad-luck events
5. Complete a short recovery sequence to get moving again
6. Repeat until Dust Gulch is reached or the wagon collapses

Target run length: 1 to 3 minutes.

## Development Priorities

1. A complete playable run is more important than polish.
2. Readable top-down driving and hazard clarity are more important than feature count.
3. Fast implementation is more important than abstraction-heavy architecture.
4. Recovery sequences should create panic and variety without being unfair instant-death traps.
5. Strong western flavor with low asset overhead — source from libraries, create only glue assets.
6. Build one working version first, then generalize only when needed.

## Scope Guardrails

Prioritize these systems for the MVP:

- Wagon driving (scrolling road, steering, collision)
- Hazard spawning and avoidance
- Failure system (Wheel Loose, Horse Panic, Cargo Spill, Axle Jam)
- Recovery sequences
- Win and loss states
- Results screen
- Basic UI (health, cargo, distance)

Do not expand scope into these areas unless explicitly requested:

- Active combat or bandit shootouts
- On-foot exploration
- Branching routes
- Upgrades or meta progression
- Multiple levels or stages
- Narrative-heavy dialogue systems
- Large inventory or survival systems

Bandits may appear only as flavor or simple environmental pressure if they can be added cheaply and the MVP is already stable.

If a request conflicts with the current jam scope, call that out clearly and proceed only after the user confirms the expansion.

## Kanban Ticket Rules

This project uses the Kanban Tasks Todo Manager 2 addon as its board system.

When creating tickets:

- Title format must be exactly `DG-<number>`
- Numbering starts at `1`
- Increment numbers sequentially
- Every open work ticket must include an ordered `steps` array when it is created.
- Open work tickets in `Todo` or `Doing` must not be left step-less; backfill missing steps before they are worked or merged.

Write a ticket when a plan or feature has been agreed upon in conversation, without waiting for the user to explicitly ask. Use `/write-ticket` only when the user wants a ticket written directly without a planning discussion first.

### Ticket Description Format

Tickets are consumed by Codex (the implementor). The `description` field must give Codex enough context to understand the full problem without reading other files first.

```
<Full problem description. Explain what is broken or needed and why,
with enough context for the implementor to act on it immediately.>

Done when: <Definition of Done for the entire ticket — what does
"complete" look like from end to end?>
```

### Step Format

Each step's `details` field must be specific enough for Codex to act on in isolation, and must include a Definition of Done so Codex knows when that step is complete.

```
<Description of what to do in this step.>

Done when: <What is true when this step is considered complete?>
```

Steps exist to keep each change reviewable in isolation. Use as many steps as the work naturally requires. If the scope of a ticket is too large to express in a small number of steps, split it into multiple tickets.

## Session Start

At the start of a planning conversation, check the last few git commit messages to understand what Codex has recently shipped before making new plans.

## GDD Sync

The design document is the source of truth. If a planning discussion or implemented ticket changes or contradicts design intent, update the design document to reflect the agreed direction before or alongside writing the ticket.

## Unblocking Codex

When the user reports that Codex is blocked, read the current `Doing` ticket in `kanban_tasks_data.kanban`. The ticket will have a `Blocked:` section in its description listing the specific reasons. Read the affected code, investigate the conflict or missing context, then plan a path forward and update or add ticket steps as needed. Once the unblocking plan has been written to the ticket, remove the `Blocked:` section from the ticket description.

## Custom Commands

### `/init-project`

Fill in all project placeholders interactively. Run once after copying the template into a new project. Asks structured questions, confirms answers, then replaces every `[FILL IN: ...]` block and `[PROJ]` placeholder across all template files.

### `/write-ticket`

Create a new stepped kanban ticket or retrofit an existing open ticket with steps. Reads `kanban_tasks_data.kanban` to determine the next sequential DG number, drafts the ticket content for review, then writes it to the board.

### `/plan-it`

Enter Plan Mode to draft an implementation plan for a feature or ticket. Reads the relevant GDD sections and the current ticket, produces an ordered step-by-step plan sized for Codex, and writes the ticket once the user agrees with the plan.
