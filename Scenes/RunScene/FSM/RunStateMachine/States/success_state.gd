extends RunStateMachineStateBase

## Placeholder top-level success state for the RunStateMachine.

# Constants

const STATE_KEY: RunStateMachineKey.Key = RunStateMachineKey.Key.SUCCESS


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> RunStateMachineKey.Key:
	return STATE_KEY


## Starts the success exit beat immediately when transitioning into success from in-progress.
func enter(previous_state_key: int) -> void:
	if previous_state_key != RunStateMachineKey.Key.IN_PROGRESS:
		return

	var scene := _get_scene()
	if scene == null:
		return

	var is_exit_beat_active := bool(scene.get(&"_is_success_exit_beat_active"))
	var has_finished_exit_beat := bool(scene.get(&"_has_finished_success_exit_beat"))
	if is_exit_beat_active or has_finished_exit_beat:
		return

	__start_success_arrival_transition(scene)
	scene.call(&"_sync_previous_frame_state")
	__refresh_success_arrival_frame(scene, 0.0)


## Advances one frame for the success branch, including the success-exit beat and post-beat result presentation.
func advance(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	if bool(scene.get(&"_is_success_exit_beat_active")):
		__refresh_success_arrival_frame(scene, delta)
		return

	var has_finished_exit_beat := bool(scene.get(&"_has_finished_success_exit_beat"))
	var should_update_presentation := not has_finished_exit_beat
	_advance_completed_result_frame(delta, should_update_presentation)


# Private Methods

## Starts the scripted success-arrival beat from the frozen true-success finish frame.
func __start_success_arrival_transition(scene: Node) -> void:
	scene.set(&"_is_success_exit_beat_active", true)
	scene.set(&"_has_finished_success_exit_beat", false)

	var run_presentation: Variant = scene.get(&"_run_presentation")
	if run_presentation != null:
		run_presentation.start_success_arrival()


## Advances the scripted success-arrival beat while keeping end-of-run UI hidden until it completes.
func __refresh_success_arrival_frame(scene: Node, delta: float) -> void:
	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	var run_presentation: Variant = scene.get(&"_run_presentation")
	if ui_presenter == null or run_presentation == null:
		return

	ui_presenter.advance_callouts(delta, scene.get_viewport().get_canvas_transform())
	var arrival_completed := bool(run_presentation.advance_success_arrival(delta))
	ui_presenter.refresh_status()
	ui_presenter.refresh_recovery_prompt()
	ui_presenter.refresh_touch_controls()
	scene.call(&"_sync_completed_run_best_state")
	scene.call(&"_refresh_audio_presentation")
	if not arrival_completed:
		return

	scene.set(&"_is_success_exit_beat_active", false)
	scene.set(&"_has_finished_success_exit_beat", true)
	ui_presenter.refresh_result_screen(scene.call(&"_build_best_run_summary"))
