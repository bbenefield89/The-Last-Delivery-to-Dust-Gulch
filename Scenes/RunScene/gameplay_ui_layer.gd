extends CanvasLayer

## Owns the run-scene gameplay UI subtree, wrapper state, HUD, onboarding, recovery prompt, and transient callouts.


# Imports
const PauseLayerType := preload(ProjectPaths.PAUSE_LAYER_SCRIPT_PATH)
const ResultLayerType := preload(ProjectPaths.RESULT_LAYER_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const TouchLayerType := preload(ProjectPaths.TOUCH_LAYER_SCRIPT_PATH)


# Constants
const ONBOARDING_TITLE := "Last Delivery to Dust Gulch"
const ONBOARDING_BODY := (
	"Steer with A/D or Left/Right. Dodge the hazards, protect your cargo, "
	+ "and hold the wagon together until you reach Dust Gulch."
)
const ONBOARDING_HINT := "Press Left, Right, Enter, or click to begin the run."
const RECOVERY_STEP_ROW_MAX_WIDTH := 240.0
const RECOVERY_STEP_MIN_WIDTH := 36.0
const RECOVERY_STEP_HEIGHT := 60.0
const RECOVERY_STEP_MAX_WIDTH := 72.0
const RECOVERY_STEP_FONT_SIZE_RATIO := 0.52
const RECOVERY_STEP_MIN_FONT_SIZE := 24
const RECOVERY_STEP_MAX_FONT_SIZE := 38
const RECOVERY_STEP_SPACING := 4
const RECOVERY_STEP_BASELINE_SEQUENCE_LENGTH := 3
const RECOVERY_STEP_PENDING_COLOR := Color(0.25098, 0.203922, 0.145098, 0.92)
const RECOVERY_STEP_ACTIVE_COLOR := Color(0.780392, 0.623529, 0.317647, 0.98)
const RECOVERY_STEP_DONE_COLOR := Color(0.419608, 0.54902, 0.290196, 0.95)
const BONUS_CALLOUT_DURATION := 1.1
const BONUS_CALLOUT_START_OFFSET := Vector2(0.0, -64.0)
const BONUS_CALLOUT_END_OFFSET := Vector2(0.0, -82.0)
const PHASE_CALLOUT_DURATION := 0.95
const TOUCH_LEFT_ACTION: StringName = &"steer_left"
const TOUCH_RIGHT_ACTION: StringName = &"steer_right"
const PAUSE_MENU_ACTION_NONE: StringName = PauseLayerType.PAUSE_MENU_ACTION_NONE
const PAUSE_MENU_ACTION_RESUME: StringName = PauseLayerType.PAUSE_MENU_ACTION_RESUME
const PAUSE_MENU_ACTION_RESTART: StringName = PauseLayerType.PAUSE_MENU_ACTION_RESTART
const PAUSE_MENU_ACTION_RETURN_TO_TITLE: StringName = PauseLayerType.PAUSE_MENU_ACTION_RETURN_TO_TITLE
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
const ARROW_FONT := preload(AssetPaths.ARROW_FONT_PATH)


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
var _bonus_callout_text := ""
var _bonus_callout_remaining := 0.0
var _bonus_callout_anchor_world_position := Vector2.ZERO
var _phase_callout_text := ""
var _phase_callout_remaining := 0.0
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
var _bonus_callout_layer: Control = $BonusCalloutLayer

@onready
var _phase_callout_layer: Control = $PhaseCalloutLayer

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
var _bonus_callout_panel: Control = %BonusCalloutPanel

@onready
var _bonus_callout_label: Label = %BonusCalloutLabel

@onready
var _phase_callout_panel: PanelContainer = %PhaseCalloutPanel

@onready
var _phase_callout_label: Label = %PhaseCalloutLabel

@onready
var _touch_layer: TouchLayerType = %TouchLayer

@onready
var _onboarding_layer: Control = $OnboardingLayer

@onready
var _onboarding_panel: PanelContainer = %OnboardingPanel

@onready
var _recovery_layer: Control = $RecoveryLayer

@onready
var _recovery_panel: PanelContainer = %RecoveryPanel

@onready
var _recovery_title: Label = %RecoveryTitle

@onready
var _recovery_hint: Label = %RecoveryHint

@onready
var _recovery_steps: HBoxContainer = %RecoverySteps

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
	if _pause_layer != null:
		_pause_layer.bind_run_state(run_state)
	if _result_layer != null:
		_result_layer.bind_run_state(run_state)


## Resets transient UI flow for a newly bound run without clearing runtime capability overrides.
func reset_for_new_run() -> void:
	onboarding_active = true
	pause_menu_open = false
	_bonus_callout_text = ""
	_bonus_callout_remaining = 0.0
	_bonus_callout_anchor_world_position = Vector2.ZERO
	_phase_callout_text = ""
	_phase_callout_remaining = 0.0


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
	if _recovery_panel == null or _recovery_steps == null or _recovery_title == null or _recovery_hint == null:
		return

	if _run_state == null:
		_recovery_panel.visible = false
		_refresh_gameplay_ui_layer_state()
		return

	var should_show_recovery_prompt := (
		_run_state.result == RunStateType.RESULT_IN_PROGRESS
		and not pause_menu_open
		and _run_state.has_active_recovery_sequence()
	)
	_recovery_panel.visible = should_show_recovery_prompt

	if not should_show_recovery_prompt:
		for child in _recovery_steps.get_children():
			child.queue_free()
		_refresh_gameplay_ui_layer_state()
		return

	for child in _recovery_steps.get_children():
		child.queue_free()

	_recovery_title.text = get_recovery_title(_run_state.active_failure)
	_recovery_hint.text = get_recovery_hint(_run_state.active_failure)
	_recovery_steps.custom_minimum_size.x = RECOVERY_STEP_ROW_MAX_WIDTH
	_recovery_steps.add_theme_constant_override("separation", RECOVERY_STEP_SPACING)

	for step_index in range(_run_state.recovery_sequence.size()):
		_recovery_steps.add_child(build_recovery_step(step_index))

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

	_pause_layer.refresh_pause_menu(pause_menu_open)
	_refresh_gameplay_ui_layer_state()


## Refreshes the end-of-run result panel contents and visibility.
func refresh_result_screen(best_run_summary: String) -> void:
	if _result_layer == null:
		return

	_result_layer.refresh_result_screen(best_run_summary)
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
		result.navigation_action = (
			_pause_layer.get_click_action(event) if _pause_layer != null else PAUSE_MENU_ACTION_NONE
		)
		if result.navigation_action != PAUSE_MENU_ACTION_NONE:
			result.consumed = true
			return result
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			result.consumed = true
			return result
		return result

	if onboarding_active:
		if should_dismiss_onboarding(event):
			result.dismissed_onboarding = true
			result.consumed = true
		return result

	if not _run_state.has_active_recovery_sequence():
		return result

	result.recovery_action = _get_recovery_action(event)
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
	_bonus_callout_text = text
	_bonus_callout_remaining = BONUS_CALLOUT_DURATION
	_bonus_callout_anchor_world_position = anchor_world_position
	refresh_bonus_callout(canvas_transform)


## Starts or refreshes the short-lived on-screen phase cue.
func show_phase_callout(text: String) -> void:
	_phase_callout_text = text
	_phase_callout_remaining = PHASE_CALLOUT_DURATION
	refresh_phase_callout()


## Advances the transient bonus and phase callout timers for the current frame.
func advance_callouts(delta: float, canvas_transform: Transform2D) -> void:
	if _bonus_callout_remaining > 0.0:
		_bonus_callout_remaining = max(0.0, _bonus_callout_remaining - max(0.0, delta))
		if _bonus_callout_remaining == 0.0:
			_bonus_callout_text = ""
	refresh_bonus_callout(canvas_transform)

	if _phase_callout_remaining > 0.0:
		_phase_callout_remaining = max(0.0, _phase_callout_remaining - max(0.0, delta))
		if _phase_callout_remaining == 0.0:
			_phase_callout_text = ""
	refresh_phase_callout()


## Shows a short in-run score callout while a bonus announcement is active.
func refresh_bonus_callout(canvas_transform: Transform2D) -> void:
	if _bonus_callout_panel == null or _bonus_callout_label == null:
		return

	var should_show_callout := _bonus_callout_remaining > 0.0 and _bonus_callout_text != ""
	_bonus_callout_panel.visible = should_show_callout
	if not should_show_callout:
		_bonus_callout_label.text = ""
		_bonus_callout_panel.self_modulate = Color(1, 1, 1, 1)
		_refresh_gameplay_ui_layer_state()
		return

	_bonus_callout_label.text = _bonus_callout_text
	var progress_ratio: float = 1.0 - (_bonus_callout_remaining / BONUS_CALLOUT_DURATION)
	var canvas_position: Vector2 = canvas_transform * _bonus_callout_anchor_world_position
	var flyout_offset: Vector2 = BONUS_CALLOUT_START_OFFSET.lerp(BONUS_CALLOUT_END_OFFSET, progress_ratio)
	var panel_size: Vector2 = _bonus_callout_panel.size
	_bonus_callout_panel.position = canvas_position + flyout_offset - (panel_size * 0.5)
	_bonus_callout_panel.self_modulate = Color(1, 1, 1, 1.0 - progress_ratio)
	_refresh_gameplay_ui_layer_state()


## Shows a short route-phase cue while an authored phase transition is active.
func refresh_phase_callout() -> void:
	if _phase_callout_panel == null or _phase_callout_label == null:
		return

	var should_show_callout := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and _phase_callout_remaining > 0.0
		and _phase_callout_text != ""
	)
	_phase_callout_panel.visible = should_show_callout
	if not should_show_callout:
		_phase_callout_label.text = ""
		_phase_callout_panel.self_modulate = Color(1, 1, 1, 1)
		_refresh_gameplay_ui_layer_state()
		return

	_phase_callout_label.text = _phase_callout_text
	var progress_ratio: float = 1.0 - (_phase_callout_remaining / PHASE_CALLOUT_DURATION)
	_phase_callout_panel.self_modulate = Color(1, 1, 1, 1.0 - (progress_ratio * 0.25))
	_refresh_gameplay_ui_layer_state()


## Shows representative result data while editing the scene in Godot.
func apply_editor_result_preview() -> void:
	if not Engine.is_editor_hint() or _result_layer == null:
		return

	_result_layer.apply_editor_result_preview()
	if _onboarding_panel != null:
		_onboarding_panel.visible = false
	if _recovery_panel != null:
		_recovery_panel.visible = false
	if _pause_layer != null:
		_pause_layer.refresh_pause_menu(false)
	_refresh_gameplay_ui_layer_state()


## Returns whether a touch pause press should open the pause menu.
func should_open_pause_from_touch() -> bool:
	return _touch_layer != null and _touch_layer.should_open_pause_from_touch(pause_menu_open)


## Releases both steering actions to avoid held touch state leaking across scene transitions.
func release_touch_steer_actions() -> void:
	if _touch_layer == null:
		return
	_touch_layer.release_touch_steer_actions()


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


## Returns the current recovery title for the active failure.
func get_recovery_title(failure_type: StringName) -> String:
	match failure_type:
		&"wheel_loose":
			return "Wheel Loose: Secure the Wagon"
		&"horse_panic":
			return "Horse Panic: Calm the Team"
		_:
			return "Recovery"


## Returns the current recovery hint for the active failure.
func get_recovery_hint(failure_type: StringName) -> String:
	match failure_type:
		&"wheel_loose":
			return "Steering is compromised. Match the sequence to lock the wheel."
		&"horse_panic":
			return "The wagon is swerving. Complete the full left-right pattern."
		_:
			return "Follow the prompts left to right."


## Returns the chip size that keeps the full recovery row inside a fixed width budget.
func get_recovery_step_minimum_size() -> Vector2:
	if _run_state == null:
		return Vector2(RECOVERY_STEP_MAX_WIDTH, RECOVERY_STEP_HEIGHT)

	var sequence_size: int = max(_run_state.recovery_sequence.size(), RECOVERY_STEP_BASELINE_SEQUENCE_LENGTH)
	var available_width: float = RECOVERY_STEP_ROW_MAX_WIDTH - ((sequence_size - 1) * RECOVERY_STEP_SPACING)
	var step_width: float = clampf(
		floor(available_width / float(sequence_size)),
		RECOVERY_STEP_MIN_WIDTH,
		RECOVERY_STEP_MAX_WIDTH
	)
	return Vector2(step_width, RECOVERY_STEP_HEIGHT)


## Returns the prompt font size that matches the active recovery chip width.
func get_recovery_step_font_size() -> int:
	var step_width := get_recovery_step_minimum_size().x
	return clampi(
		int(floor(step_width * RECOVERY_STEP_FONT_SIZE_RATIO)),
		RECOVERY_STEP_MIN_FONT_SIZE,
		RECOVERY_STEP_MAX_FONT_SIZE
	)


## Builds one recovery-step chip using the current compactness rules for the active sequence.
func build_recovery_step(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = get_recovery_step_minimum_size()
	panel.modulate = get_recovery_step_color(index)

	var label := Label.new()
	label.text = format_recovery_action(_run_state.recovery_sequence[index])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", get_recovery_step_font_size())
	if ARROW_FONT != null:
		label.add_theme_font_override("font", ARROW_FONT)
	panel.add_child(label)
	return panel


## Returns the authored color for one recovery-step chip based on current progress.
func get_recovery_step_color(index: int) -> Color:
	if index < _run_state.recovery_prompt_index:
		return RECOVERY_STEP_DONE_COLOR
	if index == _run_state.recovery_prompt_index:
		return RECOVERY_STEP_ACTIVE_COLOR
	return RECOVERY_STEP_PENDING_COLOR


## Returns the arrow-font glyph for one recovery action.
func format_recovery_action(action_name: StringName) -> String:
	match action_name:
		&"steer_left":
			return char(0xE020)
		&"steer_right":
			return char(0xE022)
		_:
			return String(action_name).to_upper()


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
		_bonus_callout_panel != null and _bonus_callout_panel.visible,
		Control.MOUSE_FILTER_IGNORE
	)
	_set_gameplay_ui_wrapper_state(
		_phase_callout_layer,
		_phase_callout_panel != null and _phase_callout_panel.visible,
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
		_recovery_panel != null and _recovery_panel.visible,
		Control.MOUSE_FILTER_IGNORE
	)
	_set_gameplay_ui_wrapper_state(
		_pause_layer,
		_pause_layer != null and _pause_layer.is_pause_menu_visible(),
		Control.MOUSE_FILTER_STOP
	)
	_set_gameplay_ui_wrapper_state(
		_result_layer,
		_result_layer != null and _result_layer.is_result_screen_visible(),
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


## Converts the latest input event into the expected recovery action name.
func _get_recovery_action(event: InputEvent) -> StringName:
	if event == null:
		return &""
	if event.is_action_pressed(TOUCH_LEFT_ACTION, false, true):
		return TOUCH_LEFT_ACTION
	if event.is_action_pressed(TOUCH_RIGHT_ACTION, false, true):
		return TOUCH_RIGHT_ACTION
	return &""


# Inner Classes
class UiInputResult:
	extends RefCounted

	## Captures the UI-specific interpretation of a single input event.

	var consumed := false
	var dismissed_onboarding := false
	var pause_command: StringName = PAUSE_COMMAND_NONE
	var navigation_action: StringName = PAUSE_MENU_ACTION_NONE
	var recovery_action: StringName = &""
