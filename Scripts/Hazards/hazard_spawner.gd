class_name HazardSpawner
extends Node2D

## Spawns readable hazard layouts with route-progress pacing and phase-based pressure pairs.

const LANE_X_POSITIONS := [-96.0, -64.0, -32.0, 0.0, 32.0, 64.0, 96.0]
const DEFAULT_SPAWN_Y := -320.0
const DEFAULT_DESPAWN_Y := 260.0
const DEFAULT_HAZARD_TYPE := &"pothole"
const PRESSURE_PAIR_Y_OFFSET := 56.0
const TUMBLEWEED_DRIFT_X_PER_SCROLL_UNIT_MIN := 0.08
const TUMBLEWEED_DRIFT_X_PER_SCROLL_UNIT_MAX := 0.50
const TUMBLEWEED_BASE_ROTATION_RADIANS_PER_SCROLL_UNIT := 0.018
const TUMBLEWEED_BOUNCE_AMPLITUDE := 5.5
const TUMBLEWEED_BOUNCE_RADIANS_PER_SCROLL_UNIT := 0.04
const TUMBLEWEED_TARGET_Y := 0.0
const LIVESTOCK_CROSSING_TARGET_Y := 0.0
const LIVESTOCK_CROSSING_X_PER_SCROLL_UNIT := 0.75
const HAZARD_SIDE_DESPAWN_X := 360.0
const ROUTE_PHASE_WARM_UP := &"warm_up"
const ROUTE_PHASE_FIRST_TROUBLE := &"first_trouble"
const ROUTE_PHASE_CROSSING_BEAT := &"crossing_beat"
const ROUTE_PHASE_CLUTTER_BEAT := &"clutter_beat"
const ROUTE_PHASE_RESET_BEFORE_FINALE := &"reset_before_finale"
const ROUTE_PHASE_FINAL_STRETCH := &"final_stretch"
const ROUTE_PHASE_WARM_UP_END := 0.20
const ROUTE_PHASE_FIRST_TROUBLE_END := 0.45
const ROUTE_PHASE_CROSSING_BEAT_END := 0.60
const ROUTE_PHASE_CLUTTER_BEAT_END := 0.80
const ROUTE_PHASE_RESET_BEFORE_FINALE_END := 0.88
const FINAL_STRETCH_SPACING_MIN := 180.0
const FINAL_STRETCH_SPACING_MAX := 250.0
const FINAL_STRETCH_CLEAR_RUNWAY_DISTANCE := 240.0
const FINAL_STRETCH_RELEASE_DISTANCE := (
	FINAL_STRETCH_CLEAR_RUNWAY_DISTANCE
	+ DEFAULT_DESPAWN_Y
	- (DEFAULT_SPAWN_Y - PRESSURE_PAIR_Y_OFFSET)
	+ 1.0
)
const FINAL_STRETCH_POTHOLE_WEIGHT := 1
const FINAL_STRETCH_ROCK_WEIGHT := 5
const FINAL_STRETCH_TUMBLEWEED_WEIGHT := 4
const FINAL_STRETCH_LIVESTOCK_WEIGHT := 2
const WARM_UP_LANE_INDICES: Array[int] = [2, 3, 4]
const FIRST_TROUBLE_LANE_INDICES: Array[int] = [1, 2, 3, 4, 5]
const FULL_ROAD_LANE_INDICES: Array[int] = [0, 1, 2, 3, 4, 5, 6]

# Public Fields: Export

@export var pothole_texture: Texture2D
@export var rock_texture: Texture2D
@export var tumbleweed_texture: Texture2D
@export var livestock_texture: Texture2D

# Private Fields

var _distance_until_next_spawn := 0.0
var _route_progress_ratio := 0.0
var _active_route_phase: StringName = &""
var _next_spawn_plan: SpawnPlan
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Initializes the first randomized spawn plan.
func _ready() -> void:
	_rng.randomize()


## Advances active hazards and spawns new ones using the current route-progress band.
func advance(
	distance_delta: float,
	route_progress_ratio: float = 0.0,
	route_remaining_distance: float = INF,
	route_distance: float = INF
) -> void:
	_route_progress_ratio = clamp(route_progress_ratio, 0.0, 1.0)
	_sync_route_phase()
	if _should_hold_final_stretch_release(route_remaining_distance, route_distance):
		_clear_regular_spawn_schedule()
	elif _next_spawn_plan == null:
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
			var hazard := child as Node2D
			hazard.position += _get_hazard_motion(hazard, distance_delta)
			hazard.rotation += _get_hazard_rotation_delta(hazard, distance_delta)
			_update_hazard_bounce(hazard, distance_delta)


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
	var hazard_type := _roll_hazard_type(band.weights)
	var lane_index := _roll_lane_index(band.lane_indices)
	var plan := SpawnPlan.new(hazard_type, lane_index, _roll_spacing(band))
	if band.allows_pressure_pair:
		var pressure_lane := _get_pressure_lane_index(lane_index, band.lane_indices)
		if pressure_lane != lane_index:
			plan.pressure_pair_type = _roll_pressure_pair_type(hazard_type, band.weights)
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


## Resets the queued spawn plan when route progress enters a new authored phase.
func _sync_route_phase() -> void:
	var next_route_phase := _get_route_phase(_route_progress_ratio)
	if next_route_phase == _active_route_phase:
		return

	_active_route_phase = next_route_phase
	_next_spawn_plan = null
	_distance_until_next_spawn = 0.0


## Returns whether the final stretch has entered the clear runway before the finish line.
func _should_hold_final_stretch_release(route_remaining_distance: float, route_distance: float) -> bool:
	return (
		_get_route_phase(_route_progress_ratio) == ROUTE_PHASE_FINAL_STRETCH
		and _supports_final_stretch_release(route_distance)
		and route_remaining_distance <= FINAL_STRETCH_RELEASE_DISTANCE
	)


## Returns whether the current route is long enough to fit the full clear-runway guarantee.
func _supports_final_stretch_release(route_distance: float) -> bool:
	if not is_finite(route_distance):
		return false

	return route_distance * (1.0 - ROUTE_PHASE_RESET_BEFORE_FINALE_END) >= FINAL_STRETCH_RELEASE_DISTANCE


## Clears the regular spawn scheduler so the final stretch can end without fresh hazards.
func _clear_regular_spawn_schedule() -> void:
	_next_spawn_plan = null
	_distance_until_next_spawn = 0.0


## Adds one hazard node using the shared visual and metadata conventions.
func _spawn_hazard(hazard_type: StringName, lane_index: int, spawn_y: float = DEFAULT_SPAWN_Y) -> void:
	var resolved_lane_index := _resolve_lane_index(lane_index)
	var hazard := _build_hazard_visual(hazard_type)
	hazard.position = _resolve_spawn_position(hazard, hazard_type, resolved_lane_index, spawn_y)
	hazard.set_meta("hazard_type", hazard_type)
	hazard.set_meta("lane_index", resolved_lane_index)
	add_child(hazard)


## Returns the current band definition for the active route progress.
func _get_active_band() -> SpawnBand:
	match _get_route_phase(_route_progress_ratio):
		ROUTE_PHASE_WARM_UP:
			return SpawnBand.new(280.0, 360.0, 9, 2, 0, 0, false, WARM_UP_LANE_INDICES)
		ROUTE_PHASE_FIRST_TROUBLE:
			return SpawnBand.new(220.0, 320.0, 4, 3, 3, 0, false, FIRST_TROUBLE_LANE_INDICES)
		ROUTE_PHASE_CROSSING_BEAT:
			return SpawnBand.new(230.0, 320.0, 1, 1, 5, 4, true, FULL_ROAD_LANE_INDICES)
		ROUTE_PHASE_CLUTTER_BEAT:
			return SpawnBand.new(210.0, 290.0, 3, 6, 1, 0, true, FULL_ROAD_LANE_INDICES)
		ROUTE_PHASE_FINAL_STRETCH:
			return SpawnBand.new(
				FINAL_STRETCH_SPACING_MIN,
				FINAL_STRETCH_SPACING_MAX,
				FINAL_STRETCH_POTHOLE_WEIGHT,
				FINAL_STRETCH_ROCK_WEIGHT,
				FINAL_STRETCH_TUMBLEWEED_WEIGHT,
				FINAL_STRETCH_LIVESTOCK_WEIGHT,
				true,
				FULL_ROAD_LANE_INDICES
			)
		_:
			return SpawnBand.new(320.0, 420.0, 5, 4, 1, 0, false, FULL_ROAD_LANE_INDICES)


## Returns the current authored phase for one route-progress ratio.
func _get_route_phase(progress_ratio: float) -> StringName:
	if progress_ratio < ROUTE_PHASE_WARM_UP_END:
		return ROUTE_PHASE_WARM_UP
	if progress_ratio < ROUTE_PHASE_FIRST_TROUBLE_END:
		return ROUTE_PHASE_FIRST_TROUBLE
	if progress_ratio < ROUTE_PHASE_CROSSING_BEAT_END:
		return ROUTE_PHASE_CROSSING_BEAT
	if progress_ratio < ROUTE_PHASE_CLUTTER_BEAT_END:
		return ROUTE_PHASE_CLUTTER_BEAT
	if progress_ratio < ROUTE_PHASE_RESET_BEFORE_FINALE_END:
		return ROUTE_PHASE_RESET_BEFORE_FINALE
	return ROUTE_PHASE_FINAL_STRETCH


## Rolls a hazard type from the current band's weights.
func _roll_hazard_type(weights: HazardWeights) -> StringName:
	var total_weight := weights.pothole + weights.rock + weights.tumbleweed + weights.livestock
	var roll := _rng.randi_range(1, total_weight)
	if roll <= weights.pothole:
		return &"pothole"
	if roll <= weights.pothole + weights.rock:
		return &"rock"
	if roll <= weights.pothole + weights.rock + weights.tumbleweed:
		return &"tumbleweed"
	return &"livestock"


## Rolls a pressure-pair hazard that complements the primary hazard's gameplay role.
func _roll_pressure_pair_type(primary_hazard_type: StringName, weights: HazardWeights) -> StringName:
	if _is_static_hazard_type(primary_hazard_type):
		return _roll_hazard_type(HazardWeights.new(0, 0, weights.tumbleweed, weights.livestock))
	return _roll_hazard_type(HazardWeights.new(weights.pothole, weights.rock, 0, 0))


## Rolls band-specific spacing for the next spawn.
func _roll_spacing(band: SpawnBand) -> float:
	return _rng.randf_range(band.spacing_min, band.spacing_max)


## Rolls one lane index from the supplied road subset.
func _roll_lane_index(allowed_lane_indices: Array[int] = FULL_ROAD_LANE_INDICES) -> int:
	if allowed_lane_indices.is_empty():
		return _rng.randi_range(0, LANE_X_POSITIONS.size() - 1)

	var resolved_roll_index := _rng.randi_range(0, allowed_lane_indices.size() - 1)
	return _resolve_lane_index(allowed_lane_indices[resolved_roll_index])


## Clamps one lane selection to the valid 7-tile road grid.
func _resolve_lane_index(lane_index: int) -> int:
	return clampi(lane_index, 0, LANE_X_POSITIONS.size() - 1)


## Returns the centered x position for one road-tile lane.
func _get_lane_center_x(lane_index: int) -> float:
	return LANE_X_POSITIONS[_resolve_lane_index(lane_index)]


## Returns the centered world position for one road-tile lane at the supplied y.
func _get_lane_center_position(lane_index: int, y_position: float) -> Vector2:
	return Vector2(_get_lane_center_x(lane_index), y_position)


## Chooses a secondary lane from the allowed subset while avoiding the primary lane.
func _get_pressure_lane_index(primary_lane_index: int, allowed_lane_indices: Array[int]) -> int:
	var pressure_lane_index := _roll_lane_index(allowed_lane_indices)
	while pressure_lane_index == primary_lane_index:
		pressure_lane_index = _roll_lane_index(allowed_lane_indices)
	return pressure_lane_index


## Returns whether the hazard's core role is static pressure instead of moving timing pressure.
func _is_static_hazard_type(hazard_type: StringName) -> bool:
	return hazard_type == &"pothole" or hazard_type == &"rock"

## Builds a readable hazard node for the requested hazard type.
func _build_hazard_visual(hazard_type: StringName) -> Node2D:
	var profile := _get_hazard_profile(hazard_type)
	var hazard := Sprite2D.new()
	hazard.texture = profile["texture"]
	return hazard


## Returns the per-frame motion offset for one hazard, including lateral drift on moving hazards.
func _get_hazard_motion(hazard: Node2D, distance_delta: float) -> Vector2:
	return Vector2(
		float(hazard.get_meta("crossing_scroll_ratio_x", 0.0)) * distance_delta,
		distance_delta
	)


## Returns the rotation delta for one hazard so moving hazards can visually match their travel speed.
func _get_hazard_rotation_delta(hazard: Node2D, distance_delta: float) -> float:
	return float(hazard.get_meta("rotation_radians_per_scroll_unit", 0.0)) * distance_delta


## Applies visual-only bounce to hazards that opt into rolling motion without changing gameplay collision.
func _update_hazard_bounce(hazard: Node2D, distance_delta: float) -> void:
	var sprite := hazard as Sprite2D
	if sprite == null:
		return

	var bounce_amplitude := float(hazard.get_meta("bounce_amplitude", 0.0))
	var bounce_radians_per_scroll_unit := float(hazard.get_meta("bounce_radians_per_scroll_unit", 0.0))
	if bounce_amplitude == 0.0 or bounce_radians_per_scroll_unit == 0.0:
		sprite.offset.y = 0.0
		return

	var bounce_phase := float(hazard.get_meta("bounce_phase", 0.0))
	bounce_phase += bounce_radians_per_scroll_unit * distance_delta
	hazard.set_meta("bounce_phase", bounce_phase)
	sprite.offset.y = sin(bounce_phase) * bounce_amplitude


## Resolves the spawn position for one hazard and configures any hazard-specific movement metadata.
func _resolve_spawn_position(
	hazard: Node2D,
	hazard_type: StringName,
	lane_index: int,
	spawn_y: float
) -> Vector2:
	if hazard_type == &"tumbleweed":
		return _configure_tumbleweed_drift(hazard, lane_index, spawn_y)
	if hazard_type != &"livestock":
		return _get_lane_center_position(lane_index, spawn_y)

	return _configure_livestock_crossing(hazard, lane_index, spawn_y)


## Assigns lateral drift metadata so tumbleweeds sweep across the road and create timing reads.
func _configure_tumbleweed_drift(hazard: Node2D, lane_index: int, spawn_y: float) -> Vector2:
	var drift_direction := _get_tumbleweed_drift_direction(lane_index)
	var drift_ratio_x := _roll_tumbleweed_drift_ratio()
	var signed_drift_ratio_x := drift_ratio_x * float(drift_direction)
	var drift_speed_multiplier := sqrt(1.0 + pow(drift_ratio_x, 2.0))
	hazard.set_meta("crossing_direction", drift_direction)
	hazard.set_meta("crossing_scroll_ratio_x", signed_drift_ratio_x)
	hazard.set_meta(
		"rotation_radians_per_scroll_unit",
		TUMBLEWEED_BASE_ROTATION_RADIANS_PER_SCROLL_UNIT * drift_speed_multiplier * float(drift_direction)
	)
	hazard.set_meta("bounce_amplitude", TUMBLEWEED_BOUNCE_AMPLITUDE)
	hazard.set_meta("bounce_radians_per_scroll_unit", TUMBLEWEED_BOUNCE_RADIANS_PER_SCROLL_UNIT * drift_speed_multiplier)
	hazard.set_meta("bounce_phase", 0.0)
	hazard.set_meta("target_lane_x", _get_tumbleweed_target_x(lane_index, spawn_y, signed_drift_ratio_x))
	return _get_lane_center_position(lane_index, spawn_y)


## Chooses a tumbleweed drift direction that keeps the hazard moving across the road instead of away from it.
func _get_tumbleweed_drift_direction(lane_index: int) -> int:
	if lane_index <= 1:
		return 1
	if lane_index >= LANE_X_POSITIONS.size() - 2:
		return -1
	return -1 if _rng.randi_range(0, 1) == 0 else 1


## Rolls one tumbleweed lateral speed ratio so different tumbleweeds can arrive slowly or quickly.
func _roll_tumbleweed_drift_ratio() -> float:
	return _rng.randf_range(TUMBLEWEED_DRIFT_X_PER_SCROLL_UNIT_MIN, TUMBLEWEED_DRIFT_X_PER_SCROLL_UNIT_MAX)


## Projects the tumbleweed's x position at the wagon line using the rolled lateral speed.
func _get_tumbleweed_target_x(lane_index: int, spawn_y: float, signed_drift_ratio_x: float) -> float:
	var travel_distance_to_target_y := absf(spawn_y - TUMBLEWEED_TARGET_Y)
	return _get_lane_center_x(lane_index) + (signed_drift_ratio_x * travel_distance_to_target_y)


## Assigns crossing metadata so livestock enters from a roadside edge and passes through a target lane.
func _configure_livestock_crossing(hazard: Node2D, lane_index: int, spawn_y: float) -> Vector2:
	var crossing_direction := _roll_livestock_crossing_direction()
	hazard.scale.x = float(crossing_direction)
	hazard.set_meta("crossing_direction", crossing_direction)
	hazard.set_meta(
		"crossing_scroll_ratio_x",
		LIVESTOCK_CROSSING_X_PER_SCROLL_UNIT * float(crossing_direction)
	)
	hazard.set_meta("target_lane_x", _get_lane_center_x(lane_index))
	return Vector2(
		_get_livestock_spawn_x(lane_index, spawn_y, crossing_direction),
		spawn_y
	)


## Rolls whether a livestock hazard crosses left-to-right or right-to-left.
func _roll_livestock_crossing_direction() -> int:
	return -1 if _rng.randi_range(0, 1) == 0 else 1


## Places livestock far enough off-road that it reaches the target lane near the wagon line.
func _get_livestock_spawn_x(lane_index: int, spawn_y: float, crossing_direction: int) -> float:
	var crossing_distance := absf(spawn_y - LIVESTOCK_CROSSING_TARGET_Y) * LIVESTOCK_CROSSING_X_PER_SCROLL_UNIT
	return _get_lane_center_x(lane_index) - (crossing_distance * float(crossing_direction))


## Resolves the shared gameplay profile for the requested hazard type.
func _get_hazard_profile(hazard_type: StringName) -> Dictionary:
	match hazard_type:
		&"rock":
			return {
				"texture": rock_texture,
				"damage": 18,
				"cargo_damage": 9,
				"size": Vector2(36.0, 36.0),
			}
		&"tumbleweed":
			return {
				"texture": tumbleweed_texture,
				"damage": 6,
				"cargo_damage": 3,
				"size": Vector2(32.0, 32.0),
			}
		&"livestock":
			return {
				"texture": livestock_texture,
				"damage": 12,
				"cargo_damage": 5,
				"size": Vector2(32.0, 32.0),
			}
		_:
			return {
				"texture": pothole_texture,
				"damage": 6,
				"cargo_damage": 2,
				"size": Vector2(32.0, 24.0),
			}


## Frees hazards after they scroll past the visible play area.
func _cleanup_hazards() -> void:
	for child in get_children():
		if child is Node2D and _should_despawn_hazard(child as Node2D):
			child.queue_free()


## Returns whether the hazard has left the playable area and should be freed.
func _should_despawn_hazard(hazard: Node2D) -> bool:
	return hazard.position.y > DEFAULT_DESPAWN_Y or absf(hazard.position.x) > HAZARD_SIDE_DESPAWN_X


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
			var profile := _get_hazard_profile(hazard.get_meta("hazard_type", &""))
			collisions.append({
				"type": hazard.get_meta("hazard_type", &""),
				"damage": profile["damage"],
				"cargo_damage": profile["cargo_damage"],
				"node": hazard,
			})

	return collisions


## Returns the collision size used for each hazard type.
func _get_hazard_size(hazard_type: StringName) -> Vector2:
	return _get_hazard_profile(hazard_type)["size"]


class SpawnBand:
	extends RefCounted
	## Describes weighted spawn rules for one route-progress band.

	var spacing_min: float
	var spacing_max: float
	var weights: HazardWeights
	var allows_pressure_pair: bool
	var lane_indices: Array[int]


	## Stores spacing bounds, type weights, and late-pressure eligibility.
	func _init(
		spacing_min_value: float,
		spacing_max_value: float,
		pothole_weight: int,
		rock_weight: int,
		tumbleweed_weight: int,
		livestock_weight: int,
		allows_pressure_pair_value: bool,
		lane_indices_value: Array[int]
	) -> void:
		spacing_min = spacing_min_value
		spacing_max = spacing_max_value
		weights = HazardWeights.new(pothole_weight, rock_weight, tumbleweed_weight, livestock_weight)
		allows_pressure_pair = allows_pressure_pair_value
		lane_indices = lane_indices_value.duplicate()


class HazardWeights:
	extends RefCounted
	## Holds weighted odds for the currently supported hazard types.

	var pothole: int
	var rock: int
	var tumbleweed: int
	var livestock: int


	## Stores weight values for hazard selection rolls.
	func _init(
		pothole_weight: int,
		rock_weight: int,
		tumbleweed_weight: int,
		livestock_weight: int
	) -> void:
		pothole = pothole_weight
		rock = rock_weight
		tumbleweed = tumbleweed_weight
		livestock = livestock_weight


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
