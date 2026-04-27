@abstract
class_name InProgressStateMachineStateBase
extends RefCounted

## Defines the minimal typed interface for one InProgressStateMachine substate.


# Imports

const InProgressContextType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_CONTEXT_SCRIPT_PATH)
const InProgressStateMachineKeyType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_KEY_SCRIPT_PATH
)
const InProgressStatePropsType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_PROPS_SCRIPT_PATH
)


# Private Fields

var _props: InProgressStatePropsType


# Public Methods

## Injects the typed in-progress state props into this substate.
func bind_props(props: InProgressStatePropsType = null) -> void:
	_props = props


## Returns this substate's key; derived states must override this and return their owned non-NONE key.
func get_state_key() -> InProgressStateMachineKeyType.Key:
	return InProgressStateMachineKeyType.Key.NONE


## Handles transition entry; derived states should override this when they need entry behavior.
func enter(_previous_state_key: InProgressStateMachineKeyType.Key) -> void:
	pass


## Handles transition exit; derived states should override this when they need exit behavior.
func exit(_next_state_key: InProgressStateMachineKeyType.Key) -> void:
	pass


## Advances this state by one process tick; derived states should override this when they own process behavior.
func advance(_delta: float) -> void:
	pass


## Handles one input event while this state is active; derived states should override this when they own input flow.
func handle_input(_event: InputEvent) -> void:
	pass


# Protected Methods

## Returns the injected in-progress dependency context for this substate.
func _get_context() -> InProgressContextType:
	if _props == null:
		return null
	return _props.context


## Requests a transition from this child substate through the owning machine.
func _request_transition(state_key: InProgressStateMachineKeyType.Key) -> void:
	if _props == null or not _props.request_transition.is_valid():
		return
	_props.request_transition.call(state_key)
