extends CanvasLayer

## Coordinates the run-scene UI tree while delegating layer-specific behavior to child owners.


# Imports
const BonusCalloutLayerType := preload(ProjectPaths.BONUS_CALLOUT_LAYER_SCRIPT_PATH)
const PauseLayerType := preload(ProjectPaths.PAUSE_LAYER_SCRIPT_PATH)
const PhaseCalloutLayerType := preload(ProjectPaths.PHASE_CALLOUT_LAYER_SCRIPT_PATH)
const RecoveryLayerType := preload(ProjectPaths.RECOVERY_LAYER_SCRIPT_PATH)
const ResultLayerType := preload(ProjectPaths.RESULT_LAYER_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const TouchLayerType := preload(ProjectPaths.TOUCH_LAYER_SCRIPT_PATH)


# Constants
const TOUCH_LEFT_ACTION: StringName = &"steer_left"
const TOUCH_RIGHT_ACTION: StringName = &"steer_right"
const PAUSE_COMMAND_NONE: StringName = &""
const PAUSE_COMMAND_TOGGLE: StringName = &"toggle"
const PAUSE_COMMAND_CLOSE: StringName = &"close"
const GAMEPLAY_UI_LAYER_NAMES: Array[StringName] = [
	&"HUDLayer",
	&"BonusCalloutLayer",
	&"PhaseCalloutLayer",
	&"TouchLayer",
	&"OnboardingLayer",
	&"RecoveryLayer",
	&"PauseLayer",
	&"ResultLayer",
]


# Public Fields
var onboarding_active := false
var pause_menu_open := false:
	get:
		return _pause_layer.menu_open if _pause_layer != null else _pause_menu_open
	set(value):
		_pause_menu_open = value
		if _pause_layer != null:
			_pause_layer.menu_open = value

var touch_controls_enabled_for_runtime := false:
	get:
		return (
			_touch_layer.touch_controls_enabled_for_runtime
			if _touch_layer != null
			else _touch_controls_enabled_for_runtime
		)
	set(value):
		_touch_controls_enabled_for_runtime = value
		if _touch_layer != null:
			_touch_layer.touch_controls_enabled_for_runtime = value

var has_native_mobile_runtime_override := false:
	get:
		return (
			_touch_layer.has_native_mobile_runtime_override
			if _touch_layer != null
			else _has_native_mobile_runtime_override
		)
	set(value):
		_has_native_mobile_runtime_override = value
		if _touch_layer != null:
			_touch_layer.has_native_mobile_runtime_override = value

var native_mobile_runtime_override := false:
	get:
		return (
			_touch_layer.native_mobile_runtime_override
			if _touch_layer != null
			else _native_mobile_runtime_override
		)
	set(value):
		_native_mobile_runtime_override = value
		if _touch_layer != null:
			_touch_layer.native_mobile_runtime_override = value

var has_mobile_web_runtime_override := false:
	get:
		return (
			_touch_layer.has_mobile_web_runtime_override
			if _touch_layer != null
			else _has_mobile_web_runtime_override
		)
	set(value):
		_has_mobile_web_runtime_override = value
		if _touch_layer != null:
			_touch_layer.has_mobile_web_runtime_override = value

var mobile_web_runtime_override := false:
	get:
		return (
			_touch_layer.mobile_web_runtime_override
			if _touch_layer != null
			else _mobile_web_runtime_override
		)
	set(value):
		_mobile_web_runtime_override = value
		if _touch_layer != null:
			_touch_layer.mobile_web_runtime_override = value

var has_touchscreen_available_override := false:
	get:
		return (
			_touch_layer.has_touchscreen_available_override
			if _touch_layer != null
			else _has_touchscreen_available_override
		)
	set(value):
		_has_touchscreen_available_override = value
		if _touch_layer != null:
			_touch_layer.has_touchscreen_available_override = value

var touchscreen_available_override := false:
	get:
		return (
			_touch_layer.touchscreen_available_override
			if _touch_layer != null
			else _touchscreen_available_override
		)
	set(value):
		_touchscreen_available_override = value
		if _touch_layer != null:
			_touch_layer.touchscreen_available_override = value


# Private Fields
var _run_state: RunStateType
var _pause_menu_open := false
var _touch_controls_enabled_for_runtime := false
var _has_native_mobile_runtime_override := false
var _native_mobile_runtime_override := false
var _has_mobile_web_runtime_override := false
var _mobile_web_runtime_override := false
var _has_touchscreen_available_override := false
var _touchscreen_available_override := false


# Private Fields: OnReady
@onready
var _hud_layer: Control = $HUDLayer

@onready
var _bonus_callout_layer: BonusCalloutLayerType = $BonusCalloutLayer

@onready
var _phase_callout_layer: PhaseCalloutLayerType = $PhaseCalloutLayer

@onready
var _health_bar: ProgressBar = %HealthBar

@onready
var _health_label: Label = %HealthLabel

@onready
var _distance_bar: ProgressBar = %DistanceBar

@onready
var _distance_band_markers: Control = %DistanceBandMarkers

@onready
var _cargo_label: Label = %CargoLabel

@onready
var _touch_layer: TouchLayerType = %TouchLayer

@onready
var _onboarding_layer: Control = $OnboardingLayer

@onready
var _onboarding_panel: PanelContainer = %OnboardingPanel

@onready
var _recovery_layer: RecoveryLayerType = $RecoveryLayer

@onready
var _pause_layer: PauseLayerType = %PauseLayer

@onready
var _result_layer: ResultLayerType = %ResultLayer


# Lifecycle Methods

## Configures wrapper ordering and synchronizes sublayer-owned runtime state.
func _ready() -> void:
	configure_gameplay_ui_layers()
	_sync_touch_layer_state()
	if _pause_layer != null:
		_pause_layer.menu_open = _pause_menu_open
	_refresh_gameplay_ui_layer_state()


# Public Methods

## Binds the active run state so runtime UI follows the current run.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state
	if _touch_layer != null:
		_touch_layer.bind_run_state(run_state)
	if _phase_callout_layer != null:
		_phase_callout_layer.bind_run_state(run_state)
	if _recovery_layer != null:
		_recovery_layer.bind_run_state(run_state)
	if _pause_layer != null:
		_pause_layer.bind_run_state(run_state)
	if _result_layer != null:
		_result_layer.bind_run_state(run_state)


## Resets transient UI flow for a newly bound run without clearing runtime capability overrides.
func reset_for_new_run() -> void:
	onboarding_active = true
	pause_menu_open = false
	if _bonus_callout_layer != null:
		_bonus_callout_layer.clear_callout()
	if _phase_callout_layer != null:
		_phase_callout_layer.clear_callout()


## Rebuilds the distance bar markers from the authored route-band thresholds.
func configure_distance_bar_band_markers(
	distance_bar_band_boundaries: Array,
	distance_bar_marker_color: Color,
	distance_bar_marker_half_width: float
) -> void:
	if _distance_band_markers == null:
		return

	for child in _distance_band_markers.get_children():
		child.queue_free()

	for boundary in distance_bar_band_boundaries:
		var marker := ColorRect.new()
		marker.color = distance_bar_marker_color
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.anchor_left = boundary
		marker.anchor_right = boundary
		marker.anchor_bottom = 1.0
		marker.offset_left = -distance_bar_marker_half_width
		marker.offset_right = distance_bar_marker_half_width
		_distance_band_markers.add_child(marker)


## Applies explicit gameplay UI wrapper order, stacking, and mouse-filter policy.
func configure_gameplay_ui_layers() -> void:
	for layer_index in range(GAMEPLAY_UI_LAYER_NAMES.size()):
		var layer_name := GAMEPLAY_UI_LAYER_NAMES[layer_index]
		var layer_node := get_node_or_null(NodePath(String(layer_name))) as Control
		if layer_node == null:
			continue

		move_child(layer_node, layer_index)
		layer_node.z_as_relative = false
		layer_node.z_index = layer_index

	_refresh_gameplay_ui_layer_state()


## Refreshes the compact run HUD values from the bound run state.
func refresh_status() -> void:
	if (
		_health_bar == null
		or _health_label == null
		or _distance_bar == null
		or _cargo_label == null
	):
		return

	if _run_state == null:
		_health_bar.value = 0.0
		_health_label.text = "--"
		_distance_bar.value = 0.0
		_cargo_label.text = "Cargo --"
		return

	_health_bar.value = _run_state.wagon_health
	_health_label.text = "%d" % _run_state.wagon_health
	_distance_bar.value = _run_state.get_delivery_progress_ratio() * 100.0
	_cargo_label.text = "Cargo %d" % _run_state.cargo_value


## Shows only the active recovery sequence prompt when gameplay allows it.
func refresh_recovery_prompt() -> void:
	if _recovery_layer == null:
		return

	_recovery_layer.refresh_prompt(pause_menu_open)
	_refresh_gameplay_ui_layer_state()


## Refreshes onboarding visibility for the active run.
func refresh_onboarding_prompt() -> void:
	if _onboarding_panel == null:
		return

	_onboarding_panel.visible = (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and onboarding_active
		and not pause_menu_open
	)
	_refresh_gameplay_ui_layer_state()


## Refreshes pause-menu visibility for the active run.
func refresh_pause_menu() -> void:
	if _pause_layer == null:
		return

	_pause_layer.refresh_menu(pause_menu_open)
	_refresh_gameplay_ui_layer_state()


## Refreshes the end-of-run result panel contents and visibility.
func refresh_result_screen(best_run_summary: String) -> void:
	if _result_layer == null:
		return

	_result_layer.refresh_screen(best_run_summary)
	_refresh_gameplay_ui_layer_state()


## Shows touch controls only while the run is actively playable on a supported runtime.
func refresh_touch_controls() -> void:
	if _touch_layer == null:
		return

	_touch_layer.refresh_touch_controls(pause_menu_open)
	_refresh_gameplay_ui_layer_state()


## Updates the pause state and returns whether it changed this frame.
func set_pause_state(paused: bool) -> bool:
	if _run_state == null:
		return false
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		paused = false

	var was_paused := pause_menu_open
	pause_menu_open = paused
	var changed := was_paused != pause_menu_open
	if changed:
		refresh_onboarding_prompt()
		refresh_pause_menu()
		refresh_recovery_prompt()
		refresh_touch_controls()
	return changed


## Returns whether the touch layer should currently be visible and interactive.
func should_show_touch_controls() -> bool:
	return _touch_layer != null and _touch_layer.should_show_touch_controls(pause_menu_open)


## Reveals touch controls after the first real touch on mobile web runtimes with delayed capability reporting.
func reveal_touch_controls_from_first_touch(event: InputEvent) -> void:
	if _touch_layer == null:
		return

	_touch_layer.reveal_touch_controls_from_first_touch(event, pause_menu_open)
	_refresh_gameplay_ui_layer_state()


## Interprets one input event against the active UI state and returns the requested UI action.
func route_input(event: InputEvent, pause_action: StringName) -> UiInputResult:
	reveal_touch_controls_from_first_touch(event)

	var result := UiInputResult.new()
	if _run_state == null:
		return result

	if event != null and event.is_action_pressed(pause_action):
		if _run_state.result == RunStateType.RESULT_IN_PROGRESS:
			result.pause_command = PAUSE_COMMAND_TOGGLE
		result.consumed = true
		return result

	if pause_menu_open and event != null and event.is_action_pressed(&"ui_cancel", false, true):
		result.pause_command = PAUSE_COMMAND_CLOSE
		result.consumed = true
		return result

	if pause_menu_open:
		result.consumed = _pause_layer != null and _pause_layer.should_consume_event(event)
		return result

	if onboarding_active:
		if should_dismiss_onboarding(event):
			result.dismissed_onboarding = true
			result.consumed = true
		return result

	if not _run_state.has_active_recovery_sequence() or _recovery_layer == null:
		return result

	result.recovery_action = _recovery_layer.get_input_action(event)
	result.consumed = result.recovery_action != &""
	return result


## Marks onboarding as dismissed and refreshes the visible gameplay UI state.
func dismiss_onboarding() -> void:
	onboarding_active = false
	refresh_onboarding_prompt()


## Starts or refreshes the short-lived in-run bonus callout text.
func show_bonus_callout(
	text: String,
	anchor_world_position: Vector2,
	canvas_transform: Transform2D
) -> void:
	if _bonus_callout_layer == null:
		return

	_bonus_callout_layer.show_callout(text, anchor_world_position, canvas_transform)
	_refresh_gameplay_ui_layer_state()


## Starts or refreshes the short-lived on-screen phase cue.
func show_phase_callout(text: String) -> void:
	if _phase_callout_layer == null:
		return

	_phase_callout_layer.show_callout(text)
	_refresh_gameplay_ui_layer_state()


## Advances the transient bonus and phase callout timers for the current frame.
func advance_callouts(delta: float, canvas_transform: Transform2D) -> void:
	if _bonus_callout_layer != null:
		_bonus_callout_layer.advance(delta, canvas_transform)
	if _phase_callout_layer != null:
		_phase_callout_layer.advance(delta)
	_refresh_gameplay_ui_layer_state()


## Refreshes the current bonus callout without mutating caller-owned timer state.
func refresh_bonus_callout(canvas_transform: Transform2D) -> void:
	if _bonus_callout_layer == null:
		return

	_bonus_callout_layer.refresh_callout(canvas_transform)
	_refresh_gameplay_ui_layer_state()


## Refreshes the current phase callout without mutating caller-owned timer state.
func refresh_phase_callout() -> void:
	if _phase_callout_layer == null:
		return

	_phase_callout_layer.refresh_callout()
	_refresh_gameplay_ui_layer_state()


## Shows representative result data while editing the scene in Godot.
func apply_editor_result_preview() -> void:
	if not Engine.is_editor_hint() or _result_layer == null:
		return

	_result_layer.apply_editor_result_preview()
	if _onboarding_panel != null:
		_onboarding_panel.visible = false
	if _recovery_layer != null:
		_recovery_layer.clear_prompt()
	if _pause_layer != null:
		_pause_layer.refresh_menu(false)
	_refresh_gameplay_ui_layer_state()


## Returns whether a touch pause press should open the pause menu.
func should_open_pause_from_touch() -> bool:
	return _touch_layer != null and _touch_layer.should_open_pause_from_touch(pause_menu_open)


## Releases both steering actions to avoid held touch state leaking across scene transitions.
func release_touch_steer_actions() -> void:
	if _touch_layer == null:
		return

	_touch_layer.release_touch_steer_actions()


## Returns the current recovery chip minimum size from the dedicated recovery layer.
func get_recovery_step_minimum_size() -> Vector2:
	return (
		_recovery_layer.get_step_minimum_size()
		if _recovery_layer != null
		else Vector2(RecoveryLayerType.STEP_MAX_WIDTH, RecoveryLayerType.STEP_HEIGHT)
	)


## Returns the current recovery chip font size from the dedicated recovery layer.
func get_recovery_step_font_size() -> int:
	return (
		_recovery_layer.get_step_font_size()
		if _recovery_layer != null
		else RecoveryLayerType.STEP_MIN_FONT_SIZE
	)


## Formats one recovery action using the dedicated recovery layer.
func format_recovery_action(action_name: StringName) -> String:
	return _recovery_layer.format_action(action_name) if _recovery_layer != null else String(action_name)


## Checks whether the current input event should dismiss the onboarding card.
func should_dismiss_onboarding(event: InputEvent) -> bool:
	if event == null:
		return false
	if event.is_action_pressed(TOUCH_LEFT_ACTION, false, true):
		return true
	if event.is_action_pressed(TOUCH_RIGHT_ACTION, false, true):
		return true
	if event.is_action_pressed(&"ui_accept", false, true):
		return true
	if event.is_action_pressed(&"ui_cancel", false, true):
		return true

	var mouse_event := event as InputEventMouseButton
	return mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed


# Private Methods

## Synchronizes the gameplay layer touch proxy values onto the touch sublayer once it is ready.
func _sync_touch_layer_state() -> void:
	if _touch_layer == null:
		return

	_touch_layer.touch_controls_enabled_for_runtime = _touch_controls_enabled_for_runtime
	_touch_layer.has_native_mobile_runtime_override = _has_native_mobile_runtime_override
	_touch_layer.native_mobile_runtime_override = _native_mobile_runtime_override
	_touch_layer.has_mobile_web_runtime_override = _has_mobile_web_runtime_override
	_touch_layer.mobile_web_runtime_override = _mobile_web_runtime_override
	_touch_layer.has_touchscreen_available_override = _has_touchscreen_available_override
	_touch_layer.touchscreen_available_override = _touchscreen_available_override


## Keeps each gameplay UI wrapper aligned with the currently visible overlay state.
func _refresh_gameplay_ui_layer_state() -> void:
	_set_gameplay_ui_wrapper_state(_hud_layer, true, Control.MOUSE_FILTER_IGNORE)
	_set_gameplay_ui_wrapper_state(
		_bonus_callout_layer,
		_bonus_callout_layer != null and _bonus_callout_layer.is_callout_visible(),
		Control.MOUSE_FILTER_IGNORE
	)
	_set_gameplay_ui_wrapper_state(
		_phase_callout_layer,
		_phase_callout_layer != null and _phase_callout_layer.is_callout_visible(),
		Control.MOUSE_FILTER_IGNORE
	)
	_set_gameplay_ui_wrapper_state(
		_touch_layer,
		_touch_layer != null and _touch_layer.visible,
		Control.MOUSE_FILTER_IGNORE
	)
	_set_gameplay_ui_wrapper_state(
		_onboarding_layer,
		_onboarding_panel != null and _onboarding_panel.visible,
		Control.MOUSE_FILTER_STOP
	)
	_set_gameplay_ui_wrapper_state(
		_recovery_layer,
		_recovery_layer != null and _recovery_layer.is_prompt_visible(),
		Control.MOUSE_FILTER_IGNORE
	)
	_set_gameplay_ui_wrapper_state(
		_pause_layer,
		_pause_layer != null and _pause_layer.is_menu_visible(),
		Control.MOUSE_FILTER_STOP
	)
	_set_gameplay_ui_wrapper_state(
		_result_layer,
		_result_layer != null and _result_layer.is_screen_visible(),
		Control.MOUSE_FILTER_STOP
	)


## Applies one gameplay UI wrapper visibility and mouse policy without touching its children.
func _set_gameplay_ui_wrapper_state(
	layer: Control,
	should_be_visible: bool,
	mouse_filter: Control.MouseFilter
) -> void:
	if layer == null:
		return

	layer.visible = should_be_visible
	layer.mouse_filter = mouse_filter if should_be_visible else Control.MOUSE_FILTER_IGNORE


# Inner Classes
class UiInputResult:
	extends RefCounted

	## Captures the UI-specific interpretation of a single input event.

	var consumed := false
	var dismissed_onboarding := false
	var pause_command: StringName = PAUSE_COMMAND_NONE
	var recovery_action: StringName = &""
