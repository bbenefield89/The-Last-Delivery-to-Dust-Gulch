# Last Delivery to Dust Gulch

## Overview

`Last Delivery to Dust Gulch` is a polished mobile-forward 2D top-down western stagecoach survival runner.

The player drives a fragile stagecoach through a dangerous desert route and tries to reach Dust Gulch before the wagon, horses, and cargo fall apart. The game is not about combat. Its core tension comes from readable hazard dodging, bad-luck pressure, and fast recovery from cascading wagon failures.

The release direction is a premium-feeling, replayable mobile game with short, finishable runs, strong atmosphere, and clear player-facing feedback.

## Product Direction

- Platform priority: mobile-first
- Session shape: short, finite delivery runs
- Core promise: survive the route, keep the wagon together, and limp into town
- Tone: tense, readable, dusty, a little chaotic
- Design philosophy: easy to read, quick to restart, hard to master

## High-Level Pitch

You are a stagecoach driver making one desperate delivery to Dust Gulch. The road is bad, the wagon is fragile, and every problem creates another one. Dodge hazards, recover from breakdowns, protect your cargo, and drag yourself across the finish line before the whole rig collapses.

## Release Pillars

1. Readable top-down driving that feels good on touch screens
2. Constant but fair pressure from hazards and bad luck
3. Recovery sequences that create panic without becoming frustrating QTE spam
4. Strong western identity through art, audio, and UI framing
5. Short runs with a clear arc, a clear ending, and immediate replay value

## Core Game Loop

1. Start a delivery run.
2. Drive along a scrolling desert road toward Dust Gulch.
3. Dodge hazards such as potholes, rocks, tumbleweeds, and livestock.
4. Take damage or trigger a failure when the wagon hits hazards or bad-luck events occur.
5. Complete a short recovery sequence to regain control and keep moving.
6. Reach Dust Gulch for success or collapse before the finish and try again.

## Player Experience

The game should feel tense, readable, and slightly out of control in a good way. The player is not meant to feel perfectly safe or perfectly precise. The fun comes from improvising under pressure and barely holding the run together.

The intended emotional arc is:

- stable early driving
- first signs of trouble
- compounding failures
- frantic recoveries
- desperate final stretch
- either a messy success or total breakdown

The final stretch should stay readable but not fully scripted. It should use a sharper late-run hazard profile with timed bad luck suspended, while still preserving enough RNG that repeated runs do not end on the exact same pattern.

## Platform and Session Goals

### Target Platforms

- primary: mobile
- secondary: desktop and web for testing, marketing, and optional release support

### Session Length

The primary mode should use finite delivery runs rather than endless survival.

Recommended timing:

- first-session failures: `45 to 75 seconds`
- typical failed runs: `45 to 90 seconds`
- successful runs: `90 to 150 seconds`
- absolute upper bound for the core mode: about `150 seconds`

The default experience should feel built for repeat play in short mobile sessions. Runs should end with a clear result, score, and reason to queue up another attempt immediately.

### Run Structure

1. Start on the route out in the desert.
2. Survive a ramping sequence of hazards and failures.
3. Reach Dust Gulch for success.
4. Show a concise results screen with score, grade, and notable stats.

On success, the run should include a short arrival beat before the results screen. Crossing the finish threshold should stop new gameplay pressure, but any live hazards already on screen may continue clearing in a brief final runoff. Once the hazard field is clear, player steering control should be removed and the wagon should travel north off the screen before the result summary appears.

Endless survival is not the primary mode. If an endless variant exists later, it should be treated as a separate challenge mode or a post-finish bonus stretch, not the default structure of the game.

## Camera and Controls

### Camera

- 2D top-down camera
- wagon sits slightly below center on screen
- road scrolls toward the player
- light screen shake and dust effects help sell motion and impact

### Controls

- desktop: `Left / Right` or `A / D` to steer
- mobile: left and right touch steering with a simple pause affordance
- recovery sequences use short directional or button prompts

Controls must remain arcade-simple. The game should be immediately understandable on a phone and should not depend on complex multi-button inputs.

## Core Systems

### Driving

The wagon moves along a top-down route while the player steers around hazards. The default state of the game should always be readable and responsive.

Driving should support:

- lane shifting or smooth lateral movement
- hazard avoidance
- collision feedback
- speed pressure
- touch-friendly readability

### Hazards

Hazards are the main source of moment-to-moment tension.

Initial hazard set:

- potholes
- rocks
- tumbleweeds
- livestock crossing the road

Hazards should be visually exaggerated for readability. Each one should be understandable at a glance on a mobile-sized screen.

### Failures

Failures are the main expression of "everything going wrong."

Planned failure types:

- `Wheel Loose`
- `Horse Panic`
- `Cargo Spill`
- `Axle Jam`

Only one failure should be active at a time unless the design intentionally expands beyond the current readability target.

### Recovery Sequences

Recovery sequences are brief emergency actions, not punishing QTE traps.

Goals for recovery sequences:

- create panic and variety
- briefly interrupt normal driving
- give the player something active to do
- cause penalties on failure, not instant death

Example implementations:

- `Wheel Loose`: directional input pattern to secure the wheel and resume movement
- `Horse Panic`: calming input sequence while steering becomes unstable
- `Cargo Spill`: rapid input sequence to secure cargo before more is lost
- `Axle Jam`: mash or alternating input to free the wagon

Recovery failures should cause:

- health loss
- speed loss
- cargo loss
- temporary control instability

They should not immediately end the run unless the wagon is already near collapse.

## Progression and Difficulty

Difficulty should escalate over the course of a single run.

Escalation methods:

- hazards become more frequent
- hazard combinations become meaner
- failures occur closer together
- path pressure tightens slightly

The game should rely on a clean authored run arc instead of stacking too many overlapping progression systems.

### Replay Motivation

Replayability should come from:

- better survival and routing
- stronger finish scores and grades
- improved cargo and health preservation
- more consistent recovery performance
- optional challenge content added later

## Win and Loss Conditions

### Win

- reach Dust Gulch before total collapse

### Lose

- wagon health reaches zero
- cargo or wagon state crosses a critical failure threshold if represented in the live rules

Loss conditions should be simple and clearly communicated.

## Scoring

Scoring is part of the shipped experience.

Core score factors:

- route completion
- wagon health remaining
- cargo value remaining
- bonus awards such as near misses and perfect recoveries

The game should also surface a delivery grade so the player gets a clean summary of run quality, not just raw points.

## UI Direction

The UI should prioritize readability over decoration.

Key qualities:

- readable at a glance under pressure
- western flavor through typography, color, and framing
- strong HUD hierarchy for health, cargo, and progress
- recovery overlays that feel urgent without obscuring prompts
- concise results presentation suited to mobile replay loops

Keep the center gameplay area clear. Push persistent HUD elements to the edges and corners. Any touch controls must stay legible without crowding the road.

## Art Direction

### Visual Direction

Use readable pixel art with a classic western desert palette:

- dusty tan roads
- red canyon accents
- faded wood signage
- dry brush and scrub
- strong wagon shadows

The goal is not realism. The goal is clarity and atmosphere.

### Asset Strategy

Use sourced assets where they fit the style and save production time, then create the minimum custom glue needed for cohesion:

- environment tiles
- hazard sprites
- wagon and horse presentation
- HUD elements
- failure overlays
- route markers
- results presentation

### Animation Priorities

Only animate what matters most:

- wagon movement
- horse motion
- dust trails
- impact feedback
- hazard crossing motion
- failure and recovery feedback

Avoid animation scope that does not materially improve readability or feel.

## Audio Direction

Audio should do a lot of the heavy lifting.

Priority sounds:

- hoofbeats
- wagon creaks
- wheel hits
- dust gusts
- warning stingers for failures
- cargo rattling
- animal noises

Music should support the western tone without overwhelming gameplay readability. Sound effects and clear state-change cues matter more than soundtrack complexity.

## Out of Scope

The following are intentionally excluded unless the release plan changes:

- active combat
- bandit shootouts as a major gameplay pillar
- on-foot exploration
- branching routes
- large inventory or survival systems
- narrative-heavy dialogue systems
- endless mode as the primary game mode

These can be reconsidered later, but they are not part of the current core release direction.

## Technical Shape

Recommended gameplay data concepts:

- `RunState`: distance remaining, wagon health, cargo value, current speed, active failure, result
- `HazardType`: pothole, rock, tumbleweed, livestock
- `FailureType`: wheel_loose, horse_panic, cargo_spill, axle_jam
- `RecoverySequence`: input pattern, time limit, success effect, fail penalty
- `RoadChunkConfig`: hazard mix and intensity settings

These should stay practical. The point is to keep logic understandable, testable, and tunable.

Repository ownership contract:

- Keep actual scenes under `Scenes/`.
- Keep each scene and its primary script as siblings in the owning scene folder.
- Keep reusable runtime owners under `Systems/<Owner>/`.
- If a system is node-backed, keep its scene and script as siblings in that owning system folder.
- If a system is a pure helper, it may contain only its `.gd` file in the owning system folder.
- Keep owner-specific support code and enums near the owner that uses them.
- Reserve top-level `Enums/` only for genuinely cross-cutting shared enums.
- Do not use a top-level `Scripts/` folder for active runtime code.

## Production Priorities

1. Make the primary delivery run fun, fair, and replayable on mobile.
2. Improve clarity, readability, and UX before expanding feature count.
3. Tighten hazard pacing, failure tuning, and recovery feel.
4. Finish the visual and audio cohesion pass.
5. Expand content only after the core run quality is consistently strong.

## Release Acceptance Criteria

The core game is ready for release candidate evaluation when:

- the player can start, complete, fail, and restart runs reliably
- the primary run loop feels good on mobile controls
- hazards are readable and avoidable on a mobile screen
- the intended failure and recovery systems are clear and fair
- success and failure states are clearly presented
- a complete run is fun, readable, and usually resolves inside `90 to 150 seconds`
- score, grade, and best-run persistence all work consistently

## Current Resolution and Art Production Target

### Target Resolution

**640x360** is the standard low-resolution 16:9 pixel-art canvas for the current production target.

- Scales cleanly to common desktop and capture sizes
- Supports readable 32x32 world art
- Keeps the playfield compact enough to reason about for touch-friendly layouts
- Godot project settings should use viewport scaling with nearest-neighbor texture filtering

### Tile Grid

**32x32 pixels per tile.**

- Game canvas: 20 tiles wide by 11 tiles tall
- All art assets designed on the 32px grid
- Sprites scaled up via viewport scaling rather than per-sprite scale hacks

### Approximate Tile Budgets

| Element | Size in tiles | Pixels |
|---|---|---|
| Wagon body | 1x2 | 32x64 |
| Horse pair | 2x3 | 32x48 |
| Hazard (pothole) | 1x1 | 32x32 |
| Hazard (rock) | 1x1 | 32x32 |
| Tumbleweed | 1x1 | 32x32 |
| Road width (total) | ~6 tiles | ~192 px |
| Desert each side | ~7 tiles | ~224 px |

### World Presentation Requirements

- Wagon and horses should use proper sprite presentation, not placeholder geometry
- Hazards should use readable sprite art and motion cues
- Road and desert should use textured world art rather than flat debug geometry
- Roadside dressing should support the setting without cluttering the play space
- Roadside dressing should be managed by a dedicated scenery system with distance-driven spawning, controlled RNG variation, and cleanup-based despawn rather than visibly recycled authored segments

### Code Impact

World-space constants in `run_scene.gd` should be tuned for the production camera and feel, not mechanically scaled from earlier placeholder values. Collision sizes should reflect real sprite footprints. Speed and scroll values should be tuned around gameplay readability and session pacing.
