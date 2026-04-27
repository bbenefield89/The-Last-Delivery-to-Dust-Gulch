extends RunStateMachineStateBase

## Owns the top-level in-progress branch by translating RunScene state into the child in-progress FSM.


# Imports

const InProgressContextType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_CONTEXT_SCRIPT_PATH)
const InProgressStateMachineKeyType := preload(ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_KEY_SCRIPT_PATH)
const InProgressStateMachineType := preload(
	ProjectPaths.RUN_STATE_MACHINE_IN_PROGRESS_STATE_MACHINE_SCRIPT_PATH
)


# Constants

const STATE_KEY: RunStateMachineKey.Key = RunStateMachineKey.Key.IN_PROGRESS


# Private Fields

var __in_progress_context: InProgressContextType
var __in_progress_state_machine := InProgressStateMachineType.new()


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> RunStateMachineKey.Key:
	return STATE_KEY


## Forces the in-progress child FSM to start in ONBOARDING on entry.
func enter(_previous_state_key: int) -> void:
	if __in_progress_state_machine == null:
		return

	__in_progress_state_machine.set_state(InProgressStateMachineKeyType.Key.ONBOARDING)


## Binds the current RunScene, builds the injected in-progress context, and wires the child FSM.
func bind(scene: RunSceneType = null) -> void:
	super.bind(scene)
	if scene == null:
		__in_progress_context = null
		__in_progress_state_machine.bind_props(null)
		return

	__in_progress_context = __build_context(scene)
	__in_progress_state_machine.bind_props(
		__in_progress_context,
		Callable(self, "__request_restart"),
		Callable(self, "__request_return_to_title")
	)


## Routes one input event through the child in-progress FSM.
func handle_input(event: InputEvent) -> void:
	if __in_progress_state_machine == null:
		return

	__in_progress_state_machine.handle_input(event)


## Advances one frame for the in-progress branch through the child FSM.
func advance(delta: float) -> void:
	if __in_progress_state_machine == null:
		return

	__in_progress_state_machine.advance(delta)


# Private Methods

## Builds one typed in-progress dependency context from the currently bound RunScene.
func __build_context(scene: RunSceneType) -> InProgressContextType:
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


## Requests a run restart through the owning RunScene intent signal.
func __request_restart() -> void:
	var scene := _get_scene()
	if scene == null:
		return
	scene.restart_requested.emit()


## Requests a return-to-title through the owning RunScene intent signal.
func __request_return_to_title() -> void:
	var scene := _get_scene()
	if scene == null:
		return
	scene.return_to_title_requested.emit()
