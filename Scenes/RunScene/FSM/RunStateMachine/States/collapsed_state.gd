extends RunStateMachineStateBase

## Placeholder top-level collapsed state for the RunStateMachine.

# Constants

const STATE_KEY: RunStateMachineKey.Key = RunStateMachineKey.Key.COLLAPSED


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> RunStateMachineKey.Key:
	return STATE_KEY


## Advances one frame for the collapsed branch, preserving the existing end-of-run presentation.
func advance(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	_advance_completed_result_frame(delta, true)
