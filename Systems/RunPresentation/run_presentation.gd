extends RefCounted

## Owns run-scene wagon, camera, scroll, dust, and impact presentation state.


# Constants
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


const WAGON_BASE_COLOR := Color(1, 1, 1, 1)
const WAGON_HIT_COLOR := Color(1, 0.72, 0.72, 1)
const CAMERA_VERTICAL_OFFSET := 120.0
const IMPACT_FLASH_DURATION := 0.18
const IMPACT_WOBBLE_DURATION := 0.32
const IMPACT_SHAKE_DURATION := 0.28
const IMPACT_WOBBLE_DEGREES := 9.0
const IMPACT_WOBBLE_FREQUENCY := 22.0
const IMPACT_SHAKE_AMPLITUDE := 10.0
const WHEEL_LOOSE_WOBBLE_DEGREES := 14.0
const WHEEL_LOOSE_WOBBLE_FREQUENCY := 15.0
const HORSE_PANIC_WOBBLE_DEGREES := 8.0
const HORSE_PANIC_WOBBLE_FREQUENCY := 10.0
const SCROLL_LOOP_HEIGHT := 960.0
const DUST_BASE_AMOUNT_RATIO := 0.35

# Public Fields

var impact_time := 0.0
var scroll_offset := 0.0

# Private Fields

var _run_state: RunStateType
var _backdrop: Sprite2D
var _road: Sprite2D
var _camera: Camera2D
var _scroll_root: Node2D
var _scroll_segment_a: Node2D
var _scroll_segment_b: Node2D
var _wagon: Node2D
var _wagon_sprite: AnimatedSprite2D
var _horse_left_sprite: AnimatedSprite2D
var _horse_right_sprite: AnimatedSprite2D
var _dust_trail: CPUParticles2D
var _impact_flash_remaining := 0.0
var _impact_wobble_remaining := 0.0
var _impact_shake_remaining := 0.0
var _authored_backdrop_position := Vector2.ZERO
var _authored_road_position := Vector2.ZERO
var _authored_wagon_position := Vector2.ZERO
var _authored_camera_position := Vector2.ZERO
var _authored_camera_y_offset := -CAMERA_VERTICAL_OFFSET


# Public Methods

## Binds the scene-owned nodes and shared art resources used by runtime presentation.
func configure_scene_nodes(
	run_state: RunStateType,
	backdrop: Sprite2D,
	road: Sprite2D,
	camera: Camera2D,
	scroll_root: Node2D,
	scroll_segment_a: Node2D,
	scroll_segment_b: Node2D,
	wagon: Node2D,
	wagon_sprite: AnimatedSprite2D,
	horse_left_sprite: AnimatedSprite2D,
	horse_right_sprite: AnimatedSprite2D,
	dust_trail: CPUParticles2D
) -> void:
	_run_state = run_state
	_backdrop = backdrop
	_road = road
	_camera = camera
	_scroll_root = scroll_root
	_scroll_segment_a = scroll_segment_a
	_scroll_segment_b = scroll_segment_b
	_wagon = wagon
	_wagon_sprite = wagon_sprite
	_horse_left_sprite = horse_left_sprite
	_horse_right_sprite = horse_right_sprite
	_dust_trail = dust_trail
	_authored_backdrop_position = _backdrop.position if _backdrop != null else Vector2.ZERO
	_authored_road_position = _road.position if _road != null else Vector2.ZERO
	_authored_wagon_position = _wagon.position if _wagon != null else Vector2.ZERO
	_authored_camera_position = _camera.position if _camera != null else Vector2.ZERO
	if _camera != null and _wagon != null:
		_authored_camera_y_offset = _camera.position.y - _wagon.position.y


## Binds the active run state so runtime presentation follows the current run.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


## Applies the tiled desert and road art to the bound world nodes.
func configure_environment_art(desert_texture: Texture2D, road_texture: Texture2D) -> void:
	if _backdrop != null:
		_backdrop.texture = desert_texture
		_backdrop.centered = false
		_backdrop.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_backdrop.region_enabled = true
		_backdrop.region_rect = Rect2(0.0, 0.0, 960.0, 1440.0)
		_backdrop.position = _authored_backdrop_position

	if _road != null:
		_road.texture = road_texture
		_road.centered = false
		_road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_road.region_enabled = true
		_road.region_rect = Rect2(0.0, 0.0, 224.0, 1440.0)
		_road.position = _authored_road_position

	_update_environment_scroll()


## Applies the authored dust-particle setup to the bound trail node.
func configure_dust_trail() -> void:
	if _dust_trail == null:
		return

	_dust_trail.emitting = true
	_dust_trail.amount = 16
	_dust_trail.lifetime = 0.85
	_dust_trail.preprocess = 0.2
	_dust_trail.local_coords = false
	_dust_trail.direction = Vector2(0.0, 1.0)
	_dust_trail.spread = 36.0
	_dust_trail.initial_velocity_min = 22.0
	_dust_trail.initial_velocity_max = 42.0
	_dust_trail.gravity = Vector2(0.0, 80.0)
	_dust_trail.scale_amount_min = 1.4
	_dust_trail.scale_amount_max = 3.0
	_dust_trail.color = Color(0.839216, 0.72549, 0.513725, 0.62)
	_dust_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust_trail.emission_rect_extents = Vector2(12.0, 6.0)


## Advances the looping world-scroll state using the active forward speed.
func advance_scroll(current_speed: float, delta: float) -> void:
	scroll_offset = fposmod(scroll_offset + current_speed * delta, SCROLL_LOOP_HEIGHT)


## Updates the wagon transform from the bound run state's lateral position.
func update_wagon_visual() -> void:
	if _wagon == null or _run_state == null:
		return

	_wagon.position = Vector2(
		_authored_wagon_position.x + _run_state.lateral_position,
		_authored_wagon_position.y
	)


## Applies the authored camera framing and screen shake around the wagon.
func update_camera_framing() -> void:
	if _camera == null or _wagon == null:
		return

	var camera_position := Vector2(
		_authored_camera_position.x,
		_wagon.position.y + _authored_camera_y_offset
	)
	if _impact_shake_remaining > 0.0:
		var shake_strength := _impact_shake_remaining / IMPACT_SHAKE_DURATION
		camera_position += Vector2(
			cos(impact_time * 31.0),
			sin(impact_time * 43.0)
		) * IMPACT_SHAKE_AMPLITUDE * shake_strength

	_camera.position = camera_position


## Updates wagon tint, wobble, and shake timers for the current frame.
func update_impact_feedback(delta: float) -> void:
	if _wagon == null:
		return

	impact_time += delta
	_impact_flash_remaining = max(0.0, _impact_flash_remaining - delta)
	_impact_wobble_remaining = max(0.0, _impact_wobble_remaining - delta)
	_impact_shake_remaining = max(0.0, _impact_shake_remaining - delta)

	_set_vehicle_modulate(WAGON_HIT_COLOR if _impact_flash_remaining > 0.0 else WAGON_BASE_COLOR)
	if _run_state != null and _run_state.active_failure == &"wheel_loose":
		_wagon.rotation = sin(impact_time * WHEEL_LOOSE_WOBBLE_FREQUENCY) * deg_to_rad(WHEEL_LOOSE_WOBBLE_DEGREES)
	elif _run_state != null and _run_state.active_failure == &"horse_panic":
		_wagon.rotation = sin(impact_time * HORSE_PANIC_WOBBLE_FREQUENCY) * deg_to_rad(HORSE_PANIC_WOBBLE_DEGREES)
	elif _impact_wobble_remaining > 0.0:
		var wobble_strength := _impact_wobble_remaining / IMPACT_WOBBLE_DURATION
		_wagon.rotation = sin(impact_time * IMPACT_WOBBLE_FREQUENCY) * deg_to_rad(IMPACT_WOBBLE_DEGREES) * wobble_strength
	else:
		_wagon.rotation = 0.0


## Arms the authored hit-flash, wobble, and shake timers for a new impact.
func trigger_impact_feedback() -> void:
	_impact_flash_remaining = IMPACT_FLASH_DURATION
	_impact_wobble_remaining = IMPACT_WOBBLE_DURATION
	_impact_shake_remaining = IMPACT_SHAKE_DURATION
	impact_time = 0.0


## Repositions the looping scroll segments and tiled world windows for the current offset.
func update_scroll_visuals() -> void:
	if _scroll_root == null or _scroll_segment_a == null or _scroll_segment_b == null:
		return

	_scroll_segment_a.position.y = scroll_offset
	_scroll_segment_b.position.y = scroll_offset - SCROLL_LOOP_HEIGHT
	_update_environment_scroll()


## Updates dust visibility and intensity from the current run state.
func refresh_dust_presentation(default_forward_speed: float) -> void:
	if _run_state == null or _dust_trail == null:
		return

	var should_emit_dust := _run_state.result == RunStateType.RESULT_IN_PROGRESS and _run_state.current_speed > 0.0
	_dust_trail.emitting = should_emit_dust
	_dust_trail.speed_scale = max(
		DUST_BASE_AMOUNT_RATIO,
		_run_state.current_speed / default_forward_speed
	)


# Private Methods

## Applies the scrolling region offset to the bound desert and road sprites.
func _update_environment_scroll() -> void:
	if _backdrop != null and _backdrop.region_enabled:
		var backdrop_rect := _backdrop.region_rect
		backdrop_rect.position.y = -scroll_offset
		_backdrop.region_rect = backdrop_rect

	if _road != null and _road.region_enabled:
		var road_rect := _road.region_rect
		road_rect.position.y = -scroll_offset
		_road.region_rect = road_rect

## Applies the shared wagon tint to the carriage and horse sprites.
func _set_vehicle_modulate(color: Color) -> void:
	if _wagon != null:
		_wagon.modulate = color
	if _wagon_sprite != null:
		_wagon_sprite.modulate = color
	if _horse_left_sprite != null:
		_horse_left_sprite.modulate = color
	if _horse_right_sprite != null:
		_horse_right_sprite.modulate = color
