extends GutTest

const RunStateType := preload("res://Scripts/RunState/run_state.gd")


func test_defaults_match_expected_mvp_boot_values() -> void:
	var state := RunStateType.new()

	assert_eq(state.distance_remaining, RunStateType.DEFAULT_DISTANCE_REMAINING)
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_eq(state.lateral_position, RunStateType.DEFAULT_LATERAL_POSITION)
	assert_eq(state.active_failure, &"")
	assert_eq(state.result, &"in_progress")

