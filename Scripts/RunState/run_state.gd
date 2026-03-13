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
const DEFAULT_SPEED_RECOVERY_RATE := 40.0
const DEFAULT_ACTIVE_FAILURE := &""
const DEFAULT_LAST_HIT_HAZARD := &""
const DEFAULT_RESULT := RESULT_IN_PROGRESS
const DEFAULT_RECOVERY_SEQUENCE: Array[StringName] = []
const DEFAULT_RECOVERY_PROMPT_INDEX := -1
const DEFAULT_RECOVERY_TIME_REMAINING := 0.0
const DEFAULT_TEMPORARY_CONTROL_INSTABILITY_REMAINING := 0.0
const DEFAULT_LAST_RECOVERY_OUTCOME := &""
const DEFAULT_RECOVERY_OUTCOME_DISPLAY_REMAINING := 0.0
const DEFAULT_RECOVERY_COOLDOWN_REMAINING := 0.0

var route_distance: float = DEFAULT_ROUTE_DISTANCE
var distance_remaining: float = DEFAULT_DISTANCE_REMAINING
var wagon_health: int = DEFAULT_WAGON_HEALTH
var cargo_value: int = DEFAULT_CARGO_VALUE
var current_speed: float = DEFAULT_FORWARD_SPEED
var speed_recovery_rate: float = DEFAULT_SPEED_RECOVERY_RATE
var active_failure: StringName = DEFAULT_ACTIVE_FAILURE
var current_failure: FailureStateType
var recovery_sequence: Array[StringName] = DEFAULT_RECOVERY_SEQUENCE.duplicate()
var recovery_prompt_index: int = DEFAULT_RECOVERY_PROMPT_INDEX
var recovery_time_remaining: float = DEFAULT_RECOVERY_TIME_REMAINING
var temporary_control_instability_remaining: float = DEFAULT_TEMPORARY_CONTROL_INSTABILITY_REMAINING
var last_recovery_outcome: StringName = DEFAULT_LAST_RECOVERY_OUTCOME
var recovery_outcome_display_remaining: float = DEFAULT_RECOVERY_OUTCOME_DISPLAY_REMAINING
var recovery_cooldown_remaining: float = DEFAULT_RECOVERY_COOLDOWN_REMAINING
var result: StringName = DEFAULT_RESULT
var lateral_position: float = DEFAULT_LATERAL_POSITION
var last_hit_hazard: StringName = DEFAULT_LAST_HIT_HAZARD


func reset_for_new_run() -> void:
	distance_remaining = route_distance
	wagon_health = DEFAULT_WAGON_HEALTH
	cargo_value = DEFAULT_CARGO_VALUE
	current_speed = DEFAULT_FORWARD_SPEED
	speed_recovery_rate = DEFAULT_SPEED_RECOVERY_RATE
	active_failure = DEFAULT_ACTIVE_FAILURE
	current_failure = null
	recovery_sequence = DEFAULT_RECOVERY_SEQUENCE.duplicate()
	recovery_prompt_index = DEFAULT_RECOVERY_PROMPT_INDEX
	recovery_time_remaining = DEFAULT_RECOVERY_TIME_REMAINING
	temporary_control_instability_remaining = DEFAULT_TEMPORARY_CONTROL_INSTABILITY_REMAINING
	last_recovery_outcome = DEFAULT_LAST_RECOVERY_OUTCOME
	recovery_outcome_display_remaining = DEFAULT_RECOVERY_OUTCOME_DISPLAY_REMAINING
	recovery_cooldown_remaining = DEFAULT_RECOVERY_COOLDOWN_REMAINING
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
	if recovery_cooldown_remaining > 0.0:
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
	clear_recovery_sequence()


func start_recovery_sequence(sequence: Array[StringName], duration: float = 0.0) -> void:
	recovery_sequence = sequence.duplicate()
	recovery_prompt_index = 0 if not recovery_sequence.is_empty() else DEFAULT_RECOVERY_PROMPT_INDEX
	recovery_time_remaining = max(0.0, duration)


func has_active_recovery_sequence() -> bool:
	return recovery_prompt_index >= 0 and recovery_prompt_index < recovery_sequence.size()


func get_current_recovery_prompt() -> StringName:
	if not has_active_recovery_sequence():
		return &""

	return recovery_sequence[recovery_prompt_index]


func advance_recovery_sequence(input_action: StringName) -> bool:
	if not has_active_recovery_sequence():
		return false
	if input_action != get_current_recovery_prompt():
		return false

	recovery_prompt_index += 1
	if recovery_prompt_index >= recovery_sequence.size():
		clear_recovery_sequence()
		return true

	return false


func tick_recovery_sequence(delta: float) -> bool:
	if not has_active_recovery_sequence():
		return false
	if recovery_time_remaining <= 0.0:
		return false

	recovery_time_remaining = max(0.0, recovery_time_remaining - delta)
	return recovery_time_remaining == 0.0


func tick_temporary_control_instability(delta: float) -> void:
	temporary_control_instability_remaining = max(
		0.0,
		temporary_control_instability_remaining - delta
	)


func tick_recovery_transients(delta: float) -> void:
	recovery_outcome_display_remaining = max(0.0, recovery_outcome_display_remaining - delta)
	if recovery_outcome_display_remaining == 0.0 and last_recovery_outcome != DEFAULT_LAST_RECOVERY_OUTCOME:
		last_recovery_outcome = DEFAULT_LAST_RECOVERY_OUTCOME

	recovery_cooldown_remaining = max(0.0, recovery_cooldown_remaining - delta)


func recover_speed(delta: float) -> void:
	if current_speed >= DEFAULT_FORWARD_SPEED:
		return

	current_speed = min(DEFAULT_FORWARD_SPEED, current_speed + (speed_recovery_rate * max(0.0, delta)))


func has_temporary_control_instability() -> bool:
	return temporary_control_instability_remaining > 0.0


func resolve_recovery_success() -> void:
	last_recovery_outcome = &"success"
	recovery_outcome_display_remaining = 1.25
	recovery_cooldown_remaining = 0.75
	clear_failure()


func apply_recovery_failure_penalty(
	health_loss: int,
	cargo_loss: int,
	speed_loss: float,
	instability_duration: float
) -> void:
	wagon_health = max(0, wagon_health - max(0, health_loss))
	cargo_value = max(0, cargo_value - max(0, cargo_loss))
	current_speed = max(0.0, current_speed - max(0.0, speed_loss))
	temporary_control_instability_remaining = max(
		temporary_control_instability_remaining,
		max(0.0, instability_duration)
	)
	last_recovery_outcome = &"failure"
	recovery_outcome_display_remaining = 1.5
	recovery_cooldown_remaining = max(1.0, instability_duration * 0.5)
	clear_failure()


func clear_recovery_sequence() -> void:
	recovery_sequence = DEFAULT_RECOVERY_SEQUENCE.duplicate()
	recovery_prompt_index = DEFAULT_RECOVERY_PROMPT_INDEX
	recovery_time_remaining = DEFAULT_RECOVERY_TIME_REMAINING
