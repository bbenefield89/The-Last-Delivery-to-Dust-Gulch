extends Control

## Owns the run-scene recovery prompt copy, layout, and compact step-chip rendering.


# Imports
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Constants
const TOUCH_LEFT_ACTION: StringName = &"steer_left"
const TOUCH_RIGHT_ACTION: StringName = &"steer_right"
const DEFAULT_STEP_MIN_FONT_SIZE := 24
const DEFAULT_STEP_MAX_WIDTH := 72.0
const DEFAULT_STEP_HEIGHT := 60.0


# Private Fields: Export
@export var _step_font: Font
@export var _step_min_width := 36.0
@export var _step_height := 60.0
@export var _step_max_width := 72.0
@export var _step_font_size_ratio := 0.52
@export var _step_min_font_size := 24
@export var _step_max_font_size := 38
@export var _step_baseline_sequence_length := 3
@export var _pending_step_color := Color(0.25098, 0.203922, 0.145098, 0.92)
@export var _active_step_color := Color(0.780392, 0.623529, 0.317647, 0.98)
@export var _completed_step_color := Color(0.419608, 0.54902, 0.290196, 0.95)


# Private Fields
var _run_state: RunStateType


# Private Fields: OnReady
@onready
var _panel: PanelContainer = %RecoveryPanel

@onready
var _title_label: Label = %RecoveryTitle

@onready
var _hint_label: Label = %RecoveryHint

@onready
var _steps_container: HBoxContainer = %RecoverySteps


# Public Methods

## Returns the fallback recovery-step size used when the layer node is unavailable.
static func get_default_step_minimum_size() -> Vector2:
	return Vector2(DEFAULT_STEP_MAX_WIDTH, DEFAULT_STEP_HEIGHT)

## Binds the active run state so recovery prompt rendering follows the current failure state.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


## Clears the active recovery prompt contents and hides the panel.
func clear_prompt() -> void:
	_clear_steps()
	if _panel != null:
		_panel.visible = false
	if _title_label != null:
		_title_label.text = ""
	if _hint_label != null:
		_hint_label.text = ""


## Shows only the active recovery sequence prompt when gameplay allows it.
func refresh_prompt(pause_menu_open: bool) -> void:
	if _panel == null or _steps_container == null or _title_label == null or _hint_label == null:
		return

	if _run_state == null:
		clear_prompt()
		return

	var should_show_prompt := (
		_run_state.result == RunStateType.RESULT_IN_PROGRESS
		and not pause_menu_open
		and _run_state.has_active_recovery_sequence()
	)
	_panel.visible = should_show_prompt
	if not should_show_prompt:
		_clear_steps()
		return

	_rebuild_steps()


## Returns whether the authored recovery panel is currently visible.
func is_prompt_visible() -> bool:
	return _panel != null and _panel.visible


## Returns the current recovery title for the active failure.
func get_title(failure_type: StringName) -> String:
	match failure_type:
		&"wheel_loose":
			return "Wheel Loose: Secure the Wagon"
		&"horse_panic":
			return "Horse Panic: Calm the Team"
		_:
			return "Recovery"


## Returns the current recovery hint for the active failure.
func get_hint(failure_type: StringName) -> String:
	match failure_type:
		&"wheel_loose":
			return "Steering is compromised. Match the sequence to lock the wheel."
		&"horse_panic":
			return "The wagon is swerving. Complete the full left-right pattern."
		_:
			return "Follow the prompts left to right."


## Returns the chip size that keeps the full recovery row inside a fixed width budget.
func get_step_minimum_size() -> Vector2:
	if _run_state == null:
		return Vector2(_step_max_width, _step_height)

	var sequence_size: int = max(_run_state.recovery_sequence.size(), _step_baseline_sequence_length)
	var available_width: float = get_step_row_max_width() - ((sequence_size - 1) * get_step_spacing())
	var step_width: float = clampf(
		floor(available_width / float(sequence_size)),
		_step_min_width,
		_step_max_width
	)
	return Vector2(step_width, _step_height)


## Returns the prompt font size that matches the active recovery chip width.
func get_step_font_size() -> int:
	var step_width := get_step_minimum_size().x
	return clampi(
		int(floor(step_width * _step_font_size_ratio)),
		_step_min_font_size,
		_step_max_font_size
	)


## Builds one recovery-step chip using the current compactness rules for the active sequence.
func build_step(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = get_step_minimum_size()
	panel.modulate = get_step_color(index)

	var label := Label.new()
	label.text = format_action(_run_state.recovery_sequence[index])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", get_step_font_size())
	if _step_font != null:
		label.add_theme_font_override("font", _step_font)
	panel.add_child(label)
	return panel


## Returns the authored color for one recovery-step chip based on current progress.
func get_step_color(index: int) -> Color:
	if index < _run_state.recovery_prompt_index:
		return _completed_step_color
	if index == _run_state.recovery_prompt_index:
		return _active_step_color
	return _pending_step_color


## Returns the arrow-font glyph for one recovery action.
func format_action(action_name: StringName) -> String:
	match action_name:
		&"steer_left":
			return char(0xE020)
		&"steer_right":
			return char(0xE022)
		_:
			return String(action_name).to_upper()


## Converts the latest input event into the expected recovery action name.
func get_input_action(event: InputEvent) -> StringName:
	if event == null:
		return &""
	if event.is_action_pressed(TOUCH_LEFT_ACTION, false, true):
		return TOUCH_LEFT_ACTION
	if event.is_action_pressed(TOUCH_RIGHT_ACTION, false, true):
		return TOUCH_RIGHT_ACTION
	return &""


# Private Methods

## Rebuilds the current recovery prompt contents from the authored run-state sequence.
func _rebuild_steps() -> void:
	_clear_steps()
	_title_label.text = get_title(_run_state.active_failure)
	_hint_label.text = get_hint(_run_state.active_failure)
	_steps_container.custom_minimum_size.x = get_step_row_max_width()

	for step_index in range(_run_state.recovery_sequence.size()):
		_steps_container.add_child(build_step(step_index))


## Removes any previously rendered recovery-step chips from the prompt row.
func _clear_steps() -> void:
	if _steps_container == null:
		return

	for child in _steps_container.get_children():
		child.queue_free()


## Returns the authored recovery-step row width budget from the steps container.
func get_step_row_max_width() -> float:
	if _steps_container == null:
		return 0.0
	return _steps_container.custom_minimum_size.x


## Returns the authored recovery-step spacing from the steps container theme.
func get_step_spacing() -> int:
	if _steps_container == null:
		return 0
	return _steps_container.get_theme_constant("separation")
