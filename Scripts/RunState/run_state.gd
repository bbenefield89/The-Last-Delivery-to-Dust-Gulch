extends RefCounted
class_name RunState

const DEFAULT_DISTANCE_REMAINING := 1000.0
const DEFAULT_WAGON_HEALTH := 100

var distance_remaining: float = DEFAULT_DISTANCE_REMAINING
var wagon_health: int = DEFAULT_WAGON_HEALTH
var current_speed: float = 0.0
var active_failure: StringName = &""
var result: StringName = &"in_progress"

