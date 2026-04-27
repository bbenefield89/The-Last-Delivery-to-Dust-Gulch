class_name RunStateMachine
extends RefCounted

## Owns the top-level RunScene outcome states and delegates frame and input flow.


# Imports

const RunStateMachineKeyType := preload(ProjectPaths.RUN_STATE_MACHINE_KEY_SCRIPT_PATH)
const InProgressStateType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_SCRIPT_PATH)
const SuccessStateType := preload(ProjectPaths.RUN_STATE_MACHINE_SUCCESS_STATE_SCRIPT_PATH)
const CollapsedStateType := preload(ProjectPaths.RUN_STATE_MACHINE_COLLAPSED_STATE_SCRIPT_PATH)
const RunSceneType := preload(ProjectPaths.RUN_SCENE_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Private Fields

var __states: Dictionary[int, RunStateMachineStateBase] = {}
var __current_state: RunStateMachineStateBase
var __scene: RunSceneType


# Lifecycle Methods

## Builds the machine and optionally registers the default top-level states.
func _init(register_default_states: bool = true) -> void:
	if register_default_states:
		register_state(InProgressStateType.new())
		register_state(SuccessStateType.new())
		register_state(CollapsedStateType.new())


## Synchronizes the active top-level state against the currently bound RunState result.
func __sync_state_for_bound_scene() -> bool:
	var desired_state_key: int = __get_desired_state_key_for_bound_scene()
	if desired_state_key == RunStateMachineKeyType.Key.NONE:
		return false

	if get_current_state_key() == desired_state_key:
		return false

	set_state(desired_state_key)
	return true


## Returns the desired top-level state key for the currently bound scene or `NONE` when unavailable.
func __get_desired_state_key_for_bound_scene() -> int:
	if __scene == null:
		return RunStateMachineKeyType.Key.NONE

	var run_state: RunStateType = __scene.get_run_state()
	if run_state == null:
		return RunStateMachineKeyType.Key.NONE

	match run_state.result:
		RunStateType.RESULT_IN_PROGRESS:
			return RunStateMachineKeyType.Key.IN_PROGRESS
		RunStateType.RESULT_SUCCESS:
			return RunStateMachineKeyType.Key.SUCCESS
		RunStateType.RESULT_COLLAPSED:
			return RunStateMachineKeyType.Key.COLLAPSED
		_:
			return RunStateMachineKeyType.Key.IN_PROGRESS


# Public Methods

## Binds the live RunScene node instance so states can call into scene-owned services during extraction.
func bind(scene: RunSceneType = null) -> void:
	__scene = scene
	for state_key: int in __states.keys():
		__states[state_key].bind(scene)


## Registers one state instance under the top-level machine key owned by that state.
func register_state(state: RunStateMachineStateBase) -> void:
	var state_key: int = state.get_state_key()
	assert(state_key != RunStateMachineKeyType.Key.NONE, "RunStateMachine states must own a non-NONE state key.")
	if state_key == RunStateMachineKeyType.Key.NONE:
		push_error("RunStateMachine refused to register a state with a NONE state key.")
		return
	__states[state_key] = state
	if __scene != null:
		state.bind(__scene)


## Returns the key for the currently active top-level state or `NONE` when unset.
func get_current_state_key() -> int:
	if __current_state == null:
		return RunStateMachineKeyType.Key.NONE

	return __current_state.get_state_key()


## Transitions the machine to the requested top-level state.
func set_state(state_key: int) -> void:
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

	var previous_state_key: int = get_current_state_key()
	if __current_state != null:
		__current_state.exit(state_key)

	__current_state = next_state
	__current_state.enter(previous_state_key)


## Advances the current top-level state by one process tick.
func advance(delta: float) -> void:
	__sync_state_for_bound_scene()
	if __current_state == null:
		return

	__current_state.advance(delta)
	__sync_state_for_bound_scene()


## Routes one input event to the current top-level state.
func handle_input(event: InputEvent) -> void:
	__sync_state_for_bound_scene()
	if __current_state == null:
		return

	__current_state.handle_input(event)
