extends GutTest

## Covers the extracted onboarding substate behavior for the in-progress run branch.


# Imports

const ProjectPaths := preload("res://Constants/project_paths.gd")
const InProgressContextType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_CONTEXT_SCRIPT_PATH)
const InProgressStateMachineKeyType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_KEY_SCRIPT_PATH)
const InProgressStatePropsType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_PROPS_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const OnboardingStateType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_ONBOARDING_STATE_SCRIPT_PATH)


# Constants

const RUN_SCENE := preload(ProjectPaths.RUN_SCENE_PATH)


# Public Methods

## Verifies the onboarding substate dismisses onboarding and shows the warm-up callout.
func test_handle_input_when_dismissing_onboarding_in_warm_up_then_active_is_requested_and_callout_shows() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var run_state := RunStateType.new()
	scene.setup(run_state)
	var onboarding_state := OnboardingStateType.new()
	var transition_recorder := _TransitionRecorder.new()
	onboarding_state.bind_props(__build_props(scene, Callable(transition_recorder, &"record_transition")))
	onboarding_state.enter(InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)

	var phase_callout_panel: PanelContainer = scene.get_node("%PhaseCalloutPanel")
	var phase_callout_label: Label = scene.get_node("%PhaseCalloutLabel")
	var dismiss_event := InputEventAction.new()
	dismiss_event.action = &"steer_left"
	dismiss_event.pressed = true

	assert_true(scene._run_ui_presenter.is_onboarding_active)
	assert_false(phase_callout_panel.visible)

	onboarding_state.handle_input(dismiss_event)

	assert_eq(transition_recorder.last_transition, InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	assert_true(scene._run_ui_presenter.is_onboarding_active)
	assert_true(phase_callout_panel.visible)
	assert_eq(phase_callout_label.text, "Warm-Up")


## Verifies entering onboarding directly enables the onboarding flag and panel.
func test_enter_when_entering_onboarding_then_onboarding_turns_on() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	scene.setup(RunStateType.new())
	scene._run_ui_presenter.dismiss_onboarding()

	var onboarding_panel: PanelContainer = scene.get_node("%OnboardingPanel")
	var onboarding_state := OnboardingStateType.new()
	onboarding_state.bind_props(__build_props(scene))
	onboarding_state.enter(InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)

	assert_true(scene._run_ui_presenter.is_onboarding_active)
	assert_true(onboarding_panel.visible)


## Verifies leaving onboarding hides the onboarding flag and panel.
func test_exit_when_leaving_onboarding_then_onboarding_turns_off() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	scene.setup(RunStateType.new())

	var onboarding_panel: PanelContainer = scene.get_node("%OnboardingPanel")
	var onboarding_state := OnboardingStateType.new()
	onboarding_state.bind_props(__build_props(scene))
	onboarding_state.enter(InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)

	assert_true(scene._run_ui_presenter.is_onboarding_active)
	assert_true(onboarding_panel.visible)

	onboarding_state.exit(InProgressStateMachineKeyType.Key.PAUSED)

	assert_false(scene._run_ui_presenter.is_onboarding_active)
	assert_false(onboarding_panel.visible)


## Verifies the onboarding substate preserves onboarding-frame movement and freeze behavior.
func test_advance_when_onboarding_is_active_then_world_scrolls_without_distance_or_hazard_progress() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var run_state := RunStateType.new()
	scene.setup(run_state)
	var onboarding_state := OnboardingStateType.new()
	onboarding_state.bind_props(__build_props(scene))
	onboarding_state.enter(InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
	var starting_distance := run_state.distance_remaining
	var starting_scroll: float = scene._run_presentation.scroll_offset
	var spawner: Node = scene.get_node("%HazardSpawner")

	onboarding_state.advance(0.5)

	assert_eq(run_state.distance_remaining, starting_distance)
	assert_eq(spawner.get_child_count(), 0)
	assert_true(scene._run_presentation.scroll_offset > starting_scroll)


# Private Methods

## Builds one in-progress props bundle from the live RunScene for onboarding substate tests.
func __build_props(
	scene: Node,
	request_transition: Callable = Callable()
) -> InProgressStatePropsType:
	return InProgressStatePropsType.new(__build_context(scene), request_transition, Callable(), Callable())


## Builds one in-progress context from the live RunScene so onboarding can be tested without scene binding.
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


# Inner Classes

class _TransitionRecorder extends RefCounted:
	## Captures one requested child-FSM transition from the onboarding substate.

	var last_transition: InProgressStateMachineKeyType.Key = InProgressStateMachineKeyType.Key.NONE


	## Stores the most recently requested child-FSM transition key.
	func record_transition(state_key: InProgressStateMachineKeyType.Key) -> void:
		last_transition = state_key
