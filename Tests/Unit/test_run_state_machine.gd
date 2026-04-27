extends GutTest

## Covers the top-level RunStateMachine scaffolding: transitions, delegation, and bind propagation.

# Imports

const ProjectPaths := preload("res://Constants/project_paths.gd")
const RunStateMachineKeyType := preload(ProjectPaths.RUN_STATE_MACHINE_KEY_SCRIPT_PATH)
const RunStateMachineType := preload(ProjectPaths.RUN_STATE_MACHINE_SCRIPT_PATH)
const RunSceneType := preload(ProjectPaths.RUN_SCENE_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Public Methods

## Verifies one transition exits the old state before entering the new state.
func test_set_state_when_transition_then_calls_exit_and_enter_with_expected_keys() -> void:
	var machine = RunStateMachineType.new(false)
	var first_state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.IN_PROGRESS)
	var second_state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.SUCCESS)

	machine.register_state(first_state)
	machine.register_state(second_state)

	machine.set_state(RunStateMachineKeyType.Key.IN_PROGRESS)
	machine.set_state(RunStateMachineKeyType.Key.SUCCESS)

	assert_eq(machine.get_current_state_key(), RunStateMachineKeyType.Key.SUCCESS)
	assert_eq(first_state.call_log, ["enter:-1", "exit:1"])
	assert_eq(second_state.call_log, ["enter:0"])


## Verifies advance delegates to whichever state is currently active.
func test_advance_when_current_state_exists_then_delegates_to_active_state() -> void:
	var machine = RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.IN_PROGRESS)

	machine.register_state(state)
	machine.set_state(RunStateMachineKeyType.Key.IN_PROGRESS)
	machine.advance(0.5)

	assert_eq(state.advance_calls, 1)
	assert_eq(state.last_delta, 0.5)


## Verifies handle_input delegates to whichever state is currently active.
func test_handle_input_when_current_state_exists_then_delegates_to_active_state() -> void:
	var machine = RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.IN_PROGRESS)
	var event := InputEventAction.new()
	event.action = &"pause_run"
	event.pressed = true

	machine.register_state(state)
	machine.set_state(RunStateMachineKeyType.Key.IN_PROGRESS)
	machine.handle_input(event)

	assert_eq(state.input_calls, 1)
	assert_same(state.last_event, event)


## Verifies the default constructor registers the top-level in-progress, success, and collapsed states.
func test_init_when_register_defaults_then_can_transition_to_expected_states() -> void:
	var machine = RunStateMachineType.new()

	machine.set_state(RunStateMachineKeyType.Key.IN_PROGRESS)
	assert_eq(machine.get_current_state_key(), RunStateMachineKeyType.Key.IN_PROGRESS)

	machine.set_state(RunStateMachineKeyType.Key.SUCCESS)
	assert_eq(machine.get_current_state_key(), RunStateMachineKeyType.Key.SUCCESS)

	machine.set_state(RunStateMachineKeyType.Key.COLLAPSED)
	assert_eq(machine.get_current_state_key(), RunStateMachineKeyType.Key.COLLAPSED)


## Verifies switching to the same state is a no-op and does not re-run enter/exit hooks.
func test_set_state_when_setting_same_state_then_enter_and_exit_are_not_repeated() -> void:
	var machine = RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.IN_PROGRESS)

	machine.register_state(state)

	machine.set_state(RunStateMachineKeyType.Key.IN_PROGRESS)
	machine.set_state(RunStateMachineKeyType.Key.IN_PROGRESS)

	assert_eq(state.call_log, ["enter:-1"])


## Verifies advance and handle_input are safe when no current state has been set.
func test_delegation_when_no_current_state_then_no_spy_methods_are_called() -> void:
	var machine = RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.IN_PROGRESS)
	var event := InputEventAction.new()
	event.action = &"pause_run"
	event.pressed = true

	machine.register_state(state)

	machine.advance(0.1)
	machine.handle_input(event)

	assert_eq(state.advance_calls, 0)
	assert_eq(state.input_calls, 0)


## Verifies binding a scene propagates to registered state instances.
func test_bind_when_scene_is_set_then_registered_states_receive_bind() -> void:
	var machine = RunStateMachineType.new(false)
	var scene := RunSceneType.new()
	var state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.IN_PROGRESS)

	machine.register_state(state)
	machine.bind(scene)

	assert_same(state.bound_scene, scene)
	scene.free()


## Verifies advance syncs the active top-level state from the bound RunState result before delegation.
func test_advance_when_bound_scene_result_changes_then_machine_routes_in_progress_success_and_collapsed() -> void:
	var machine = RunStateMachineType.new(false)
	var in_progress_state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.IN_PROGRESS)
	var success_state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.SUCCESS)
	var collapsed_state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.COLLAPSED)
	var scene := RunSceneType.new()
	scene._run_state = RunStateType.new()

	machine.register_state(in_progress_state)
	machine.register_state(success_state)
	machine.register_state(collapsed_state)
	machine.bind(scene)

	scene._run_state.result = RunStateType.RESULT_IN_PROGRESS
	machine.advance(0.1)
	assert_eq(machine.get_current_state_key(), RunStateMachineKeyType.Key.IN_PROGRESS)
	assert_eq(in_progress_state.advance_calls, 1)

	scene._run_state.result = RunStateType.RESULT_SUCCESS
	machine.advance(0.2)
	assert_eq(machine.get_current_state_key(), RunStateMachineKeyType.Key.SUCCESS)
	assert_eq(success_state.advance_calls, 1)
	assert_eq(in_progress_state.call_log, ["enter:-1", "exit:1"])

	scene._run_state.result = RunStateType.RESULT_COLLAPSED
	machine.advance(0.3)
	assert_eq(machine.get_current_state_key(), RunStateMachineKeyType.Key.COLLAPSED)
	assert_eq(collapsed_state.advance_calls, 1)
	assert_eq(success_state.call_log, ["enter:0", "exit:2"])

	scene.free()


## Verifies input delegation also syncs from the bound RunState result before routing the event.
func test_handle_input_when_bound_scene_result_is_collapsed_then_machine_syncs_before_delegating() -> void:
	var machine = RunStateMachineType.new(false)
	var in_progress_state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.IN_PROGRESS)
	var collapsed_state := _SpyRunStateMachineState.new(RunStateMachineKeyType.Key.COLLAPSED)
	var scene := RunSceneType.new()
	scene._run_state = RunStateType.new()
	var event := InputEventAction.new()
	event.action = &"pause_run"
	event.pressed = true

	machine.register_state(in_progress_state)
	machine.register_state(collapsed_state)
	machine.bind(scene)

	scene._run_state.result = RunStateType.RESULT_COLLAPSED
	machine.handle_input(event)

	assert_eq(machine.get_current_state_key(), RunStateMachineKeyType.Key.COLLAPSED)
	assert_eq(in_progress_state.input_calls, 0)
	assert_eq(collapsed_state.input_calls, 1)
	assert_same(collapsed_state.last_event, event)

	scene.free()


# Inner Classes

class _SpyRunStateMachineState extends "res://Scenes/RunScene/FSM/RunStateMachine/States/run_state_machine_state_base.gd":
	## Captures lifecycle, process, and input delegation for one test state.

	var _key: RunStateMachineKey.Key
	var call_log: Array[String] = []
	var advance_calls: int = 0
	var input_calls: int = 0
	var last_delta: float = -1.0
	var last_event: InputEvent
	var bound_scene: RunSceneType

	## Builds one named state spy for readable assertion output.
	func _init(key: RunStateMachineKey.Key) -> void:
		_key = key

	## Returns the top-level machine key owned by this spy state.
	func get_state_key() -> RunStateMachineKey.Key:
		return _key

	## Records the scene from the machine bind.
	func bind(scene: RunSceneType = null) -> void:
		bound_scene = scene
		super.bind(scene)

	## Records the previous-state handoff for this entry.
	func enter(previous_state_key: int) -> void:
		call_log.append("enter:%d" % previous_state_key)

	## Records the next-state handoff for this exit.
	func exit(next_state_key: int) -> void:
		call_log.append("exit:%d" % next_state_key)

	## Records one delegated advance tick.
	func advance(delta: float) -> void:
		advance_calls += 1
		last_delta = delta

	## Records one delegated input event.
	func handle_input(event: InputEvent) -> void:
		input_calls += 1
		last_event = event
