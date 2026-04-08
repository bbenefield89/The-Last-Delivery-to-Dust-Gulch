extends RefCounted

## Owns the top-level RunScene outcome states and delegates frame and input flow.


# Imports

const ProjectPaths := preload("res://Constants/project_paths.gd")
const RunStateMachineStateType := preload(ProjectPaths.RUN_STATE_MACHINE_STATE_SCRIPT_PATH)
const InProgressStateType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_SCRIPT_PATH)
const SuccessStateType := preload(ProjectPaths.RUN_STATE_MACHINE_SUCCESS_STATE_SCRIPT_PATH)
const CollapsedStateType := preload(ProjectPaths.RUN_STATE_MACHINE_COLLAPSED_STATE_SCRIPT_PATH)


# Constants

const STATE_IN_PROGRESS := &"in_progress"
const STATE_SUCCESS := &"success"
const STATE_COLLAPSED := &"collapsed"


# Regular Fields

var __scene: Node
var __states: Dictionary[StringName, RunStateMachineStateType] = {}
var __current_state: RunStateMachineStateType
var current_state_key: StringName = &""


# Lifecycle Methods

## Builds the machine and optionally registers the default top-level states.
func _init(register_default_states: bool = true) -> void:
	if register_default_states:
		register_state(STATE_IN_PROGRESS, InProgressStateType.new())
		register_state(STATE_SUCCESS, SuccessStateType.new())
		register_state(STATE_COLLAPSED, CollapsedStateType.new())


# Public Methods

## Binds the owning RunScene so registered states can later access scene-local behavior.
func bind(scene: Node) -> void:
	__scene = scene
	for state_key in __states.keys():
		__states[state_key].bind(__scene, state_key)


## Registers one state instance under its top-level machine key.
func register_state(state_key: StringName, state: RunStateMachineStateType) -> void:
	__states[state_key] = state
	if __scene != null:
		state.bind(__scene, state_key)


## Transitions the machine to the requested top-level state.
func set_state(state_key: StringName) -> void:
	assert(__states.has(state_key), "RunStateMachine is missing state '%s'." % state_key)

	var next_state := __states[state_key]
	if __current_state == next_state:
		return

	var previous_state_key := current_state_key
	if __current_state != null:
		__current_state.exit(state_key)

	__current_state = next_state
	current_state_key = state_key
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
