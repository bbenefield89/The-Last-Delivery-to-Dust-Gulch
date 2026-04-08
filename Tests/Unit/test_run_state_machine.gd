extends GutTest

# Imports

const ProjectPaths := preload("res://Constants/project_paths.gd")
const RunStateMachineType := preload(ProjectPaths.RUN_STATE_MACHINE_SCRIPT_PATH)
const RunStateMachineStateType := preload(ProjectPaths.RUN_STATE_MACHINE_STATE_SCRIPT_PATH)


# Public Methods

## Verifies one transition exits the old state before entering the new state.
func test_set_state_when_transition_then_calls_exit_and_enter_with_expected_keys() -> void:
	var machine := RunStateMachineType.new(false)
	var first_state := _SpyRunStateMachineState.new("first")
	var second_state := _SpyRunStateMachineState.new("second")

	machine.register_state(&"first", first_state)
	machine.register_state(&"second", second_state)

	machine.set_state(&"first")
	machine.set_state(&"second")

	assert_eq(machine.current_state_key, &"second")
	assert_eq(first_state.call_log, ["enter:", "exit:second"])
	assert_eq(second_state.call_log, ["enter:first"])


## Verifies advance delegates to whichever state is currently active.
func test_advance_when_current_state_exists_then_delegates_to_active_state() -> void:
	var machine := RunStateMachineType.new(false)
	var state := _SpyRunStateMachineState.new("active")

	machine.register_state(&"active", state)
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

	machine.register_state(&"active", state)
	machine.set_state(&"active")
	machine.handle_input(event)

	assert_eq(state.input_calls, 1)
	assert_same(state.last_event, event)

## Verifies the default constructor registers the top-level in-progress, success, and collapsed states.
func test_init_when_register_defaults_then_can_transition_to_expected_states() -> void:
	var machine := RunStateMachineType.new()

	machine.set_state(RunStateMachineType.STATE_IN_PROGRESS)
	assert_eq(machine.current_state_key, RunStateMachineType.STATE_IN_PROGRESS)

	machine.set_state(RunStateMachineType.STATE_SUCCESS)
	assert_eq(machine.current_state_key, RunStateMachineType.STATE_SUCCESS)

	machine.set_state(RunStateMachineType.STATE_COLLAPSED)
	assert_eq(machine.current_state_key, RunStateMachineType.STATE_COLLAPSED)


## Verifies binding a scene propagates to registered state instances.
func test_bind_when_scene_is_set_then_registered_states_receive_bind() -> void:
	var machine := RunStateMachineType.new(false)
	var scene := Node.new()
	var state := _SpyRunStateMachineState.new("active")

	machine.register_state(&"active", state)
	machine.bind(scene)

	assert_same(state.bound_scene, scene)
	assert_eq(state.bound_key, &"active")
	scene.free()


# Inner Classes

class _SpyRunStateMachineState extends RunStateMachineStateType:
	## Captures lifecycle, process, and input delegation for one test state.

	var _label: String
	var call_log: Array[String] = []
	var advance_calls: int = 0
	var input_calls: int = 0
	var last_delta: float = -1.0
	var last_event: InputEvent
	var bound_scene: Node
	var bound_key: StringName = &""

	## Builds one named state spy for readable assertion output.
	func _init(label: String) -> void:
		_label = label

	## Records the scene and registered key from the machine bind.
	func bind(scene: Node, state_key: StringName) -> void:
		bound_scene = scene
		bound_key = state_key
		super.bind(scene, state_key)

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
