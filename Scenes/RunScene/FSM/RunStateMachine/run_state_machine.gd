extends RefCounted

## Owns the top-level RunScene outcome states and delegates frame and input flow.


# Imports

const RunStateMachineStateBaseType := preload(ProjectPaths.RUN_STATE_MACHINE_STATE_BASE_SCRIPT_PATH)
const InProgressStateType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_SCRIPT_PATH)
const SuccessStateType := preload(ProjectPaths.RUN_STATE_MACHINE_SUCCESS_STATE_SCRIPT_PATH)
const CollapsedStateType := preload(ProjectPaths.RUN_STATE_MACHINE_COLLAPSED_STATE_SCRIPT_PATH)


# Private Fields

var __states: Dictionary[StringName, RunStateMachineStateBaseType] = {}
var __current_state: RunStateMachineStateBaseType


# Lifecycle Methods

## Builds the machine and optionally registers the default top-level states.
func _init(register_default_states: bool = true) -> void:
	if register_default_states:
		register_state(InProgressStateType.new())
		register_state(SuccessStateType.new())
		register_state(CollapsedStateType.new())


# Public Methods

## Binds the live RunScene node instance so states can call into scene-owned services during extraction.
func bind(scene: Node) -> void:
	for state_key: StringName in __states.keys():
		__states[state_key].bind(scene)


## Registers one state instance under the top-level machine key owned by that state.
func register_state(state: RunStateMachineStateBaseType) -> void:
	var state_key := state.get_state_key()
	assert(state_key != &"", "RunStateMachine states must own a non-empty state key.")
	if state_key == &"":
		push_error("RunStateMachine refused to register a state with an empty state key.")
		return
	__states[state_key] = state
	state.bind()


## Returns the key for the currently active top-level state or an empty key when unset.
func get_current_state_key() -> StringName:
	if __current_state == null:
		return &""

	return __current_state.get_state_key()


## Transitions the machine to the requested top-level state.
func set_state(state_key: StringName) -> void:
	assert(__states.has(state_key), "RunStateMachine is missing state '%s'." % state_key)
	if not __states.has(state_key):
		push_error("RunStateMachine is missing state '%s'." % state_key)
		return

	var next_state := __states[state_key]
	if next_state == null:
		push_error("RunStateMachine state '%s' resolved to null." % state_key)
		return
	if __current_state == next_state:
		return

	var previous_state_key := get_current_state_key()
	if __current_state != null:
		__current_state.exit(state_key)

	__current_state = next_state
	__current_state.enter(previous_state_key)


## Advances the current top-level state by one process tick.
func advance(delta: float) -> void:
	if __current_state == null:
		return

	__current_state.advance(delta)


## Routes one input event to the current top-level state.
func handle_input(event: InputEvent) -> void:
	if __current_state == null:
		return

	__current_state.handle_input(event)
