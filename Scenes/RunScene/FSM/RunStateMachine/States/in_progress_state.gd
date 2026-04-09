extends "res://Scenes/RunScene/FSM/RunStateMachine/States/run_state_machine_state_base.gd"

## Placeholder top-level in-progress state for the RunStateMachine.


# Constants

const STATE_KEY := &"in_progress"


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> StringName:
	return STATE_KEY
