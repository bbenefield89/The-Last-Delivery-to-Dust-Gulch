extends GutTest

## Covers the child InProgressStateMachine scaffolding: transitions, routing, and context propagation.


# Imports

const ProjectPaths := preload("res://Constants/project_paths.gd")
const GameplayUiLayerType := preload(ProjectPaths.GAMEPLAY_UI_LAYER_SCRIPT_PATH)
const InProgressContextType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_CONTEXT_SCRIPT_PATH)
const InProgressStateMachineKeyType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_KEY_SCRIPT_PATH
)
const InProgressStatePropsType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_PROPS_SCRIPT_PATH)
const InProgressStateMachineType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_MACHINE_SCRIPT_PATH
)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Constants

const RUN_SCENE := preload(ProjectPaths.RUN_SCENE_PATH)


# Public Methods

## Verifies the default constructor registers the onboarding, active gameplay, and paused substates.
func test_init_when_register_defaults_then_can_transition_to_expected_substates() -> void:
	var machine = InProgressStateMachineType.new()

	machine.set_state(InProgressStateMachineKeyType.Key.ONBOARDING)
	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ONBOARDING)

	machine.set_state(InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)

	machine.set_state(InProgressStateMachineKeyType.Key.PAUSED)
	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.PAUSED)


## Verifies injecting a context propagates to registered child-FSM substates.
func test_set_context_when_context_is_set_then_registered_states_receive_same_context() -> void:
	var machine = InProgressStateMachineType.new(false)
	var onboarding_state := _SpyInProgressState.new(InProgressStateMachineKeyType.Key.ONBOARDING)
	var active_gameplay_state := _SpyInProgressState.new(
		InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY
	)
	var context := __make_context()

	machine.register_state(onboarding_state)
	machine.register_state(active_gameplay_state)
	machine.bind_props(context)

	assert_same(onboarding_state.bound_context, context)
	assert_same(active_gameplay_state.bound_context, context)
	assert_true(onboarding_state.has_transition_requester)
	assert_true(active_gameplay_state.has_transition_requester)


## Verifies advancing the child FSM selects paused before onboarding and active gameplay from the injected context.
func test_advance_when_ui_flags_change_then_machine_routes_paused_onboarding_and_active_gameplay() -> void:
	var machine = InProgressStateMachineType.new(false)
	var paused_state := _SpyInProgressState.new(InProgressStateMachineKeyType.Key.PAUSED)
	var onboarding_state := _SpyInProgressState.new(InProgressStateMachineKeyType.Key.ONBOARDING)
	var active_gameplay_state := _SpyInProgressState.new(
		InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY
	)
	var context := __make_context()

	machine.register_state(paused_state)
	machine.register_state(onboarding_state)
	machine.register_state(active_gameplay_state)
	machine.bind_props(context)

	context.ui_presenter.is_pause_menu_open = true
	context.ui_presenter.is_onboarding_active = true
	machine.advance(0.1)
	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.PAUSED)
	assert_eq(paused_state.advance_calls, 1)

	context.ui_presenter.is_pause_menu_open = false
	context.ui_presenter.is_onboarding_active = true
	machine.advance(0.2)
	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ONBOARDING)
	assert_eq(onboarding_state.advance_calls, 1)

	context.ui_presenter.is_onboarding_active = false
	machine.advance(0.3)
	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	assert_eq(active_gameplay_state.advance_calls, 1)


## Verifies input routing also syncs the active child substate from the injected context before delegation.
func test_handle_input_when_ui_is_not_paused_or_onboarding_then_machine_delegates_to_active_gameplay() -> void:
	var machine = InProgressStateMachineType.new(false)
	var active_gameplay_state := _SpyInProgressState.new(
		InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY
	)
	var context := __make_context()
	var event := InputEventAction.new()
	event.action = &"pause_run"
	event.pressed = true

	machine.register_state(active_gameplay_state)
	machine.bind_props(context)
	machine.handle_input(event)

	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	assert_eq(active_gameplay_state.input_calls, 1)
	assert_same(active_gameplay_state.last_event, event)


## Verifies onboarding requests a paused transition directly instead of relying on UI-flag auto-sync.
func test_handle_input_when_onboarding_receives_pause_then_machine_transitions_to_paused() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var machine = InProgressStateMachineType.new()
	var run_state := RunStateType.new()
	scene.setup(run_state)
	var context := __build_context(scene)
	var event := InputEventAction.new()
	event.action = &"pause_run"
	event.pressed = true

	context.ui_presenter.is_onboarding_active = true
	machine.bind_props(context)
	machine.set_state(InProgressStateMachineKeyType.Key.ONBOARDING)
	machine.handle_input(event)

	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.PAUSED)
	assert_false(context.ui_presenter.is_onboarding_active)
	assert_true(context.ui_presenter.is_pause_menu_open)


## Verifies onboarding dismissal transitions directly into active gameplay.
func test_handle_input_when_onboarding_is_dismissed_then_machine_transitions_to_active_gameplay() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var machine = InProgressStateMachineType.new()
	var run_state := RunStateType.new()
	scene.setup(run_state)
	var context := __build_context(scene)
	var event := InputEventAction.new()
	event.action = &"steer_left"
	event.pressed = true

	context.ui_presenter.is_onboarding_active = true
	machine.bind_props(context)
	machine.set_state(InProgressStateMachineKeyType.Key.ONBOARDING)
	machine.handle_input(event)

	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	assert_false(context.ui_presenter.is_onboarding_active)


## Verifies active gameplay pause input requests a direct transition into paused.
func test_handle_input_when_active_gameplay_receives_pause_then_machine_transitions_to_paused() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var machine = InProgressStateMachineType.new()
	var run_state := RunStateType.new()
	scene.setup(run_state)
	var context := __build_context(scene)
	var event := InputEventAction.new()
	event.action = &"pause_run"
	event.pressed = true

	context.ui_presenter.is_onboarding_active = false
	machine.bind_props(context)
	machine.set_state(InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	machine.handle_input(event)

	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.PAUSED)
	assert_true(context.ui_presenter.is_pause_menu_open)


## Verifies paused close input resumes back to onboarding when pause was entered from onboarding.
func test_handle_input_when_paused_receives_close_then_machine_transitions_back_to_onboarding() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var machine = InProgressStateMachineType.new()
	var run_state := RunStateType.new()
	scene.setup(run_state)
	var context := __build_context(scene)
	var event := InputEventAction.new()
	__ensure_action(&"ui_cancel")
	event.action = &"ui_cancel"
	event.pressed = true

	context.ui_presenter.is_onboarding_active = true
	machine.bind_props(context)
	machine.set_state(InProgressStateMachineKeyType.Key.ONBOARDING)
	machine.set_state(InProgressStateMachineKeyType.Key.PAUSED)

	assert_false(context.ui_presenter.is_onboarding_active)
	assert_true(context.ui_presenter.is_pause_menu_open)

	machine.handle_input(event)

	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ONBOARDING)
	assert_true(context.ui_presenter.is_onboarding_active)
	assert_false(context.ui_presenter.is_pause_menu_open)


## Verifies paused close input resumes back to active gameplay when pause was entered from gameplay.
func test_handle_input_when_paused_receives_close_from_active_gameplay_then_machine_transitions_back_to_active_gameplay() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var machine = InProgressStateMachineType.new()
	var run_state := RunStateType.new()
	scene.setup(run_state)
	var context := __build_context(scene)
	var event := InputEventAction.new()
	__ensure_action(&"ui_cancel")
	event.action = &"ui_cancel"
	event.pressed = true

	context.ui_presenter.is_onboarding_active = false
	machine.bind_props(context)
	machine.set_state(InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	machine.set_state(InProgressStateMachineKeyType.Key.PAUSED)
	machine.handle_input(event)

	assert_eq(machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	assert_false(context.ui_presenter.is_pause_menu_open)


# Private Methods

## Builds one typed in-progress context with a lightweight gameplay UI layer for child-FSM routing tests.
func __make_context() -> InProgressContextType:
	var context := InProgressContextType.new()
	var run_state := RunStateType.new()
	var ui_presenter := GameplayUiLayerType.new()
	context.bind_dependencies(
		run_state,
		ui_presenter,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		&"pause_run",
		0.0,
		&"in_progress",
		false
	)
	return context


## Builds one typed in-progress context from a live RunScene for runtime-faithful child-FSM tests.
func __build_context(scene: Node) -> InProgressContextType:
	var context := InProgressContextType.new()
	context.bind_dependencies(
		scene._run_state,
		scene._run_ui_presenter,
		scene._run_presentation,
		scene._run_director,
		scene._run_audio_presenter,
		scene._run_hazard_resolver,
		scene._roadside_scenery,
		scene._hazard_spawner,
		scene._pause_layer,
		scene._touch_layer,
		scene._dev_cheats,
		scene._wagon,
		scene.get_viewport(),
		scene.PAUSE_ACTION,
		scene.FINISH_RUNOFF_DISTANCE,
		scene._previous_frame_result,
		scene._previous_frame_has_crossed_finish_line
	)
	return context


## Registers one input action for runtime-faithful input-event tests when it is not already present.
func __ensure_action(action_name: StringName) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)


# Inner Classes

class _SpyInProgressState extends InProgressStateMachineStateBase:
	## Captures context injection, lifecycle, and delegation for one child-FSM spy state.

	var _key: InProgressStateMachineKeyType.Key
	var bound_context: RefCounted
	var has_transition_requester := false
	var advance_calls := 0
	var input_calls := 0
	var last_event: InputEvent


	## Builds one named spy state for readable child-FSM assertions.
	func _init(key: InProgressStateMachineKeyType.Key) -> void:
		_key = key


	## Returns the child-FSM key owned by this spy state.
	func get_state_key() -> InProgressStateMachineKeyType.Key:
		return _key


	## Records the injected props from the child machine.
	func bind_props(props: InProgressStatePropsType = null) -> void:
		bound_context = props.context if props != null else null
		has_transition_requester = props != null and props.request_transition.is_valid()
		super.bind_props(props)


	## Records one delegated child-FSM advance tick.
	func advance(_delta: float) -> void:
		advance_calls += 1


	## Records one delegated child-FSM input event.
	func handle_input(event: InputEvent) -> void:
		input_calls += 1
		last_event = event
