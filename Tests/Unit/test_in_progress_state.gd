extends GutTest

## Covers top-level in-progress state context construction and injection.


# Imports

const ProjectPaths := preload("res://Constants/project_paths.gd")
const InProgressStateType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_SCRIPT_PATH)
const InProgressStateMachineKeyType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_KEY_SCRIPT_PATH)
const RUN_SCENE := preload(ProjectPaths.RUN_SCENE_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const RunSceneType := preload(ProjectPaths.RUN_SCENE_SCRIPT_PATH)


# Public Methods

## Verifies binding a live RunScene builds and injects the typed in-progress context.
func test_bind_when_scene_is_run_scene_then_child_machine_receives_built_context() -> void:
	var state = InProgressStateType.new()
	var scene = RunSceneType.new()
	scene._run_state = RunStateType.new()

	state.bind(scene)

	var context = state.get(&"__in_progress_context")
	var child_machine = state.get(&"__in_progress_state_machine")

	assert_not_null(context)
	assert_same(context, child_machine.get(&"__context"))
	assert_same(context.run_state, scene._run_state)
	assert_same(context.run_presentation, scene._run_presentation)
	assert_same(context.run_director, scene._run_director)
	assert_same(context.run_audio_presenter, scene._run_audio_presenter)
	assert_eq(context.pause_action, scene.PAUSE_ACTION)
	assert_eq(context.finish_runoff_distance, scene.FINISH_RUNOFF_DISTANCE)

	scene.free()


## Verifies binding null clears any previously injected child-FSM context safely.
func test_bind_when_scene_is_null_then_child_machine_context_is_cleared() -> void:
	var state = InProgressStateType.new()
	var run_scene = RunSceneType.new()
	run_scene._run_state = RunStateType.new()

	state.bind(run_scene)
	assert_not_null(state.get(&"__in_progress_context"))

	state.bind(null)

	assert_null(state.get(&"__in_progress_context"))
	assert_null(state.get(&"__in_progress_state_machine").get(&"__context"))

	run_scene.free()


## Verifies entering the top-level in-progress state forces the child FSM into onboarding immediately.
func test_enter_when_in_progress_is_entered_then_child_fsm_starts_onboarding() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	scene.setup(RunStateType.new())

	scene._run_ui_presenter.is_onboarding_active = false

	var state = InProgressStateType.new()
	state.bind(scene)
	state.enter(0)

	var child_machine = state.get(&"__in_progress_state_machine")
	assert_eq(child_machine.get_current_state_key(), InProgressStateMachineKeyType.Key.ONBOARDING)
	assert_true(scene._run_ui_presenter.is_onboarding_active)
