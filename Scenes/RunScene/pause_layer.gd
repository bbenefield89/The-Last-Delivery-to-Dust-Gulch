extends Control

## Owns pause-menu visibility, focus navigation, click consumption, and pause button intent signals.


# Signals
signal resume_requested
signal restart_requested
signal return_to_title_requested


# Imports
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Public Fields
var is_menu_open := false


# Private Fields
var _run_state: RunStateType


# Private Fields: OnReady
@onready
var _pause_overlay: Control = %PauseOverlay

@onready
var _pause_panel: PanelContainer = %PausePanel

@onready
var _resume_button: Button = %PauseResumeButton

@onready
var _restart_button: Button = %PauseRestartButton

@onready
var _return_button: Button = %PauseReturnButton


# Lifecycle Methods

## Configures pause-menu navigation and button wiring when the pause wrapper enters the tree.
func _ready() -> void:
	__configure_navigation()
	__set_process_mode_recursive(_pause_overlay, Node.PROCESS_MODE_ALWAYS)
	__connect_buttons()


# Event Handlers

## Emits the pause-menu resume intent upward.
func __on_resume_button_pressed() -> void:
	resume_requested.emit()


## Emits the pause-menu restart intent upward.
func __on_restart_button_pressed() -> void:
	restart_requested.emit()


## Emits the pause-menu return-to-title intent upward.
func __on_return_button_pressed() -> void:
	return_to_title_requested.emit()


# Public Methods

## Binds the active run state so pause visibility tracks the current run.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


## Refreshes pause-menu visibility for the active run.
func refresh_menu(is_menu_open_value: bool) -> void:
	is_menu_open = is_menu_open_value
	if _pause_overlay == null or _pause_panel == null:
		return

	var should_show_menu := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and is_menu_open
	)
	_pause_overlay.visible = should_show_menu
	_pause_panel.visible = should_show_menu
	if should_show_menu and not __has_button_focus():
		focus_default_button()


## Returns whether the current input event should be swallowed while the pause menu is open.
func should_consume_event(event: InputEvent) -> bool:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null:
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed

	var touch_event := event as InputEventScreenTouch
	if touch_event != null:
		return touch_event.pressed

	return event is InputEventScreenDrag


## Gives the pause menu a deterministic starting focus for keyboard-only play.
func focus_default_button() -> void:
	if _resume_button != null:
		_resume_button.grab_focus()


## Returns whether the pause overlay is currently visible.
func is_menu_visible() -> bool:
	return _pause_overlay != null and _pause_overlay.visible


# Private Methods

## Connects each authored pause button to its matching signal-emission handler once.
func __connect_buttons() -> void:
	__connect_button(_resume_button, __on_resume_button_pressed)
	__connect_button(_restart_button, __on_restart_button_pressed)
	__connect_button(_return_button, __on_return_button_pressed)


## Connects one pause button to its pressed handler if that connection is not already present.
func __connect_button(button: Button, handler: Callable) -> void:
	if button == null or button.pressed.is_connected(handler):
		return

	button.pressed.connect(handler)


## Returns whether any pause-menu button already owns keyboard focus.
func __has_button_focus() -> bool:
	return (
		(_resume_button != null and _resume_button.has_focus())
		or (_restart_button != null and _restart_button.has_focus())
		or (_return_button != null and _return_button.has_focus())
	)


## Configures explicit keyboard focus traversal for the pause menu buttons.
func __configure_navigation() -> void:
	if _resume_button == null or _restart_button == null or _return_button == null:
		return

	__enable_button_focus()
	__configure_resume_navigation()
	__configure_restart_navigation()
	__configure_return_navigation()


## Enables keyboard focus for the authored pause-menu buttons.
func __enable_button_focus() -> void:
	_resume_button.focus_mode = Control.FOCUS_ALL
	_restart_button.focus_mode = Control.FOCUS_ALL
	_return_button.focus_mode = Control.FOCUS_ALL


## Configures the authored pause resume button focus neighbors.
func __configure_resume_navigation() -> void:
	var resume_to_restart := _resume_button.get_path_to(_restart_button)
	var resume_to_return := _resume_button.get_path_to(_return_button)
	_resume_button.focus_neighbor_top = resume_to_return
	_resume_button.focus_neighbor_bottom = resume_to_restart
	_resume_button.focus_neighbor_left = resume_to_return
	_resume_button.focus_neighbor_right = resume_to_restart
	_resume_button.focus_previous = resume_to_return
	_resume_button.focus_next = resume_to_restart


## Configures the authored pause restart button focus neighbors.
func __configure_restart_navigation() -> void:
	var restart_to_resume := _restart_button.get_path_to(_resume_button)
	var restart_to_return := _restart_button.get_path_to(_return_button)
	_restart_button.focus_neighbor_top = restart_to_resume
	_restart_button.focus_neighbor_bottom = restart_to_return
	_restart_button.focus_neighbor_left = restart_to_resume
	_restart_button.focus_neighbor_right = restart_to_return
	_restart_button.focus_previous = restart_to_resume
	_restart_button.focus_next = restart_to_return


## Configures the authored pause return button focus neighbors.
func __configure_return_navigation() -> void:
	var return_to_resume := _return_button.get_path_to(_resume_button)
	var return_to_restart := _return_button.get_path_to(_restart_button)
	_return_button.focus_neighbor_top = return_to_restart
	_return_button.focus_neighbor_bottom = return_to_resume
	_return_button.focus_neighbor_left = return_to_restart
	_return_button.focus_neighbor_right = return_to_resume
	_return_button.focus_previous = return_to_restart
	_return_button.focus_next = return_to_resume


## Ensures overlay controls keep running while the rest of the scene updates around them.
func __set_process_mode_recursive(node: Node, mode: ProcessMode) -> void:
	if node == null:
		return

	node.process_mode = mode
	for child in node.get_children():
		__set_process_mode_recursive(child, mode)
