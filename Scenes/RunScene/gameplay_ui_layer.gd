extends CanvasLayer

## Owns the run-scene UI subtree, transient overlays, touch-control behavior, and UI input interpretation.


# Signals

signal touch_pause_requested
signal pause_resume_requested
signal pause_restart_requested
signal pause_return_to_title_requested
signal result_restart_requested
signal result_return_to_title_requested


# Imports
const ResultPanelUiType := preload(ProjectPaths.RESULT_PANEL_UI_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


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
const PAUSE_MENU_ACTION_NONE: StringName = &""
const PAUSE_MENU_ACTION_RESUME: StringName = &"resume"
const PAUSE_MENU_ACTION_RESTART: StringName = &"restart"
const PAUSE_MENU_ACTION_RETURN_TO_TITLE: StringName = &"return_to_title"
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
var pause_menu_open := false
var touch_controls_enabled_for_runtime := false
var has_native_mobile_runtime_override := false
var native_mobile_runtime_override := false
var has_mobile_web_runtime_override := false
var mobile_web_runtime_override := false
var has_touchscreen_available_override := false
var touchscreen_available_override := false


# Private Fields
var _run_state: RunStateType
var _bonus_callout_text := ""
var _bonus_callout_remaining := 0.0
var _bonus_callout_anchor_world_position := Vector2.ZERO
var _phase_callout_text := ""
var _phase_callout_remaining := 0.0


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
var _touch_layer: Control = %TouchLayer

@onready
var _touch_left_button: Button = %TouchLeft

@onready
var _touch_right_button: Button = %TouchRight

@onready
var _touch_pause_button: Button = %TouchPause

@onready
var _onboarding_layer: Control = $OnboardingLayer

@onready
var _onboarding_panel: PanelContainer = %OnboardingPanel

@onready
var _onboarding_title: Label = %OnboardingTitle

@onready
var _onboarding_body: Label = %OnboardingBody

@onready
var _onboarding_hint: Label = %OnboardingHint

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
var _pause_layer: Control = $PauseLayer

@onready
var _result_panel: ResultPanelUiType = %ResultPanel

@onready
var _result_restart_button: Button = %ResultRestartButton

@onready
var _result_return_button: Button = %ResultReturnButton

@onready
var _result_layer: Control = $ResultLayer


# Lifecycle Methods

## Configures UI subtree ownership and internal button wiring once the layer enters the scene tree.
func _ready() -> void:
	configure_gameplay_ui_layers()
	configure_touch_buttons()
	configure_pause_menu_navigation()
	configure_result_menu_navigation()
	_set_process_mode_recursive(_pause_overlay, Node.PROCESS_MODE_ALWAYS)

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
	if _pause_resume_button != null and not _pause_resume_button.pressed.is_connected(_on_pause_resume_button_pressed):
		_pause_resume_button.pressed.connect(_on_pause_resume_button_pressed)
	if _pause_restart_button != null and not _pause_restart_button.pressed.is_connected(_on_pause_restart_button_pressed):
		_pause_restart_button.pressed.connect(_on_pause_restart_button_pressed)
	if (
		_pause_return_button != null
		and not _pause_return_button.pressed.is_connected(_on_pause_return_button_pressed)
	):
		_pause_return_button.pressed.connect(_on_pause_return_button_pressed)
	if (
		_result_restart_button != null
		and not _result_restart_button.pressed.is_connected(_on_result_restart_button_pressed)
	):
		_result_restart_button.pressed.connect(_on_result_restart_button_pressed)
	if (
		_result_return_button != null
		and not _result_return_button.pressed.is_connected(_on_result_return_button_pressed)
	):
		_result_return_button.pressed.connect(_on_result_return_button_pressed)


# Event Handlers

## Emits a pause intent when the touch pause button is pressed during active gameplay.
func _on_touch_pause_button_pressed() -> void:
	if not should_open_pause_from_touch():
		return
	touch_pause_requested.emit()


## Presses the left steering action while the mobile left button is held.
func _on_touch_left_button_down() -> void:
	if not should_show_touch_controls():
		return
	_parse_touch_action_event(TOUCH_LEFT_ACTION, true)


## Releases the left steering action when the mobile left button is released.
func _on_touch_left_button_up() -> void:
	if not touch_controls_enabled_for_runtime:
		return
	_parse_touch_action_event(TOUCH_LEFT_ACTION, false)


## Presses the right steering action while the mobile right button is held.
func _on_touch_right_button_down() -> void:
	if not should_show_touch_controls():
		return
	_parse_touch_action_event(TOUCH_RIGHT_ACTION, true)


## Releases the right steering action when the mobile right button is released.
func _on_touch_right_button_up() -> void:
	if not touch_controls_enabled_for_runtime:
		return
	_parse_touch_action_event(TOUCH_RIGHT_ACTION, false)


## Emits the pause-menu resume intent upward.
func _on_pause_resume_button_pressed() -> void:
	pause_resume_requested.emit()


## Emits the pause-menu restart intent upward.
func _on_pause_restart_button_pressed() -> void:
	pause_restart_requested.emit()


## Emits the pause-menu return-to-title intent upward.
func _on_pause_return_button_pressed() -> void:
	pause_return_to_title_requested.emit()


## Emits the result-screen restart intent upward.
func _on_result_restart_button_pressed() -> void:
	result_restart_requested.emit()


## Emits the result-screen return-to-title intent upward.
func _on_result_return_button_pressed() -> void:
	result_return_to_title_requested.emit()


# Public Methods

## Binds the active run state so runtime UI follows the current run.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


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


## Applies the shared input-prompt font styling to the mobile touch buttons.
func configure_touch_buttons() -> void:
	if _touch_left_button != null:
		_touch_left_button.add_theme_font_override("font", ARROW_FONT)
		_touch_left_button.add_theme_stylebox_override("normal", _make_touch_button_stylebox())
		_touch_left_button.add_theme_stylebox_override(
			"hover",
			_make_touch_button_stylebox(RECOVERY_STEP_ACTIVE_COLOR)
		)
		_touch_left_button.add_theme_stylebox_override(
			"pressed",
			_make_touch_button_stylebox(RECOVERY_STEP_DONE_COLOR)
		)
		_touch_left_button.text = char(0xE020)
	if _touch_right_button != null:
		_touch_right_button.add_theme_font_override("font", ARROW_FONT)
		_touch_right_button.add_theme_stylebox_override("normal", _make_touch_button_stylebox())
		_touch_right_button.add_theme_stylebox_override(
			"hover",
			_make_touch_button_stylebox(RECOVERY_STEP_ACTIVE_COLOR)
		)
		_touch_right_button.add_theme_stylebox_override(
			"pressed",
			_make_touch_button_stylebox(RECOVERY_STEP_DONE_COLOR)
		)
		_touch_right_button.text = char(0xE022)
	if _touch_pause_button != null:
		_touch_pause_button.text = char(0xE061)
		_touch_pause_button.add_theme_font_override("font", ARROW_FONT)
		_touch_pause_button.add_theme_font_size_override("font_size", 52)
		_touch_pause_button.add_theme_stylebox_override("normal", _make_touch_button_stylebox())
		_touch_pause_button.add_theme_stylebox_override(
			"hover",
			_make_touch_button_stylebox(RECOVERY_STEP_ACTIVE_COLOR)
		)
		_touch_pause_button.add_theme_stylebox_override(
			"pressed",
			_make_touch_button_stylebox(RECOVERY_STEP_DONE_COLOR)
		)
		_touch_pause_button.rotation = PI / 2


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

	_health_bar.max_value = 100.0
	_health_bar.value = _run_state.wagon_health
	_health_label.text = "%d" % _run_state.wagon_health
	_distance_bar.max_value = 100.0
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

	var has_recovery := (
		_run_state.result == RunStateType.RESULT_IN_PROGRESS
		and not pause_menu_open
		and _run_state.has_active_recovery_sequence()
	)
	_recovery_panel.visible = has_recovery
	if not has_recovery:
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
	if _onboarding_panel == null or _onboarding_title == null or _onboarding_body == null or _onboarding_hint == null:
		return

	var should_show_panel := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and onboarding_active
		and not pause_menu_open
	)
	_onboarding_panel.visible = should_show_panel
	if should_show_panel:
		_onboarding_title.text = ONBOARDING_TITLE
		_onboarding_body.text = ONBOARDING_BODY
		_onboarding_hint.text = ONBOARDING_HINT

	_refresh_gameplay_ui_layer_state()


## Configures explicit keyboard focus traversal for the pause menu buttons.
func configure_pause_menu_navigation() -> void:
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


## Configures explicit keyboard focus traversal for the result screen buttons.
func configure_result_menu_navigation() -> void:
	if _result_restart_button == null or _result_return_button == null:
		return

	_result_restart_button.focus_mode = Control.FOCUS_ALL
	_result_return_button.focus_mode = Control.FOCUS_ALL

	var restart_to_return := _result_restart_button.get_path_to(_result_return_button)
	var return_to_restart := _result_return_button.get_path_to(_result_restart_button)

	_result_restart_button.focus_neighbor_top = restart_to_return
	_result_restart_button.focus_neighbor_bottom = restart_to_return
	_result_restart_button.focus_neighbor_left = restart_to_return
	_result_restart_button.focus_neighbor_right = restart_to_return
	_result_restart_button.focus_previous = restart_to_return
	_result_restart_button.focus_next = restart_to_return

	_result_return_button.focus_neighbor_top = return_to_restart
	_result_return_button.focus_neighbor_bottom = return_to_restart
	_result_return_button.focus_neighbor_left = return_to_restart
	_result_return_button.focus_neighbor_right = return_to_restart
	_result_return_button.focus_previous = return_to_restart
	_result_return_button.focus_next = return_to_restart


## Refreshes pause-menu visibility for the active run.
func refresh_pause_menu() -> void:
	if _pause_overlay == null or _pause_panel == null:
		return

	var should_show_pause_menu := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and pause_menu_open
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

	_refresh_gameplay_ui_layer_state()


## Refreshes the end-of-run result panel contents and visibility.
func refresh_result_screen(best_run_summary: String) -> void:
	if _result_panel == null:
		return
	if _run_state == null or _run_state.result == RunStateType.RESULT_IN_PROGRESS:
		_result_panel.visible = false
		_result_panel.clear_result_data()
		_refresh_gameplay_ui_layer_state()
		return

	_result_panel.visible = true
	_result_panel.set_result_data(_get_result_title(), best_run_summary, _build_result_stat_rows())
	if (
		_result_restart_button != null
		and _result_return_button != null
		and not _result_restart_button.has_focus()
		and not _result_return_button.has_focus()
	):
		focus_default_result_button()

	_refresh_gameplay_ui_layer_state()


## Shows touch controls only while the run is actively playable on a supported runtime.
func refresh_touch_controls() -> void:
	if _touch_layer == null:
		return

	var was_visible := _touch_layer.visible
	_refresh_touch_controls_runtime_state()
	var should_show_layer := should_show_touch_controls()
	_touch_layer.visible = should_show_layer
	if _touch_left_button != null:
		_touch_left_button.disabled = not should_show_layer
	if _touch_right_button != null:
		_touch_right_button.disabled = not should_show_layer
	if _touch_pause_button != null:
		_touch_pause_button.disabled = not should_show_layer
	if was_visible and not should_show_layer:
		release_touch_steer_actions()

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
	return (
		touch_controls_enabled_for_runtime
		and _run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and not pause_menu_open
	)


## Reveals touch controls after the first real touch on mobile web runtimes with delayed capability reporting.
func reveal_touch_controls_from_first_touch(event: InputEvent) -> void:
	if event == null or touch_controls_enabled_for_runtime:
		return
	if not is_mobile_web_runtime():
		return

	var screen_touch_event := event as InputEventScreenTouch
	if screen_touch_event != null and screen_touch_event.pressed:
		touch_controls_enabled_for_runtime = true
		refresh_touch_controls()
		return

	if event is InputEventScreenDrag:
		touch_controls_enabled_for_runtime = true
		refresh_touch_controls()


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
		result.navigation_action = get_pause_menu_click_action(event)
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
	if not Engine.is_editor_hint():
		return
	if _result_panel == null:
		return

	_result_panel.visible = true
	_result_panel.show_editor_preview()

	if _onboarding_panel != null:
		_onboarding_panel.visible = false
	if _pause_overlay != null:
		_pause_overlay.visible = false
	if _recovery_panel != null:
		_recovery_panel.visible = false


## Returns whether a touch pause press should open the pause menu.
func should_open_pause_from_touch() -> bool:
	return should_show_touch_controls()


## Releases both steering actions to avoid held touch state leaking across scene transitions.
func release_touch_steer_actions() -> void:
	_parse_touch_action_event(TOUCH_LEFT_ACTION, false)
	_parse_touch_action_event(TOUCH_RIGHT_ACTION, false)


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


## Returns which pause-menu action, if any, was clicked by the current input event.
func get_pause_menu_click_action(event: InputEvent) -> StringName:
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


## Gives the pause menu a deterministic starting focus for keyboard-only play.
func focus_default_pause_button() -> void:
	if _pause_resume_button == null:
		return
	_pause_resume_button.grab_focus()


## Gives the result screen a deterministic starting focus for keyboard-only play.
func focus_default_result_button() -> void:
	if _result_restart_button == null:
		return
	_result_restart_button.grab_focus()


## Returns whether the current runtime is a native Android or iOS build.
func is_native_mobile_runtime() -> bool:
	if has_native_mobile_runtime_override:
		return native_mobile_runtime_override
	return OS.has_feature("android") or OS.has_feature("ios")


## Returns whether the current runtime is a web export hosted on Android or iOS.
func is_mobile_web_runtime() -> bool:
	if has_mobile_web_runtime_override:
		return mobile_web_runtime_override
	return OS.has_feature("web_android") or OS.has_feature("web_ios")


## Returns whether the active runtime currently reports touchscreen capability.
func is_touchscreen_available() -> bool:
	if has_touchscreen_available_override:
		return touchscreen_available_override
	return DisplayServer.is_touchscreen_available()


# Private Methods

## Returns the visible result title that matches the active run outcome.
func _get_result_title() -> String:
	match _run_state.result:
		RunStateType.RESULT_SUCCESS:
			return "Delivered to Dust Gulch"
		RunStateType.RESULT_COLLAPSED:
			return "Wagon Collapsed"
		_:
			return "Run Complete"


## Builds the ordered structured stat rows shown in the result panel.
func _build_result_stat_rows() -> Array:
	return [
		ResultPanelUiType.ResultStatRowData.new("Score", "%d" % _run_state.get_score()),
		ResultPanelUiType.ResultStatRowData.new("Delivery Grade", _run_state.get_delivery_grade()),
		ResultPanelUiType.ResultStatRowData.new("Health", "%d" % _run_state.wagon_health),
		ResultPanelUiType.ResultStatRowData.new("Cargo", "%d" % _run_state.cargo_value),
		ResultPanelUiType.ResultStatRowData.new(
			"Distance traveled",
			"%.0f / %.0f" % [_run_state.get_distance_traveled(), _run_state.route_distance]
		),
		ResultPanelUiType.ResultStatRowData.new("Hazards Dodged", "%d" % _run_state.hazards_dodged),
		ResultPanelUiType.ResultStatRowData.new("Near Misses", "%d" % _run_state.near_misses),
		ResultPanelUiType.ResultStatRowData.new(
			"Perfect Recoveries",
			"%d" % _run_state.perfect_recoveries
		),
		ResultPanelUiType.ResultStatRowData.new(
			"Recovery Failures",
			"%d" % _run_state.recovery_failures
		),
	]


## Enables touch controls automatically for native mobile and touch-capable mobile web runtimes.
func _refresh_touch_controls_runtime_state() -> void:
	if touch_controls_enabled_for_runtime:
		return
	if is_native_mobile_runtime():
		touch_controls_enabled_for_runtime = true
		return
	if is_mobile_web_runtime() and is_touchscreen_available():
		touch_controls_enabled_for_runtime = true


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
		_pause_overlay != null and _pause_overlay.visible,
		Control.MOUSE_FILTER_STOP
	)
	_set_gameplay_ui_wrapper_state(
		_result_layer,
		_result_panel != null and _result_panel.visible,
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


## Builds a touch-button stylebox that matches the recovery-step chips.
func _make_touch_button_stylebox(
	background_color: Color = RECOVERY_STEP_PENDING_COLOR
) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = background_color
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.745098, 0.592157, 0.305882, 0.95)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	return stylebox


## Injects a synthetic steering action event so touch input shares the keyboard gameplay path.
func _parse_touch_action_event(action_name: StringName, pressed: bool) -> void:
	var action_event := InputEventAction.new()
	action_event.action = action_name
	action_event.pressed = pressed
	Input.parse_input_event(action_event)


## Converts the latest input event into the expected recovery action name.
func _get_recovery_action(event: InputEvent) -> StringName:
	if event == null:
		return &""
	if event.is_action_pressed(TOUCH_LEFT_ACTION, false, true):
		return TOUCH_LEFT_ACTION
	if event.is_action_pressed(TOUCH_RIGHT_ACTION, false, true):
		return TOUCH_RIGHT_ACTION
	return &""


## Ensures overlay controls keep running while the rest of the scene updates around them.
func _set_process_mode_recursive(node: Node, mode: ProcessMode) -> void:
	if node == null:
		return

	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)


# Inner Classes
class UiInputResult:
	extends RefCounted

	## Captures the UI-specific interpretation of a single input event.

	var consumed := false
	var dismissed_onboarding := false
	var pause_command: StringName = PAUSE_COMMAND_NONE
	var navigation_action: StringName = PAUSE_MENU_ACTION_NONE
	var recovery_action: StringName = &""
