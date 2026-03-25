extends GutTest


# Constants

const FailureStateType := preload(ProjectPaths.FAILURE_STATE_SCRIPT_PATH)

# Public Methods




## Verifies the failure-state helper preserves its constructor arguments.

func test_failure_state_records_type_source_and_trigger_progress() -> void:
	var failure := FailureStateType.new(&"wheel_loose", &"rock", 0.6)

	assert_eq(failure.failure_type, &"wheel_loose")
	assert_eq(failure.source_hazard, &"rock")
	assert_eq(failure.trigger_progress_ratio, 0.6)
	assert_eq(failure.elapsed_time, 0.0)
