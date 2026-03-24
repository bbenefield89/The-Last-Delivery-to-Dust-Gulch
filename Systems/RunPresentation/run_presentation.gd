class_name RunPresentation
extends RefCounted

## Owns run-scene wagon, camera, scroll, dust, and impact presentation state.

const WAGON_BASE_Y := 0.0
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
const ROADSIDE_DECOR_SPACING := 144.0
const ROADSIDE_DECOR_COUNT := 8
const DUST_BASE_AMOUNT_RATIO := 0.35

# Public Fields

var impact_time := 0.0
var scroll_offset := 0.0

# Private Fields

var _run_state: RunState
var _backdrop: Sprite2D
var _road: Sprite2D
var _camera: Camera2D
var _scroll_root: Node2D
var _scroll_segment_a: Node2D
var _scroll_segment_b: Node2D
var _wagon: Polygon2D
var _wagon_sprite: AnimatedSprite2D
var _horse_left_sprite: AnimatedSprite2D
var _horse_right_sprite: AnimatedSprite2D
var _dust_trail: CPUParticles2D
var _shrub_textures: Array[Texture2D] = []
var _sign_texture: Texture2D
var _impact_flash_remaining := 0.0
var _impact_wobble_remaining := 0.0
var _impact_shake_remaining := 0.0


## Binds the scene-owned nodes and shared art resources used by runtime presentation.
func configure_scene_nodes(
	run_state: RunState,
	backdrop: Sprite2D,
	road: Sprite2D,
	camera: Camera2D,
	scroll_root: Node2D,
	scroll_segment_a: Node2D,
	scroll_segment_b: Node2D,
	wagon: Polygon2D,
	wagon_sprite: AnimatedSprite2D,
	horse_left_sprite: AnimatedSprite2D,
	horse_right_sprite: AnimatedSprite2D,
	dust_trail: CPUParticles2D,
	shrub_textures: Array[Texture2D],
	sign_texture: Texture2D
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
	_shrub_textures = shrub_textures.duplicate()
	_sign_texture = sign_texture


## Binds the active run state so runtime presentation follows the current run.
func bind_run_state(run_state: RunState) -> void:
	_run_state = run_state


## Applies the tiled desert and road art to the bound world nodes.
func configure_environment_art(desert_texture: Texture2D, road_texture: Texture2D) -> void:
	if _backdrop != null:
		_backdrop.texture = desert_texture
		_backdrop.centered = false
		_backdrop.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_backdrop.region_enabled = true
		_backdrop.region_rect = Rect2(0.0, 0.0, 960.0, 1440.0)
		_backdrop.position = Vector2(-480.0, -720.0)

	if _road != null:
		_road.texture = road_texture
		_road.centered = false
		_road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_road.region_enabled = true
		_road.region_rect = Rect2(0.0, 0.0, 224.0, 1440.0)
		_road.position = Vector2(-112.0, -720.0)

	_update_environment_scroll()


## Ensures both scroll segments contain the authored roadside decor needed for continuous travel.
func ensure_scroll_visuals() -> void:
	if _scroll_root == null:
		return

	if _scroll_segment_a != null and _scroll_segment_a.get_child_count() == 0:
		_populate_scroll_segment(_scroll_segment_a)
	if _scroll_segment_b != null and _scroll_segment_b.get_child_count() == 0:
		_populate_scroll_segment(_scroll_segment_b)


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

	_wagon.position = Vector2(_run_state.lateral_position, WAGON_BASE_Y)


## Applies the authored camera framing and screen shake around the wagon.
func update_camera_framing() -> void:
	if _camera == null or _wagon == null:
		return

	var camera_position := Vector2(0.0, _wagon.position.y - CAMERA_VERTICAL_OFFSET)
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

	var should_emit_dust := _run_state.result == RunState.RESULT_IN_PROGRESS and _run_state.current_speed > 0.0
	_dust_trail.emitting = should_emit_dust
	_dust_trail.speed_scale = max(
		DUST_BASE_AMOUNT_RATIO,
		_run_state.current_speed / default_forward_speed
	)


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


## Builds one looping roadside segment with scrub clusters and the Dust Gulch sign.
func _populate_scroll_segment(segment: Node2D) -> void:
	for i in range(ROADSIDE_DECOR_COUNT):
		var left_scrub := _make_scrub_cluster(i)
		left_scrub.position = Vector2(-184.0, -SCROLL_LOOP_HEIGHT + (i * ROADSIDE_DECOR_SPACING))
		segment.add_child(left_scrub)

		var right_scrub := _make_scrub_cluster(i + 2)
		right_scrub.position = Vector2(184.0, -SCROLL_LOOP_HEIGHT + (i * ROADSIDE_DECOR_SPACING) + 56.0)
		right_scrub.scale.x = -1.0
		segment.add_child(right_scrub)

	var sign := _make_road_sign()
	sign.position = Vector2(-252.0, -SCROLL_LOOP_HEIGHT + 280.0)
	segment.add_child(sign)


## Creates one roadside scrub sprite using the authored variant cycle.
func _make_scrub_cluster(variant_index: int) -> Sprite2D:
	var scrub := Sprite2D.new()
	if not _shrub_textures.is_empty():
		scrub.texture = _shrub_textures[variant_index % _shrub_textures.size()]
	return scrub


## Creates the authored Dust Gulch roadside sign sprite.
func _make_road_sign() -> Sprite2D:
	var sign := Sprite2D.new()
	sign.name = "RoadsideSign"
	sign.texture = _sign_texture
	return sign


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

