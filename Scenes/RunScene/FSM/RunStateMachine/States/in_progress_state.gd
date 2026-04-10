extends RunStateMachineStateBase

## Placeholder top-level in-progress state for the RunStateMachine.

# Constants

const STATE_KEY: RunStateMachineKey.Key = RunStateMachineKey.Key.IN_PROGRESS


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> RunStateMachineKey.Key:
	return STATE_KEY


## Advances one frame for the in-progress branch, preserving onboarding and pause branching inside this state.
func advance(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if ui_presenter != null and bool(ui_presenter.is_pause_menu_open):
		scene.call(&"_advance_paused_frame", delta)
		return

	if ui_presenter != null and bool(ui_presenter.is_onboarding_active):
		scene.call(&"_advance_onboarding_frame", delta)
		return

	scene.call(&"_advance_active_drive_frame", delta)
