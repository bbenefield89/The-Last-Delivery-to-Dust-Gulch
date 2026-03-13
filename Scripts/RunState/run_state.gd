extends RefCounted
class_name RunState

const RESULT_IN_PROGRESS := &"in_progress"
const RESULT_SUCCESS := &"success"
const RESULT_COLLAPSED := &"collapsed"

const DEFAULT_ROUTE_DISTANCE := 24000.0
const DEFAULT_DISTANCE_REMAINING := DEFAULT_ROUTE_DISTANCE
const DEFAULT_WAGON_HEALTH := 100
const DEFAULT_CARGO_VALUE := 100
const DEFAULT_LATERAL_POSITION := 0.0
const DEFAULT_FORWARD_SPEED := 280.0
const DEFAULT_ACTIVE_FAILURE := &""
const DEFAULT_LAST_HIT_HAZARD := &""
const DEFAULT_RESULT := RESULT_IN_PROGRESS

var distance_remaining: float = DEFAULT_DISTANCE_REMAINING
var wagon_health: int = DEFAULT_WAGON_HEALTH
var cargo_value: int = DEFAULT_CARGO_VALUE
var current_speed: float = DEFAULT_FORWARD_SPEED
var active_failure: StringName = DEFAULT_ACTIVE_FAILURE
var result: StringName = DEFAULT_RESULT
var lateral_position: float = DEFAULT_LATERAL_POSITION
var last_hit_hazard: StringName = DEFAULT_LAST_HIT_HAZARD


func reset_for_new_run() -> void:
	distance_remaining = DEFAULT_DISTANCE_REMAINING
	wagon_health = DEFAULT_WAGON_HEALTH
	cargo_value = DEFAULT_CARGO_VALUE
	current_speed = DEFAULT_FORWARD_SPEED
	active_failure = DEFAULT_ACTIVE_FAILURE
	result = DEFAULT_RESULT
	lateral_position = DEFAULT_LATERAL_POSITION
	last_hit_hazard = DEFAULT_LAST_HIT_HAZARD


func get_distance_traveled() -> float:
	return DEFAULT_ROUTE_DISTANCE - distance_remaining


func get_delivery_progress_ratio() -> float:
	if DEFAULT_ROUTE_DISTANCE <= 0.0:
		return 1.0

	return clamp(get_distance_traveled() / DEFAULT_ROUTE_DISTANCE, 0.0, 1.0)
