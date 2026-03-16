# Last Delivery to Dust Gulch

## Overview

`Last Delivery to Dust Gulch` is a 2D top-down western stagecoach survival runner built for `Mini Jam 206: Western`.

The game is designed around the jam limitation `Everything going wrong`.

The player must drive a stagecoach through a dangerous desert route and reach Dust Gulch before the wagon, horses, or cargo completely fall apart. The main gameplay is not combat. The core tension comes from avoiding hazards, surviving bad luck, and rapidly recovering from cascading wagon failures.

This MVP is intentionally scoped for a solo developer working in a 72-hour jam, with sourced pixel art and audio where possible.

## Jam Fit

- Theme: `Western`
- Required limitation: `Everything going wrong`
- Jam structure: `72-hour jam`

This concept fits the jam because the player is constantly reacting to failures:

- wheels come loose
- cargo spills
- horses panic
- the wagon jams
- the road becomes more dangerous over time

The western theme is expressed through the stagecoach fantasy, desert route, frontier hazards, signage, and overall art direction.

## High-Level Pitch

You are a stagecoach driver making one desperate final delivery to Dust Gulch. The road is bad, the wagon is fragile, and every problem creates another one. Dodge hazards, recover from breakdowns, keep the team moving, and limp into town with as much cargo and dignity left as possible.

## MVP Pillars

1. Readable top-down wagon driving
2. Constant pressure from hazards
3. Short emergency recovery actions when things go wrong
4. Strong western flavor with low asset overhead
5. Polished, finishable solo jam scope

## Core Game Loop

1. Start a delivery run.
2. Drive along a scrolling desert road toward Dust Gulch.
3. Dodge hazards such as potholes, rocks, tumbleweeds, livestock, and debris.
4. Take damage or trigger a failure when the wagon hits hazards or scripted bad-luck events occur.
5. Complete a short recovery sequence to get moving again.
6. Repeat until the player reaches Dust Gulch or the wagon collapses.

## Player Experience

The game should feel tense, readable, and a little chaotic. The player is not meant to feel fully in control. The fun comes from improvising under pressure and barely holding the run together.

The intended emotional arc is:

- stable early driving
- first signs of trouble
- compounding failures
- frantic recoveries
- desperate final stretch
- either a messy success or total breakdown

## Camera and Controls

### Camera

- 2D top-down camera
- wagon sits slightly below center on screen
- road scrolls toward the player
- light screen shake and dust effects help sell motion and impact

### Controls

- `Left / Right` or `A / D` to steer
- optional `Up / Down` or `W / S` for acceleration and braking only if it remains simple
- recovery sequences use short directional or button prompts

Controls must remain arcade-simple. If acceleration/braking makes the game worse, cut it and keep only steering plus recovery inputs.

## Core Systems

### Driving

The wagon moves along a top-down route while the player steers around hazards. The default state of the game should always be readable and responsive.

Driving should support:

- lane shifting or smooth lateral movement
- hazard avoidance
- collision feedback
- speed pressure

### Hazards

Hazards are the main source of moment-to-moment tension.

Initial hazard set:

- potholes
- rocks
- tumbleweeds
- cacti or roadside debris
- livestock crossing the road

Hazards should be visually exaggerated for readability. Each one should be understandable at a glance.

### Failures

Failures are the main expression of `Everything going wrong`.

MVP failure types:

- `Wheel Loose`
- `Horse Panic`
- `Cargo Spill`
- `Axle Jam`

Only one failure should be active at a time in the MVP.

### Recovery Sequences

Recovery sequences are brief emergency actions, not hard fail QTE traps.

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

## Run Structure

The MVP should use a single short stage with a clear destination rather than an endless mode.

Recommended run length:

- `1 to 3 minutes`

Run flow:

1. Start on the route out in the desert.
2. Survive a ramping sequence of hazards and failures.
3. Reach Dust Gulch for success.
4. Show a simple results screen.

This is better for a jam than endless survival because it creates a clear win state, makes balancing easier, and gives the game a stronger sense of completion.

## Progression and Difficulty

Difficulty should escalate over the course of a single run.

Escalation methods:

- hazards become more frequent
- hazard combinations become meaner
- failures occur closer together
- visibility pressure or path tightness increases slightly

Avoid adding multiple complex difficulty systems. The game only needs enough escalation to support a short, satisfying run.

## Win and Loss Conditions

### Win

- reach Dust Gulch before total collapse

### Lose

- wagon health reaches zero
- cargo or wagon state crosses a critical failure threshold
- optionally, horse condition fully breaks down if this is represented in MVP

Loss conditions should be simple and clearly communicated.

## Scoring

Scoring is optional but recommended if it stays light.

Simple scoring factors:

- cargo remaining
- wagon health remaining
- total delivery completion
- time bonus or cleanliness bonus

If scoring threatens scope, keep only a binary success/failure result with a few end-of-run stats.

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

Source as much as possible from Itch or similar libraries:

- environment tiles
- props
- hazard sprites
- UI frames if useful
- possibly wagon, horse, and animal sprites

Create only the custom glue assets needed for cohesion:

- HUD elements
- failure overlays
- route markers
- result screen elements

### Animation Priorities

Only animate what matters most:

- wagon movement
- wheel wobble or damage indication
- dust trails
- impact feedback
- horse panic state
- simple failure and recovery feedback

Avoid any feature that requires a large bespoke animation workload.

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

Music is optional. If included, keep it light and repetitive. Strong sound effects are more important than a complex soundtrack.

## Out of Scope for MVP

The following are intentionally excluded unless the game is already stable and polished:

- active combat
- bandit shootouts
- on-foot exploration
- branching routes
- upgrades or meta progression
- multiple levels
- narrative-heavy dialogue systems
- large inventory or survival systems

Bandits may appear only as flavor or simple environmental pressure if they can be added cheaply.

## Technical Shape

Recommended gameplay data concepts:

- `RunState`: distance remaining, wagon health, cargo value, current speed, active failure, result
- `HazardType`: pothole, rock, tumbleweed, livestock, debris
- `FailureType`: wheel_loose, horse_panic, cargo_spill, axle_jam
- `RecoverySequence`: input pattern, time limit, success effect, fail penalty
- `RoadChunkConfig`: hazard mix and intensity settings

These do not need to be overengineered. They exist to keep the game logic clean and make balancing easier.

## MVP Build Order

### Day 1

- implement wagon movement
- create scrolling road
- add 3 basic hazards
- add collisions and wagon health
- get a playable start-to-finish route working

### Day 2

- add failure system
- implement 2 to 4 recovery sequences
- tune pacing and hazard density
- add end-of-run success/failure screens

### Day 3

- add juice and polish
- improve feedback, particles, and sound
- tighten art cohesion
- rebalance run length and fairness
- package and submit

## Acceptance Criteria

The MVP is complete when:

- the player can start a run and reach Dust Gulch
- hazards are readable and avoidable
- at least 3 distinct hazard types are present
- at least 2 distinct failure types are implemented
- at least 2 recovery sequences are playable
- success and failure states are clearly shown
- the full run is fun, readable, and completable in 1 to 3 minutes

## Final Recommendation

This concept was selected because it gives the best chance of a finished, polished solo jam submission while still strongly expressing the western theme and the `Everything going wrong` limitation.

If extra time remains after the MVP is stable, the best upgrade path is:

1. add more failure types
2. improve visual/audio polish
3. add lightweight scoring and replayability

Do not add combat unless the rest of the game is already finished and solid.

## Post-Jam Art Direction

The MVP shipped with procedurally drawn placeholder visuals (Polygon2D shapes). The post-jam goal is a full pixel art pass replacing all placeholder geometry with proper sprites.

### Target Resolution

**640×360** — the standard low-resolution 16:9 pixel art canvas for 32×32 tile games.

- Scales 2× to 1280×720 and 3× to 1920×1080 cleanly
- Replaces the jam viewport of 1152×648 entirely
- Godot project settings: viewport 640×360, stretch mode `viewport`, stretch aspect `keep`, nearest-neighbor texture filtering

### Tile Grid

**32×32 pixels per tile.**

- Game canvas: 20 tiles wide × 11 tiles tall
- All art assets designed on the 32px grid
- Sprites scaled up via Godot's viewport scaling — no per-sprite scale overrides needed

### Approximate Tile Budgets

| Element | Size in tiles | Pixels |
|---|---|---|
| Wagon body | 1×2 | 32×64 |
| Horse pair | 2×3 | 32×48 (two 16×48 horses side by side) |
| Hazard (pothole) | 1×1 | 32×32 |
| Hazard (rock) | 1×1 | 32×32 |
| Tumbleweed | 1×1 | 32×32 |
| Road width (total) | ~6 tiles | ~192 px |
| Desert each side | ~7 tiles | ~224 px |

### What Needs Replacing

- **Wagon + horses** — Polygon2D → Sprite2D
- **Hazards** — Polygon2D → Sprite2D (pothole, rock, tumbleweed)
- **Road surface** — Polygon2D → tiled texture or scrolling sprite
- **Road edge stripes** — Polygon2D → baked into road tile or separate sprite
- **Desert background** — Polygon2D → tiled background texture
- **Scrub clusters** — procedural Polygon2D → sprite instances
- **Road signs** — procedural Polygon2D + Label → sprite

### Code Impact

All world-space constants in `run_scene.gd` will need to be set to correct values for the new 640×360 coordinate space. Read each constant and set it to what makes sense for the new canvas — do not mechanically scale old values. `WAGON_COLLISION_SIZE` should be set to the actual sprite footprint (32×64). Speed and scroll values should be tuned for feel at the new resolution.
