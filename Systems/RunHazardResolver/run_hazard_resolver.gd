extends RefCounted

## Owns hazard adjudication rules such as hits, dodges, near misses, and failure handoff.


# Constants
const HazardSpawnerType := preload(ProjectPaths.HAZARD_SPAWNER_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Public Methods

## Resolves one gameplay frame of hazard state and returns scene-owned presentation side effects.
func resolve_frame(
	hazard_spawner: HazardSpawnerType,
	run_state: RunStateType,
	run_director: RunDirectorType
) -> HazardFrameUpdate:
	var update := HazardFrameUpdate.new()
	if hazard_spawner == null or run_state == null:
		return update

	_apply_hazard_collisions(hazard_spawner, run_state, run_director, update)
	_apply_near_miss_awards(hazard_spawner, run_state, update)
	_apply_completed_hazard_passes(hazard_spawner, run_state, update)
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
	update: HazardFrameUpdate
) -> void:
	var collisions: Array[Dictionary] = hazard_spawner.consume_pending_collisions()
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


## Applies all cleanup-boundary exits as successful dodges and optional near-miss bonuses.
func _apply_near_miss_awards(
	hazard_spawner: HazardSpawnerType,
	run_state: RunStateType,
	update: HazardFrameUpdate
) -> void:
	var near_misses: Array[Dictionary] = hazard_spawner.consume_pending_near_misses()
	for _near_miss in near_misses:
		run_state.award_near_miss_bonus()
		update.bonus_callout_texts.append("NEAR MISS +%d" % RunStateType.NEAR_MISS_BONUS_SCORE)


## Applies all cleanup-boundary exits as successful dodges once hazards fully leave the play space.
func _apply_completed_hazard_passes(
	hazard_spawner: HazardSpawnerType,
	run_state: RunStateType,
	update: HazardFrameUpdate
) -> void:
	var completed_passes: Array[Dictionary] = hazard_spawner.consume_completed_passes()
	for _completed_pass in completed_passes:
		run_state.record_hazard_dodged()


# Inner Classes

class HazardFrameUpdate:
	extends RefCounted
	## Carries scene-owned presentation work such as impact cues and near-miss callouts.

	var impact_hazard_types: Array[StringName] = []
	var bonus_callout_texts: Array[String] = []
