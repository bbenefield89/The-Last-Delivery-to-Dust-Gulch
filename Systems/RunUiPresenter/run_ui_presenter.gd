class_name RunUiPresenter
extends RefCounted

## Owns run-scene HUD, onboarding, recovery, pause/result panels, and touch-control visibility.

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
const PAUSE_MENU_ACTION_NONE: StringName = &""
const PAUSE_MENU_ACTION_RESUME: StringName = &"resume"
const PAUSE_MENU_ACTION_RESTART: StringName = &"restart"
const PAUSE_MENU_ACTION_RETURN_TO_TITLE: StringName = &"return_to_title"

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

var _run_state: RunState
var _health_bar: ProgressBar
var _health_label: Label
var _distance_bar: ProgressBar
var _distance_band_markers: Control
var _cargo_label: Label
var _touch_layer: CanvasLayer
var _touch_left_button: Button
var _touch_right_button: Button
var _touch_pause_button: Button
var _onboarding_panel: PanelContainer
var _onboarding_title: Label
var _onboarding_body: Label
var _onboarding_hint: Label
var _pause_overlay: Control
var _pause_panel: PanelContainer
var _pause_resume_button: Button
var _pause_restart_button: Button
var _pause_return_button: Button
var _recovery_panel: PanelContainer
var _recovery_title: Label
var _recovery_hint: Label
var _recovery_steps: HBoxContainer
var _result_panel: PanelContainer
var _result_title: Label
var _result_summary: Label
var _result_stats: Label
var _result_restart_button: Button
var _result_return_button: Button
var _arrow_font: Font


## Binds the scene-owned UI nodes and shared resources used by runtime UI presentation.
func configure_scene_nodes(
	run_state: RunState,
	health_bar: ProgressBar,
	health_label: Label,
	distance_bar: ProgressBar,
	distance_band_markers: Control,
	cargo_label: Label,
	touch_layer: CanvasLayer,
	touch_left_button: Button,
	touch_right_button: Button,
	touch_pause_button: Button,
	onboarding_panel: PanelContainer,
	onboarding_title: Label,
	onboarding_body: Label,
	onboarding_hint: Label,
	pause_overlay: Control,
	pause_panel: PanelContainer,
	pause_resume_button: Button,
	pause_restart_button: Button,
	pause_return_button: Button,
	recovery_panel: PanelContainer,
	recovery_title: Label,
	recovery_hint: Label,
	recovery_steps: HBoxContainer,
	result_panel: PanelContainer,
	result_title: Label,
	result_summary: Label,
	result_stats: Label,
	result_restart_button: Button,
	result_return_button: Button,
	arrow_font: Font
) -> void:
	_run_state = run_state
	_health_bar = health_bar
	_health_label = health_label
	_distance_bar = distance_bar
	_distance_band_markers = distance_band_markers
	_cargo_label = cargo_label
	_touch_layer = touch_layer
	_touch_left_button = touch_left_button
	_touch_right_button = touch_right_button
	_touch_pause_button = touch_pause_button
	_onboarding_panel = onboarding_panel
	_onboarding_title = onboarding_title
	_onboarding_body = onboarding_body
	_onboarding_hint = onboarding_hint
	_pause_overlay = pause_overlay
	_pause_panel = pause_panel
	_pause_resume_button = pause_resume_button
	_pause_restart_button = pause_restart_button
	_pause_return_button = pause_return_button
	_recovery_panel = recovery_panel
	_recovery_title = recovery_title
	_recovery_hint = recovery_hint
	_recovery_steps = recovery_steps
	_result_panel = result_panel
	_result_title = result_title
	_result_summary = result_summary
	_result_stats = result_stats
	_result_restart_button = result_restart_button
	_result_return_button = result_return_button
	_arrow_font = arrow_font


## Binds the active run state so runtime UI follows the current run.
func bind_run_state(run_state: RunState) -> void:
	_run_state = run_state


## Resets transient UI flow for a newly bound run without clearing runtime capability overrides.
func reset_for_new_run() -> void:
	onboarding_active = true
	pause_menu_open = false


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
		return

	var has_recovery := (
		_run_state.result == RunState.RESULT_IN_PROGRESS
		and not pause_menu_open
		and _run_state.has_active_recovery_sequence()
	)
	_recovery_panel.visible = has_recovery
	if not has_recovery:
		for child in _recovery_steps.get_children():
			child.queue_free()
		return

	for child in _recovery_steps.get_children():
		child.queue_free()

	_recovery_title.text = get_recovery_title(_run_state.active_failure)
	_recovery_hint.text = get_recovery_hint(_run_state.active_failure)
	_recovery_steps.custom_minimum_size.x = RECOVERY_STEP_ROW_MAX_WIDTH
	_recovery_steps.add_theme_constant_override("separation", RECOVERY_STEP_SPACING)

	for i in range(_run_state.recovery_sequence.size()):
		_recovery_steps.add_child(build_recovery_step(i))


## Refreshes onboarding visibility for the active run.
func refresh_onboarding_prompt() -> void:
	if _onboarding_panel == null or _onboarding_title == null or _onboarding_body == null or _onboarding_hint == null:
		return

	var is_visible := (
		_run_state != null
		and _run_state.result == RunState.RESULT_IN_PROGRESS
		and onboarding_active
		and not pause_menu_open
	)
	_onboarding_panel.visible = is_visible
	if not is_visible:
		return

	_onboarding_title.text = ONBOARDING_TITLE
	_onboarding_body.text = ONBOARDING_BODY
	_onboarding_hint.text = ONBOARDING_HINT


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

	var is_visible := _run_state != null and _run_state.result == RunState.RESULT_IN_PROGRESS and pause_menu_open
	_pause_overlay.visible = is_visible
	_pause_panel.visible = is_visible
	if (
		is_visible
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


## Refreshes the end-of-run result panel contents and visibility.
func refresh_result_screen(best_run_summary: String) -> void:
	if _result_panel == null or _result_title == null or _result_summary == null or _result_stats == null:
		return
	if _run_state == null or _run_state.result == RunState.RESULT_IN_PROGRESS:
		_result_panel.visible = false
		_result_summary.visible = false
		return

	_result_panel.visible = true
	match _run_state.result:
		RunState.RESULT_SUCCESS:
			_result_title.text = "Delivered to Dust Gulch"
		RunState.RESULT_COLLAPSED:
			_result_title.text = "Wagon Collapsed"
		_:
			_result_title.text = "Run Complete"

	_result_summary.text = best_run_summary
	_result_summary.visible = not _result_summary.text.is_empty()
	_result_stats.text = (
		"Score: %d\n"
		+ "Delivery Grade: %s\n"
		+ "Health: %d\n"
		+ "Cargo: %d\n"
		+ "Distance traveled: %.0f / %.0f\n"
		+ "Hazards Dodged: %d\n"
		+ "Near Misses: %d\n"
		+ "Perfect Recoveries: %d\n"
		+ "Recovery Failures: %d"
	) % [
		_run_state.get_score(),
		_run_state.get_delivery_grade(),
		_run_state.wagon_health,
		_run_state.cargo_value,
		_run_state.get_distance_traveled(),
		_run_state.route_distance,
		_run_state.hazards_dodged,
		_run_state.near_misses,
		_run_state.perfect_recoveries,
		_run_state.recovery_failures,
	]
	if (
		_result_restart_button != null
		and _result_return_button != null
		and not _result_restart_button.has_focus()
		and not _result_return_button.has_focus()
	):
		focus_default_result_button()


## Shows touch controls only while the run is actively playable on a supported runtime.
func refresh_touch_controls() -> void:
	if _touch_layer == null:
		return

	_refresh_touch_controls_runtime_state()
	var is_visible := should_show_touch_controls()
	_touch_layer.visible = is_visible
	if _touch_left_button != null:
		_touch_left_button.disabled = not is_visible
	if _touch_right_button != null:
		_touch_right_button.disabled = not is_visible
	if _touch_pause_button != null:
		_touch_pause_button.disabled = not is_visible


## Updates the pause state and returns whether it changed this frame.
func set_pause_state(paused: bool) -> bool:
	if _run_state == null:
		return false
	if _run_state.result != RunState.RESULT_IN_PROGRESS:
		paused = false

	var was_paused := pause_menu_open
	pause_menu_open = paused
	return was_paused != pause_menu_open


## Returns whether the touch layer should currently be visible and interactive.
func should_show_touch_controls() -> bool:
	return (
		touch_controls_enabled_for_runtime
		and _run_state != null
		and _run_state.result == RunState.RESULT_IN_PROGRESS
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


## Checks whether the current input event should dismiss the onboarding card.
func should_dismiss_onboarding(event: InputEvent) -> bool:
	if event == null:
		return false
	if event.is_action_pressed(&"steer_left", false, true):
		return true
	if event.is_action_pressed(&"steer_right", false, true):
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
	if _arrow_font != null:
		label.add_theme_font_override("font", _arrow_font)
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


## Enables touch controls automatically for native mobile and touch-capable mobile web runtimes.
func _refresh_touch_controls_runtime_state() -> void:
	if touch_controls_enabled_for_runtime:
		return
	if is_native_mobile_runtime():
		touch_controls_enabled_for_runtime = true
		return
	if is_mobile_web_runtime() and is_touchscreen_available():
		touch_controls_enabled_for_runtime = true


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
