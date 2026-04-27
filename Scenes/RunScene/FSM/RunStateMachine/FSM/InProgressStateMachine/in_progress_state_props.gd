class_name InProgressStateProps
extends RefCounted

## Bundles the shared runtime props passed from the child FSM into one in-progress substate.


# Imports

const InProgressContextType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_CONTEXT_SCRIPT_PATH)


# Public Fields

var context: InProgressContextType
var request_transition: Callable
var request_restart: Callable
var request_return_to_title: Callable


# Lifecycle Methods

## Builds the runtime props used by one in-progress substate.
func _init(
	context_value: InProgressContextType = null,
	request_transition_value: Callable = Callable(),
	request_restart_value: Callable = Callable(),
	request_return_to_title_value: Callable = Callable()
) -> void:
	context = context_value
	request_transition = request_transition_value
	request_restart = request_restart_value
	request_return_to_title = request_return_to_title_value
