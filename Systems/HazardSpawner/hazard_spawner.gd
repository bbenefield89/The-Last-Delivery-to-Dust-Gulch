extends Node2D

## Spawns readable hazard layouts with route-progress pacing and phase-based pressure pairs.

# Constants

const HazardDefinitionType := preload(ProjectPaths.HAZARD_DEFINITION_SCRIPT_PATH)
const HazardInstanceType := preload(ProjectPaths.HAZARD_INSTANCE_SCRIPT_PATH)
const HAZARD_SCENE := preload(ProjectPaths.HAZARD_SCENE_PATH)
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
const LIVESTOCK_VISUAL_CENTER_OFFSET_X := 7.0
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

@export
var pothole_definition: HazardDefinitionType = preload(ProjectPaths.POTHOLE_HAZARD_DEFINITION_RESOURCE_PATH)

@export
var rock_definition: HazardDefinitionType = preload(ProjectPaths.ROCK_HAZARD_DEFINITION_RESOURCE_PATH)

@export
var tumbleweed_definition: HazardDefinitionType = preload(ProjectPaths.TUMBLEWEED_HAZARD_DEFINITION_RESOURCE_PATH)

@export
var livestock_definition: HazardDefinitionType = preload(ProjectPaths.LIVESTOCK_HAZARD_DEFINITION_RESOURCE_PATH)

# Private Fields

var _distance_until_next_spawn := 0.0
var _route_progress_ratio := 0.0
var _active_route_phase: StringName = &""
var _next_spawn_plan: SpawnPlan
var _pending_collision_hazards: Array[HazardInstanceType] = []
var _pending_near_miss_hazards: Array[HazardInstanceType] = []
var _pending_completed_passes: Array[Dictionary] = []
var _wagon_collision_area: Area2D
var _wagon_near_miss_area: Area2D
var _hazard_cleanup_areas: Array[Area2D] = []
var _shared_hazard_collision_size := Vector2.ZERO
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


# Lifecycle Methods

## Initializes the first randomized spawn plan.
func _ready() -> void:
	_rng.randomize()
	_shared_hazard_collision_size = _get_shared_hazard_collision_size()


# Public Methods

## Advances active hazards and spawns new ones using the current route-progress band.
func advance(
	distance_delta: float,
	route_progress_ratio: float = 0.0,
	route_remaining_distance: float = INF,
	route_distance: float = INF
) -> void:
	_route_progress_ratio = clamp(route_progress_ratio, 0.0, 1.0)
	_sync_route_phase()
	var has_crossed_finish_line := is_finite(route_remaining_distance) and route_remaining_distance <= 0.0
	if has_crossed_finish_line:
		_clear_regular_spawn_schedule()
	elif _should_hold_final_stretch_release(route_remaining_distance, route_distance):
		_clear_regular_spawn_schedule()
	elif _next_spawn_plan == null:
		_prime_next_spawn()
	if not has_crossed_finish_line and _next_spawn_plan != null:
		var active_spacing := _next_spawn_plan.spacing
		_distance_until_next_spawn = min(_distance_until_next_spawn, active_spacing)
	_move_hazards(distance_delta)
	if has_crossed_finish_line:
		return

	_spawn_hazards(distance_delta)


## Binds the active wagon collision area to the event-based hazard hit queue.
func bind_wagon_collision_area(wagon_collision_area: Area2D) -> void:
	if _wagon_collision_area != null and _wagon_collision_area.area_entered.is_connected(_on_wagon_area_entered):
		_wagon_collision_area.area_entered.disconnect(_on_wagon_area_entered)

	_wagon_collision_area = wagon_collision_area
	if _wagon_collision_area == null:
		return

	if not _wagon_collision_area.area_entered.is_connected(_on_wagon_area_entered):
		_wagon_collision_area.area_entered.connect(_on_wagon_area_entered)


## Binds the active wagon near-miss area to the event-based near-miss queue.
func bind_wagon_near_miss_area(wagon_near_miss_area: Area2D) -> void:
	if _wagon_near_miss_area != null:
		if _wagon_near_miss_area.area_entered.is_connected(_on_wagon_near_miss_area_entered):
			_wagon_near_miss_area.area_entered.disconnect(_on_wagon_near_miss_area_entered)
		if _wagon_near_miss_area.area_exited.is_connected(_on_wagon_near_miss_area_exited):
			_wagon_near_miss_area.area_exited.disconnect(_on_wagon_near_miss_area_exited)

	_wagon_near_miss_area = wagon_near_miss_area
	if _wagon_near_miss_area == null:
		return

	if not _wagon_near_miss_area.area_entered.is_connected(_on_wagon_near_miss_area_entered):
		_wagon_near_miss_area.area_entered.connect(_on_wagon_near_miss_area_entered)
	if not _wagon_near_miss_area.area_exited.is_connected(_on_wagon_near_miss_area_exited):
		_wagon_near_miss_area.area_exited.connect(_on_wagon_near_miss_area_exited)


## Binds the active cleanup boundaries that mark hazards as safely passed and free them.
func bind_hazard_cleanup_areas(hazard_cleanup_areas: Array) -> void:
	for cleanup_area in _hazard_cleanup_areas:
		if cleanup_area != null and cleanup_area.area_entered.is_connected(_on_hazard_cleanup_area_entered):
			cleanup_area.area_entered.disconnect(_on_hazard_cleanup_area_entered)

	_hazard_cleanup_areas.clear()
	for cleanup_area in hazard_cleanup_areas:
		if cleanup_area == null:
			continue

		_hazard_cleanup_areas.append(cleanup_area)
		if not cleanup_area.area_entered.is_connected(_on_hazard_cleanup_area_entered):
			cleanup_area.area_entered.connect(_on_hazard_cleanup_area_entered)


## Frees all live hazards and clears queued hazard runtime state for non-gameplay transitions.
func clear_runtime_hazards() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_pending_collision_hazards.clear()
	_pending_near_miss_hazards.clear()
	_pending_completed_passes.clear()
	_next_spawn_plan = null
	_distance_until_next_spawn = 0.0


## Returns whether hazards or unresolved hazard events are still active in the runtime field.
func has_runtime_hazards() -> bool:
	return (
		get_child_count() > 0
		or not _pending_collision_hazards.is_empty()
		or not _pending_near_miss_hazards.is_empty()
		or not _pending_completed_passes.is_empty()
	)


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
	var hazard := _build_hazard_visual()
	if hazard is HazardInstanceType:
		var hazard_instance := hazard as HazardInstanceType
		hazard_instance.apply_definition(_get_hazard_definition(hazard_type))
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


## Builds one unconfigured shared hazard instance.
func _build_hazard_visual() -> Node2D:
	return HAZARD_SCENE.instantiate() as HazardInstanceType


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
	var hazard_instance := hazard as HazardInstanceType
	if hazard_instance == null:
		return

	var bounce_amplitude := float(hazard.get_meta("bounce_amplitude", 0.0))
	var bounce_radians_per_scroll_unit := float(hazard.get_meta("bounce_radians_per_scroll_unit", 0.0))
	if bounce_amplitude == 0.0 or bounce_radians_per_scroll_unit == 0.0:
		hazard_instance.get_visual().offset.y = 0.0
		return

	var bounce_phase := float(hazard.get_meta("bounce_phase", 0.0))
	bounce_phase += bounce_radians_per_scroll_unit * distance_delta
	hazard.set_meta("bounce_phase", bounce_phase)
	hazard_instance.get_visual().offset.y = sin(bounce_phase) * bounce_amplitude


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
	var visual_center_offset_x := _get_livestock_visual_center_offset_x(crossing_direction)
	hazard.scale.x = float(crossing_direction)
	hazard.set_meta("crossing_direction", crossing_direction)
	hazard.set_meta(
		"crossing_scroll_ratio_x",
		LIVESTOCK_CROSSING_X_PER_SCROLL_UNIT * float(crossing_direction)
	)
	hazard.set_meta("target_lane_x", _get_lane_center_x(lane_index) + visual_center_offset_x)
	return Vector2(
		_get_livestock_spawn_x(lane_index, spawn_y, crossing_direction) + visual_center_offset_x,
		spawn_y
	)


## Returns the signed horizontal offset that centers the visible jackalope body on the crossing line.
func _get_livestock_visual_center_offset_x(crossing_direction: int) -> float:
	return LIVESTOCK_VISUAL_CENTER_OFFSET_X * float(crossing_direction)


## Rolls whether a livestock hazard crosses left-to-right or right-to-left.
func _roll_livestock_crossing_direction() -> int:
	return -1 if _rng.randi_range(0, 1) == 0 else 1


## Places livestock far enough off-road that it reaches the target lane near the wagon line.
func _get_livestock_spawn_x(lane_index: int, spawn_y: float, crossing_direction: int) -> float:
	var crossing_distance := absf(spawn_y - LIVESTOCK_CROSSING_TARGET_Y) * LIVESTOCK_CROSSING_X_PER_SCROLL_UNIT
	return _get_lane_center_x(lane_index) - (crossing_distance * float(crossing_direction))


## Resolves the shared gameplay profile for the requested hazard type.
func _get_hazard_profile(hazard_type: StringName) -> Dictionary:
	var definition := _get_hazard_definition(hazard_type)
	return {
		"texture": null if definition == null else definition.texture,
		"damage": 0 if definition == null else definition.damage,
		"cargo_damage": 0 if definition == null else definition.cargo_damage,
		"size": _get_shared_hazard_collision_size(),
	}


## Returns the authored hazard definition resource for one hazard type.
func _get_hazard_definition(hazard_type: StringName) -> HazardDefinitionType:
	match hazard_type:
		&"rock":
			return rock_definition
		&"tumbleweed":
			return tumbleweed_definition
		&"livestock":
			return livestock_definition
		_:
			return pothole_definition


## Returns all queued wagon-overlap collisions since the previous consume.
func consume_pending_collisions() -> Array[Dictionary]:
	var collisions: Array[Dictionary] = []
	var pending_hazards := _pending_collision_hazards.duplicate()
	_pending_collision_hazards.clear()

	for hazard in pending_hazards:
		if hazard == null or not is_instance_valid(hazard):
			continue

		hazard.set_meta("collision_pending", false)
		if bool(hazard.get_meta("was_hit", false)):
			continue

		var profile := _get_hazard_profile(hazard.get_meta("hazard_type", &""))
		collisions.append({
			"type": hazard.get_meta("hazard_type", &""),
			"damage": profile["damage"],
			"cargo_damage": profile["cargo_damage"],
			"node": hazard,
		})

	return collisions


## Returns all queued cleanup-boundary passes since the previous consume.
func consume_completed_passes() -> Array[Dictionary]:
	var completed_passes := _pending_completed_passes.duplicate(true)
	_pending_completed_passes.clear()
	return completed_passes


## Returns all queued near-miss exits since the previous consume.
func consume_pending_near_misses() -> Array[Dictionary]:
	var near_misses: Array[Dictionary] = []
	var pending_hazards := _pending_near_miss_hazards.duplicate()
	_pending_near_miss_hazards.clear()

	for hazard in pending_hazards:
		if hazard == null or not is_instance_valid(hazard):
			continue

		hazard.set_meta("near_miss_pending", false)
		if bool(hazard.get_meta("was_hit", false)):
			continue
		if bool(hazard.get_meta("near_miss_awarded", false)):
			continue

		hazard.set_meta("near_miss_awarded", true)
		near_misses.append({
			"type": hazard.get_meta("hazard_type", &""),
		})

	return near_misses


## Queues one hazard for collision resolution when its collision area enters the wagon area.
func _on_wagon_area_entered(area: Area2D) -> void:
	var hazard_instance := _get_hazard_instance_from_area(area)
	if hazard_instance == null:
		return
	if bool(hazard_instance.get_meta("was_hit", false)):
		return
	if bool(hazard_instance.get_meta("collision_pending", false)):
		return

	hazard_instance.set_meta("collision_pending", true)
	_pending_collision_hazards.append(hazard_instance)


## Marks hazards that enter the wagon near-miss band while still approaching from ahead.
func _on_wagon_near_miss_area_entered(area: Area2D) -> void:
	var hazard_instance := _get_hazard_instance_from_area(area)
	if hazard_instance == null:
		return
	if bool(hazard_instance.get_meta("was_hit", false)):
		return
	if _wagon_near_miss_area == null:
		return
	if not _is_hazard_ahead_of_area(hazard_instance, _wagon_near_miss_area):
		return

	hazard_instance.set_meta("near_miss_candidate", true)


## Queues one near miss as soon as a candidate hazard exits the band below the wagon without hitting.
func _on_wagon_near_miss_area_exited(area: Area2D) -> void:
	var hazard_instance := _get_hazard_instance_from_area(area)
	if hazard_instance == null:
		return
	if bool(hazard_instance.get_meta("was_hit", false)):
		return
	if bool(hazard_instance.get_meta("collision_pending", false)):
		return
	if bool(hazard_instance.get_meta("near_miss_pending", false)):
		return
	if bool(hazard_instance.get_meta("near_miss_awarded", false)):
		return
	if not bool(hazard_instance.get_meta("near_miss_candidate", false)):
		return
	if _wagon_near_miss_area == null:
		return
	if _is_hazard_ahead_of_area(hazard_instance, _wagon_near_miss_area):
		return

	hazard_instance.set_meta("near_miss_pending", true)
	_pending_near_miss_hazards.append(hazard_instance)


## Queues one clean hazard pass and frees the instance after it exits through a cleanup boundary.
func _on_hazard_cleanup_area_entered(area: Area2D) -> void:
	var hazard_instance := _get_hazard_instance_from_area(area)
	if hazard_instance == null:
		return
	if bool(hazard_instance.get_meta("was_hit", false)):
		return
	if bool(hazard_instance.get_meta("collision_pending", false)):
		return
	if bool(hazard_instance.get_meta("pass_pending", false)):
		return

	hazard_instance.set_meta("pass_pending", true)
	_pending_completed_passes.append({
		"type": hazard_instance.get_meta("hazard_type", &""),
	})
	hazard_instance.queue_free()


## Returns the spawned hazard instance that owns one hazard collision area.
func _get_hazard_instance_from_area(area: Area2D) -> HazardInstanceType:
	return null if area == null else area.get_parent() as HazardInstanceType


## Returns whether the hazard is still approaching from above the supplied wagon-owned area.
func _is_hazard_ahead_of_area(hazard: HazardInstanceType, wagon_area: Area2D) -> bool:
	if hazard == null or wagon_area == null:
		return false

	var hazard_rect := hazard.get_collision_rect()
	var wagon_area_rect := _get_area_rect(wagon_area)
	return hazard_rect.end.y < wagon_area_rect.get_center().y


## Returns the authored world-space rect for one wagon-owned area shape.
func _get_area_rect(area: Area2D) -> Rect2:
	if area == null:
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var collision_shape := area.get_child(0) as CollisionShape2D
	if collision_shape == null:
		return Rect2(area.global_position, Vector2.ZERO)

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return Rect2(collision_shape.global_position, Vector2.ZERO)

	return Rect2(
		collision_shape.global_position - (rectangle_shape.size * 0.5),
		rectangle_shape.size
	)


## Returns the shared authored collision size from the reusable hazard scene.
func _get_shared_hazard_collision_size() -> Vector2:
	if _shared_hazard_collision_size != Vector2.ZERO:
		return _shared_hazard_collision_size

	var hazard := HAZARD_SCENE.instantiate() as Node
	if hazard == null:
		return Vector2.ZERO

	var collision_shape := hazard.get_node_or_null("CollisionArea/CollisionShape") as CollisionShape2D
	var rectangle_shape := collision_shape.shape as RectangleShape2D if collision_shape != null else null
	_shared_hazard_collision_size = Vector2.ZERO if rectangle_shape == null else rectangle_shape.size
	hazard.free()
	return _shared_hazard_collision_size


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
