# AGENTS.md

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

If a request conflicts with the current jam scope, call that out clearly and proceed only after the user confirms the expansion.

## Kanban Ticket Rules

This project uses the Kanban Tasks Todo Manager 2 addon as its board system.

When creating tickets:

- Title format must be exactly `DG-<number>`
- Numbering starts at `1`
- Increment numbers sequentially
- Every open work ticket must include an ordered `steps` array when it is created.
- Open work tickets in `Todo` or `Doing` must not be left step-less; backfill missing steps before they are worked or merged.

Do not create tickets unless the user explicitly asks for them.

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

## UI Direction

When implementing or proposing UI, prioritize readability and clarity over decoration.

Key UI qualities:

- Readable at a glance under pressure
- Western flavor through typography, color, and framing — not ornament
- Clear HUD hierarchy: health, cargo, distance progress
- Failure and recovery overlays should feel urgent and distinct from normal driving UI
- Results screen should feel like a frontier dispatch — matter-of-fact, a little dusty

Art direction reference from `Docs/GDD.md`:

- Dusty tan roads, red canyon accents, faded wood signage, dry brush and scrub
- Readable pixel art with a classic western desert palette
- Strong wagon shadows and exaggerated hazard readability

Keep the center gameplay area clear. Push persistent HUD elements to edges and corners. Failure overlays should be dramatic but not obscure the recovery input prompt.

## Blocked Work

If you reach a point where you cannot continue without a design decision, missing context, or an unexpected architectural conflict, stop and signal the block clearly rather than guessing or working around it.

To signal a block:

1. Append a `Blocked:` section to the current ticket's `description` field in `kanban_tasks_data.kanban`, listing the specific reasons:
   ```
   Blocked:
   - <Reason 1 — what is unclear or conflicting>
   - <Reason 2>
   ```
2. Commit current progress with the message `wip(DG-<number>): blocked — <short reason>`.
3. Report back to the user with a clear description of what you were attempting, what you encountered, and what decision or information is needed to unblock you.

The user will bring the block to Claude (the architect) who will read the ticket, investigate, and plan a path forward.

## Repository Rules

- Never modify files under `/addons` unless the user explicitly asks.
- Do not modify the `addons/kanban_tasks` plugin unless the user explicitly asks.
- Keep changes focused and small where possible.
- Prefer practical Godot scene-and-script solutions over speculative frameworks.
- Preserve existing documentation and add to it when it improves execution clarity.
- Use conventional commits when committing changes.
- Follow good SOLID and Clean Code practices.
- Agent-generated code must remain easy for humans to read, review, and maintain.
- Favor clear naming, small focused units, low coupling, and straightforward control flow over cleverness.

## Working Style

Before implementing a system, check whether it supports the vertical slice directly.

Every response should include a short `Prompt Summary` line that briefly explains the user's most recent prompt.

After making code changes and reporting back to the user:

- Do not reply with a prose paragraph explaining the changes.
- Reply with a list of the changes made by file.
- Group that list by the slice each file belongs to.

## Design Decisions

When making design decisions:

- Prefer simple data flow
- Optimize for shipping a playable, completable run
- Keep the game feel readable and responsive under pressure
- Treat the GDD as the current baseline unless the user changes direction

If a request conflicts with the current jam scope, call that out clearly and proceed only after the user confirms the expansion.

After making Godot project changes, verify them when feasible. Prefer `godot --headless --path . --quit` for a quick project startup and load/parse baseline check when the Godot executable is available.

Do not treat the headless boot command as sufficient verification by itself when a smoke-test runner exists. Run the smoke test as well so critical scenes and resources are explicitly validated beyond the main startup path.

Default to adding newly critical scenes and resources to the smoke test as feature work progresses. Gameplay-critical scenes, overlays, hazards, failure states, and recovery sequences should become part of smoke coverage as they are introduced.

When unit tests are available, run verification in this order when feasible:

1. `godot --headless --path . --quit`
2. `godot --headless --path . --script res://Tests/Smoke/smoke_test_runner.gd`
3. `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`

## Agent Verification Standard

Treat automated verification as the primary safety mechanism for agent-written code, with human review acting as a secondary check for design, readability, and test quality.

- Do not rely on human review alone for gameplay correctness. Agents should prove meaningful changes through automated verification.
- Every meaningful gameplay or systems change should add or update tests unless the work is truly documentation-only.
- Name test scripts using the pattern `test_class_name.gd`, and name GUT test methods using the pattern `test_method_name_when_condition_then_result` so discovery stays consistent and readable.
- Prefer extracting small testable logic units instead of leaving behavior buried in large scene scripts.
- Keep scene scripts thin and push decisions, calculations, and rule evaluation into code that is easier to unit test.
- If a change is difficult to test, treat that as a design smell and prefer a small refactor that improves testability.
- Do not add or widen public gameplay API purely to satisfy tests. Tests must not be the reason a field, getter, setter, or method becomes public.
- If tests need visibility into behavior, prefer asserting through existing public behavior, signals, scene state, or a small refactor that extracts testable logic. Do not add test-only getters or setters to production code.
- If a new public field or method is currently referenced only by tests but is intentionally being introduced for a planned real gameplay/runtime use later in the same ticket or near-future work, add a short doc comment that says so. Remove that comment once the API has a real non-test caller.
- Use human review time to judge architecture, naming, readability, gameplay intent, and whether tests are meaningful, not to manually simulate every code path.
- No important behavior should exist without automated verification coverage at the appropriate layer.
- Prefer layered verification: unit tests for rules, scene tests for runtime behavior, smoke tests for startup and resource coverage.

## Automation-Friendly Coding

Write gameplay code so it can support future automated validation without forcing a large architecture upfront.

- Avoid coupling gameplay logic directly to live human input when a small command or controller abstraction would work.
- Prefer player intent flowing through a reusable command source or controller layer so human input and bots can share the same gameplay path.
- Keep important runtime state queryable from code. Health, cargo value, distance, run phase, active failure, and win/loss state should not only exist as UI text or deeply nested scene state.
- Prefer explicit signals for important gameplay events such as hazard spawn, hazard hit, failure trigger, recovery success, recovery failure, and run completion.
- Keep core rules and run logic in testable code units where feasible instead of burying everything inside scene callbacks.
- Centralize randomness when possible and support seeded runs if practical so failures can be reproduced.

## Project Structure

- Organize the project by vertical slice or feature ownership, not by broad file type buckets like global `Scenes` or `Scripts` folders.
- Keep files with the slice that owns them. Example: wagon scenes, scripts, data, and assets belong under a wagon-related slice folder.
- When a slice grows, split by role inside that slice using folders such as `/Scenes`, `/Scripts`, `/Data`, and `/Enums`.
- Put enum files in an `/Enums` folder inside the owning slice.
- Use a shared folder only for code or assets that are genuinely shared by multiple slices. Do not use it as a dumping ground.
- Start small. If a slice only has one or two files, keep the structure flat until more subdivision improves readability.

## Godot Script References

- Do not preload `.gd` scripts for project-owned code when a `class_name` reference is available.
- Use `class_name` for reusable script classes and static utility scripts that are referenced across files.
- Prefer referencing project-owned script classes by `class_name` directly. If a script needs an instance, call `.new()` on the class instead of preloading the script resource.
- When adding a new project-owned `class_name` script that other files will reference immediately, prefer a quick Godot import/boot pass such as `godot --headless --path . --quit` before wiring those references so the script-class cache is refreshed.
- Do not treat a newly added `class_name` script failing to resolve on the first headless parse as justification to switch that reference to `preload(...)` by default. Refresh imports first, then keep the `class_name` reference when feasible.
- Keep `preload` for `PackedScene` resources and other assets where loading the resource itself is the goal.
- Instantiate scenes with `.instantiate()`, not `.new()`.

## GDScript Organization

- Order project-owned `.gd` files like this when feasible: `class_name`, `extends`, doc comment, signals, enums, constants, static variables, exported fields, regular fields, onready fields, static init, static methods, built-in lifecycle methods, custom overridden methods, remaining methods, inner classes.
- Add section comments for the active parts of the file, grouped by visibility where appropriate, using labels like `# Public Fields`, `# Private Fields`, `# Public Fields: OnReady`, `# Private Fields: OnReady`, `# Lifecycle Methods`, `# Event Handlers`, `# Public Static Methods`, and `# Private Methods`.
- Put fields with Godot attributes in dedicated field sections instead of the generic field sections. Use labels such as `# Public Fields: Export`, `# Private Fields: Export`, `# Public Fields: OnReady`, and `# Private Fields: OnReady` for `@export*`, `@onready`, and similar attribute-driven fields.
- Do not treat `@export` or other Godot field attributes as a reason to widen visibility. Exported fields should follow the same public/private rules as any other field.
- Put event-handler methods in a dedicated `# Event Handlers` section immediately after the lifecycle-methods section when the file has any event handlers.
- Add a `##` doc comment above each method you add or change. Backfill older untouched methods only when you are already modifying them for another reason.
- Default to typed classes, including small inner classes when appropriate, instead of project-owned dictionaries; only use dictionaries when the tradeoff is appropriate.
- When using inner classes in GDScript, place them at the bottom of the file after the file's non-inner-class fields and methods.
- Add a `##` doc comment directly below each inner class `extends` line, and keep the same spacing/readability rules inside inner classes that the file uses elsewhere.
- Never leave a project-owned variable, method argument, or method return type untyped.
- Prefer inferred typing where it keeps the code clear, and when inference is not sufficient, add an explicit type annotation.
- Format ternaries like this when they span multiple lines: `var value := result \` on the first line, `    if condition \` on the second line, and `    else fallback` on the third line.
- Leave a blank line between `extends` and the doc comment.
- Leave a blank line between the doc comment and the next code or section comment.
- Leave a blank line between each section comment and the code that follows it.
- Keep `class_name` on the first relevant line and `extends` on the next line.
- Use visibility prefixes consistently for project-owned symbols when feasible: public has no prefix, protected uses a single leading underscore, and private uses a double leading underscore.
- Do not rename Godot built-in virtual callbacks like `_ready()`, `_draw()`, or `_physics_process()` to match the private prefix rule; keep the engine-required names intact.
- Keep lines at 120 characters or fewer when feasible.

## Testing Expectations

- This is an agentic project. Bias strongly toward exhaustive automated verification rather than human-only spot checks.
- Add more unit tests than would be typical for a human-paced jam or prototype project.
- Test everything that can reasonably be tested: pure logic, state transitions, scene wiring, regression-prone behavior, and failure paths.
- When adding new systems or behavior, treat missing automated tests as a gap to close unless the code is truly trivial or temporary scaffolding.
- Prefer small, focused tests with clear intent over a few broad tests that are harder to debug.
- Keep headless verification, GUT coverage, and lightweight smoke checks in the normal development loop whenever they are applicable.
