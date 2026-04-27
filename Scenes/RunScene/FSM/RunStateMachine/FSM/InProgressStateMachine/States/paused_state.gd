extends InProgressStateMachineStateBase

## Owns the modal pause branch while the RunScene remains inside the in-progress state.


# Imports

const GameplayUiLayerType := preload(ProjectPaths.GAMEPLAY_UI_LAYER_SCRIPT_PATH)

# Constants

const STATE_KEY: InProgressStateMachineKeyType.Key = InProgressStateMachineKeyType.Key.PAUSED


# Private Fields

var __resume_state_key: InProgressStateMachineKeyType.Key = InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY
var __navigation_click_in_progress := false


# Public Methods

## Returns the child-FSM key owned by this paused substate.
func get_state_key() -> InProgressStateMachineKeyType.Key:
	return STATE_KEY


## Handles transition entry for the paused substate.
func enter(previous_state_key: InProgressStateMachineKeyType.Key) -> void:
	var context := _get_context()
	if context == null:
		return

	if (
		previous_state_key != InProgressStateMachineKeyType.Key.NONE
		and previous_state_key != InProgressStateMachineKeyType.Key.PAUSED
	):
		__resume_state_key = previous_state_key

	context.set_pause_state(true)
	__connect_pause_layer_signals(context)


## Handles transition exit for the paused substate.
func exit(_next_state_key: InProgressStateMachineKeyType.Key) -> void:
	var context := _get_context()
	if context == null:
		return

	__disconnect_pause_layer_signals(context)
	context.set_pause_state(false)


## Handles pause-menu input while the in-progress branch is paused.
func handle_input(event: InputEvent) -> void:
	var context := _get_context()
	if context == null:
		return

	var ui_input_result: Variant = context.route_ui_input(event)
	if ui_input_result == null:
		return
	
	if (
		ui_input_result.pause_command == GameplayUiLayerType.PAUSE_COMMAND_TOGGLE
		or ui_input_result.pause_command == GameplayUiLayerType.PAUSE_COMMAND_CLOSE
	):
		_request_transition(__resume_state_key)


# Private Methods

## Handles pause-menu resume requests emitted by the pause layer.
func __on_pause_resume_requested() -> void:
	var context := _get_context()
	if context == null:
		return

	if context.run_audio_presenter != null:
		context.run_audio_presenter.play_ui_click()

	_request_transition(__resume_state_key)


## Handles pause-menu restart requests; stays paused while awaiting navigation.
func __on_pause_restart_requested() -> void:
	if __navigation_click_in_progress:
		return
	
	__navigation_click_in_progress = true

	var context := _get_context()
	if context != null and context.run_audio_presenter != null:
		await context.run_audio_presenter.play_ui_click_and_wait()

	__navigation_click_in_progress = false

	if _props == null or not _props.request_restart.is_valid():
		return
	
	_props.request_restart.call()


## Handles pause-menu return-to-title requests; stays paused while awaiting navigation.
func __on_pause_return_to_title_requested() -> void:
	if __navigation_click_in_progress:
		return

	__navigation_click_in_progress = true

	var context := _get_context()
	if context != null and context.run_audio_presenter != null:
		await context.run_audio_presenter.play_ui_click_and_wait()

	__navigation_click_in_progress = false

	if _props == null or not _props.request_return_to_title.is_valid():
		return

	_props.request_return_to_title.call()


## Connects pause-layer button intent signals so this substate owns pause menu navigation.
func __connect_pause_layer_signals(context: InProgressContextType) -> void:
	var pause_layer := context.pause_layer
	if pause_layer == null:
		return

	if not pause_layer.resume_requested.is_connected(__on_pause_resume_requested):
		pause_layer.resume_requested.connect(__on_pause_resume_requested)
	if not pause_layer.restart_requested.is_connected(__on_pause_restart_requested):
		pause_layer.restart_requested.connect(__on_pause_restart_requested)
	if not pause_layer.return_to_title_requested.is_connected(__on_pause_return_to_title_requested):
		pause_layer.return_to_title_requested.connect(__on_pause_return_to_title_requested)


## Disconnects pause-layer button intent signals previously owned by this paused substate.
func __disconnect_pause_layer_signals(context: InProgressContextType) -> void:
	var pause_layer := context.pause_layer
	if pause_layer == null:
		return

	if pause_layer.resume_requested.is_connected(__on_pause_resume_requested):
		pause_layer.resume_requested.disconnect(__on_pause_resume_requested)
	if pause_layer.restart_requested.is_connected(__on_pause_restart_requested):
		pause_layer.restart_requested.disconnect(__on_pause_restart_requested)
	if pause_layer.return_to_title_requested.is_connected(__on_pause_return_to_title_requested):
		pause_layer.return_to_title_requested.disconnect(__on_pause_return_to_title_requested)
