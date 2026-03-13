extends RefCounted
class_name RunState

const FailureStateType := preload("res://Scripts/Failures/failure_state.gd")

const RESULT_IN_PROGRESS := &"in_progress"
const RESULT_SUCCESS := &"success"
const RESULT_COLLAPSED := &"collapsed"

const DEFAULT_ROUTE_DISTANCE := 500.0
const DEFAULT_DISTANCE_REMAINING := DEFAULT_ROUTE_DISTANCE
const DEFAULT_WAGON_HEALTH := 100
const DEFAULT_CARGO_VALUE := 100
const DEFAULT_LATERAL_POSITION := 0.0
const DEFAULT_FORWARD_SPEED := 280.0
const DEFAULT_ACTIVE_FAILURE := &""
const DEFAULT_LAST_HIT_HAZARD := &""
const DEFAULT_RESULT := RESULT_IN_PROGRESS

var route_distance: float = DEFAULT_ROUTE_DISTANCE
var distance_remaining: float = DEFAULT_DISTANCE_REMAINING
var wagon_health: int = DEFAULT_WAGON_HEALTH
var cargo_value: int = DEFAULT_CARGO_VALUE
var current_speed: float = DEFAULT_FORWARD_SPEED
var active_failure: StringName = DEFAULT_ACTIVE_FAILURE
var current_failure: FailureStateType
var result: StringName = DEFAULT_RESULT
var lateral_position: float = DEFAULT_LATERAL_POSITION
var last_hit_hazard: StringName = DEFAULT_LAST_HIT_HAZARD


func reset_for_new_run() -> void:
	distance_remaining = route_distance
	wagon_health = DEFAULT_WAGON_HEALTH
	cargo_value = DEFAULT_CARGO_VALUE
	current_speed = DEFAULT_FORWARD_SPEED
	active_failure = DEFAULT_ACTIVE_FAILURE
	current_failure = null
	result = DEFAULT_RESULT
	lateral_position = DEFAULT_LATERAL_POSITION
	last_hit_hazard = DEFAULT_LAST_HIT_HAZARD


func get_distance_traveled() -> float:
	return route_distance - distance_remaining


func get_delivery_progress_ratio() -> float:
	if route_distance <= 0.0:
		return 1.0

	return clamp(get_distance_traveled() / route_distance, 0.0, 1.0)


func configure_route_distance(value: float) -> void:
	route_distance = max(1.0, value)
	distance_remaining = route_distance


func has_active_failure() -> bool:
	return current_failure != null and active_failure != DEFAULT_ACTIVE_FAILURE


func can_start_failure(failure_type: StringName) -> bool:
	if failure_type == DEFAULT_ACTIVE_FAILURE:
		return false

	return not has_active_failure()


func start_failure(failure_type: StringName, source_hazard: StringName = &"") -> bool:
	if not can_start_failure(failure_type):
		return false

	active_failure = failure_type
	current_failure = FailureStateType.new(
		failure_type,
		source_hazard,
		get_delivery_progress_ratio(),
	)
	return true


func tick_failure(delta: float) -> void:
	if current_failure == null:
		return

	current_failure.elapsed_time += delta


func clear_failure() -> void:
	active_failure = DEFAULT_ACTIVE_FAILURE
	current_failure = null
