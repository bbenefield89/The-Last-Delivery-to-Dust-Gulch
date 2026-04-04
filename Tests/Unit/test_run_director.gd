extends GutTest

# Constants

const RecoverySequenceGeneratorType := preload(ProjectPaths.RECOVERY_SEQUENCE_GENERATOR_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)

# Private Methods




## Binds a fresh run state to one director and moves it to the supplied route progress.
func _bind_director_at_progress(progress_ratio: float) -> Array[Variant]:
	var director = RunDirectorType.new()
	var run_state := RunStateType.new()
	var generator := RecoverySequenceGeneratorType.new()
	run_state.distance_remaining = run_state.route_distance * (1.0 - progress_ratio)
	director.bind_run_state(run_state, generator)
	return [director, run_state, generator]
# Public Methods

# Public Methods



## Verifies authored route phases still transition with the same callout behavior after extraction.

func test_sync_route_phase_when_progress_crosses_into_first_trouble_then_callout_and_interval_update() -> void:
	var bound_values := _bind_director_at_progress(0.19)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	assert_eq(director.route_phase, RunDirectorType.ROUTE_PHASE_WARM_UP)
	assert_eq(director.scheduled_bad_luck_interval, 0.0)

	director.bad_luck_rng.seed = 7
	run_state.distance_remaining = run_state.route_distance * 0.79
	var update: Variant = director.sync_route_phase()

	assert_eq(director.route_phase, RunDirectorType.ROUTE_PHASE_FIRST_TROUBLE)
	assert_eq(update.phase_callout_text, "First Trouble")
	assert_true(director.scheduled_bad_luck_interval >= RunDirectorType.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN)
	assert_true(director.scheduled_bad_luck_interval <= RunDirectorType.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX)


## Verifies the final stretch still disables timer bad luck and clears any armed timer state.

func test_advance_when_progress_enters_final_stretch_then_bad_luck_is_disabled() -> void:
	var bound_values := _bind_director_at_progress(0.879)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	director.bad_luck_rng.seed = 23
	director.sync_route_phase()

	assert_eq(director.route_phase, RunDirectorType.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_true(director.is_bad_luck_timer_enabled())
	assert_true(director.scheduled_bad_luck_interval > 0.0)

	run_state.distance_remaining = run_state.route_distance * 0.12
	var update: Variant = director.advance(0.0)

	assert_eq(update.phase_callout_text, "FINAL STRETCH")
	assert_eq(director.route_phase, RunDirectorType.ROUTE_PHASE_FINAL_STRETCH)
	assert_false(director.is_bad_luck_timer_enabled())
	assert_eq(director.scheduled_bad_luck_interval, 0.0)
	assert_eq(director.bad_luck_elapsed, 0.0)
	assert_false(director.pending_bad_luck_trigger)


## Verifies hazard failure handoff still maps rock pressure to wheel-loose failures.

func test_attempt_failure_trigger_from_collision_when_rock_then_wheel_loose_starts_and_reschedules_bad_luck() -> void:
	var bound_values := _bind_director_at_progress(0.30)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	director.bad_luck_rng.seed = 5
	director.bad_luck_elapsed = 4.0
	director.pending_bad_luck_trigger = true
	director.scheduled_bad_luck_interval = 99.0

	var started: bool = director.attempt_failure_trigger_from_collision(&"rock")

	assert_true(started)
	assert_eq(run_state.active_failure, &"wheel_loose")
	assert_eq(run_state.current_failure.source_hazard, &"rock")
	assert_eq(director.bad_luck_elapsed, 0.0)
	assert_false(director.pending_bad_luck_trigger)
	assert_true(director.scheduled_bad_luck_interval >= RunDirectorType.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN)
	assert_true(director.scheduled_bad_luck_interval <= RunDirectorType.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX)


## Verifies timer bad luck still waits as pending when another failure is already active.

func test_advance_when_bad_luck_timer_elapses_during_active_failure_then_pending_trigger_arms() -> void:
	var bound_values := _bind_director_at_progress(0.30)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	run_state.start_failure(&"wheel_loose", &"rock")
	director.scheduled_bad_luck_interval = 0.2
	director.bad_luck_elapsed = 0.0

	director.advance(0.2)

	assert_true(director.pending_bad_luck_trigger)
	assert_eq(director.bad_luck_elapsed, 0.0)
	assert_eq(run_state.active_failure, &"wheel_loose")


## Verifies a pending timer failure still starts as soon as the active failure clears.

func test_advance_when_pending_bad_luck_can_start_then_horse_panic_begins() -> void:
	var bound_values := _bind_director_at_progress(0.30)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	run_state.start_failure(&"wheel_loose", &"rock")
	director.scheduled_bad_luck_interval = 0.2
	director.advance(0.2)
	run_state.clear_failure()

	director.advance(0.1)

	assert_false(director.pending_bad_luck_trigger)
	assert_eq(director.bad_luck_elapsed, 0.0)
	assert_eq(run_state.active_failure, &"horse_panic")
	assert_eq(run_state.current_failure.source_hazard, &"bad_luck")


## Verifies perfect recovery completion still clears the failure and awards the authored bonus.

func test_handle_recovery_action_when_sequence_completed_perfectly_then_bonus_and_success_apply() -> void:
	var bound_values := _bind_director_at_progress(0.50)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	var generator := bound_values[2] as RecoverySequenceGeneratorType
	generator.set_seed(11)
	run_state.start_failure(&"wheel_loose", &"rock")
	director.advance(0.0)
	var recovery_sequence := run_state.recovery_sequence.duplicate()
	var final_result: Variant = null

	for action_name in recovery_sequence:
		final_result = director.handle_recovery_action(action_name)

	assert_not_null(final_result)
	assert_true(final_result.recovery_completed)
	assert_eq(final_result.bonus_callout_text, "PERFECT RECOVERY +100")
	assert_eq(run_state.active_failure, &"")
	assert_eq(run_state.perfect_recoveries, 1)
	assert_eq(run_state.last_recovery_outcome, &"success")


## Verifies recovery timeouts still apply the authored wheel-loose penalty package.

func test_advance_when_wheel_loose_recovery_times_out_then_authored_penalty_applies() -> void:
	var bound_values := _bind_director_at_progress(0.45)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	var generator := bound_values[2] as RecoverySequenceGeneratorType
	generator.set_seed(3)
	run_state.start_failure(&"wheel_loose", &"rock")
	director.advance(0.0)

	var update: Variant = director.advance(RunDirectorType.WHEEL_LOOSE_RECOVERY_DURATION)

	assert_true(update.recovery_penalty_applied)
	assert_eq(run_state.wagon_health, 90)
	assert_eq(run_state.cargo_value, 94)
	assert_eq(run_state.current_speed, 225.0)
	assert_eq(run_state.recovery_failures, 1)
	assert_eq(run_state.last_recovery_outcome, &"failure")
	assert_eq(run_state.active_failure, &"")


## Verifies collapse still wins over success when both edge conditions happen together.

func test_advance_when_health_and_distance_both_hit_zero_then_collapse_wins() -> void:
	var bound_values := _bind_director_at_progress(1.0)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	run_state.wagon_health = 0
	run_state.distance_remaining = 0.0

	director.advance(0.0)

	assert_eq(run_state.result, RunStateType.RESULT_COLLAPSED)
	assert_eq(run_state.current_speed, 0.0)


## Verifies reaching the finish threshold arms the delayed success buffer instead of resolving success immediately.
func test_advance_when_finish_threshold_is_crossed_then_finish_crossed_is_marked_without_success() -> void:
	var bound_values := _bind_director_at_progress(1.0)
	var director = bound_values[0]
	var run_state := bound_values[1] as RunStateType
	run_state.distance_remaining = 0.0
	run_state.current_speed = 280.0

	director.advance(0.0)

	assert_true(run_state.has_crossed_finish_line)
	assert_eq(run_state.result, RunStateType.RESULT_IN_PROGRESS)
	assert_eq(run_state.current_speed, 280.0)
	assert_false(director.is_bad_luck_timer_enabled())
