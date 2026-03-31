extends Control

## Owns touch-control runtime visibility and synthetic steering input for the run UI.


# Signals

signal pause_requested


# Imports
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Constants
const TOUCH_LEFT_ACTION: StringName = &"steer_left"
const TOUCH_RIGHT_ACTION: StringName = &"steer_right"


# Public Fields
var are_touch_controls_enabled_for_runtime := false
var has_native_mobile_runtime_override := false
var is_native_mobile_runtime_override := false
var has_mobile_web_runtime_override := false
var is_mobile_web_runtime_override := false
var has_touchscreen_available_override := false
var is_touchscreen_available_override := false


# Private Fields
var _run_state: RunStateType


# Private Fields: OnReady
@onready
var _touch_left_button: Button = %TouchLeft

@onready
var _touch_right_button: Button = %TouchRight

@onready
var _touch_pause_button: Button = %TouchPause


# Lifecycle Methods

## Configures runtime button wiring.
func _ready() -> void:
	if _touch_left_button != null and not _touch_left_button.button_down.is_connected(_on_touch_left_button_down):
		_touch_left_button.button_down.connect(_on_touch_left_button_down)

	if _touch_left_button != null and not _touch_left_button.button_up.is_connected(_on_touch_left_button_up):
		_touch_left_button.button_up.connect(_on_touch_left_button_up)

	if _touch_right_button != null and not _touch_right_button.button_down.is_connected(_on_touch_right_button_down):
		_touch_right_button.button_down.connect(_on_touch_right_button_down)

	if _touch_right_button != null and not _touch_right_button.button_up.is_connected(_on_touch_right_button_up):
		_touch_right_button.button_up.connect(_on_touch_right_button_up)

	if _touch_pause_button != null and not _touch_pause_button.pressed.is_connected(_on_touch_pause_button_pressed):
		_touch_pause_button.pressed.connect(_on_touch_pause_button_pressed)


# Event Handlers

## Emits a pause intent when the touch pause button is pressed during active gameplay.
func _on_touch_pause_button_pressed() -> void:
	if not should_open_pause_from_touch(false):
		return
	pause_requested.emit()


## Presses the left steering action while the mobile left button is held.
func _on_touch_left_button_down() -> void:
	if not should_show_touch_controls(false):
		return
	_parse_touch_action_event(TOUCH_LEFT_ACTION, true)


## Releases the left steering action when the mobile left button is released.
func _on_touch_left_button_up() -> void:
	if not are_touch_controls_enabled_for_runtime:
		return
	_parse_touch_action_event(TOUCH_LEFT_ACTION, false)


## Presses the right steering action while the mobile right button is held.
func _on_touch_right_button_down() -> void:
	if not should_show_touch_controls(false):
		return
	_parse_touch_action_event(TOUCH_RIGHT_ACTION, true)


## Releases the right steering action when the mobile right button is released.
func _on_touch_right_button_up() -> void:
	if not are_touch_controls_enabled_for_runtime:
		return
	_parse_touch_action_event(TOUCH_RIGHT_ACTION, false)


# Public Methods

## Binds the active run state so touch visibility tracks the current run.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


## Shows touch controls only while the run is actively playable on a supported runtime.
func refresh_touch_controls(pause_menu_open: bool) -> void:
	var was_visible := visible
	_refresh_touch_controls_runtime_state()

	var should_show_layer := should_show_touch_controls(pause_menu_open)
	visible = should_show_layer
	if _touch_left_button != null:
		_touch_left_button.disabled = not should_show_layer
	if _touch_right_button != null:
		_touch_right_button.disabled = not should_show_layer
	if _touch_pause_button != null:
		_touch_pause_button.disabled = not should_show_layer
	if was_visible and not should_show_layer:
		release_touch_steer_actions()


## Returns whether the touch layer should currently be visible and interactive.
func should_show_touch_controls(pause_menu_open: bool) -> bool:
	return (
		are_touch_controls_enabled_for_runtime
		and _run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and not pause_menu_open
	)


## Returns whether a touch pause press should open the pause menu.
func should_open_pause_from_touch(pause_menu_open: bool) -> bool:
	return should_show_touch_controls(pause_menu_open)


## Reveals touch controls after the first real touch on mobile web runtimes with delayed capability reporting.
func reveal_touch_controls_from_first_touch(event: InputEvent, pause_menu_open: bool) -> void:
	if event == null or are_touch_controls_enabled_for_runtime:
		return
	if not is_mobile_web_runtime():
		return

	var screen_touch_event := event as InputEventScreenTouch
	var should_enable_touch_controls := (
		screen_touch_event != null and screen_touch_event.pressed
	) or event is InputEventScreenDrag
	if not should_enable_touch_controls:
		return

	are_touch_controls_enabled_for_runtime = true
	refresh_touch_controls(pause_menu_open)


## Releases both steering actions to avoid held touch state leaking across scene transitions.
func release_touch_steer_actions() -> void:
	_parse_touch_action_event(TOUCH_LEFT_ACTION, false)
	_parse_touch_action_event(TOUCH_RIGHT_ACTION, false)


## Returns whether the current runtime is a native Android or iOS build.
func is_native_mobile_runtime() -> bool:
	if has_native_mobile_runtime_override:
		return is_native_mobile_runtime_override
	return OS.has_feature("android") or OS.has_feature("ios")


## Returns whether the current runtime is a web export hosted on Android or iOS.
func is_mobile_web_runtime() -> bool:
	if has_mobile_web_runtime_override:
		return is_mobile_web_runtime_override
	return OS.has_feature("web_android") or OS.has_feature("web_ios")


## Returns whether the active runtime currently reports touchscreen capability.
func is_touchscreen_available() -> bool:
	if has_touchscreen_available_override:
		return is_touchscreen_available_override
	return DisplayServer.is_touchscreen_available()


# Private Methods

## Enables touch controls automatically for native mobile and touch-capable mobile web runtimes.
func _refresh_touch_controls_runtime_state() -> void:
	if are_touch_controls_enabled_for_runtime:
		return
	if is_native_mobile_runtime():
		are_touch_controls_enabled_for_runtime = true
		return
	if is_mobile_web_runtime() and is_touchscreen_available():
		are_touch_controls_enabled_for_runtime = true


## Injects a synthetic steering action event so touch input shares the keyboard gameplay path.
func _parse_touch_action_event(action_name: StringName, pressed: bool) -> void:
	var action_event := InputEventAction.new()
	action_event.action = action_name
	action_event.pressed = pressed
	Input.parse_input_event(action_event)
