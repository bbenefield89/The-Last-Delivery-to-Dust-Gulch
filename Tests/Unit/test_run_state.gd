extends GutTest

const RunStateType := preload("res://Scripts/RunState/run_state.gd")


func test_defaults_match_expected_mvp_boot_values() -> void:
	var state := RunStateType.new()

	assert_eq(state.distance_remaining, RunStateType.DEFAULT_DISTANCE_REMAINING)
	assert_eq(state.route_distance, RunStateType.DEFAULT_ROUTE_DISTANCE)
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_eq(state.lateral_position, RunStateType.DEFAULT_LATERAL_POSITION)
	assert_eq(state.active_failure, RunStateType.DEFAULT_ACTIVE_FAILURE)
	assert_null(state.current_failure)
	assert_eq(state.last_hit_hazard, &"")
	assert_eq(state.result, RunStateType.DEFAULT_RESULT)


func test_reset_for_new_run_restores_all_core_run_values() -> void:
	var state := RunStateType.new()
	state.distance_remaining = 1200.0
	state.route_distance = 1600.0
	state.wagon_health = 18
	state.cargo_value = 42
	state.current_speed = 90.0
	state.active_failure = &"wheel_loose"
	state.result = RunStateType.RESULT_COLLAPSED
	state.lateral_position = -150.0
	state.last_hit_hazard = &"rock"

	state.reset_for_new_run()

	assert_eq(state.distance_remaining, 1600.0)
	assert_eq(state.route_distance, 1600.0)
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_eq(state.active_failure, RunStateType.DEFAULT_ACTIVE_FAILURE)
	assert_null(state.current_failure)
	assert_eq(state.result, RunStateType.DEFAULT_RESULT)
	assert_eq(state.lateral_position, RunStateType.DEFAULT_LATERAL_POSITION)
	assert_eq(state.last_hit_hazard, RunStateType.DEFAULT_LAST_HIT_HAZARD)


func test_delivery_progress_ratio_tracks_route_completion() -> void:
	var state := RunStateType.new()
	state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.25

	assert_eq(state.get_distance_traveled(), RunStateType.DEFAULT_ROUTE_DISTANCE * 0.75)
	assert_eq(state.get_delivery_progress_ratio(), 0.75)


func test_configure_route_distance_updates_starting_distance() -> void:
	var state := RunStateType.new()

	state.configure_route_distance(900.0)

	assert_eq(state.route_distance, 900.0)
	assert_eq(state.distance_remaining, 900.0)


func test_start_failure_creates_a_single_active_failure_record() -> void:
	var state := RunStateType.new()
	state.distance_remaining = 200.0

	var did_start := state.start_failure(&"wheel_loose", &"rock")

	assert_true(did_start)
	assert_true(state.has_active_failure())
	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.failure_type, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")
	assert_eq(state.current_failure.trigger_progress_ratio, 0.6)


func test_cannot_start_second_failure_until_current_failure_is_cleared() -> void:
	var state := RunStateType.new()

	assert_true(state.start_failure(&"wheel_loose", &"rock"))
	assert_false(state.start_failure(&"horse_panic", &"tumbleweed"))
	assert_eq(state.active_failure, &"wheel_loose")

	state.clear_failure()

	assert_true(state.start_failure(&"horse_panic", &"tumbleweed"))
	assert_eq(state.active_failure, &"horse_panic")


func test_tick_failure_increments_elapsed_time_for_active_failure() -> void:
	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")

	state.tick_failure(0.75)

	assert_eq(state.current_failure.elapsed_time, 0.75)


func test_recovery_sequence_tracks_prompt_progress_and_completion() -> void:
	var state := RunStateType.new()
	state.start_recovery_sequence([&"steer_left", &"steer_right"], 2.5)

	assert_true(state.has_active_recovery_sequence())
	assert_eq(state.get_current_recovery_prompt(), &"steer_left")
	assert_eq(state.recovery_time_remaining, 2.5)
	assert_false(state.advance_recovery_sequence(&"steer_right"))
	assert_eq(state.get_current_recovery_prompt(), &"steer_left")
	assert_false(state.advance_recovery_sequence(&"steer_left"))
	assert_eq(state.get_current_recovery_prompt(), &"steer_right")
	assert_true(state.advance_recovery_sequence(&"steer_right"))
	assert_false(state.has_active_recovery_sequence())


func test_recovery_sequence_timeout_counts_down_and_triggers_expiry() -> void:
	var state := RunStateType.new()
	state.start_recovery_sequence([&"steer_left"], 1.0)

	assert_false(state.tick_recovery_sequence(0.4))
	assert_eq(state.recovery_time_remaining, 0.6)
	assert_true(state.tick_recovery_sequence(0.7))
	assert_eq(state.recovery_time_remaining, 0.0)


func test_recovery_failure_penalty_applies_resource_losses_and_instability() -> void:
	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	state.start_recovery_sequence([&"steer_left"], 1.0)

	state.apply_recovery_failure_penalty(12, 18, 90.0, 2.5)

	assert_eq(state.wagon_health, 88)
	assert_eq(state.cargo_value, 82)
	assert_eq(state.current_speed, 190.0)
	assert_eq(state.last_recovery_outcome, &"failure")
	assert_true(state.has_temporary_control_instability())
	assert_eq(state.temporary_control_instability_remaining, 2.5)
	assert_eq(state.active_failure, &"")


func test_recovery_success_clears_failure_without_penalty() -> void:
	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	state.start_recovery_sequence([&"steer_left"], 1.0)

	state.resolve_recovery_success()

	assert_eq(state.last_recovery_outcome, &"success")
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_false(state.has_active_failure())
	assert_false(state.has_active_recovery_sequence())


func test_recover_speed_restores_forward_speed_over_time() -> void:
	var state := RunStateType.new()
	state.current_speed = 140.0

	state.recover_speed(1.0)

	assert_eq(state.current_speed, 180.0)
	state.recover_speed(10.0)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)


func test_recovery_transients_clear_outcome_and_cooldown_over_time() -> void:
	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	state.start_recovery_sequence([&"steer_left"], 1.0)

	state.resolve_recovery_success()

	assert_eq(state.last_recovery_outcome, &"success")
	assert_true(state.recovery_cooldown_remaining > 0.0)
	assert_false(state.can_start_failure(&"horse_panic"))

	state.tick_recovery_transients(2.0)

	assert_eq(state.last_recovery_outcome, &"")
	assert_eq(state.recovery_cooldown_remaining, 0.0)
	assert_true(state.can_start_failure(&"horse_panic"))
