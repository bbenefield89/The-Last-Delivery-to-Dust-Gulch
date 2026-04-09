extends RunStateMachineStateBase

## Placeholder top-level success state for the RunStateMachine.

# Constants

const STATE_KEY: RunStateMachineKey.Key = RunStateMachineKey.Key.SUCCESS


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> RunStateMachineKey.Key:
	return STATE_KEY
