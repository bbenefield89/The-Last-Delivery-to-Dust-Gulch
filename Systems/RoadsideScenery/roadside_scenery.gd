extends Node2D

## Owns roadside scenery spawning, movement, and cleanup using distance-driven spacing.


# Constants
const SCENERY_TYPE_SCRUB := &"scrub"
const SCENERY_TYPE_SIGN := &"sign"
const CLEANUP_COLLISION_LAYER := 1
const DEFAULT_SPAWN_Y := -360.0
const DEFAULT_SPACING_MIN := 132.0
const DEFAULT_SPACING_MAX := 188.0
const SCRUB_MARGIN_X := 184.0
const SIGN_MARGIN_X := 252.0
const SCRUB_X_JITTER := 18.0
const SIGN_X_JITTER := 10.0
const SPAWN_Y_JITTER := 16.0
const MAX_SAME_SIDE_STREAK := 2
const SIGN_DISTANCE_INTERVAL := 720.0
const DEFAULT_COLLISION_SIZE := Vector2(40.0, 40.0)


# Private Fields

var _distance_until_next_spawn := 0.0
var _distance_since_last_sign: float = SIGN_DISTANCE_INTERVAL
var _last_side := 0
var _same_side_streak := 0
var _cleanup_areas: Array[Area2D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shrub_textures: Array[Texture2D] = []
var _sign_texture: Texture2D


# Lifecycle Methods

## Seeds the scenery RNG the first time the owner enters the tree.
func _ready() -> void:
	_rng.randomize()


# Public Methods

## Applies the authored roadside art resources used by spawned scenery.
func configure_scenery_art(shrub_textures: Array[Texture2D], sign_texture: Texture2D) -> void:
	_shrub_textures = shrub_textures.duplicate()
	_sign_texture = sign_texture
	_reset_runtime_state()


## Binds cleanup boundaries so spawned scenery leaves through the same boundary flow as hazards.
func bind_cleanup_areas(cleanup_areas: Array[Area2D]) -> void:
	for cleanup_area in _cleanup_areas:
		if cleanup_area != null and cleanup_area.area_entered.is_connected(_on_cleanup_area_entered):
			cleanup_area.area_entered.disconnect(_on_cleanup_area_entered)

	_cleanup_areas.clear()
	for cleanup_area in cleanup_areas:
		if cleanup_area == null:
			continue

		_cleanup_areas.append(cleanup_area)
		if not cleanup_area.area_entered.is_connected(_on_cleanup_area_entered):
			cleanup_area.area_entered.connect(_on_cleanup_area_entered)


## Advances scenery spawn and motion using traveled distance instead of wall-clock time.
func advance(distance_delta: float) -> void:
	if distance_delta <= 0.0:
		return

	_advance_scenery(distance_delta)


# Private Methods

## Clears live scenery and resets spawn bookkeeping for a new runtime pass.
func _reset_runtime_state() -> void:
	for child in get_children():
		child.queue_free()

	_distance_until_next_spawn = 0.0
	_distance_since_last_sign = SIGN_DISTANCE_INTERVAL
	_last_side = 0
	_same_side_streak = 0


## Moves every spawned roadside item downward with the same scroll distance as the world.
func _move_scenery(distance_delta: float) -> void:
	for child in get_children():
		var scenery := child as Node2D
		if scenery == null:
			continue

		scenery.position.y += distance_delta


## Advances movement and spawning in traveled-distance chunks so spacing stays stable across frame sizes.
func _advance_scenery(distance_delta: float) -> void:
	if _distance_until_next_spawn <= 0.0:
		_prime_next_spawn()

	var remaining_distance: float = distance_delta
	while remaining_distance > 0.0:
		var travel_step: float = minf(remaining_distance, _distance_until_next_spawn)
		_move_scenery(travel_step)
		remaining_distance -= travel_step
		_distance_until_next_spawn -= travel_step
		_distance_since_last_sign += travel_step

		if _distance_until_next_spawn > 0.0:
			continue

		_spawn_next_item()
		_prime_next_spawn()


## Rolls the next spacing threshold before another scenery item may appear.
func _prime_next_spawn() -> void:
	_distance_until_next_spawn = _rng.randf_range(DEFAULT_SPACING_MIN, DEFAULT_SPACING_MAX)


## Creates one roadside item with controlled side selection and small authored jitter.
func _spawn_next_item() -> void:
	var scenery_type := _roll_scenery_type()
	var side := _roll_side()
	var item: Area2D = _build_scenery_item(scenery_type, side)
	item.position = _get_spawn_position(scenery_type, side)
	item.set_meta("spawn_y", item.position.y)
	add_child(item)
	if scenery_type == SCENERY_TYPE_SIGN:
		_distance_since_last_sign = 0.0


## Returns the next scenery type while keeping the sign on a simple deterministic distance interval.
func _roll_scenery_type() -> StringName:
	if _sign_texture != null and _distance_since_last_sign >= SIGN_DISTANCE_INTERVAL:
		return SCENERY_TYPE_SIGN

	return SCENERY_TYPE_SCRUB


## Chooses a roadside side while preventing long same-side streaks.
func _roll_side() -> int:
	var side := -1 if _rng.randi_range(0, 1) == 0 else 1
	if _last_side != 0 and side == _last_side and _same_side_streak >= MAX_SAME_SIDE_STREAK:
		side *= -1

	if side == _last_side:
		_same_side_streak += 1
	else:
		_same_side_streak = 1

	_last_side = side
	return side


## Builds one cleanup-aware scenery item with the correct roadside sprite attached.
func _build_scenery_item(scenery_type: StringName, side: int) -> Area2D:
	var item := Area2D.new()
	item.monitoring = false
	item.monitorable = true
	item.collision_layer = CLEANUP_COLLISION_LAYER
	item.collision_mask = 0
	item.set_meta("scenery_type", scenery_type)
	item.set_meta("side", side)

	var sprite := Sprite2D.new()
	sprite.texture = _get_scenery_texture(scenery_type)
	if scenery_type == SCENERY_TYPE_SCRUB and side > 0:
		sprite.scale.x = -1.0
	item.add_child(sprite)

	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = _build_collision_shape(sprite.texture)
	item.add_child(collision_shape)
	return item


## Resolves the authored art resource used by one scenery type.
func _get_scenery_texture(scenery_type: StringName) -> Texture2D:
	if scenery_type == SCENERY_TYPE_SIGN:
		return _sign_texture
	if _shrub_textures.is_empty():
		return null

	return _shrub_textures[_rng.randi_range(0, _shrub_textures.size() - 1)]


## Builds a small rectangle collision shape for cleanup overlap tracking.
func _build_collision_shape(texture: Texture2D) -> RectangleShape2D:
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = DEFAULT_COLLISION_SIZE if texture == null else texture.get_size()
	return rectangle_shape


## Returns the local spawn position just above view with small roadside jitter.
func _get_spawn_position(scenery_type: StringName, side: int) -> Vector2:
	var base_x := SIGN_MARGIN_X if scenery_type == SCENERY_TYPE_SIGN else SCRUB_MARGIN_X
	var x_jitter := SIGN_X_JITTER if scenery_type == SCENERY_TYPE_SIGN else SCRUB_X_JITTER
	return Vector2(
		(float(side) * base_x) + _rng.randf_range(-x_jitter, x_jitter),
		DEFAULT_SPAWN_Y + _rng.randf_range(-SPAWN_Y_JITTER, SPAWN_Y_JITTER)
	)


# Event Handlers

## Frees one spawned roadside item after it enters a bound cleanup boundary.
func _on_cleanup_area_entered(area: Area2D) -> void:
	var scenery_item := _get_scenery_item_from_area(area)
	if scenery_item == null:
		return

	scenery_item.queue_free()


## Returns the roadside scenery item that entered a cleanup boundary, when owned by this system.
func _get_scenery_item_from_area(area: Area2D) -> Area2D:
	if area == null:
		return null
	if area.get_parent() != self:
		return null

	return area
