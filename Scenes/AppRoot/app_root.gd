extends Node

## Owns the title-to-run scene flow and completed-run restart or return shortcuts.


# Constants
const DevCheatsType := preload(ProjectPaths.DEV_CHEATS_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const TITLE_SCENE := preload(ProjectPaths.TITLE_SCREEN_SCENE_PATH)
const RUN_SCENE := preload(ProjectPaths.RUN_SCENE_PATH)
const RESTART_ACTION := "restart_run"
const RETURN_TO_TITLE_ACTION := "return_to_title"


# Public Fields: Export

@export
var starting_distance: float = 500.0

@export
var allow_quit: bool = true


# Public Fields

var run_state: RunStateType


# Private Fields

var _dev_cheats: DevCheatsType = DevCheatsType.new()
var _title_screen: Control
var _run_scene: Node
var _quit_requested := false


# Lifecycle Methods

## Boots the app flow, registers shared input shortcuts, and shows the title screen first.
func _ready() -> void:
	_ensure_restart_action()
	_ensure_return_to_title_action()
	_dev_cheats.register_input_actions()
	_show_title_screen()


## Handles restart and return shortcuts once a run result is available.
func _unhandled_input(event: InputEvent) -> void:
	if run_state == null:
		return
	if run_state.result == RunStateType.RESULT_IN_PROGRESS:
		return
	if event.is_action_pressed(RESTART_ACTION):
		_start_new_run()
	elif event.is_action_pressed(RETURN_TO_TITLE_ACTION):
		_show_title_screen()


# Public Methods

## Rebuilds the active run scene and fresh run state from the current starting-distance config.
func _start_new_run() -> void:
	get_tree().paused = false
	if is_instance_valid(_title_screen):
		_title_screen.queue_free()
		_title_screen = null
	if is_instance_valid(_run_scene):
		_run_scene.queue_free()

	run_state = RunStateType.new()
	run_state.configure_route_distance(starting_distance)
	_run_scene = RUN_SCENE.instantiate()
	add_child(_run_scene)
	if _run_scene.has_signal("restart_requested"):
		_run_scene.restart_requested.connect(_start_new_run)
	if _run_scene.has_signal("return_to_title_requested"):
		_run_scene.return_to_title_requested.connect(_show_title_screen)
	if _run_scene.has_method("setup"):
		_run_scene.setup(run_state, _dev_cheats)


## Returns to the title screen and clears any active run scene or run-state instance.
func _show_title_screen() -> void:
	get_tree().paused = false
	if is_instance_valid(_run_scene):
		_run_scene.queue_free()
		_run_scene = null

	run_state = null
	_title_screen = TITLE_SCENE.instantiate()
	add_child(_title_screen)
	_title_screen.play_requested.connect(_start_new_run)
	_title_screen.quit_requested.connect(_request_quit)


# Private Methods

## Records the quit request and exits immediately when quitting is allowed for this runtime.
func _request_quit() -> void:
	_quit_requested = true
	if allow_quit:
		get_tree().quit()


## Registers the shared restart shortcut if it is not already present in the input map.
func _ensure_restart_action() -> void:
	if not InputMap.has_action(RESTART_ACTION):
		InputMap.add_action(RESTART_ACTION)

	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	if not InputMap.action_has_event(RESTART_ACTION, event):
		InputMap.action_add_event(RESTART_ACTION, event)


## Registers the shared return-to-title shortcut if it is not already present in the input map.
func _ensure_return_to_title_action() -> void:
	if not InputMap.has_action(RETURN_TO_TITLE_ACTION):
		InputMap.add_action(RETURN_TO_TITLE_ACTION)

	var event := InputEventKey.new()
	event.physical_keycode = KEY_T
	if not InputMap.action_has_event(RETURN_TO_TITLE_ACTION, event):
		InputMap.action_add_event(RETURN_TO_TITLE_ACTION, event)
