extends Node2D
class_name HazardSpawner

const LANE_X_POSITIONS := [-68.0, 0.0, 68.0]
const DEFAULT_SPAWN_Y := -320.0
const DEFAULT_DESPAWN_Y := 260.0
const MAX_PROGRESS_SPAWN_MULTIPLIER := 0.68
const PRESSURE_PAIR_PROGRESS_THRESHOLD := 0.72
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
const PATTERN := [
	{"type": &"pothole", "lane_index": 1, "spacing": 540.0},
	{"type": &"rock", "lane_index": 0, "spacing": 500.0},
	{"type": &"tumbleweed", "lane_index": 2, "spacing": 600.0},
	{"type": &"rock", "lane_index": 1, "spacing": 520.0},
	{"type": &"pothole", "lane_index": 0, "spacing": 620.0},
	{"type": &"tumbleweed", "lane_index": 1, "spacing": 560.0},
]

const HAZARD_COLORS := {
	&"pothole": Color(0.168627, 0.117647, 0.082353, 0.95),
	&"rock": Color(0.501961, 0.470588, 0.411765, 0.95),
	&"tumbleweed": Color(0.690196, 0.556863, 0.294118, 0.95),
}

var _pattern_index := 0
var _distance_until_next_spawn := 0.0
var _route_progress_ratio := 0.0


func _ready() -> void:
	_prime_next_spawn()


func advance(distance_delta: float, route_progress_ratio: float = 0.0) -> void:
	_route_progress_ratio = clamp(route_progress_ratio, 0.0, 1.0)
	if not PATTERN.is_empty():
		var active_spacing: float = _get_scaled_spacing(PATTERN[_pattern_index]["spacing"])
		_distance_until_next_spawn = min(_distance_until_next_spawn, active_spacing)
	_move_hazards(distance_delta)
	_spawn_hazards(distance_delta)
	_cleanup_hazards()


func _move_hazards(distance_delta: float) -> void:
	for child in get_children():
		if child is Polygon2D:
			child.position.y += distance_delta


func _spawn_hazards(distance_delta: float) -> void:
	if PATTERN.is_empty():
		return

	var remaining_distance := distance_delta
	while _distance_until_next_spawn <= remaining_distance:
		remaining_distance -= _distance_until_next_spawn
		_spawn_current_entry()
		advance_pattern()

	_distance_until_next_spawn -= remaining_distance


func advance_pattern() -> void:
	_pattern_index = (_pattern_index + 1) % PATTERN.size()
	_prime_next_spawn()


func _prime_next_spawn() -> void:
	if PATTERN.is_empty():
		_distance_until_next_spawn = INF
		return

	var base_spacing: float = PATTERN[_pattern_index]["spacing"]
	_distance_until_next_spawn = _get_scaled_spacing(base_spacing)


func _spawn_current_entry() -> void:
	var entry: Dictionary = PATTERN[_pattern_index]
	var hazard_type: StringName = entry["type"]
	var lane_index: int = entry["lane_index"]
	_spawn_hazard(hazard_type, lane_index)

	if _route_progress_ratio >= PRESSURE_PAIR_PROGRESS_THRESHOLD:
		var pressure_lane := _get_pressure_lane_index(lane_index)
		if pressure_lane != lane_index:
			var pressure_type: StringName = PATTERN[(_pattern_index + 1) % PATTERN.size()]["type"]
			_spawn_hazard(pressure_type, pressure_lane, DEFAULT_SPAWN_Y - 56.0)


func _spawn_hazard(hazard_type: StringName, lane_index: int, spawn_y: float = DEFAULT_SPAWN_Y) -> void:
	var hazard := _build_hazard_visual(hazard_type)
	hazard.position = Vector2(LANE_X_POSITIONS[lane_index], spawn_y)
	hazard.set_meta("hazard_type", hazard_type)
	hazard.set_meta("lane_index", lane_index)
	add_child(hazard)


func _get_scaled_spacing(base_spacing: float) -> float:
	var multiplier: float = lerp(1.0, MAX_PROGRESS_SPAWN_MULTIPLIER, _route_progress_ratio)
	return max(140.0, base_spacing * multiplier)


func _get_pressure_lane_index(primary_lane_index: int) -> int:
	if primary_lane_index == 1:
		return 0 if _route_progress_ratio < 0.85 else 2

	return 1


func _build_hazard_visual(hazard_type: StringName) -> Polygon2D:
	var hazard := Polygon2D.new()
	hazard.polygon = _get_hazard_polygon(hazard_type)
	hazard.color = HAZARD_COLORS.get(hazard_type, Color.WHITE)
	return hazard


func _get_hazard_polygon(hazard_type: StringName) -> PackedVector2Array:
	match hazard_type:
		&"pothole":
			return PackedVector2Array([
				Vector2(-16.0, -4.0),
				Vector2(-10.0, -12.0),
				Vector2(6.0, -14.0),
				Vector2(14.0, -6.0),
				Vector2(12.0, 6.0),
				Vector2(2.0, 14.0),
				Vector2(-12.0, 10.0),
			])
		&"rock":
			return PackedVector2Array([
				Vector2(-14.0, 14.0),
				Vector2(-18.0, -4.0),
				Vector2(-6.0, -18.0),
				Vector2(10.0, -14.0),
				Vector2(18.0, 4.0),
				Vector2(10.0, 18.0),
			])
		&"tumbleweed":
			return PackedVector2Array([
				Vector2(-8.0, -16.0),
				Vector2(6.0, -15.0),
				Vector2(16.0, -6.0),
				Vector2(14.0, 10.0),
				Vector2(2.0, 18.0),
				Vector2(-14.0, 14.0),
				Vector2(-18.0, 0.0),
			])
		_:
			return PackedVector2Array([
				Vector2(0.0, -32.0),
				Vector2(32.0, 0.0),
				Vector2(0.0, 32.0),
				Vector2(-32.0, 0.0),
			])


func _cleanup_hazards() -> void:
	for child in get_children():
		if child is Polygon2D and child.position.y > DEFAULT_DESPAWN_Y:
			child.queue_free()


func collect_collisions(wagon_position: Vector2, wagon_size: Vector2) -> Array[Dictionary]:
	var collisions: Array[Dictionary] = []
	var wagon_rect := Rect2(wagon_position - (wagon_size * 0.5), wagon_size)

	for child in get_children():
		if not child is Polygon2D:
			continue

		var polygon := child as Polygon2D
		var hazard_size := _get_hazard_size(polygon.get_meta("hazard_type", &""))
		var hazard_rect := Rect2(polygon.position - (hazard_size * 0.5), hazard_size)
		if wagon_rect.intersects(hazard_rect):
			collisions.append({
				"type": polygon.get_meta("hazard_type", &""),
				"damage": HAZARD_DAMAGE.get(polygon.get_meta("hazard_type", &""), 0),
				"cargo_damage": HAZARD_CARGO_DAMAGE.get(polygon.get_meta("hazard_type", &""), 0),
				"node": polygon,
			})

	return collisions


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
