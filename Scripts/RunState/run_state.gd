extends RefCounted
class_name RunState

const DEFAULT_DISTANCE_REMAINING := 1000.0
const DEFAULT_WAGON_HEALTH := 100
const DEFAULT_LATERAL_POSITION := 0.0
const DEFAULT_FORWARD_SPEED := 280.0
const DEFAULT_LAST_HIT_HAZARD := &""

var distance_remaining: float = DEFAULT_DISTANCE_REMAINING
var wagon_health: int = DEFAULT_WAGON_HEALTH
var current_speed: float = DEFAULT_FORWARD_SPEED
var active_failure: StringName = &""
var result: StringName = &"in_progress"
var lateral_position: float = DEFAULT_LATERAL_POSITION
var last_hit_hazard: StringName = DEFAULT_LAST_HIT_HAZARD
