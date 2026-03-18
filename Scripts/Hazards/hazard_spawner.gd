class_name HazardSpawner
extends Node2D

## Spawns readable hazard layouts with route-progress pacing and late-run pressure pairs.

const LANE_X_POSITIONS := [-68.0, 0.0, 68.0]
const DEFAULT_SPAWN_Y := -320.0
const DEFAULT_DESPAWN_Y := 260.0
const POTHOLE_TEXTURE := preload("res://Assets/Tilesets/Pothole/Pothole-32x32.png")
const ROCK_TEXTURE := preload("res://Assets/Tilesets/Boulder/Boulder-32x32.png")
const TUMBLEWEED_TEXTURE := preload("res://Assets/Tilesets/Tumbleweed/Tumbleweed-32x32.png")
const PRESSURE_PAIR_PROGRESS_THRESHOLD := 0.72
const PRESSURE_PAIR_Y_OFFSET := 56.0
const HAZARD_DAMAGE := {
	&"pothole": 10,
	&"rock": 15,
	&"tumbleweed": 6,
}
const HAZARD_CARGO_DAMAGE := {
	&"pothole": 4,
	&"rock": 7,
	&"tumbleweed": 3,
}

# Private Fields

var _distance_until_next_spawn := 0.0
var _route_progress_ratio := 0.0
var _next_spawn_plan: SpawnPlan
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Initializes the first randomized spawn plan.
func _ready() -> void:
	_rng.randomize()


## Advances active hazards and spawns new ones using the current route-progress band.
func advance(distance_delta: float, route_progress_ratio: float = 0.0) -> void:
	_route_progress_ratio = clamp(route_progress_ratio, 0.0, 1.0)
	if _next_spawn_plan == null:
		_prime_next_spawn()
	if _next_spawn_plan != null:
		var active_spacing := _next_spawn_plan.spacing
		_distance_until_next_spawn = min(_distance_until_next_spawn, active_spacing)
	_move_hazards(distance_delta)
	_spawn_hazards(distance_delta)
	_cleanup_hazards()


## Moves all live hazards downward with the current scroll distance.
func _move_hazards(distance_delta: float) -> void:
	for child in get_children():
		if child is Node2D:
			child.position.y += distance_delta


## Consumes scroll distance to spawn one or more planned hazard groups.
func _spawn_hazards(distance_delta: float) -> void:
	if _next_spawn_plan == null:
		return

	var remaining_distance := distance_delta
	while _distance_until_next_spawn <= remaining_distance:
		remaining_distance -= _distance_until_next_spawn
		_spawn_current_plan()
		_prime_next_spawn()

	_distance_until_next_spawn -= remaining_distance


## Rolls the next spawn plan from the active route-progress band.
func _prime_next_spawn() -> void:
	var band := _get_active_band()
	var lane_index := _rng.randi_range(0, LANE_X_POSITIONS.size() - 1)
	var plan := SpawnPlan.new(_roll_hazard_type(band.weights), lane_index, _roll_spacing(band))
	if band.allows_pressure_pair and _route_progress_ratio >= PRESSURE_PAIR_PROGRESS_THRESHOLD:
		var pressure_lane := _get_pressure_lane_index(lane_index)
		if pressure_lane != lane_index:
			plan.pressure_pair_type = _roll_hazard_type(band.weights)
			plan.pressure_pair_lane_index = pressure_lane
	_next_spawn_plan = plan
	_distance_until_next_spawn = _next_spawn_plan.spacing


## Spawns the currently rolled primary hazard and optional late-run pressure pair.
func _spawn_current_plan() -> void:
	if _next_spawn_plan == null:
		return

	_spawn_hazard(_next_spawn_plan.hazard_type, _next_spawn_plan.lane_index)
	if _next_spawn_plan.has_pressure_pair():
		_spawn_hazard(
			_next_spawn_plan.pressure_pair_type,
			_next_spawn_plan.pressure_pair_lane_index,
			DEFAULT_SPAWN_Y - PRESSURE_PAIR_Y_OFFSET
		)


## Adds one hazard node using the shared visual and metadata conventions.
func _spawn_hazard(hazard_type: StringName, lane_index: int, spawn_y: float = DEFAULT_SPAWN_Y) -> void:
	var hazard := _build_hazard_visual(hazard_type)
	hazard.position = Vector2(LANE_X_POSITIONS[lane_index], spawn_y)
	hazard.set_meta("hazard_type", hazard_type)
	hazard.set_meta("lane_index", lane_index)
	add_child(hazard)


## Returns the current band definition for the active route progress.
func _get_active_band() -> SpawnBand:
	if _route_progress_ratio < 0.33:
		return SpawnBand.new(520.0, 660.0, 6, 2, 4, false)
	if _route_progress_ratio < 0.66:
		return SpawnBand.new(420.0, 560.0, 4, 3, 3, false)
	return SpawnBand.new(320.0, 460.0, 4, 5, 3, true)


## Rolls a hazard type from the current band's weights.
func _roll_hazard_type(weights: HazardWeights) -> StringName:
	var total_weight := weights.pothole + weights.rock + weights.tumbleweed
	var roll := _rng.randi_range(1, total_weight)
	if roll <= weights.pothole:
		return &"pothole"
	if roll <= weights.pothole + weights.rock:
		return &"rock"
	return &"tumbleweed"


## Rolls band-specific spacing for the next spawn.
func _roll_spacing(band: SpawnBand) -> float:
	return _rng.randf_range(band.spacing_min, band.spacing_max)


## Chooses a secondary lane that preserves the existing center-lane pressure behavior.
func _get_pressure_lane_index(primary_lane_index: int) -> int:
	if primary_lane_index == 1:
		return 0 if _route_progress_ratio < 0.85 else 2

	return 1


## Builds a readable sprite for the requested hazard type.
func _build_hazard_visual(hazard_type: StringName) -> Sprite2D:
	var hazard := Sprite2D.new()
	hazard.texture = _get_hazard_texture(hazard_type)
	return hazard


## Resolves the imported sprite texture for the requested hazard type.
func _get_hazard_texture(hazard_type: StringName) -> Texture2D:
	match hazard_type:
		&"pothole":
			return POTHOLE_TEXTURE
		&"rock":
			return ROCK_TEXTURE
		&"tumbleweed":
			return TUMBLEWEED_TEXTURE
		_:
			return POTHOLE_TEXTURE


## Frees hazards after they scroll past the visible play area.
func _cleanup_hazards() -> void:
	for child in get_children():
		if child is Node2D and child.position.y > DEFAULT_DESPAWN_Y:
			child.queue_free()


## Collects all hazards whose current bounds overlap the wagon bounds.
func collect_collisions(wagon_position: Vector2, wagon_size: Vector2) -> Array[Dictionary]:
	var collisions: Array[Dictionary] = []
	var wagon_rect := Rect2(wagon_position - (wagon_size * 0.5), wagon_size)

	for child in get_children():
		if not child is Node2D:
			continue

		var hazard := child as Node2D
		var hazard_size := _get_hazard_size(hazard.get_meta("hazard_type", &""))
		var hazard_rect := Rect2(hazard.position - (hazard_size * 0.5), hazard_size)
		if wagon_rect.intersects(hazard_rect):
			collisions.append({
				"type": hazard.get_meta("hazard_type", &""),
				"damage": HAZARD_DAMAGE.get(hazard.get_meta("hazard_type", &""), 0),
				"cargo_damage": HAZARD_CARGO_DAMAGE.get(hazard.get_meta("hazard_type", &""), 0),
				"node": hazard,
			})

	return collisions


## Returns the collision size used for each hazard type.
func _get_hazard_size(hazard_type: StringName) -> Vector2:
	match hazard_type:
		&"pothole":
			return Vector2(32.0, 24.0)
		&"rock":
			return Vector2(36.0, 36.0)
		&"tumbleweed":
			return Vector2(32.0, 32.0)
		_:
			return Vector2(32.0, 32.0)


class SpawnBand:
	extends RefCounted
	## Describes weighted spawn rules for one route-progress band.

	var spacing_min: float
	var spacing_max: float
	var weights: HazardWeights
	var allows_pressure_pair: bool


	## Stores spacing bounds, type weights, and late-pressure eligibility.
	func _init(
		spacing_min_value: float,
		spacing_max_value: float,
		pothole_weight: int,
		rock_weight: int,
		tumbleweed_weight: int,
		allows_pressure_pair_value: bool
	) -> void:
		spacing_min = spacing_min_value
		spacing_max = spacing_max_value
		weights = HazardWeights.new(pothole_weight, rock_weight, tumbleweed_weight)
		allows_pressure_pair = allows_pressure_pair_value


class HazardWeights:
	extends RefCounted
	## Holds weighted odds for the three supported hazard types.

	var pothole: int
	var rock: int
	var tumbleweed: int


	## Stores weight values for hazard selection rolls.
	func _init(pothole_weight: int, rock_weight: int, tumbleweed_weight: int) -> void:
		pothole = pothole_weight
		rock = rock_weight
		tumbleweed = tumbleweed_weight


class SpawnPlan:
	extends RefCounted
	## Captures one rolled spawn group, including an optional pressure pair.

	var hazard_type: StringName
	var lane_index: int
	var spacing: float
	var pressure_pair_type: StringName = &""
	var pressure_pair_lane_index := -1


	## Stores the rolled primary hazard and its spacing until spawn.
	func _init(primary_hazard_type: StringName, primary_lane_index: int, spawn_spacing: float) -> void:
		hazard_type = primary_hazard_type
		lane_index = primary_lane_index
		spacing = spawn_spacing


	## Returns whether this plan includes a secondary pressure-pair hazard.
	func has_pressure_pair() -> bool:
		return pressure_pair_lane_index >= 0 and pressure_pair_type != &""
