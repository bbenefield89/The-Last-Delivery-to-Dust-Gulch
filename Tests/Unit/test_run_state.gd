extends GutTest

const RunStateType := preload("res://Scripts/RunState/run_state.gd")


func test_defaults_match_expected_mvp_boot_values() -> void:
	var state := RunStateType.new()

	assert_eq(state.distance_remaining, RunStateType.DEFAULT_DISTANCE_REMAINING)
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_eq(state.lateral_position, RunStateType.DEFAULT_LATERAL_POSITION)
	assert_eq(state.active_failure, RunStateType.DEFAULT_ACTIVE_FAILURE)
	assert_eq(state.last_hit_hazard, &"")
	assert_eq(state.result, RunStateType.DEFAULT_RESULT)


func test_reset_for_new_run_restores_all_core_run_values() -> void:
	var state := RunStateType.new()
	state.distance_remaining = 1200.0
	state.wagon_health = 18
	state.cargo_value = 42
	state.current_speed = 90.0
	state.active_failure = &"wheel_loose"
	state.result = RunStateType.RESULT_COLLAPSED
	state.lateral_position = -150.0
	state.last_hit_hazard = &"rock"

	state.reset_for_new_run()

	assert_eq(state.distance_remaining, RunStateType.DEFAULT_DISTANCE_REMAINING)
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_eq(state.active_failure, RunStateType.DEFAULT_ACTIVE_FAILURE)
	assert_eq(state.result, RunStateType.DEFAULT_RESULT)
	assert_eq(state.lateral_position, RunStateType.DEFAULT_LATERAL_POSITION)
	assert_eq(state.last_hit_hazard, RunStateType.DEFAULT_LAST_HIT_HAZARD)


func test_delivery_progress_ratio_tracks_route_completion() -> void:
	var state := RunStateType.new()
	state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.25

	assert_eq(state.get_distance_traveled(), RunStateType.DEFAULT_ROUTE_DISTANCE * 0.75)
	assert_eq(state.get_delivery_progress_ratio(), 0.75)
