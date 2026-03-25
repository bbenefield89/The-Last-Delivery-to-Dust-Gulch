extends RefCounted

## Owns hazard adjudication rules such as hits, dodges, near misses, and failure handoff.


# Constants
const HazardSpawnerType := preload(ProjectPaths.HAZARD_SPAWNER_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


const DEFAULT_NEAR_MISS_MAX_HORIZONTAL_CLEARANCE := 12.0


# Public Methods

## Resolves one gameplay frame of hazard state and returns scene-owned presentation side effects.
func resolve_frame(
	hazard_spawner: HazardSpawnerType,
	run_state: RunStateType,
	run_director: RunDirectorType,
	wagon_position: Vector2,
	wagon_size: Vector2,
	near_miss_max_horizontal_clearance: float = DEFAULT_NEAR_MISS_MAX_HORIZONTAL_CLEARANCE
) -> HazardFrameUpdate:
	var update := HazardFrameUpdate.new()
	if hazard_spawner == null or run_state == null:
		return update

	_update_hazard_near_miss_tracking(hazard_spawner, wagon_position, wagon_size)
	_apply_hazard_collisions(hazard_spawner, run_state, run_director, wagon_position, wagon_size, update)
	_record_completed_hazard_dodges(hazard_spawner, run_state, wagon_position, wagon_size)
	_award_completed_near_misses(
		hazard_spawner,
		run_state,
		wagon_position,
		wagon_size,
		near_miss_max_horizontal_clearance,
		update
	)
	return update


## Delegates one hazard hit into the authored failure flow without owning the failure rules themselves.
func attempt_failure_trigger_from_collision(run_director: RunDirectorType, hazard_type: StringName) -> bool:
	if run_director == null:
		return false

	return run_director.attempt_failure_trigger_from_collision(hazard_type)


# Private Methods

## Applies all current hazard overlaps to run-state damage, cargo loss, and failure handoff.
func _apply_hazard_collisions(
	hazard_spawner: HazardSpawnerType,
	run_state: RunStateType,
	run_director: RunDirectorType,
	wagon_position: Vector2,
	wagon_size: Vector2,
	update: HazardFrameUpdate
) -> void:
	var collisions: Array[Dictionary] = hazard_spawner.collect_collisions(wagon_position, wagon_size)
	for collision in collisions:
		var hazard_node := collision["node"] as Node
		var hazard_type := collision["type"] as StringName
		var damage := int(collision["damage"])
		var cargo_damage := int(collision.get("cargo_damage", 0))
		if hazard_node != null:
			hazard_node.set_meta("was_hit", true)
			hazard_node.queue_free()
		run_state.wagon_health = max(0, run_state.wagon_health - damage)
		run_state.cargo_value = max(0, run_state.cargo_value - cargo_damage)
		run_state.last_hit_hazard = hazard_type
		attempt_failure_trigger_from_collision(run_director, hazard_type)
		update.impact_hazard_types.append(hazard_type)


## Tracks whether hazards were ever head-on threats and records their tightest clean clearance.
func _update_hazard_near_miss_tracking(
	hazard_spawner: HazardSpawnerType,
	wagon_position: Vector2,
	wagon_size: Vector2
) -> void:
	for child in hazard_spawner.get_children():
		if not child is Node2D:
			continue

		var hazard := child as Node2D
		var hazard_size: Vector2 = hazard_spawner._get_hazard_size(hazard.get_meta("hazard_type", &""))
		if _is_hazard_ahead_of_wagon(hazard.position, hazard_size, wagon_position, wagon_size):
			if _get_horizontal_clearance_to_wagon(hazard.position, hazard_size, wagon_position, wagon_size) <= 0.0:
				hazard.set_meta("was_head_on_threat", true)
		if not _has_vertical_overlap_with_wagon(hazard.position, hazard_size, wagon_position, wagon_size):
			continue

		var horizontal_clearance: float = _get_horizontal_clearance_to_wagon(
			hazard.position,
			hazard_size,
			wagon_position,
			wagon_size
		)
		if horizontal_clearance <= 0.0:
			continue

		var closest_horizontal_clearance: float = min(
			float(hazard.get_meta("closest_horizontal_clearance_to_wagon", INF)),
			horizontal_clearance
		)
		hazard.set_meta("closest_horizontal_clearance_to_wagon", closest_horizontal_clearance)


## Awards near misses once hazards safely pass without colliding inside the authored clearance window.
func _award_completed_near_misses(
	hazard_spawner: HazardSpawnerType,
	run_state: RunStateType,
	wagon_position: Vector2,
	wagon_size: Vector2,
	near_miss_max_horizontal_clearance: float,
	update: HazardFrameUpdate
) -> void:
	for child in hazard_spawner.get_children():
		if not child is Node2D:
			continue

		var hazard := child as Node2D
		if bool(hazard.get_meta("near_miss_awarded", false)):
			continue
		if bool(hazard.get_meta("was_hit", false)):
			continue
		if not bool(hazard.get_meta("was_head_on_threat", false)):
			continue
		if not _has_hazard_safely_passed_wagon(hazard_spawner, hazard, wagon_position, wagon_size):
			continue
		if (
			float(hazard.get_meta("closest_horizontal_clearance_to_wagon", INF))
			> near_miss_max_horizontal_clearance
		):
			continue

		hazard.set_meta("near_miss_awarded", true)
		run_state.award_near_miss_bonus()
		update.bonus_callout_texts.append("NEAR MISS +%d" % RunStateType.NEAR_MISS_BONUS_SCORE)


## Records each hazard exactly once after it safely passes the wagon without a hit.
func _record_completed_hazard_dodges(
	hazard_spawner: HazardSpawnerType,
	run_state: RunStateType,
	wagon_position: Vector2,
	wagon_size: Vector2
) -> void:
	for child in hazard_spawner.get_children():
		if not child is Node2D:
			continue

		var hazard := child as Node2D
		if bool(hazard.get_meta("was_hit", false)):
			continue
		if bool(hazard.get_meta("dodge_recorded", false)):
			continue
		if not _has_hazard_safely_passed_wagon(hazard_spawner, hazard, wagon_position, wagon_size):
			continue

		hazard.set_meta("dodge_recorded", true)
		run_state.record_hazard_dodged()


## Returns whether one hazard has fully moved beyond the wagon line and can no longer collide.
func _has_hazard_safely_passed_wagon(
	hazard_spawner: HazardSpawnerType,
	hazard: Node2D,
	wagon_position: Vector2,
	wagon_size: Vector2
) -> bool:
	var hazard_size: Vector2 = hazard_spawner._get_hazard_size(hazard.get_meta("hazard_type", &""))
	var wagon_bottom_y: float = wagon_position.y + (wagon_size.y * 0.5)
	var hazard_top_y: float = hazard.position.y - (hazard_size.y * 0.5)
	return hazard_top_y > wagon_bottom_y


## Returns whether one hazard overlaps the wagon's vertical threat band.
func _has_vertical_overlap_with_wagon(
	hazard_position: Vector2,
	hazard_size: Vector2,
	wagon_position: Vector2,
	wagon_size: Vector2
) -> bool:
	var combined_half_height: float = (wagon_size.y + hazard_size.y) * 0.5
	return absf(hazard_position.y - wagon_position.y) < combined_half_height


## Returns whether the hazard is still approaching from ahead of the wagon.
func _is_hazard_ahead_of_wagon(
	hazard_position: Vector2,
	hazard_size: Vector2,
	wagon_position: Vector2,
	_wagon_size: Vector2
) -> bool:
	var hazard_bottom_y: float = hazard_position.y + (hazard_size.y * 0.5)
	return hazard_bottom_y < wagon_position.y


## Returns the horizontal non-overlap gap between one hazard and the wagon bounds.
func _get_horizontal_clearance_to_wagon(
	hazard_position: Vector2,
	hazard_size: Vector2,
	wagon_position: Vector2,
	wagon_size: Vector2
) -> float:
	var combined_half_width: float = (wagon_size.x + hazard_size.x) * 0.5
	return absf(hazard_position.x - wagon_position.x) - combined_half_width


# Inner Classes

class HazardFrameUpdate:
	extends RefCounted
	## Carries scene-owned presentation work such as impact cues and near-miss callouts.

	var impact_hazard_types: Array[StringName] = []
	var bonus_callout_texts: Array[String] = []
