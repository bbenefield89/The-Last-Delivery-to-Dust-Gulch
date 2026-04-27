class_name InProgressStateMachine
extends RefCounted

## Owns the RunScene in-progress substates and routes frame and input flow between them.


# Imports

const InProgressContextType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_CONTEXT_SCRIPT_PATH)
const InProgressStateMachineKeyType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_KEY_SCRIPT_PATH
)
const InProgressStatePropsType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_PROPS_SCRIPT_PATH
)
const InProgressStateMachineStateBaseType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_BASE_SCRIPT_PATH
)
const OnboardingStateType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_ONBOARDING_STATE_SCRIPT_PATH)
const ActiveGameplayStateType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_ACTIVE_GAMEPLAY_STATE_SCRIPT_PATH
)
const PausedStateType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_PAUSED_STATE_SCRIPT_PATH)


# Private Fields

var __states: Dictionary[int, InProgressStateMachineStateBaseType] = {}
var __current_state: InProgressStateMachineStateBaseType
var __context: InProgressContextType
var __request_restart: Callable
var __request_return_to_title: Callable


# Lifecycle Methods

## Builds the child FSM and optionally registers the default in-progress substates.
func _init(register_default_states: bool = true) -> void:
	if register_default_states:
		register_state(OnboardingStateType.new())
		register_state(ActiveGameplayStateType.new())
		register_state(PausedStateType.new())


## Synchronizes the active child state against the injected in-progress context.
func __sync_state_for_context() -> bool:
	var desired_state_key := __get_desired_state_key_for_context()
	if desired_state_key == InProgressStateMachineKeyType.Key.NONE:
		return false
	if get_current_state_key() == desired_state_key:
		return false

	set_state(desired_state_key)
	return true


## Returns the desired child-FSM state key for the current injected context.
func __get_desired_state_key_for_context() -> InProgressStateMachineKeyType.Key:
	if __context == null:
		return InProgressStateMachineKeyType.Key.NONE

	if __context.ui_presenter == null:
		return InProgressStateMachineKeyType.Key.NONE

	if __context.ui_presenter.is_pause_menu_open:
		return InProgressStateMachineKeyType.Key.PAUSED

	if __context.ui_presenter.is_onboarding_active:
		return InProgressStateMachineKeyType.Key.ONBOARDING

	return InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY


# Public Methods

## Injects one typed in-progress dependency context into the child FSM and its registered substates.
func bind_props(
	context: InProgressContextType = null,
	request_restart: Callable = Callable(),
	request_return_to_title: Callable = Callable()
) -> void:
	__context = context
	__request_restart = request_restart
	__request_return_to_title = request_return_to_title

	for state_key: InProgressStateMachineKeyType.Key in __states.keys():
		__states[state_key].bind_props(__build_state_props())


## Registers one substate instance under the child-FSM key owned by that state.
func register_state(state: InProgressStateMachineStateBaseType) -> void:
	var state_key := state.get_state_key()
	assert(
		state_key != InProgressStateMachineKeyType.Key.NONE,
		"InProgressStateMachine states must own a non-NONE state key."
	)
	if state_key == InProgressStateMachineKeyType.Key.NONE:
		push_error("InProgressStateMachine refused to register a state with a NONE state key.")
		return

	__states[state_key] = state
	state.bind_props(__build_state_props())


## Returns the key for the currently active child-FSM substate or `NONE` when unset.
func get_current_state_key() -> InProgressStateMachineKeyType.Key:
	if __current_state == null:
		return InProgressStateMachineKeyType.Key.NONE
	return __current_state.get_state_key()


## Transitions the child FSM to the requested substate.
func set_state(state_key: InProgressStateMachineKeyType.Key) -> void:
	assert(__states.has(state_key), "InProgressStateMachine is missing state '%s'." % state_key)
	if not __states.has(state_key):
		push_error("InProgressStateMachine is missing state '%s'." % state_key)
		return

	var next_state := __states[state_key]
	if next_state == null:
		push_error("InProgressStateMachine state '%s' resolved to null." % state_key)
		return
	if __current_state == next_state:
		return

	var previous_state_key: InProgressStateMachineKeyType.Key = get_current_state_key()
	if __current_state != null:
		__current_state.exit(state_key)

	__current_state = next_state
	__current_state.enter(previous_state_key)


## Advances the current in-progress substate by one process tick.
func advance(delta: float) -> void:
	__sync_state_for_context()
	if __current_state == null:
		return

	__current_state.advance(delta)
	__sync_state_for_context()


## Routes one input event to the current in-progress substate.
func handle_input(event: InputEvent) -> void:
	if __current_state == null:
		__sync_state_for_context()
	if __current_state == null:
		return

	__current_state.handle_input(event)


# Private Methods

## Builds one substate props bundle using the current child-FSM context and transition requester.
func __build_state_props() -> InProgressStatePropsType:
	return InProgressStatePropsType.new(
		__context,
		Callable(self, "_request_transition_from_child"),
		__request_restart,
		__request_return_to_title
	)


## Applies one child-requested transition through the owning machine.
func _request_transition_from_child(state_key: InProgressStateMachineKeyType.Key) -> void:
	if state_key == InProgressStateMachineKeyType.Key.NONE:
		return
	set_state(state_key)
