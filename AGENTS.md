# AGENTS.md

## Project

`Last Delivery to Dust Gulch` is a polished mobile-forward 2D top-down western stagecoach survival runner. The player drives a stagecoach through a dangerous desert route, dodging hazards and managing cascading wagon failures, trying to reach Dust Gulch before the wagon completely falls apart. The project is no longer being treated as a jam build; the current direction is a polished release with short, finishable runs and strong replay value.

## Primary References

- `Docs/GDD.md` is the current gameplay and scope source of truth.
- `Docs/SHIP_CHECKLIST.md` tracks release readiness and ship targets.

## Role Docs

Project-scoped Codex subagent docs live under `.codex/agents/`.

- `implementor.md` owns execution workflow, blocker handling, and implementation reporting expectations.
- `planner.md` owns planning workflow and detailed ticket-authoring guidance.
- `reviewer.md` owns review priorities and reviewer output expectations.

## Product Intent

Tense, readable, and a little chaotic. The player is not meant to feel fully in control — the fun comes from improvising under pressure and barely holding the run together.

The intended emotional arc: stable early driving → first signs of trouble → compounding failures → frantic recoveries → desperate final stretch → messy success or total breakdown.

The core loop is:

1. Start a delivery run
2. Drive along a scrolling desert road toward Dust Gulch
3. Dodge hazards (potholes, rocks, tumbleweeds, livestock)
4. Take damage or trigger a failure on collision or bad-luck events
5. Complete a short recovery sequence to get moving again
6. Repeat until Dust Gulch is reached or the wagon collapses

Target run length: 90 to 150 seconds on success, with failed runs usually resolving faster.

## Development Priorities

1. A strong mobile-friendly core run is more important than feature count.
2. Readable top-down driving and hazard clarity are more important than added systems.
3. Polish that improves feel, readability, and replay value is worth prioritizing.
4. Recovery sequences should create panic and variety without being unfair instant-death traps.
5. Strong western flavor with low asset overhead — source from libraries, create only glue assets.
6. Keep architecture practical and maintainable; do not overbuild prematurely.

## Scope Guardrails

Prioritize these systems for the current release slice:

- Wagon driving (scrolling road, steering, collision)
- Hazard spawning and avoidance
- Failure system (Wheel Loose, Horse Panic, Cargo Spill, Axle Jam)
- Recovery sequences
- Win and loss states
- Results screen
- Basic UI (health, cargo, distance)
- Mobile-friendly onboarding, touch controls, and pacing

Do not expand scope into these areas unless explicitly requested:

- Active combat or bandit shootouts
- On-foot exploration
- Branching routes
- Upgrades or meta progression
- Multiple levels or stages
- Narrative-heavy dialogue systems
- Large inventory or survival systems

Bandits may appear only as flavor or simple environmental pressure if they can be added cheaply and the core release loop is already stable.

If a request conflicts with the current release direction, call that out clearly and proceed only after the user confirms the expansion.

## Kanban Ticket Rules

This project uses the Kanban Tasks Todo Manager 2 addon as its board system.

When creating tickets:

- Title format must be exactly `DG-<number>`
- Numbering starts at `1`
- Increment numbers sequentially
- Every open work ticket must include an ordered `steps` array when it is created.
- Open work tickets in `Todo` or `Doing` must not be left step-less; backfill missing steps before they are worked or merged.

Write a ticket when a plan or feature has been agreed upon in conversation, without waiting for the user to explicitly ask.
Use `$write-ticket` only when the user wants a ticket written directly without a planning discussion first.
Detailed ticket description and step-authoring rules now live in `.codex/agents/planner.md`.

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

## GDD Sync

`Docs/GDD.md` is the source of truth. If a planning discussion or implemented ticket changes or contradicts design intent, update the design document to reflect the agreed direction before or alongside writing the ticket.

## Custom Skills

- `$start-next-task` — Start or resume the next kanban ticket step by step.
- `$merge-it` — Finish and merge the active ticket; fast-forward `main`.
- `$implement-plan` — Execute an already-discussed agreed plan end-to-end.
- `$plan-it` — Plan a feature or ticket collaboratively, then write the ticket.
- `$write-ticket` — Create or retrofit a kanban ticket with proper steps.

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
- Centralize reusable `res://` and `user://` path strings in const files under `res://Constants/` instead of scattering raw path literals through project-owned code.

## Design Decisions

When making design decisions:

- Prefer simple data flow
- Optimize for shipping a playable, completable run
- Keep the game feel readable and responsive under pressure
- Treat the GDD as the current baseline unless the user changes direction

## Verification

After meaningful Godot project changes, verify them when feasible in this order:

1. `godot --headless --path . --quit`
2. `godot --headless --path . --script res://Tests/Smoke/smoke_test_runner.gd`
3. `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`

- Treat the headless boot as a baseline parse/load check, not full verification.
- When a smoke-test runner exists, run it for scene and resource coverage.
- Use the single GUT command above to run the full test suite; do not run individual test files one by one.
- Add newly critical gameplay scenes, overlays, hazards, failure states, and recovery sequences to smoke coverage as they are introduced.

## Agent Verification Standard

Treat automated verification as the primary safety mechanism for agent-written code, with human review acting as a secondary check for design, readability, and test quality.

- Do not rely on human review alone for gameplay correctness.
- Every meaningful gameplay or systems change should add or update tests unless the work is documentation-only.
- Prefer extracting small testable logic units instead of burying behavior inside large scene scripts.
- If a change is difficult to test, treat that as a design smell and prefer a small refactor that improves testability.
- Do not widen public gameplay API purely to satisfy tests. Prefer asserting through existing public behavior, signals, scene state, or a small refactor.
- Name test scripts `test_class_name.gd` and GUT methods `test_method_name_when_condition_then_result`.
- No important behavior should exist without automated verification at the appropriate layer.
- Prefer layered coverage: unit tests for rules, scene tests for runtime behavior, smoke tests for startup and resource coverage.

## Automation-Friendly Coding

Write gameplay code so it can support future automated validation without forcing a large architecture upfront.

- Avoid coupling gameplay logic directly to live human input when a small command or controller abstraction would work.
- Prefer player intent flowing through a reusable command source or controller layer so human input and bots can share the same gameplay path.
- Keep important runtime state queryable from code. Health, cargo value, distance, run phase, active failure, and win/loss state should not only exist as UI text or deeply nested scene state.
- Prefer explicit signals for important gameplay events such as hazard spawn, hazard hit, failure trigger, recovery success, recovery failure, and run completion.
- Keep core rules and run logic in testable code units where feasible instead of burying everything inside scene callbacks.
- Centralize randomness when possible and support seeded runs if practical so failures can be reproduced.

## Project Structure

- Keep actual game scenes under the top-level `Scenes/` folder.
- Keep each scene and its primary script as siblings inside the owning scene folder. Example: `Scenes/RunScene/RunScene.tscn` and `Scenes/RunScene/run_scene.gd`.
- Keep reusable runtime owners under `Systems/<Owner>/`.
- If a system is node-backed, keep its scene and script as siblings in the same owning `Systems/<Owner>/` folder.
- If a system is a pure helper, it may contain only the `.gd` file in its owning `Systems/<Owner>/` folder.
- Keep owner-specific support types, constants, data, and enums near the owner that uses them.
- Put owner-specific enum files in an `Enums/` folder under that owner when they need their own file.
- Reserve top-level `Enums/` only for genuinely generic cross-cutting enums.
- Do not reintroduce a top-level `Scripts/` folder for active project code.
- Use a shared folder only for code or assets that are genuinely shared by multiple slices. Do not use it as a dumping ground.
- Start small. If an owner only has one or two files, keep the structure flat until more subdivision improves readability.

## Godot Script References

- Use `class_name` only when a script genuinely needs global registration or repeated direct cross-file script-class access.
- Do not add `class_name` by default, especially for scene-owned scripts that are loaded through `PackedScene`.
- Constants-only modules are a valid exception; prefer referring to them by `class_name` instead of preloading the constants file into every consumer.
- For project-owned script references without `class_name`, prefer a local named script preload constant near the top of the file.
- Keep `preload` for `PackedScene` resources and other assets where loading the resource itself is the goal.
- Instantiate scenes with `.instantiate()`, not `.new()`.

## GDScript Organization

- Order project-owned `.gd` files like this when feasible: `class_name` when used, `extends`, doc comment, signals, enums, constants, static variables, exported fields, regular fields, onready fields, static init, static methods, built-in lifecycle methods, custom overridden methods, remaining methods, inner classes.
- Add section comments for the active parts of the file, grouped by visibility where appropriate, using labels such as `# Public Fields`, `# Private Fields`, `# Public Fields: Export`, `# Private Fields: Export`, `# Public Fields: OnReady`, `# Private Fields: OnReady`, `# Lifecycle Methods`, `# Event Handlers`, `# Public Static Methods`, and `# Private Methods`.
- Do not treat `@export` or other Godot field attributes as a reason to widen visibility. Exported fields should follow the same public/private rules as any other field.
- Put event-handler methods in a dedicated `# Event Handlers` section immediately after the lifecycle-methods section when the file has any event handlers.
- Add a `##` doc comment above each method you add or change. Backfill older untouched methods only when you are already modifying them for another reason.
- Default to typed classes, including small inner classes when appropriate, instead of project-owned dictionaries; only use dictionaries when the tradeoff is appropriate.
- When using inner classes in GDScript, place them at the bottom of the file after the file's non-inner-class fields and methods.
- Add a `##` doc comment directly below each inner class `extends` line, and keep the same spacing/readability rules inside inner classes that the file uses elsewhere.
- Never leave a project-owned variable, method argument, or method return type untyped.
- Prefer inferred typing where it keeps the code clear, and when inference is not sufficient, add an explicit type annotation.
- Format ternaries like this when they span multiple lines: `var value := result \` on the first line, `    if condition \` on the second line, and `    else fallback` on the third line.
- Leave a blank line between `extends` and the doc comment, between the doc comment and the next code or section comment, and between each section comment and the code that follows it.
- When a file uses `class_name`, keep it on the first relevant line and `extends` on the next line.
- Use visibility prefixes consistently for project-owned symbols when feasible: public has no prefix, protected uses a single leading underscore, and private uses a double leading underscore.
- Do not rename Godot built-in virtual callbacks like `_ready()`, `_draw()`, or `_physics_process()` to match the private prefix rule; keep the engine-required names intact.
- Keep lines at 120 characters or fewer when feasible.

## Shared Standards Reference

For shared Godot and GDScript implementation and review standards, see
`Docs/Standards/GDSCRIPT_STANDARDS.md`.
