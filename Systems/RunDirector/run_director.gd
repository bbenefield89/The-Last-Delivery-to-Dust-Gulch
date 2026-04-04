extends RefCounted

## Owns route-phase pressure, failure and recovery rules, and win/loss adjudication for one run.

# Constants
const RecoverySequenceGeneratorType := preload(ProjectPaths.RECOVERY_SEQUENCE_GENERATOR_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


const ROUTE_PHASE_WARM_UP := &"warm_up"
const ROUTE_PHASE_FIRST_TROUBLE := &"first_trouble"
const ROUTE_PHASE_CROSSING_BEAT := &"crossing_beat"
const ROUTE_PHASE_CLUTTER_BEAT := &"clutter_beat"
const ROUTE_PHASE_RESET_BEFORE_FINALE := &"reset_before_finale"
const ROUTE_PHASE_FINAL_STRETCH := &"final_stretch"
const ROUTE_PHASE_WARM_UP_END := 0.20
const ROUTE_PHASE_FIRST_TROUBLE_END := 0.45
const ROUTE_PHASE_CROSSING_BEAT_END := 0.60
const ROUTE_PHASE_CLUTTER_BEAT_END := 0.80
const ROUTE_PHASE_RESET_BEFORE_FINALE_END := 0.88
const BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN := 12.0
const BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX := 14.0
const BAD_LUCK_INTERVAL_CROSSING_BEAT_MIN := 9.5
const BAD_LUCK_INTERVAL_CROSSING_BEAT_MAX := 11.5
const BAD_LUCK_INTERVAL_CLUTTER_BEAT_MIN := 7.5
const BAD_LUCK_INTERVAL_CLUTTER_BEAT_MAX := 9.0
const BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN := 11.5
const BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX := 13.5
const RECOVERY_PROMPT_POOL: Array[StringName] = [
	&"steer_left",
	&"steer_right",
]
const WHEEL_LOOSE_RECOVERY_DURATION := 3.1
const HORSE_PANIC_RECOVERY_DURATION := 3.7
const WHEEL_LOOSE_FAILURE_HEALTH_LOSS := 10
const WHEEL_LOOSE_FAILURE_CARGO_LOSS := 6
const WHEEL_LOOSE_FAILURE_SPEED_LOSS := 55.0
const WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION := 1.9
const HORSE_PANIC_FAILURE_CARGO_LOSS := 14
const HORSE_PANIC_FAILURE_SPEED_LOSS := 65.0
const HORSE_PANIC_FAILURE_INSTABILITY_DURATION := 2.2

# Public Fields

var bad_luck_elapsed := 0.0
var scheduled_bad_luck_interval := 0.0
var pending_bad_luck_trigger := false
var route_phase: StringName = &""
var route_phase_callout_zone: StringName = &""
var bad_luck_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Private Fields

var _run_state: RunStateType
var _recovery_sequence_generator: RecoverySequenceGeneratorType = RecoverySequenceGeneratorType.new()


# Public Methods

## Binds the active run state and resets director-owned transient rule timers.
func bind_run_state(
	run_state: RunStateType,
	recovery_sequence_generator: RecoverySequenceGeneratorType = null
) -> RunUpdate:
	_run_state = run_state
	if recovery_sequence_generator != null:
		_recovery_sequence_generator = recovery_sequence_generator
	bad_luck_elapsed = 0.0
	scheduled_bad_luck_interval = 0.0
	pending_bad_luck_trigger = false
	route_phase = &""
	route_phase_callout_zone = &""
	return sync_route_phase()


## Synchronizes route-phase state against the bound run progress and returns any emitted callout data.
func sync_route_phase() -> RunUpdate:
	var update := RunUpdate.new()
	if _run_state == null:
		return update

	var route_progress_ratio := _run_state.get_delivery_progress_ratio()
	var next_route_phase := get_route_phase_for_progress(route_progress_ratio)
	var next_route_phase_callout_zone := get_route_phase_callout_zone_for_progress(route_progress_ratio)
	var route_phase_changed := next_route_phase != route_phase
	var route_phase_callout_zone_changed := next_route_phase_callout_zone != route_phase_callout_zone
	if not route_phase_changed and not route_phase_callout_zone_changed:
		return update

	route_phase = next_route_phase
	var previous_route_phase_callout_zone := route_phase_callout_zone
	route_phase_callout_zone = next_route_phase_callout_zone
	if route_phase_changed:
		_handle_route_phase_change()
	if route_phase_callout_zone_changed and previous_route_phase_callout_zone != &"":
		update.phase_callout_text = get_route_phase_display_name(route_phase_callout_zone)

	return update


## Advances route pressure, recovery timers, and result checks for one gameplay frame.
func advance(delta: float) -> RunUpdate:
	var update := sync_route_phase()
	if _run_state == null:
		return update

	_run_state.tick_failure(delta)
	_run_state.tick_temporary_control_instability(delta)
	_run_state.tick_recovery_transients(delta)
	var had_active_recovery_sequence := _run_state.has_active_recovery_sequence()
	_sync_recovery_sequence()
	if had_active_recovery_sequence and _run_state.tick_recovery_sequence(delta):
		_run_state.record_recovery_timeout()
		apply_recovery_failure_penalty()
		update.recovery_penalty_applied = true
		_resolve_run_result()
		return update

	if not is_timer_bad_luck_enabled():
		bad_luck_elapsed = 0.0
		pending_bad_luck_trigger = false
		_resolve_run_result()
		return update

	if pending_bad_luck_trigger:
		if _run_state.can_start_failure(&"horse_panic"):
			start_failure_and_reschedule_bad_luck(&"horse_panic", &"bad_luck")
		_resolve_run_result()
		return update

	bad_luck_elapsed += delta
	if bad_luck_elapsed < scheduled_bad_luck_interval:
		_resolve_run_result()
		return update

	if not _run_state.can_start_failure(&"horse_panic"):
		bad_luck_elapsed = 0.0
		pending_bad_luck_trigger = true
		_resolve_run_result()
		return update

	start_failure_and_reschedule_bad_luck(&"horse_panic", &"bad_luck")
	_resolve_run_result()
	return update


## Attempts to translate one hazard hit into its failure type without owning collision resolution.
func attempt_failure_trigger_from_collision(hazard_type: StringName) -> bool:
	if _run_state == null or _run_state.has_active_failure():
		return false

	match hazard_type:
		&"rock", &"pothole":
			return start_failure_and_reschedule_bad_luck(&"wheel_loose", hazard_type)
		&"tumbleweed", &"livestock":
			return start_failure_and_reschedule_bad_luck(&"horse_panic", hazard_type)
		_:
			return false


## Applies one recovery input against the active sequence and reports the resulting rule outcome.
func handle_recovery_action(action_name: StringName) -> RecoveryActionResult:
	var result := RecoveryActionResult.new()
	if _run_state == null or not _run_state.has_active_recovery_sequence():
		return result
	if action_name == &"":
		return result

	var expected_action := _run_state.get_current_recovery_prompt()
	if action_name != expected_action:
		_run_state.record_recovery_wrong_input()
		result.was_wrong_input = true
		return result

	result.play_step_sound = true
	if _run_state.advance_recovery_sequence(action_name):
		if _run_state.is_current_recovery_perfect():
			_run_state.award_perfect_recovery_bonus()
			result.bonus_callout_text = "PERFECT RECOVERY +%d" % RunStateType.PERFECT_RECOVERY_BONUS_SCORE
		_run_state.resolve_recovery_success()
		result.recovery_completed = true
	else:
		result.step_advanced = true

	return result


## Applies the current failure's authored recovery penalty to the bound run state.
func apply_recovery_failure_penalty() -> void:
	if _run_state == null:
		return

	match _run_state.active_failure:
		&"wheel_loose":
			_run_state.apply_recovery_failure_penalty(
				WHEEL_LOOSE_FAILURE_HEALTH_LOSS,
				WHEEL_LOOSE_FAILURE_CARGO_LOSS,
				WHEEL_LOOSE_FAILURE_SPEED_LOSS,
				WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION
			)
		&"horse_panic":
			_run_state.apply_recovery_failure_penalty(
				0,
				HORSE_PANIC_FAILURE_CARGO_LOSS,
				HORSE_PANIC_FAILURE_SPEED_LOSS,
				HORSE_PANIC_FAILURE_INSTABILITY_DURATION
			)


## Returns whether the route is in a phase that should schedule timer-driven bad luck.
func is_timer_bad_luck_enabled() -> bool:
	if _run_state != null and _run_state.has_crossed_finish_line:
		return false

	return (
		route_phase != &""
		and route_phase != ROUTE_PHASE_WARM_UP
		and route_phase != ROUTE_PHASE_FINAL_STRETCH
	)


## Returns the authored bad-luck interval range for the supplied route progress ratio.
func get_bad_luck_interval_range(progress_ratio: float) -> Vector2:
	match get_route_phase_for_progress(progress_ratio):
		ROUTE_PHASE_FIRST_TROUBLE:
			return Vector2(BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN, BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX)
		ROUTE_PHASE_CROSSING_BEAT:
			return Vector2(BAD_LUCK_INTERVAL_CROSSING_BEAT_MIN, BAD_LUCK_INTERVAL_CROSSING_BEAT_MAX)
		ROUTE_PHASE_CLUTTER_BEAT:
			return Vector2(BAD_LUCK_INTERVAL_CLUTTER_BEAT_MIN, BAD_LUCK_INTERVAL_CLUTTER_BEAT_MAX)
		ROUTE_PHASE_RESET_BEFORE_FINALE:
			return Vector2(
				BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN,
				BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX
			)
		_:
			return Vector2.ZERO


## Rolls a fresh bad-luck interval from the current bound run progress.
func roll_bad_luck_interval() -> float:
	if not is_timer_bad_luck_enabled():
		return 0.0

	var progress_ratio := 0.0 if _run_state == null else _run_state.get_delivery_progress_ratio()
	var interval_range := get_bad_luck_interval_range(progress_ratio)
	return bad_luck_rng.randf_range(interval_range.x, interval_range.y)


## Schedules the next timer bad-luck interval for the current authored route phase.
func schedule_next_bad_luck_interval() -> void:
	if not is_timer_bad_luck_enabled():
		scheduled_bad_luck_interval = 0.0
		return

	scheduled_bad_luck_interval = roll_bad_luck_interval()


## Starts a failure and re-arms timer bad luck only when the failure actually begins.
func start_failure_and_reschedule_bad_luck(failure_type: StringName, source_hazard: StringName) -> bool:
	if _run_state == null:
		return false
	if not _run_state.start_failure(failure_type, source_hazard):
		return false

	bad_luck_elapsed = 0.0
	pending_bad_luck_trigger = false
	schedule_next_bad_luck_interval()
	return true


## Returns the authored route phase for one normalized delivery progress value.
static func get_route_phase_for_progress(progress_ratio: float) -> StringName:
	if progress_ratio < ROUTE_PHASE_WARM_UP_END:
		return ROUTE_PHASE_WARM_UP
	if progress_ratio < ROUTE_PHASE_FIRST_TROUBLE_END:
		return ROUTE_PHASE_FIRST_TROUBLE
	if progress_ratio < ROUTE_PHASE_CROSSING_BEAT_END:
		return ROUTE_PHASE_CROSSING_BEAT
	if progress_ratio < ROUTE_PHASE_CLUTTER_BEAT_END:
		return ROUTE_PHASE_CLUTTER_BEAT
	if progress_ratio < ROUTE_PHASE_RESET_BEFORE_FINALE_END:
		return ROUTE_PHASE_RESET_BEFORE_FINALE
	return ROUTE_PHASE_FINAL_STRETCH


## Returns the callout-zone identifier for one normalized delivery progress value.
static func get_route_phase_callout_zone_for_progress(progress_ratio: float) -> StringName:
	return get_route_phase_for_progress(progress_ratio)


## Returns the player-facing label for one authored route phase.
static func get_route_phase_display_name(active_route_phase: StringName) -> String:
	match active_route_phase:
		ROUTE_PHASE_WARM_UP:
			return "Warm-Up"
		ROUTE_PHASE_FIRST_TROUBLE:
			return "First Trouble"
		ROUTE_PHASE_CROSSING_BEAT:
			return "Crossing Beat"
		ROUTE_PHASE_CLUTTER_BEAT:
			return "Clutter Beat"
		ROUTE_PHASE_RESET_BEFORE_FINALE:
			return "Reset Before Finale"
		ROUTE_PHASE_FINAL_STRETCH:
			return "FINAL STRETCH"
		_:
			return "Route Phase"


## Applies phase-change side effects to timer bad-luck state when the authored band changes.
func _handle_route_phase_change() -> void:
	bad_luck_elapsed = 0.0
	pending_bad_luck_trigger = false
	if not is_timer_bad_luck_enabled():
		scheduled_bad_luck_interval = 0.0
		return

	schedule_next_bad_luck_interval()


## Ensures the active failure owns the expected generated recovery sequence and duration.
func _sync_recovery_sequence() -> void:
	if _run_state == null:
		return

	if _run_state.active_failure == &"wheel_loose":
		if not _run_state.has_active_recovery_sequence():
			_start_generated_recovery_sequence(WHEEL_LOOSE_RECOVERY_DURATION)
		return
	if _run_state.active_failure == &"horse_panic":
		if not _run_state.has_active_recovery_sequence():
			_start_generated_recovery_sequence(HORSE_PANIC_RECOVERY_DURATION)
		return

	if _run_state.has_active_recovery_sequence():
		_run_state.clear_recovery_sequence()


## Starts one authored generated recovery sequence using the shared prompt pool.
func _start_generated_recovery_sequence(duration: float) -> void:
	if _run_state == null:
		return

	var recovery_sequence := _recovery_sequence_generator.generate_sequence(
		_run_state.get_delivery_progress_ratio(),
		RECOVERY_PROMPT_POOL
	)
	_run_state.start_recovery_sequence(recovery_sequence, duration)


## Resolves collapse before success so simultaneous edge cases keep the current run-scene ordering.
func _resolve_run_result() -> void:
	if _run_state == null or _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	if _run_state.wagon_health <= 0:
		_run_state.wagon_health = 0
		_run_state.result = RunStateType.RESULT_COLLAPSED
		_run_state.current_speed = 0.0
		return
	if _run_state.distance_remaining > 0.0:
		return

	_run_state.distance_remaining = 0.0
	_run_state.has_crossed_finish_line = true


class RunUpdate:
	extends RefCounted
	## Carries one frame of director-authored side effects back to the scene coordinator.

	var phase_callout_text: String = ""
	var recovery_penalty_applied: bool = false


class RecoveryActionResult:
	extends RefCounted
	## Reports whether one recovery input advanced, completed, or failed the authored sequence.

	var was_wrong_input: bool = false
	var step_advanced: bool = false
	var recovery_completed: bool = false
	var play_step_sound: bool = false
	var bonus_callout_text: String = ""
