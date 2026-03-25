extends RefCounted

## Owns the mutable gameplay state, scoring, failure flow, and persisted best-run data.

# Constants
const FailureStateType := preload(ProjectPaths.FAILURE_STATE_SCRIPT_PATH)



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
const DEFAULT_HAZARDS_DODGED := 0
const DEFAULT_NEAR_MISSES := 0
const DEFAULT_PERFECT_RECOVERIES := 0
const DEFAULT_RECOVERY_FAILURES := 0
const SCORE_COMPLETION_MAX := 1000
const SCORE_HEALTH_POINT_VALUE := 5
const SCORE_CARGO_POINT_VALUE := 5
const NEAR_MISS_BONUS_SCORE := 50
const PERFECT_RECOVERY_BONUS_SCORE := 100
const GRADE_S_MIN_SCORE := 1800
const GRADE_A_MIN_SCORE := 1500
const GRADE_B_MIN_SCORE := 1200
const GRADE_C_MIN_SCORE := 900
const GRADE_D_MIN_SCORE := 600
const BEST_RUN_SAVE_PATH := SavePaths.BEST_RUN_SAVE_PATH
const BEST_RUN_SECTION := "best_run"
const BEST_RUN_SCORE_KEY := "score"
const BEST_RUN_GRADE_KEY := "grade"


# Public Fields

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
var recovery_had_wrong_input: bool = false
var recovery_timed_out: bool = false
var temporary_control_instability_remaining: float = DEFAULT_TEMPORARY_CONTROL_INSTABILITY_REMAINING
var last_recovery_outcome: StringName = DEFAULT_LAST_RECOVERY_OUTCOME
var recovery_outcome_display_remaining: float = DEFAULT_RECOVERY_OUTCOME_DISPLAY_REMAINING
var recovery_cooldown_remaining: float = DEFAULT_RECOVERY_COOLDOWN_REMAINING
var result: StringName = DEFAULT_RESULT
var lateral_position: float = DEFAULT_LATERAL_POSITION
var last_hit_hazard: StringName = DEFAULT_LAST_HIT_HAZARD
var bonus_score: int = 0
var hazards_dodged: int = DEFAULT_HAZARDS_DODGED
var near_misses: int = DEFAULT_NEAR_MISSES
var perfect_recoveries: int = DEFAULT_PERFECT_RECOVERIES
var recovery_failures: int = DEFAULT_RECOVERY_FAILURES
var best_run: BestRunData = BestRunData.new()
var current_run_is_new_best: bool = false


# Public Methods

## Restores the active run-state values back to their clean new-run defaults.
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
	recovery_had_wrong_input = false
	recovery_timed_out = false
	temporary_control_instability_remaining = DEFAULT_TEMPORARY_CONTROL_INSTABILITY_REMAINING
	last_recovery_outcome = DEFAULT_LAST_RECOVERY_OUTCOME
	recovery_outcome_display_remaining = DEFAULT_RECOVERY_OUTCOME_DISPLAY_REMAINING
	recovery_cooldown_remaining = DEFAULT_RECOVERY_COOLDOWN_REMAINING
	result = DEFAULT_RESULT
	lateral_position = DEFAULT_LATERAL_POSITION
	last_hit_hazard = DEFAULT_LAST_HIT_HAZARD
	bonus_score = 0
	hazards_dodged = DEFAULT_HAZARDS_DODGED
	near_misses = DEFAULT_NEAR_MISSES
	perfect_recoveries = DEFAULT_PERFECT_RECOVERIES
	recovery_failures = DEFAULT_RECOVERY_FAILURES
	current_run_is_new_best = false


## Returns the route distance already completed in the current run.
func get_distance_traveled() -> float:
	return route_distance - distance_remaining


## Returns the normalized route progress ratio for the current run.
func get_delivery_progress_ratio() -> float:
	if route_distance <= 0.0:
		return 1.0

	return clamp(get_distance_traveled() / route_distance, 0.0, 1.0)


## Returns the score contribution earned from route completion progress.
func get_completion_score() -> int:
	return int(round(get_delivery_progress_ratio() * float(SCORE_COMPLETION_MAX)))


## Returns the score contribution earned from remaining wagon health.
func get_health_score() -> int:
	return max(0, wagon_health) * SCORE_HEALTH_POINT_VALUE


## Returns the score contribution earned from remaining cargo value.
func get_cargo_score() -> int:
	return max(0, cargo_value) * SCORE_CARGO_POINT_VALUE


## Returns the deterministic end-of-run score based on current delivery stats.
func get_score() -> int:
	return get_completion_score() + get_health_score() + get_cargo_score() + bonus_score


## Awards one near-miss bonus into the shared run score bucket.
func award_near_miss_bonus() -> void:
	near_misses += 1
	bonus_score += NEAR_MISS_BONUS_SCORE


## Awards one perfect-recovery bonus into the shared run score bucket.
func award_perfect_recovery_bonus() -> void:
	perfect_recoveries += 1
	bonus_score += PERFECT_RECOVERY_BONUS_SCORE


## Records one hazard as successfully dodged after it fully passes the wagon.
func record_hazard_dodged() -> void:
	hazards_dodged += 1


## Returns the delivery grade that corresponds to the current run score.
func get_delivery_grade() -> String:
	var score := get_score()
	if score >= GRADE_S_MIN_SCORE:
		return "S"
	if score >= GRADE_A_MIN_SCORE:
		return "A"
	if score >= GRADE_B_MIN_SCORE:
		return "B"
	if score >= GRADE_C_MIN_SCORE:
		return "C"
	if score >= GRADE_D_MIN_SCORE:
		return "D"
	return "F"


## Loads the persisted best-run snapshot into this run-state instance for later result comparison.
func load_persisted_best_run(save_path: String = BEST_RUN_SAVE_PATH) -> void:
	best_run = load_best_run(save_path)


## Finalizes best-run comparison for a completed run and persists only a strictly higher score.
func record_best_run_if_needed(save_path: String = BEST_RUN_SAVE_PATH) -> bool:
	current_run_is_new_best = false
	if result == RESULT_IN_PROGRESS:
		return false

	if not best_run.has_value:
		best_run = load_best_run(save_path)
	var current_score := get_score()
	if best_run.has_value and current_score <= best_run.score:
		return false

	best_run = BestRunData.new(current_score, get_delivery_grade(), true)
	current_run_is_new_best = save_best_run(best_run, save_path) == OK
	if not current_run_is_new_best:
		best_run = load_best_run(save_path)
	return current_run_is_new_best


## Sets the authored route distance and resets the remaining distance to match it.
func configure_route_distance(value: float) -> void:
	route_distance = max(1.0, value)
	distance_remaining = route_distance


## Returns whether a failure is currently active for the run.
func has_active_failure() -> bool:
	return current_failure != null and active_failure != DEFAULT_ACTIVE_FAILURE


## Returns whether the requested failure is currently allowed to begin.
func can_start_failure(failure_type: StringName) -> bool:
	if failure_type == DEFAULT_ACTIVE_FAILURE:
		return false
	if recovery_cooldown_remaining > 0.0:
		return false

	return not has_active_failure()


## Starts a new active failure when the run can accept one.
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


## Advances the active failure timer while a failure is present.
func tick_failure(delta: float) -> void:
	if current_failure == null:
		return

	current_failure.elapsed_time += delta


## Clears the active failure and any attached recovery sequence state.
func clear_failure() -> void:
	active_failure = DEFAULT_ACTIVE_FAILURE
	current_failure = null
	clear_recovery_sequence()


## Starts a new recovery sequence and resets its transient progress flags.
func start_recovery_sequence(sequence: Array[StringName], duration: float = 0.0) -> void:
	recovery_sequence = sequence.duplicate()
	recovery_prompt_index = 0 if not recovery_sequence.is_empty() else DEFAULT_RECOVERY_PROMPT_INDEX
	recovery_time_remaining = max(0.0, duration)
	recovery_had_wrong_input = false
	recovery_timed_out = false


## Returns whether a recovery sequence is currently in progress.
func has_active_recovery_sequence() -> bool:
	return recovery_prompt_index >= 0 and recovery_prompt_index < recovery_sequence.size()


## Returns the current expected recovery prompt or an empty prompt when idle.
func get_current_recovery_prompt() -> StringName:
	if not has_active_recovery_sequence():
		return &""

	return recovery_sequence[recovery_prompt_index]


## Advances the recovery sequence when the provided input matches the next expected prompt.
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


## Marks the active recovery as imperfect after any wrong input attempt.
func record_recovery_wrong_input() -> void:
	recovery_had_wrong_input = true


## Marks the active recovery as imperfect after it expires on time.
func record_recovery_timeout() -> void:
	recovery_timed_out = true


## Returns whether the current recovery remained clean enough to award the perfect bonus.
func is_current_recovery_perfect() -> bool:
	return not recovery_had_wrong_input and not recovery_timed_out


## Counts down the active recovery timer and reports whether it expired this tick.
func tick_recovery_sequence(delta: float) -> bool:
	if not has_active_recovery_sequence():
		return false
	if recovery_time_remaining <= 0.0:
		return false

	recovery_time_remaining = max(0.0, recovery_time_remaining - delta)
	return recovery_time_remaining == 0.0


## Counts down temporary control instability after a failed recovery.
func tick_temporary_control_instability(delta: float) -> void:
	temporary_control_instability_remaining = max(
		0.0,
		temporary_control_instability_remaining - delta
	)


## Counts down short-lived recovery outcome and cooldown timers.
func tick_recovery_transients(delta: float) -> void:
	recovery_outcome_display_remaining = max(0.0, recovery_outcome_display_remaining - delta)
	if recovery_outcome_display_remaining == 0.0 and last_recovery_outcome != DEFAULT_LAST_RECOVERY_OUTCOME:
		last_recovery_outcome = DEFAULT_LAST_RECOVERY_OUTCOME

	recovery_cooldown_remaining = max(0.0, recovery_cooldown_remaining - delta)


## Restores forward speed toward the default run speed over time.
func recover_speed(delta: float) -> void:
	if current_speed >= DEFAULT_FORWARD_SPEED:
		return

	current_speed = min(DEFAULT_FORWARD_SPEED, current_speed + (speed_recovery_rate * max(0.0, delta)))


## Returns whether post-failure control instability is still active.
func has_temporary_control_instability() -> bool:
	return temporary_control_instability_remaining > 0.0


## Resolves the current recovery as a success and starts the short cooldown window.
func resolve_recovery_success() -> void:
	last_recovery_outcome = &"success"
	recovery_outcome_display_remaining = 1.25
	recovery_cooldown_remaining = 0.75
	clear_failure()


## Applies the configured failed-recovery penalties and clears the active failure flow.
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
	recovery_failures += 1
	last_recovery_outcome = &"failure"
	recovery_outcome_display_remaining = 1.5
	recovery_cooldown_remaining = max(1.0, instability_duration * 0.5)
	clear_failure()


## Clears the active recovery sequence and its prompt-tracking values.
func clear_recovery_sequence() -> void:
	recovery_sequence = DEFAULT_RECOVERY_SEQUENCE.duplicate()
	recovery_prompt_index = DEFAULT_RECOVERY_PROMPT_INDEX
	recovery_time_remaining = DEFAULT_RECOVERY_TIME_REMAINING


# Public Static Methods

## Saves the current best-run snapshot to the local user data path.
static func save_best_run(best_run: BestRunData, save_path: String = BEST_RUN_SAVE_PATH) -> int:
	if best_run == null or not best_run.has_value:
		return ERR_INVALID_PARAMETER

	var config := ConfigFile.new()
	config.set_value(BEST_RUN_SECTION, BEST_RUN_SCORE_KEY, best_run.score)
	config.set_value(BEST_RUN_SECTION, BEST_RUN_GRADE_KEY, best_run.grade)
	return config.save(save_path)


## Loads the stored best-run snapshot from the local user data path when available.
static func load_best_run(save_path: String = BEST_RUN_SAVE_PATH) -> BestRunData:
	if not FileAccess.file_exists(save_path):
		return BestRunData.new()

	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return BestRunData.new()
	if not config.has_section_key(BEST_RUN_SECTION, BEST_RUN_SCORE_KEY):
		return BestRunData.new()
	if not config.has_section_key(BEST_RUN_SECTION, BEST_RUN_GRADE_KEY):
		return BestRunData.new()

	var score_value: Variant = config.get_value(BEST_RUN_SECTION, BEST_RUN_SCORE_KEY)
	var grade_value: Variant = config.get_value(BEST_RUN_SECTION, BEST_RUN_GRADE_KEY)
	if typeof(score_value) != TYPE_INT or typeof(grade_value) != TYPE_STRING:
		return BestRunData.new()

	return BestRunData.new(score_value, grade_value, true)


# Inner Classes

class BestRunData:
	extends RefCounted
	## Stores the persistent local best-run summary that survives app relaunches.

	var score: int
	var grade: String
	var has_value: bool


	## Builds a typed best-run snapshot for save/load and later comparison logic.
	func _init(score_value: int = 0, grade_value: String = "", has_stored_value: bool = false) -> void:
		score = score_value
		grade = grade_value
		has_value = has_stored_value
