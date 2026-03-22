extends GutTest

const RunStateType := preload("res://Scripts/RunState/run_state.gd")
const TEST_BEST_RUN_SAVE_PATH := "user://dg30_test_best_run.cfg"


## Clears the step-local best-run fixture before each persistence test path is used.
func before_each() -> void:
	_delete_test_best_run_file()


## Clears the step-local best-run fixture after each persistence test completes.
func after_each() -> void:
	_delete_test_best_run_file()


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
	assert_eq(state.hazards_dodged, RunStateType.DEFAULT_HAZARDS_DODGED)
	assert_eq(state.near_misses, RunStateType.DEFAULT_NEAR_MISSES)
	assert_eq(state.perfect_recoveries, RunStateType.DEFAULT_PERFECT_RECOVERIES)
	assert_eq(state.recovery_failures, RunStateType.DEFAULT_RECOVERY_FAILURES)


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
	state.hazards_dodged = 3
	state.near_misses = 2
	state.perfect_recoveries = 1
	state.recovery_failures = 4

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
	assert_eq(state.hazards_dodged, RunStateType.DEFAULT_HAZARDS_DODGED)
	assert_eq(state.near_misses, RunStateType.DEFAULT_NEAR_MISSES)
	assert_eq(state.perfect_recoveries, RunStateType.DEFAULT_PERFECT_RECOVERIES)
	assert_eq(state.recovery_failures, RunStateType.DEFAULT_RECOVERY_FAILURES)


func test_delivery_progress_ratio_tracks_route_completion() -> void:
	var state := RunStateType.new()
	state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.25

	assert_eq(state.get_distance_traveled(), RunStateType.DEFAULT_ROUTE_DISTANCE * 0.75)
	assert_eq(state.get_delivery_progress_ratio(), 0.75)


## Verifies the score formula uses progress, health, and cargo only.
func test_score_when_run_stats_change_then_score_uses_completion_health_and_cargo() -> void:
	var state := RunStateType.new()
	state.distance_remaining = 125.0
	state.wagon_health = 41
	state.cargo_value = 72

	assert_eq(state.get_completion_score(), 750)
	assert_eq(state.get_health_score(), 205)
	assert_eq(state.get_cargo_score(), 360)
	assert_eq(state.get_score(), 1315)


## Verifies near-miss bonuses add into the shared deterministic run score.
func test_near_miss_bonus_when_awarded_then_bonus_score_is_added_once_per_award() -> void:
	var state := RunStateType.new()
	state.distance_remaining = 125.0
	state.award_near_miss_bonus()
	state.award_near_miss_bonus()

	assert_eq(state.near_misses, 2)
	assert_eq(state.bonus_score, RunStateType.NEAR_MISS_BONUS_SCORE * 2)
	assert_eq(state.get_score(), 1850)


## Verifies completed hazard dodges are tracked independently from the near-miss subset.
func test_hazard_dodged_when_recorded_then_dodge_counter_increments_without_affecting_score() -> void:
	var state := RunStateType.new()

	state.record_hazard_dodged()
	state.record_hazard_dodged()

	assert_eq(state.hazards_dodged, 2)
	assert_eq(state.near_misses, 0)
	assert_eq(state.bonus_score, 0)


## Verifies representative thresholds map to the expected delivery grades.
func test_delivery_grade_when_score_crosses_thresholds_then_expected_grade_is_returned() -> void:
	var elite_state := RunStateType.new()
	elite_state.distance_remaining = 0.0
	assert_eq(elite_state.get_delivery_grade(), "S")

	var strong_state := RunStateType.new()
	strong_state.distance_remaining = 125.0
	strong_state.wagon_health = 41
	strong_state.cargo_value = 72
	assert_eq(strong_state.get_delivery_grade(), "B")

	var failed_state := RunStateType.new()
	failed_state.distance_remaining = 375.0
	failed_state.wagon_health = 20
	failed_state.cargo_value = 10
	assert_eq(failed_state.get_delivery_grade(), "F")


## Verifies loading with no saved file returns an empty best-run snapshot.
func test_best_run_load_when_file_is_missing_then_empty_snapshot_is_returned() -> void:
	var best_run := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)

	assert_false(best_run.has_value)
	assert_eq(best_run.score, 0)
	assert_eq(best_run.grade, "")


## Verifies a saved best-run snapshot round-trips the exact stored score and grade.
func test_best_run_save_and_load_when_data_is_valid_then_snapshot_round_trips() -> void:
	var save_result := RunStateType.save_best_run(
		RunStateType.BestRunData.new(1565, "A", true),
		TEST_BEST_RUN_SAVE_PATH
	)
	var best_run := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)

	assert_eq(save_result, OK)
	assert_true(best_run.has_value)
	assert_eq(best_run.score, 1565)
	assert_eq(best_run.grade, "A")


## Verifies invalid save requests are rejected instead of writing an empty best-run entry.
func test_best_run_save_when_snapshot_has_no_value_then_invalid_parameter_is_returned() -> void:
	var save_result := RunStateType.save_best_run(
		RunStateType.BestRunData.new(),
		TEST_BEST_RUN_SAVE_PATH
	)

	assert_eq(save_result, ERR_INVALID_PARAMETER)
	assert_false(FileAccess.file_exists(TEST_BEST_RUN_SAVE_PATH))


## Verifies malformed save data falls back to the default empty best-run snapshot.
func test_best_run_load_when_save_file_is_missing_grade_then_empty_snapshot_is_returned() -> void:
	var config := ConfigFile.new()
	config.set_value(RunStateType.BEST_RUN_SECTION, RunStateType.BEST_RUN_SCORE_KEY, 1800)
	assert_eq(config.save(TEST_BEST_RUN_SAVE_PATH), OK)

	var best_run := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)

	assert_false(best_run.has_value)
	assert_eq(best_run.score, 0)
	assert_eq(best_run.grade, "")


## Verifies a lower finished score leaves the stored best run unchanged.
func test_record_best_run_when_current_score_is_lower_then_existing_best_is_kept() -> void:
	assert_eq(
		RunStateType.save_best_run(RunStateType.BestRunData.new(1500, "A", true), TEST_BEST_RUN_SAVE_PATH),
		OK
	)
	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 125.0
	state.wagon_health = 41
	state.cargo_value = 72
	state.load_persisted_best_run(TEST_BEST_RUN_SAVE_PATH)

	var did_set_new_best := state.record_best_run_if_needed(TEST_BEST_RUN_SAVE_PATH)
	var stored_best := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)

	assert_false(did_set_new_best)
	assert_false(state.current_run_is_new_best)
	assert_eq(stored_best.score, 1500)
	assert_eq(stored_best.grade, "A")


## Verifies a tied finished score does not replace the existing best run.
func test_record_best_run_when_current_score_ties_then_existing_best_is_kept() -> void:
	assert_eq(
		RunStateType.save_best_run(RunStateType.BestRunData.new(1565, "A", true), TEST_BEST_RUN_SAVE_PATH),
		OK
	)
	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.wagon_health = 41
	state.cargo_value = 72
	state.load_persisted_best_run(TEST_BEST_RUN_SAVE_PATH)

	var did_set_new_best := state.record_best_run_if_needed(TEST_BEST_RUN_SAVE_PATH)
	var stored_best := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)

	assert_false(did_set_new_best)
	assert_false(state.current_run_is_new_best)
	assert_eq(state.get_score(), 1565)
	assert_eq(stored_best.score, 1565)
	assert_eq(stored_best.grade, "A")


## Verifies a higher finished score replaces the stored best run and marks the run as new best.
func test_record_best_run_when_current_score_is_higher_then_best_run_is_replaced() -> void:
	assert_eq(
		RunStateType.save_best_run(RunStateType.BestRunData.new(1400, "B", true), TEST_BEST_RUN_SAVE_PATH),
		OK
	)
	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.wagon_health = 50
	state.cargo_value = 80
	state.load_persisted_best_run(TEST_BEST_RUN_SAVE_PATH)

	var did_set_new_best := state.record_best_run_if_needed(TEST_BEST_RUN_SAVE_PATH)
	var stored_best := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)

	assert_true(did_set_new_best)
	assert_true(state.current_run_is_new_best)
	assert_eq(stored_best.score, state.get_score())
	assert_eq(stored_best.grade, state.get_delivery_grade())


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


func test_perfect_recovery_bonus_when_awarded_then_bonus_score_is_added() -> void:
	var state := RunStateType.new()

	state.award_perfect_recovery_bonus()

	assert_eq(state.perfect_recoveries, 1)
	assert_eq(state.bonus_score, RunStateType.PERFECT_RECOVERY_BONUS_SCORE)


func test_recovery_sequence_timeout_counts_down_and_triggers_expiry() -> void:
	var state := RunStateType.new()
	state.start_recovery_sequence([&"steer_left"], 1.0)

	assert_false(state.tick_recovery_sequence(0.4))
	assert_eq(state.recovery_time_remaining, 0.6)
	assert_true(state.tick_recovery_sequence(0.7))
	assert_eq(state.recovery_time_remaining, 0.0)


func test_current_recovery_perfect_when_wrong_input_or_timeout_then_bonus_eligibility_is_lost() -> void:
	var state := RunStateType.new()
	state.start_recovery_sequence([&"steer_left"], 1.0)

	assert_true(state.is_current_recovery_perfect())
	state.record_recovery_wrong_input()
	assert_false(state.is_current_recovery_perfect())

	state.start_recovery_sequence([&"steer_left"], 1.0)
	state.record_recovery_timeout()
	assert_false(state.is_current_recovery_perfect())


func test_recovery_failure_penalty_applies_resource_losses_and_instability() -> void:
	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	state.start_recovery_sequence([&"steer_left"], 1.0)

	state.apply_recovery_failure_penalty(12, 18, 90.0, 2.5)

	assert_eq(state.wagon_health, 88)
	assert_eq(state.cargo_value, 82)
	assert_eq(state.current_speed, 190.0)
	assert_eq(state.recovery_failures, 1)
	assert_eq(state.last_recovery_outcome, &"failure")
	assert_true(state.has_temporary_control_instability())
	assert_eq(state.temporary_control_instability_remaining, 2.5)
	assert_eq(state.active_failure, &"")


func test_recovery_success_clears_failure_without_penalty() -> void:
	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	state.start_recovery_sequence([&"steer_left"], 1.0)

	state.resolve_recovery_success()

	assert_eq(state.perfect_recoveries, 0)
	assert_eq(state.recovery_failures, 0)
	assert_eq(state.last_recovery_outcome, &"success")
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_false(state.has_active_failure())
	assert_false(state.has_active_recovery_sequence())


## Verifies only explicitly awarded perfect recoveries are counted.
func test_recovery_success_when_bonus_not_awarded_then_perfect_recovery_count_does_not_change() -> void:
	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	state.start_recovery_sequence([&"steer_left"], 1.0)

	state.resolve_recovery_success()

	assert_eq(state.perfect_recoveries, 0)
	assert_eq(state.recovery_failures, 0)


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


## Removes the persisted best-run fixture file when the test created one.
func _delete_test_best_run_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_BEST_RUN_SAVE_PATH)
	if FileAccess.file_exists(TEST_BEST_RUN_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
