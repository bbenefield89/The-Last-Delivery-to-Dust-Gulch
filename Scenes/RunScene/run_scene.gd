extends Node2D

const HazardSpawnerType := preload("res://Scripts/Hazards/hazard_spawner.gd")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")
const STEER_ACTION_NEGATIVE := "steer_left"
const STEER_ACTION_POSITIVE := "steer_right"
const STEER_SPEED := 300.0
const ROAD_HALF_WIDTH := 220.0
const WAGON_BASE_Y := 0.0
const WAGON_BASE_COLOR := Color(0.301961, 0.180392, 0.101961, 1.0)
const WAGON_HIT_COLOR := Color(0.760784, 0.447059, 0.239216, 1.0)
const CAMERA_VERTICAL_OFFSET := 260.0
const IMPACT_FLASH_DURATION := 0.18
const IMPACT_WOBBLE_DURATION := 0.32
const IMPACT_SHAKE_DURATION := 0.28
const IMPACT_WOBBLE_DEGREES := 9.0
const IMPACT_WOBBLE_FREQUENCY := 22.0
const IMPACT_SHAKE_AMPLITUDE := 10.0
const WHEEL_LOOSE_STEER_MULTIPLIER := 0.6
const WHEEL_LOOSE_DRIFT_SPEED := 32.0
const WHEEL_LOOSE_DRIFT_FREQUENCY := 8.0
const WHEEL_LOOSE_WOBBLE_DEGREES := 14.0
const WHEEL_LOOSE_WOBBLE_FREQUENCY := 15.0
const HORSE_PANIC_STEER_MULTIPLIER := 0.3
const HORSE_PANIC_DRIFT_SPEED := 150.0
const HORSE_PANIC_DRIFT_FREQUENCY := 5.0
const HORSE_PANIC_WOBBLE_DEGREES := 8.0
const HORSE_PANIC_WOBBLE_FREQUENCY := 10.0
const BAD_LUCK_INTERVAL_EARLY := 9.0
const BAD_LUCK_INTERVAL_LATE := 4.5
const WHEEL_LOOSE_RECOVERY_SEQUENCE: Array[StringName] = [
	&"steer_left",
	&"steer_right",
	&"steer_left",
]
const HORSE_PANIC_RECOVERY_SEQUENCE: Array[StringName] = [
	&"steer_left",
	&"steer_right",
	&"steer_left",
	&"steer_right",
]
const WHEEL_LOOSE_RECOVERY_DURATION := 2.75
const HORSE_PANIC_RECOVERY_DURATION := 3.25
const POST_FAILURE_STEER_MULTIPLIER := 0.75
const POST_FAILURE_DRIFT_SPEED := 55.0
const POST_FAILURE_DRIFT_FREQUENCY := 6.0
const WHEEL_LOOSE_FAILURE_HEALTH_LOSS := 14
const WHEEL_LOOSE_FAILURE_CARGO_LOSS := 8
const WHEEL_LOOSE_FAILURE_SPEED_LOSS := 70.0
const WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION := 2.4
const HORSE_PANIC_FAILURE_CARGO_LOSS := 20
const HORSE_PANIC_FAILURE_SPEED_LOSS := 85.0
const HORSE_PANIC_FAILURE_INSTABILITY_DURATION := 2.8
const SCROLL_LOOP_HEIGHT := 2880.0
const CENTER_DASH_SPACING := 240.0
const CENTER_DASH_SIZE := Vector2(14.0, 140.0)
const CENTER_DASH_COUNT := 13
const ROADSIDE_DECOR_SPACING := 320.0
const ROADSIDE_DECOR_COUNT := 10
const WAGON_COLLISION_SIZE := Vector2(72.0, 112.0)
const RECOVERY_STEP_PENDING_COLOR := Color(0.25098, 0.203922, 0.145098, 0.92)
const RECOVERY_STEP_ACTIVE_COLOR := Color(0.780392, 0.623529, 0.317647, 0.98)
const RECOVERY_STEP_DONE_COLOR := Color(0.419608, 0.54902, 0.290196, 0.95)

const DASH_COLOR := Color(0.886275, 0.811765, 0.572549, 0.8)
const SCRUB_COLOR := Color(0.47451, 0.443137, 0.219608, 0.95)

var _run_state: RunStateType
var _scroll_offset := 0.0
var _impact_flash_remaining := 0.0
var _impact_wobble_remaining := 0.0
var _impact_shake_remaining := 0.0
var _impact_time := 0.0
var _bad_luck_elapsed := 0.0

@onready var _camera: Camera2D = %Camera
@onready var _hazard_spawner: HazardSpawnerType = %HazardSpawner
@onready var _scroll_root: Node2D = %ScrollRoot
@onready var _scroll_segment_a: Node2D = %ScrollSegmentA
@onready var _scroll_segment_b: Node2D = %ScrollSegmentB
@onready var _wagon: Polygon2D = %Wagon
@onready var _health_label: Label = %HealthLabel
@onready var _cargo_label: Label = %CargoLabel
@onready var _speed_label: Label = %SpeedLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _recovery_panel: PanelContainer = %RecoveryPanel
@onready var _recovery_title: Label = %RecoveryTitle
@onready var _recovery_hint: Label = %RecoveryHint
@onready var _recovery_steps: HBoxContainer = %RecoverySteps
@onready var _result_panel: PanelContainer = %ResultPanel
@onready var _result_title: Label = %ResultTitle
@onready var _result_summary: Label = %ResultSummary
@onready var _result_stats: Label = %ResultStats


func setup(run_state: RunStateType) -> void:
	_run_state = run_state
	_refresh_status()
	_refresh_recovery_prompt()


func _ready() -> void:
	_ensure_input_actions()
	_ensure_scroll_visuals()
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_refresh_status()
	_refresh_recovery_prompt()
	_refresh_result_screen()


func _process(delta: float) -> void:
	if _run_state == null:
		return
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		_update_impact_feedback(delta)
		_update_wagon_visual()
		_update_camera_framing()
		_refresh_status()
		_refresh_recovery_prompt()
		_refresh_result_screen()
		return

	var steer_input := Input.get_axis(STEER_ACTION_NEGATIVE, STEER_ACTION_POSITIVE)
	var steer_multiplier := 1.0
	var lateral_drift := 0.0
	match _run_state.active_failure:
		&"wheel_loose":
			steer_multiplier = WHEEL_LOOSE_STEER_MULTIPLIER
			lateral_drift = sin(_impact_time * WHEEL_LOOSE_DRIFT_FREQUENCY) * WHEEL_LOOSE_DRIFT_SPEED
		&"horse_panic":
			steer_multiplier = HORSE_PANIC_STEER_MULTIPLIER
			lateral_drift = sin(_impact_time * HORSE_PANIC_DRIFT_FREQUENCY) * HORSE_PANIC_DRIFT_SPEED
		_:
			if _run_state.has_temporary_control_instability():
				steer_multiplier = POST_FAILURE_STEER_MULTIPLIER
				lateral_drift = sin(_impact_time * POST_FAILURE_DRIFT_FREQUENCY) * POST_FAILURE_DRIFT_SPEED

	_run_state.lateral_position = clamp(
		_run_state.lateral_position + ((steer_input * STEER_SPEED * steer_multiplier) + lateral_drift) * delta,
		-ROAD_HALF_WIDTH,
		ROAD_HALF_WIDTH,
	)
	_run_state.recover_speed(delta)
	_run_state.distance_remaining = max(
		0.0,
		_run_state.distance_remaining - _run_state.current_speed * delta,
	)
	_scroll_offset = fposmod(_scroll_offset + _run_state.current_speed * delta, SCROLL_LOOP_HEIGHT)
	_hazard_spawner.advance(_run_state.current_speed * delta, _run_state.get_delivery_progress_ratio())
	_apply_hazard_collisions()
	_advance_failure_triggers(delta)
	_check_for_loss()
	_check_for_success()
	_update_impact_feedback(delta)
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_refresh_status()
	_refresh_recovery_prompt()
	_refresh_result_screen()


func _refresh_status() -> void:
	if _health_label == null or _cargo_label == null or _speed_label == null or _progress_label == null or _progress_bar == null:
		return

	if _run_state == null:
		_health_label.text = "Health: --"
		_cargo_label.text = "Cargo: --"
		_speed_label.text = "Speed: --"
		_progress_label.text = "Distance: --"
		_progress_bar.value = 0.0
		return

	_health_label.text = "Health: %d" % _run_state.wagon_health
	_cargo_label.text = "Cargo: %d" % _run_state.cargo_value
	_speed_label.text = "Speed: %.0f" % _run_state.current_speed
	_progress_label.text = "Distance: %.0f / %.0f" % [
		_run_state.distance_remaining,
		_run_state.route_distance,
	]
	_progress_bar.value = _run_state.get_delivery_progress_ratio() * 100.0


func _refresh_recovery_prompt() -> void:
	if _recovery_panel == null or _recovery_steps == null or _recovery_title == null or _recovery_hint == null:
		return
	if _run_state == null:
		_recovery_panel.visible = false
		return

	var has_recovery := _run_state.result == RunStateType.RESULT_IN_PROGRESS and _run_state.has_active_recovery_sequence()
	_recovery_panel.visible = has_recovery
	if not has_recovery:
		for child in _recovery_steps.get_children():
			child.queue_free()
		return

	for child in _recovery_steps.get_children():
		child.queue_free()

	_recovery_title.text = _get_recovery_title(_run_state.active_failure)
	_recovery_hint.text = _get_recovery_hint(_run_state.active_failure)

	for i in range(_run_state.recovery_sequence.size()):
		_recovery_steps.add_child(_build_recovery_step(i))


func _refresh_result_screen() -> void:
	if _result_panel == null or _result_title == null or _result_summary == null or _result_stats == null:
		return
	if _run_state == null or _run_state.result == RunStateType.RESULT_IN_PROGRESS:
		_result_panel.visible = false
		return

	_result_panel.visible = true
	match _run_state.result:
		RunStateType.RESULT_SUCCESS:
			_result_title.text = "Delivered to Dust Gulch"
			_result_summary.text = "You made it in one piece. Press R to ride again."
		RunStateType.RESULT_COLLAPSED:
			_result_title.text = "Wagon Collapsed"
			_result_summary.text = "The delivery failed. Press R to try the route again."
		_:
			_result_title.text = "Run Complete"
			_result_summary.text = "Press R to restart."

	_result_stats.text = "Health: %d\nCargo: %d\nDistance traveled: %.0f / %.0f\nSpeed: %.0f" % [
		_run_state.wagon_health,
		_run_state.cargo_value,
		_run_state.get_distance_traveled(),
		_run_state.route_distance,
		_run_state.current_speed,
	]


func _update_wagon_visual() -> void:
	if _wagon == null or _run_state == null:
		return

	_wagon.position = Vector2(_run_state.lateral_position, WAGON_BASE_Y)


func _update_camera_framing() -> void:
	if _camera == null or _wagon == null:
		return

	var camera_position := Vector2(0.0, _wagon.position.y - CAMERA_VERTICAL_OFFSET)
	if _impact_shake_remaining > 0.0:
		var shake_strength := _impact_shake_remaining / IMPACT_SHAKE_DURATION
		camera_position += Vector2(
			cos(_impact_time * 31.0),
			sin(_impact_time * 43.0)
		) * IMPACT_SHAKE_AMPLITUDE * shake_strength

	_camera.position = camera_position


func _apply_hazard_collisions() -> void:
	if _hazard_spawner == null or _run_state == null:
		return

	var collisions := _hazard_spawner.collect_collisions(_wagon.position, WAGON_COLLISION_SIZE)
	for collision in collisions:
		_run_state.wagon_health = max(0, _run_state.wagon_health - collision["damage"])
		_run_state.cargo_value = max(0, _run_state.cargo_value - collision.get("cargo_damage", 0))
		_run_state.last_hit_hazard = collision["type"]
		_attempt_failure_trigger_from_collision(collision["type"])
		_trigger_impact_feedback()
		(collision["node"] as Node).queue_free()


func _advance_failure_triggers(delta: float) -> void:
	if _run_state == null:
		return

	_run_state.tick_failure(delta)
	_run_state.tick_temporary_control_instability(delta)
	_run_state.tick_recovery_transients(delta)
	var had_active_recovery_sequence := _run_state.has_active_recovery_sequence()
	_sync_recovery_sequence()
	if had_active_recovery_sequence and _run_state.tick_recovery_sequence(delta):
		_apply_recovery_failure_penalty()
		return
	if _run_state.has_active_failure():
		return

	_bad_luck_elapsed += delta
	if _bad_luck_elapsed < _get_bad_luck_interval():
		return

	_bad_luck_elapsed = 0.0
	_run_state.start_failure(&"horse_panic", &"bad_luck")


func _attempt_failure_trigger_from_collision(hazard_type: StringName) -> void:
	if _run_state == null:
		return
	if _run_state.has_active_failure():
		return

	match hazard_type:
		&"rock", &"pothole":
			if _run_state.start_failure(&"wheel_loose", hazard_type):
				_bad_luck_elapsed = 0.0
		&"tumbleweed":
			if _run_state.start_failure(&"horse_panic", hazard_type):
				_bad_luck_elapsed = 0.0


func _get_bad_luck_interval() -> float:
	if _run_state == null:
		return BAD_LUCK_INTERVAL_EARLY

	return lerp(
		BAD_LUCK_INTERVAL_EARLY,
		BAD_LUCK_INTERVAL_LATE,
		_run_state.get_delivery_progress_ratio()
	)


func _check_for_success() -> void:
	if _run_state == null:
		return
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	if _run_state.distance_remaining > 0.0:
		return

	_run_state.distance_remaining = 0.0
	_run_state.result = RunStateType.RESULT_SUCCESS
	_run_state.current_speed = 0.0


func _check_for_loss() -> void:
	if _run_state == null:
		return
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	if _run_state.wagon_health > 0:
		return

	_run_state.wagon_health = 0
	_run_state.result = RunStateType.RESULT_COLLAPSED
	_run_state.current_speed = 0.0


func _sync_recovery_sequence() -> void:
	if _run_state == null:
		return

	if _run_state.active_failure == &"wheel_loose":
		if not _run_state.has_active_recovery_sequence():
			_run_state.start_recovery_sequence(WHEEL_LOOSE_RECOVERY_SEQUENCE, WHEEL_LOOSE_RECOVERY_DURATION)
		return
	if _run_state.active_failure == &"horse_panic":
		if not _run_state.has_active_recovery_sequence():
			_run_state.start_recovery_sequence(HORSE_PANIC_RECOVERY_SEQUENCE, HORSE_PANIC_RECOVERY_DURATION)
		return

	if _run_state.has_active_recovery_sequence():
		_run_state.clear_recovery_sequence()


func _input(event: InputEvent) -> void:
	if _run_state == null:
		return
	if not _run_state.has_active_recovery_sequence():
		return

	var action_name := _extract_recovery_action(event)
	if action_name == &"":
		return

	if _run_state.advance_recovery_sequence(action_name):
		_run_state.resolve_recovery_success()

	_refresh_status()
	_refresh_recovery_prompt()


func _update_impact_feedback(delta: float) -> void:
	if _wagon == null:
		return

	_impact_time += delta
	_impact_flash_remaining = max(0.0, _impact_flash_remaining - delta)
	_impact_wobble_remaining = max(0.0, _impact_wobble_remaining - delta)
	_impact_shake_remaining = max(0.0, _impact_shake_remaining - delta)

	_wagon.color = WAGON_HIT_COLOR if _impact_flash_remaining > 0.0 else WAGON_BASE_COLOR
	if _run_state != null and _run_state.active_failure == &"wheel_loose":
		_wagon.rotation = sin(_impact_time * WHEEL_LOOSE_WOBBLE_FREQUENCY) * deg_to_rad(WHEEL_LOOSE_WOBBLE_DEGREES)
	elif _run_state != null and _run_state.active_failure == &"horse_panic":
		_wagon.rotation = sin(_impact_time * HORSE_PANIC_WOBBLE_FREQUENCY) * deg_to_rad(HORSE_PANIC_WOBBLE_DEGREES)
	elif _impact_wobble_remaining > 0.0:
		var wobble_strength := _impact_wobble_remaining / IMPACT_WOBBLE_DURATION
		_wagon.rotation = sin(_impact_time * IMPACT_WOBBLE_FREQUENCY) * deg_to_rad(IMPACT_WOBBLE_DEGREES) * wobble_strength
	else:
		_wagon.rotation = 0.0


func _trigger_impact_feedback() -> void:
	_impact_flash_remaining = IMPACT_FLASH_DURATION
	_impact_wobble_remaining = IMPACT_WOBBLE_DURATION
	_impact_shake_remaining = IMPACT_SHAKE_DURATION
	_impact_time = 0.0


func _ensure_scroll_visuals() -> void:
	if _scroll_root == null:
		return

	if _scroll_segment_a.get_child_count() == 0:
		_populate_scroll_segment(_scroll_segment_a)

	if _scroll_segment_b.get_child_count() == 0:
		_populate_scroll_segment(_scroll_segment_b)


func _update_scroll_visuals() -> void:
	if _scroll_root == null or _scroll_segment_a == null or _scroll_segment_b == null:
		return

	_scroll_segment_a.position.y = _scroll_offset
	_scroll_segment_b.position.y = _scroll_offset - SCROLL_LOOP_HEIGHT


func _populate_scroll_segment(segment: Node2D) -> void:
	for i in range(CENTER_DASH_COUNT):
		var dash := Polygon2D.new()
		dash.polygon = PackedVector2Array([
			Vector2(-CENTER_DASH_SIZE.x * 0.5, -CENTER_DASH_SIZE.y * 0.5),
			Vector2(CENTER_DASH_SIZE.x * 0.5, -CENTER_DASH_SIZE.y * 0.5),
			Vector2(CENTER_DASH_SIZE.x * 0.5, CENTER_DASH_SIZE.y * 0.5),
			Vector2(-CENTER_DASH_SIZE.x * 0.5, CENTER_DASH_SIZE.y * 0.5),
		])
		dash.position = Vector2(0.0, -SCROLL_LOOP_HEIGHT + (i * CENTER_DASH_SPACING))
		dash.color = DASH_COLOR
		segment.add_child(dash)

	for i in range(ROADSIDE_DECOR_COUNT):
		var left_scrub := _make_scrub_cluster()
		left_scrub.position = Vector2(-300.0, -SCROLL_LOOP_HEIGHT + (i * ROADSIDE_DECOR_SPACING))
		segment.add_child(left_scrub)

		var right_scrub := _make_scrub_cluster()
		right_scrub.position = Vector2(300.0, -SCROLL_LOOP_HEIGHT + (i * ROADSIDE_DECOR_SPACING) + 120.0)
		right_scrub.scale.x = -1.0
		segment.add_child(right_scrub)


func _make_scrub_cluster() -> Polygon2D:
	var scrub := Polygon2D.new()
	scrub.polygon = PackedVector2Array([
		Vector2(-26.0, 20.0),
		Vector2(-8.0, -12.0),
		Vector2(0.0, 6.0),
		Vector2(10.0, -18.0),
		Vector2(28.0, 18.0),
		Vector2(4.0, 28.0),
	])
	scrub.color = SCRUB_COLOR
	return scrub


func _ensure_input_actions() -> void:
	_register_action(STEER_ACTION_NEGATIVE, [KEY_A, KEY_LEFT])
	_register_action(STEER_ACTION_POSITIVE, [KEY_D, KEY_RIGHT])


func _register_action(action_name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _extract_recovery_action(event: InputEvent) -> StringName:
	if event == null:
		return &""
	if event.is_action_pressed(STEER_ACTION_NEGATIVE, false, true):
		return STEER_ACTION_NEGATIVE
	if event.is_action_pressed(STEER_ACTION_POSITIVE, false, true):
		return STEER_ACTION_POSITIVE
	return &""


func _get_recovery_title(failure_type: StringName) -> String:
	match failure_type:
		&"wheel_loose":
			return "Wheel Loose: Secure the Wagon"
		&"horse_panic":
			return "Horse Panic: Calm the Team"
		_:
			return "Recovery"


func _get_recovery_hint(failure_type: StringName) -> String:
	match failure_type:
		&"wheel_loose":
			return "Steering is compromised. Match the sequence to lock the wheel."
		&"horse_panic":
			return "The wagon is swerving. Complete the full left-right pattern."
		_:
			return "Follow the prompts left to right."


func _apply_recovery_failure_penalty() -> void:
	if _run_state == null:
		return

	match _run_state.active_failure:
		&"wheel_loose":
			_run_state.apply_recovery_failure_penalty(
				WHEEL_LOOSE_FAILURE_HEALTH_LOSS,
				WHEEL_LOOSE_FAILURE_CARGO_LOSS,
				WHEEL_LOOSE_FAILURE_SPEED_LOSS,
				WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION
			)
		&"horse_panic":
			_run_state.apply_recovery_failure_penalty(
				0,
				HORSE_PANIC_FAILURE_CARGO_LOSS,
				HORSE_PANIC_FAILURE_SPEED_LOSS,
				HORSE_PANIC_FAILURE_INSTABILITY_DURATION
			)

	_refresh_status()
	_refresh_recovery_prompt()


func _build_recovery_step(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(90.0, 52.0)
	panel.modulate = _get_recovery_step_color(index)

	var label := Label.new()
	label.text = _format_recovery_action(_run_state.recovery_sequence[index])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 20)
	panel.add_child(label)
	return panel


func _get_recovery_step_color(index: int) -> Color:
	if index < _run_state.recovery_prompt_index:
		return RECOVERY_STEP_DONE_COLOR
	if index == _run_state.recovery_prompt_index:
		return RECOVERY_STEP_ACTIVE_COLOR
	return RECOVERY_STEP_PENDING_COLOR


func _format_recovery_action(action_name: StringName) -> String:
	match action_name:
		&"steer_left":
			return "LEFT"
		&"steer_right":
			return "RIGHT"
		_:
			return String(action_name).to_upper()
