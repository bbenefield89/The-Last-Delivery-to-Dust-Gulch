@abstract
class_name RunStateMachineStateBase
extends RefCounted

## Defines the minimal typed interface for one top-level RunScene state.


# Imports

const RunSceneType := preload(ProjectPaths.RUN_SCENE_SCRIPT_PATH)


# Private Fields

var __scene: RunSceneType


# Public Methods

## Binds the owning RunScene node instance or null in unit tests.
func bind(scene: RunSceneType = null) -> void:
	__scene = scene


## Returns this state's enum key; derived states must override this and return their owned non-NONE key.
func get_state_key() -> RunStateMachineKey.Key:
	return RunStateMachineKey.Key.NONE


## Handles transition entry; derived states should override this when they need entry behavior.
func enter(_previous_state_key: int) -> void:
	pass


## Handles transition exit; derived states should override this when they need exit behavior.
func exit(_next_state_key: int) -> void:
	pass


## Advances this state by one process tick; derived states should override this when they own process behavior.
func advance(_delta: float) -> void:
	pass


## Handles one input event while this state is active; derived states should override this when they own input behavior.
func handle_input(_event: InputEvent) -> void:
	pass


# Protected Methods

## Returns the bound scene for state implementations that need scene-local access.
func _get_scene() -> RunSceneType:
	return __scene


## Advances one completed-run frame while the result screen is visible.
func _advance_completed_result_frame(delta: float, should_update_presentation: bool) -> void:
	if __scene == null:
		return

	var ui_presenter: Variant = __scene._run_ui_presenter
	if ui_presenter == null:
		return

	__scene._sync_previous_frame_state()
	ui_presenter.advance_callouts(delta, __scene.get_viewport().get_canvas_transform())
	if should_update_presentation:
		__scene._update_impact_feedback(delta)
		__scene._update_wagon_visual()
		__scene._update_camera_framing()

	ui_presenter.refresh_status()
	ui_presenter.refresh_result_screen(__scene._build_best_run_summary())
	ui_presenter.refresh_touch_controls()
	__scene._refresh_audio_presentation()
