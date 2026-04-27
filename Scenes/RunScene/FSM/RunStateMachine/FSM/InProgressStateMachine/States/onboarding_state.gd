extends InProgressStateMachineStateBase

## Owns the onboarding substate flow while the run remains in the in-progress branch.


# Imports

const GameplayUiLayerType := preload(ProjectPaths.GAMEPLAY_UI_LAYER_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)

# Constants

const STATE_KEY: InProgressStateMachineKeyType.Key = InProgressStateMachineKeyType.Key.ONBOARDING


# Public Methods

## Returns the child-FSM key owned by this onboarding substate.
func get_state_key() -> InProgressStateMachineKeyType.Key:
	return STATE_KEY


## Handles transition entry for the onboarding substate.
func enter(_previous_state_key: InProgressStateMachineKeyType.Key) -> void:
	var context := _get_context()
	if context == null or context.ui_presenter == null:
		return

	context.ui_presenter.is_onboarding_active = true
	context.ui_presenter.refresh_onboarding_prompt()


## Handles transition exit for the onboarding substate.
func exit(_next_state_key: InProgressStateMachineKeyType.Key) -> void:
	var context := _get_context()
	if context == null or context.ui_presenter == null:
		return

	context.ui_presenter.dismiss_onboarding()


## Advances one frame while the onboarding overlay is active.
func advance(delta: float) -> void:
	var context := _get_context()
	if context == null:
		return

	if context.run_state == null or context.run_presentation == null or context.ui_presenter == null:
		return

	context.sync_previous_frame_state()
	context.run_presentation.advance_scroll(context.run_state.current_speed, delta)
	context.refresh_regular_roadside_sign_spawning()
	context.advance_roadside_scenery(context.run_state.current_speed * delta)
	context.update_impact_feedback(delta)
	context.update_wagon_visual()
	context.update_scroll_visuals()
	context.update_camera_framing()
	context.refresh_audio_presentation()


## Handles onboarding-specific input, including pause commands and onboarding dismissal.
func handle_input(event: InputEvent) -> void:
	var context := _get_context()
	if context == null:
		return

	var ui_input_result: Variant = context.route_ui_input(event)
	if ui_input_result == null:
		return
	
	if ui_input_result.pause_command == GameplayUiLayerType.PAUSE_COMMAND_TOGGLE:
		_request_transition(InProgressStateMachineKeyType.Key.PAUSED)
		return

	if (
		not ui_input_result.should_dismiss_onboarding_ui_prompt or
		context.ui_presenter == null
	):
		return

	if context.run_director != null and context.run_director.route_phase_callout_zone == RunDirectorType.ROUTE_PHASE_WARM_UP:
		context.ui_presenter.show_phase_callout(
			RunDirectorType.get_route_phase_display_name(context.run_director.route_phase_callout_zone)
		)
	
	_request_transition(InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY)
