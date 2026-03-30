extends Control

## Owns pause-menu visibility, focus navigation, click hit testing, and pause button intent signals.


# Signals

signal resume_requested
signal restart_requested
signal return_to_title_requested


# Imports
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Constants
const PAUSE_MENU_ACTION_NONE: StringName = &""
const PAUSE_MENU_ACTION_RESUME: StringName = &"resume"
const PAUSE_MENU_ACTION_RESTART: StringName = &"restart"
const PAUSE_MENU_ACTION_RETURN_TO_TITLE: StringName = &"return_to_title"


# Public Fields
var menu_open := false


# Private Fields
var _run_state: RunStateType


# Private Fields: OnReady
@onready
var _pause_overlay: Control = %PauseOverlay

@onready
var _pause_panel: PanelContainer = %PausePanel

@onready
var _pause_resume_button: Button = %PauseResumeButton

@onready
var _pause_restart_button: Button = %PauseRestartButton

@onready
var _pause_return_button: Button = %PauseReturnButton


# Lifecycle Methods

## Configures pause-menu navigation and button wiring when the pause wrapper enters the tree.
func _ready() -> void:
	_configure_pause_menu_navigation()
	_set_process_mode_recursive(_pause_overlay, Node.PROCESS_MODE_ALWAYS)

	if _pause_resume_button != null and not _pause_resume_button.pressed.is_connected(_on_pause_resume_button_pressed):
		_pause_resume_button.pressed.connect(_on_pause_resume_button_pressed)
	if _pause_restart_button != null and not _pause_restart_button.pressed.is_connected(_on_pause_restart_button_pressed):
		_pause_restart_button.pressed.connect(_on_pause_restart_button_pressed)
	if (
		_pause_return_button != null
		and not _pause_return_button.pressed.is_connected(_on_pause_return_button_pressed)
	):
		_pause_return_button.pressed.connect(_on_pause_return_button_pressed)


# Event Handlers

## Emits the pause-menu resume intent upward.
func _on_pause_resume_button_pressed() -> void:
	resume_requested.emit()


## Emits the pause-menu restart intent upward.
func _on_pause_restart_button_pressed() -> void:
	restart_requested.emit()


## Emits the pause-menu return-to-title intent upward.
func _on_pause_return_button_pressed() -> void:
	return_to_title_requested.emit()


# Public Methods

## Binds the active run state so pause visibility tracks the current run.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


## Refreshes pause-menu visibility for the active run.
func refresh_pause_menu(menu_open_value: bool) -> void:
	menu_open = menu_open_value
	if _pause_overlay == null or _pause_panel == null:
		return

	var should_show_pause_menu := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and menu_open
	)
	_pause_overlay.visible = should_show_pause_menu
	_pause_panel.visible = should_show_pause_menu
	if (
		should_show_pause_menu
		and _pause_resume_button != null
		and _pause_restart_button != null
		and _pause_return_button != null
	):
		if (
			not _pause_resume_button.has_focus()
			and not _pause_restart_button.has_focus()
			and not _pause_return_button.has_focus()
		):
			focus_default_pause_button()


## Returns which pause-menu action, if any, was clicked by the current input event.
func get_click_action(event: InputEvent) -> StringName:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return PAUSE_MENU_ACTION_NONE
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return PAUSE_MENU_ACTION_NONE

	var click_position := mouse_event.position
	if _pause_resume_button != null and _pause_resume_button.get_global_rect().has_point(click_position):
		return PAUSE_MENU_ACTION_RESUME
	if _pause_restart_button != null and _pause_restart_button.get_global_rect().has_point(click_position):
		return PAUSE_MENU_ACTION_RESTART
	if _pause_return_button != null and _pause_return_button.get_global_rect().has_point(click_position):
		return PAUSE_MENU_ACTION_RETURN_TO_TITLE
	return PAUSE_MENU_ACTION_NONE


## Gives the pause menu a deterministic starting focus for keyboard-only play.
func focus_default_pause_button() -> void:
	if _pause_resume_button == null:
		return
	_pause_resume_button.grab_focus()


## Returns whether the pause overlay is currently visible.
func is_pause_menu_visible() -> bool:
	return _pause_overlay != null and _pause_overlay.visible


# Private Methods

## Configures explicit keyboard focus traversal for the pause menu buttons.
func _configure_pause_menu_navigation() -> void:
	if _pause_resume_button == null or _pause_restart_button == null or _pause_return_button == null:
		return

	_pause_resume_button.focus_mode = Control.FOCUS_ALL
	_pause_restart_button.focus_mode = Control.FOCUS_ALL
	_pause_return_button.focus_mode = Control.FOCUS_ALL

	var resume_to_restart := _pause_resume_button.get_path_to(_pause_restart_button)
	var resume_to_return := _pause_resume_button.get_path_to(_pause_return_button)
	var restart_to_resume := _pause_restart_button.get_path_to(_pause_resume_button)
	var restart_to_return := _pause_restart_button.get_path_to(_pause_return_button)
	var return_to_resume := _pause_return_button.get_path_to(_pause_resume_button)
	var return_to_restart := _pause_return_button.get_path_to(_pause_restart_button)

	_pause_resume_button.focus_neighbor_top = resume_to_return
	_pause_resume_button.focus_neighbor_bottom = resume_to_restart
	_pause_resume_button.focus_neighbor_left = resume_to_return
	_pause_resume_button.focus_neighbor_right = resume_to_restart
	_pause_resume_button.focus_previous = resume_to_return
	_pause_resume_button.focus_next = resume_to_restart

	_pause_restart_button.focus_neighbor_top = restart_to_resume
	_pause_restart_button.focus_neighbor_bottom = restart_to_return
	_pause_restart_button.focus_neighbor_left = restart_to_resume
	_pause_restart_button.focus_neighbor_right = restart_to_return
	_pause_restart_button.focus_previous = restart_to_resume
	_pause_restart_button.focus_next = restart_to_return

	_pause_return_button.focus_neighbor_top = return_to_restart
	_pause_return_button.focus_neighbor_bottom = return_to_resume
	_pause_return_button.focus_neighbor_left = return_to_restart
	_pause_return_button.focus_neighbor_right = return_to_resume
	_pause_return_button.focus_previous = return_to_restart
	_pause_return_button.focus_next = return_to_resume


## Ensures overlay controls keep running while the rest of the scene updates around them.
func _set_process_mode_recursive(node: Node, mode: ProcessMode) -> void:
	if node == null:
		return

	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)
