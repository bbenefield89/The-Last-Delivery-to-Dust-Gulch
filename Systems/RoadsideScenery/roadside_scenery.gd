extends Node2D

## Owns roadside scenery spawning, movement, and cleanup using distance-driven spacing.


# Constants
const SCENERY_TYPE_SCRUB := &"scrub"
const SCENERY_TYPE_SIGN := &"sign"
const SCRUB_VARIANT_COMPACT := &"compact"
const SCRUB_VARIANT_FULL := &"full"
const SCRUB_VARIANT_TALL := &"tall"
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
const MAX_SAME_SCRUB_TEXTURE_STREAK := 2
const MAX_SAME_SCRUB_VARIANT_STREAK := 2
const MIN_SCRUB_SPAWNS_BETWEEN_SIGNS := 3
const SIGN_DISTANCE_INTERVAL := 720.0
const DEFAULT_COLLISION_SIZE := Vector2(40.0, 40.0)


# Private Fields

var _distance_until_next_spawn := 0.0
var _distance_since_last_sign: float = SIGN_DISTANCE_INTERVAL
var _distance_traveled_total := 0.0
var _spawn_sequence_id := 0
var _scrub_spawns_since_last_sign := MIN_SCRUB_SPAWNS_BETWEEN_SIGNS
var _last_roadside_side := 0
var _same_roadside_side_streak := 0
var _last_sign_side := 0
var _last_scrub_texture_index := -1
var _same_scrub_texture_streak := 0
var _last_scrub_variant := StringName()
var _same_scrub_variant_streak := 0
var _cleanup_areas: Array[Area2D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shrub_textures: Array[Texture2D] = []
var _sign_texture: Texture2D


# Lifecycle Methods

## Seeds the scenery RNG the first time the owner enters the tree.
func _ready() -> void:
	_rng.randomize()


# Event Handlers

## Frees one spawned roadside scenery area after it enters a bound cleanup boundary.
func __on_cleanup_area_entered(area: Area2D) -> void:
	var spawned_scenery_area := _get_spawned_scenery_area_from_cleanup_overlap(area)
	if spawned_scenery_area == null:
		return

	spawned_scenery_area.queue_free()


# Public Methods

## Binds cleanup boundaries so spawned scenery leaves through the same boundary flow as hazards.
func bind_cleanup_areas(cleanup_areas: Array[Area2D]) -> void:
	for cleanup_area in _cleanup_areas:
		if cleanup_area != null and cleanup_area.area_entered.is_connected(__on_cleanup_area_entered):
			cleanup_area.area_entered.disconnect(__on_cleanup_area_entered)

	_cleanup_areas.clear()
	for cleanup_area in cleanup_areas:
		if cleanup_area == null:
			continue

		_cleanup_areas.append(cleanup_area)
		if not cleanup_area.area_entered.is_connected(__on_cleanup_area_entered):
			cleanup_area.area_entered.connect(__on_cleanup_area_entered)


## Applies the authored roadside art resources used by spawned scenery.
func configure_scenery_art(shrub_textures: Array[Texture2D], sign_texture: Texture2D) -> void:
	_shrub_textures = shrub_textures.duplicate()
	_sign_texture = sign_texture
	_reset_runtime_state()


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
	_distance_traveled_total = 0.0
	_spawn_sequence_id = 0
	_scrub_spawns_since_last_sign = MIN_SCRUB_SPAWNS_BETWEEN_SIGNS
	_last_roadside_side = 0
	_same_roadside_side_streak = 0
	_last_sign_side = 0
	_last_scrub_texture_index = -1
	_same_scrub_texture_streak = 0
	_last_scrub_variant = StringName()
	_same_scrub_variant_streak = 0


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
		_schedule_next_spawn_distance()

	var unprocessed_travel_distance: float = distance_delta
	while unprocessed_travel_distance > 0.0:
		var travel_step: float = minf(unprocessed_travel_distance, _distance_until_next_spawn)
		_move_scenery(travel_step)
		unprocessed_travel_distance -= travel_step
		_distance_until_next_spawn -= travel_step
		_distance_since_last_sign += travel_step
		_distance_traveled_total += travel_step

		if _distance_until_next_spawn > 0.0:
			continue

		_spawn_next_scenery_area()
		_schedule_next_spawn_distance()


## Schedules how much farther the run must travel before another roadside spawn is allowed.
func _schedule_next_spawn_distance() -> void:
	_distance_until_next_spawn = _rng.randf_range(DEFAULT_SPACING_MIN, DEFAULT_SPACING_MAX)


## Creates one roadside scenery area with controlled side selection and small authored jitter.
func _spawn_next_scenery_area() -> void:
	var scenery_type := _select_next_scenery_type()
	var roadside_side := _select_spawn_side(scenery_type)
	var scrub_texture_index := -1
	var scrub_variant := StringName()
	if scenery_type == SCENERY_TYPE_SCRUB:
		scrub_texture_index = _select_scrub_texture_index()
		scrub_variant = _select_scrub_variant()

	var spawned_scenery_area: Area2D = _build_spawned_scenery_area(
		scenery_type,
		roadside_side,
		scrub_texture_index,
		scrub_variant
	)
	spawned_scenery_area.position = _get_spawn_position(scenery_type, roadside_side)
	spawned_scenery_area.set_meta("spawn_y", spawned_scenery_area.position.y)
	spawned_scenery_area.set_meta("spawn_sequence_id", _spawn_sequence_id)
	spawned_scenery_area.set_meta("travel_distance_spawned", _distance_traveled_total)
	add_child(spawned_scenery_area)
	_spawn_sequence_id += 1

	if scenery_type == SCENERY_TYPE_SIGN:
		_distance_since_last_sign = 0.0
		_scrub_spawns_since_last_sign = 0
		_last_sign_side = roadside_side
	else:
		_scrub_spawns_since_last_sign += 1


## Returns the next scenery type while keeping the sign on explicit cadence and scrub-cooldown rules.
func _select_next_scenery_type() -> StringName:
	if _can_spawn_sign():
		return SCENERY_TYPE_SIGN

	return SCENERY_TYPE_SCRUB


## Returns whether the next spawn slot is allowed to place the Dust Gulch sign.
func _can_spawn_sign() -> bool:
	if _sign_texture == null:
		return false
	if _distance_since_last_sign < SIGN_DISTANCE_INTERVAL:
		return false

	return _scrub_spawns_since_last_sign >= MIN_SCRUB_SPAWNS_BETWEEN_SIGNS


## Chooses the next left-or-right roadside side while preventing long same-side streaks.
func _select_spawn_side(scenery_type: StringName) -> int:
	if scenery_type == SCENERY_TYPE_SIGN:
		return _select_sign_side()

	return _select_scrub_side()


## Chooses the next scrub side while preventing long same-side streaks.
func _select_scrub_side() -> int:
	var roadside_side := -1 if _rng.randi_range(0, 1) == 0 else 1
	if (
		_last_roadside_side != 0
		and roadside_side == _last_roadside_side
		and _same_roadside_side_streak >= MAX_SAME_SIDE_STREAK
	):
		roadside_side *= -1

	if roadside_side == _last_roadside_side:
		_same_roadside_side_streak += 1
	else:
		_same_roadside_side_streak = 1

	_last_roadside_side = roadside_side
	return roadside_side


## Chooses a sign side that alternates when possible so signs stay readable and intentional.
func _select_sign_side() -> int:
	if _last_sign_side != 0:
		return -_last_sign_side

	return _select_scrub_side()


## Chooses one scrub texture index while preventing long repeated texture streaks.
func _select_scrub_texture_index() -> int:
	if _shrub_textures.is_empty():
		return -1

	var selected_index := _rng.randi_range(0, _shrub_textures.size() - 1)
	if (
		_shrub_textures.size() > 1
		and selected_index == _last_scrub_texture_index
		and _same_scrub_texture_streak >= MAX_SAME_SCRUB_TEXTURE_STREAK
	):
		selected_index = (selected_index + 1 + _rng.randi_range(0, _shrub_textures.size() - 2)) % _shrub_textures.size()

	if selected_index == _last_scrub_texture_index:
		_same_scrub_texture_streak += 1
	else:
		_same_scrub_texture_streak = 1

	_last_scrub_texture_index = selected_index
	return selected_index


## Chooses one scrub size variant with weighted variety while limiting repeated silhouettes.
func _select_scrub_variant() -> StringName:
	var scrub_variant := _roll_weighted_scrub_variant()
	if (
		scrub_variant == _last_scrub_variant
		and _same_scrub_variant_streak >= MAX_SAME_SCRUB_VARIANT_STREAK
	):
		scrub_variant = _choose_alternate_scrub_variant(scrub_variant)

	if scrub_variant == _last_scrub_variant:
		_same_scrub_variant_streak += 1
	else:
		_same_scrub_variant_streak = 1

	_last_scrub_variant = scrub_variant
	return scrub_variant


## Returns one weighted scrub variant to keep the stream varied without feeling noisy.
func _roll_weighted_scrub_variant() -> StringName:
	var scrub_variant_roll := _rng.randf()
	if scrub_variant_roll < 0.45:
		return SCRUB_VARIANT_FULL
	if scrub_variant_roll < 0.8:
		return SCRUB_VARIANT_COMPACT

	return SCRUB_VARIANT_TALL


## Returns a different scrub variant when the weighted pick would over-repeat one silhouette.
func _choose_alternate_scrub_variant(current_variant: StringName) -> StringName:
	var alternate_variants: Array[StringName] = [
		SCRUB_VARIANT_FULL,
		SCRUB_VARIANT_COMPACT,
		SCRUB_VARIANT_TALL,
	]
	alternate_variants.erase(current_variant)
	return alternate_variants[_rng.randi_range(0, alternate_variants.size() - 1)]


## Builds one cleanup-aware roadside scenery area with the correct roadside sprite attached.
func _build_spawned_scenery_area(
	scenery_type: StringName,
	roadside_side: int,
	scrub_texture_index: int,
	scrub_variant: StringName
) -> Area2D:
	var spawned_scenery_area := Area2D.new()
	spawned_scenery_area.monitoring = false
	spawned_scenery_area.monitorable = true
	spawned_scenery_area.collision_layer = CLEANUP_COLLISION_LAYER
	spawned_scenery_area.collision_mask = 0
	spawned_scenery_area.set_meta("scenery_type", scenery_type)
	spawned_scenery_area.set_meta("roadside_side", roadside_side)
	spawned_scenery_area.set_meta("texture_index", scrub_texture_index)
	spawned_scenery_area.set_meta("scrub_variant", scrub_variant)

	var sprite := Sprite2D.new()
	var scenery_texture := _get_scenery_texture(scenery_type, scrub_texture_index)
	sprite.texture = scenery_texture
	sprite.scale = _get_sprite_scale(scenery_type, roadside_side, scrub_variant)
	spawned_scenery_area.add_child(sprite)

	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = _build_collision_shape(scenery_texture, sprite.scale)
	spawned_scenery_area.add_child(collision_shape)
	return spawned_scenery_area


## Resolves the authored art resource used by one scenery type.
func _get_scenery_texture(scenery_type: StringName, scrub_texture_index: int) -> Texture2D:
	if scenery_type == SCENERY_TYPE_SIGN:
		return _sign_texture
	if scrub_texture_index < 0 or scrub_texture_index >= _shrub_textures.size():
		return null

	return _shrub_textures[scrub_texture_index]


## Returns the display scale for one scenery sprite while keeping scrub variation readable.
func _get_sprite_scale(scenery_type: StringName, roadside_side: int, scrub_variant: StringName) -> Vector2:
	if scenery_type == SCENERY_TYPE_SIGN:
		return Vector2.ONE

	var scrub_scale := _get_scrub_variant_scale(scrub_variant)
	if roadside_side > 0:
		scrub_scale.x *= -1.0

	return scrub_scale


## Returns the display scale for one scrub silhouette variant.
func _get_scrub_variant_scale(scrub_variant: StringName) -> Vector2:
	match scrub_variant:
		SCRUB_VARIANT_COMPACT:
			return Vector2(0.88, 0.88)
		SCRUB_VARIANT_TALL:
			return Vector2(1.06, 1.18)
		_:
			return Vector2.ONE


## Builds a small rectangle collision shape for cleanup overlap tracking.
func _build_collision_shape(texture: Texture2D, sprite_scale: Vector2) -> RectangleShape2D:
	var rectangle_shape := RectangleShape2D.new()
	var texture_size := DEFAULT_COLLISION_SIZE if texture == null else texture.get_size()
	rectangle_shape.size = Vector2(
		texture_size.x * absf(sprite_scale.x),
		texture_size.y * absf(sprite_scale.y)
	)
	return rectangle_shape


## Returns the local spawn position just above view with small roadside jitter.
func _get_spawn_position(scenery_type: StringName, roadside_side: int) -> Vector2:
	var base_x := SIGN_MARGIN_X if scenery_type == SCENERY_TYPE_SIGN else SCRUB_MARGIN_X
	var x_jitter := SIGN_X_JITTER if scenery_type == SCENERY_TYPE_SIGN else SCRUB_X_JITTER
	return Vector2(
		(float(roadside_side) * base_x) + _rng.randf_range(-x_jitter, x_jitter),
		DEFAULT_SPAWN_Y + _rng.randf_range(-SPAWN_Y_JITTER, SPAWN_Y_JITTER)
	)


## Returns the spawned roadside scenery area that entered a cleanup boundary, when owned by this system.
func _get_spawned_scenery_area_from_cleanup_overlap(area: Area2D) -> Area2D:
	if area == null:
		return null
	if area.get_parent() != self:
		return null

	return area
