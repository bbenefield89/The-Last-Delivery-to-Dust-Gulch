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
const SCROLL_LOOP_HEIGHT := 2880.0
const CENTER_DASH_SPACING := 240.0
const CENTER_DASH_SIZE := Vector2(14.0, 140.0)
const CENTER_DASH_COUNT := 13
const ROADSIDE_DECOR_SPACING := 320.0
const ROADSIDE_DECOR_COUNT := 10
const WAGON_COLLISION_SIZE := Vector2(72.0, 112.0)

const DASH_COLOR := Color(0.886275, 0.811765, 0.572549, 0.8)
const SCRUB_COLOR := Color(0.47451, 0.443137, 0.219608, 0.95)

var _run_state: RunStateType
var _scroll_offset := 0.0
var _impact_flash_remaining := 0.0
var _impact_wobble_remaining := 0.0
var _impact_shake_remaining := 0.0
var _impact_time := 0.0

@onready var _camera: Camera2D = %Camera
@onready var _hazard_spawner: HazardSpawnerType = %HazardSpawner
@onready var _scroll_root: Node2D = %ScrollRoot
@onready var _scroll_segment_a: Node2D = %ScrollSegmentA
@onready var _scroll_segment_b: Node2D = %ScrollSegmentB
@onready var _wagon: Polygon2D = %Wagon
@onready var _status_label: Label = %StatusLabel


func setup(run_state: RunStateType) -> void:
	_run_state = run_state
	_refresh_status()


func _ready() -> void:
	_ensure_input_actions()
	_ensure_scroll_visuals()
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_refresh_status()


func _process(delta: float) -> void:
	if _run_state == null:
		return

	var steer_input := Input.get_axis(STEER_ACTION_NEGATIVE, STEER_ACTION_POSITIVE)
	_run_state.lateral_position = clamp(
		_run_state.lateral_position + steer_input * STEER_SPEED * delta,
		-ROAD_HALF_WIDTH,
		ROAD_HALF_WIDTH,
	)
	_run_state.distance_remaining = max(
		0.0,
		_run_state.distance_remaining - _run_state.current_speed * delta,
	)
	_scroll_offset = fposmod(_scroll_offset + _run_state.current_speed * delta, SCROLL_LOOP_HEIGHT)
	_hazard_spawner.advance(_run_state.current_speed * delta, _run_state.get_delivery_progress_ratio())
	_apply_hazard_collisions()
	_update_impact_feedback(delta)
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_refresh_status()


func _refresh_status() -> void:
	if _status_label == null:
		return

	if _run_state == null:
		_status_label.text = "Run scene loaded.\nAwaiting run state."
		return

	_status_label.text = "Run ready.\nDistance: %.0f\nHealth: %d\nCargo: %d\nSpeed: %.0f\nLane offset: %.0f\nResult: %s" % [
		_run_state.distance_remaining,
		_run_state.wagon_health,
		_run_state.cargo_value,
		_run_state.current_speed,
		_run_state.lateral_position,
		String(_run_state.result),
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
		_run_state.last_hit_hazard = collision["type"]
		_trigger_impact_feedback()
		(collision["node"] as Node).queue_free()


func _update_impact_feedback(delta: float) -> void:
	if _wagon == null:
		return

	_impact_time += delta
	_impact_flash_remaining = max(0.0, _impact_flash_remaining - delta)
	_impact_wobble_remaining = max(0.0, _impact_wobble_remaining - delta)
	_impact_shake_remaining = max(0.0, _impact_shake_remaining - delta)

	_wagon.color = WAGON_HIT_COLOR if _impact_flash_remaining > 0.0 else WAGON_BASE_COLOR
	if _impact_wobble_remaining > 0.0:
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
