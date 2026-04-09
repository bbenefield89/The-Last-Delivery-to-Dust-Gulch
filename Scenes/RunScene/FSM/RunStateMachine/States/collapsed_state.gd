extends "res://Scenes/RunScene/FSM/RunStateMachine/States/run_state_machine_state_base.gd"

## Placeholder top-level collapsed state for the RunStateMachine.


# Constants

const STATE_KEY := &"collapsed"


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> StringName:
	return STATE_KEY
