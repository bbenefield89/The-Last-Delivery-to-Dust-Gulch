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

	scene.call(&"_start_success_arrival_transition")
	scene.call(&"_sync_previous_frame_state")
	scene.call(&"_refresh_success_arrival_frame", 0.0)


## Advances one frame for the success branch, including the success-exit beat and post-beat result presentation.
func advance(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if ui_presenter != null and bool(ui_presenter.is_pause_menu_open):
		scene.call(&"_advance_paused_frame", delta)
		return

	if bool(scene.get(&"_is_success_exit_beat_active")):
		scene.call(&"_advance_success_exit_beat_frame", delta)
		return

	var has_finished_exit_beat := bool(scene.get(&"_has_finished_success_exit_beat"))
	var should_update_presentation := not has_finished_exit_beat
	scene.call(&"_advance_completed_result_frame", delta, should_update_presentation)
