extends GutTest

## Covers the top-level RunStateMachine scaffolding: transitions, delegation, and bind propagation.

# Imports

const ProjectPaths := preload("res://Constants/project_paths.gd")
const RunStateMachineType := preload(ProjectPaths.RUN_STATE_MACHINE_SCRIPT_PATH)
const RunStateMachineStateBaseType := preload(ProjectPaths.RUN_STATE_MACHINE_STATE_BASE_SCRIPT_PATH)
const InProgressStateType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_SCRIPT_PATH)
const SuccessStateType := preload(ProjectPaths.RUN_STATE_MACHINE_SUCCESS_STATE_SCRIPT_PATH)
const CollapsedStateType := preload(ProjectPaths.RUN_STATE_MACHINE_COLLAPSED_STATE_SCRIPT_PATH)


# Public Methods

## Verifies one transition exits the old state before entering the new state.
func test_set_state_when_transition_then_calls_exit_and_enter_with_expected_keys() -> void:
	var machine := RunStateMachineType.new(false)
	var first_state := _SpyRunStateMachineState.new("first")
	var second_state := _SpyRunStateMachineState.new("second")

	machine.register_state(first_state)
	machine.register_state(second_state)

	machine.set_state(&"first")
	machine.set_state(&"second")

	assert_eq(machine.get_current_state_key(), &"second")
	assert_eq(first_state.call_log, ["enter:", "exit:second"])
	assert_eq(second_state.call_log, ["enter:first"])


## Verifies advance delegates to whichever state is currently active.
func test_advance_when_current_state_exists_then_delegates_to_active_state() -> void:
	var machine := RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new("active")

	machine.register_state(state)
	machine.set_state(&"active")
	machine.advance(0.5)

	assert_eq(state.advance_calls, 1)
	assert_eq(state.last_delta, 0.5)


## Verifies handle_input delegates to whichever state is currently active.
func test_handle_input_when_current_state_exists_then_delegates_to_active_state() -> void:
	var machine := RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new("active")
	var event := InputEventAction.new()
	event.action = &"pause_run"
	event.pressed = true

	machine.register_state(state)
	machine.set_state(&"active")
	machine.handle_input(event)

	assert_eq(state.input_calls, 1)
	assert_same(state.last_event, event)


## Verifies the default constructor registers the top-level in-progress, success, and collapsed states.
func test_init_when_register_defaults_then_can_transition_to_expected_states() -> void:
	var machine := RunStateMachineType.new()

	machine.set_state(InProgressStateType.STATE_KEY)
	assert_eq(machine.get_current_state_key(), InProgressStateType.STATE_KEY)

	machine.set_state(SuccessStateType.STATE_KEY)
	assert_eq(machine.get_current_state_key(), SuccessStateType.STATE_KEY)

	machine.set_state(CollapsedStateType.STATE_KEY)
	assert_eq(machine.get_current_state_key(), CollapsedStateType.STATE_KEY)


## Verifies switching to the same state is a no-op and does not re-run enter/exit hooks.
func test_set_state_when_setting_same_state_then_enter_and_exit_are_not_repeated() -> void:
	var machine := RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new("active")

	machine.register_state(state)

	machine.set_state(&"active")
	machine.set_state(&"active")

	assert_eq(state.call_log, ["enter:"])


## Verifies advance and handle_input are safe when no current state has been set.
func test_delegation_when_no_current_state_then_no_spy_methods_are_called() -> void:
	var machine := RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new("active")
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
	var machine := RunStateMachineType.new(false)
	var scene := Node.new()
	var state := _SpyRunStateMachineState.new("active")

	machine.register_state(state)
	machine.bind(scene)

	assert_same(state.bound_scene, scene)
	scene.free()


# Inner Classes

class _SpyRunStateMachineState extends RunStateMachineStateBaseType:
	## Captures lifecycle, process, and input delegation for one test state.

	var _label: String
	var call_log: Array[String] = []
	var advance_calls: int = 0
	var input_calls: int = 0
	var last_delta: float = -1.0
	var last_event: InputEvent
	var bound_scene: Node

	## Builds one named state spy for readable assertion output.
	func _init(label: String) -> void:
		_label = label

	## Returns the top-level machine key owned by this spy state.
	func get_state_key() -> StringName:
		return StringName(_label)

	## Records the scene from the machine bind.
	func bind(scene: Node = null) -> void:
		bound_scene = scene
		super.bind(scene)

	## Records the previous-state handoff for this entry.
	func enter(previous_state_key: StringName) -> void:
		call_log.append("enter:%s" % String(previous_state_key))

	## Records the next-state handoff for this exit.
	func exit(next_state_key: StringName) -> void:
		call_log.append("exit:%s" % String(next_state_key))

	## Records one delegated advance tick.
	func advance(delta: float) -> void:
		advance_calls += 1
		last_delta = delta

	## Records one delegated input event.
	func handle_input(event: InputEvent) -> void:
		input_calls += 1
		last_event = event
