class_name RunSceneTuning
extends RefCounted

## Centralizes scene-local tuning constants shared between RunScene and its extracted FSM states.


# Constants

const STEER_ACTION_NEGATIVE := "steer_left"
const STEER_ACTION_POSITIVE := "steer_right"
const STEER_SPEED := 180.0
const ROAD_HALF_WIDTH := 104.0

const WHEEL_LOOSE_STEER_MULTIPLIER := 0.6
const WHEEL_LOOSE_DRIFT_SPEED := 32.0
const WHEEL_LOOSE_DRIFT_FREQUENCY := 8.0

const HORSE_PANIC_STEER_MULTIPLIER := 0.3
const HORSE_PANIC_DRIFT_SPEED := 150.0
const HORSE_PANIC_DRIFT_FREQUENCY := 5.0

const POST_FAILURE_STEER_MULTIPLIER := 0.75
const POST_FAILURE_DRIFT_SPEED := 55.0
const POST_FAILURE_DRIFT_FREQUENCY := 6.0

