extends GutTest

# Constants

const HazardSpawnerType := preload(ProjectPaths.HAZARD_SPAWNER_SCRIPT_PATH)
const RecoverySequenceGeneratorType := preload(ProjectPaths.RECOVERY_SEQUENCE_GENERATOR_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunHazardResolverType := preload(ProjectPaths.RUN_HAZARD_RESOLVER_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)

# Private Methods




## Creates one bound run-state stack at the supplied delivery progress ratio.
func _build_bound_rule_stack(progress_ratio: float = 0.30) -> Array[Variant]:
	var run_state := RunStateType.new()
	var run_director := RunDirectorType.new()
	var recovery_sequence_generator := RecoverySequenceGeneratorType.new()
	run_state.distance_remaining = run_state.route_distance * (1.0 - progress_ratio)
	run_director.bind_run_state(run_state, recovery_sequence_generator)
	return [run_state, run_director]


## Adds one lightweight hazard node with the metadata the resolver expects to the supplied spawner.
func _add_hazard(spawner: HazardSpawnerType, hazard_type: StringName, position: Vector2) -> Node2D:
	var hazard := Node2D.new()
	hazard.position = position
	hazard.set_meta("hazard_type", hazard_type)
	spawner.add_child(hazard)
	return hazard
# Public Methods

# Public Methods



## Verifies collisions still apply damage, cargo loss, impact metadata, and wheel-loose handoff.

func test_resolve_frame_when_rock_hits_then_damage_and_failure_handoff_match_scene_behavior() -> void:
	var resolver = RunHazardResolverType.new()
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	var bound_rule_stack := _build_bound_rule_stack(0.30)
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType
	var hazard := _add_hazard(spawner, &"rock", Vector2.ZERO)

	var update = resolver.resolve_frame(
		spawner,
		run_state,
		run_director,
		Vector2.ZERO,
		Vector2(32.0, 64.0)
	)

	assert_eq(run_state.wagon_health, 82)
	assert_eq(run_state.cargo_value, 91)
	assert_eq(run_state.last_hit_hazard, &"rock")
	assert_eq(run_state.active_failure, &"wheel_loose")
	assert_eq(run_state.current_failure.source_hazard, &"rock")
	assert_eq(update.impact_hazard_types, [&"rock"])
	assert_true(hazard.get_meta("was_hit", false))
	assert_true(hazard.is_queued_for_deletion())


## Verifies a tight clean pass still records both the dodge and the near-miss reward once.

func test_resolve_frame_when_head_on_hazard_passes_close_then_dodge_and_near_miss_award_once() -> void:
	var resolver = RunHazardResolverType.new()
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	var bound_rule_stack := _build_bound_rule_stack()
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType
	var hazard := _add_hazard(spawner, &"pothole", Vector2(0.0, -60.0))

	resolver.resolve_frame(spawner, run_state, run_director, Vector2.ZERO, Vector2(32.0, 64.0))
	hazard.position = Vector2(40.0, 0.0)
	resolver.resolve_frame(spawner, run_state, run_director, Vector2.ZERO, Vector2(32.0, 64.0))
	hazard.position = Vector2(40.0, 50.0)
	var update = resolver.resolve_frame(
		spawner,
		run_state,
		run_director,
		Vector2.ZERO,
		Vector2(32.0, 64.0),
		12.0
	)

	assert_eq(run_state.hazards_dodged, 1)
	assert_eq(run_state.near_misses, 1)
	assert_eq(run_state.bonus_score, RunStateType.NEAR_MISS_BONUS_SCORE)
	assert_eq(update.bonus_callout_texts, ["NEAR MISS +50"])
	assert_true(hazard.get_meta("dodge_recorded", false))
	assert_true(hazard.get_meta("near_miss_awarded", false))


## Verifies a wide safe pass still counts as a dodge without incorrectly awarding a near miss.

func test_resolve_frame_when_hazard_passes_wide_then_only_dodge_is_recorded() -> void:
	var resolver = RunHazardResolverType.new()
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	var bound_rule_stack := _build_bound_rule_stack()
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType
	var hazard := _add_hazard(spawner, &"pothole", Vector2(0.0, -60.0))

	resolver.resolve_frame(spawner, run_state, run_director, Vector2.ZERO, Vector2(32.0, 64.0))
	hazard.position = Vector2(72.0, 0.0)
	resolver.resolve_frame(spawner, run_state, run_director, Vector2.ZERO, Vector2(32.0, 64.0))
	hazard.position = Vector2(72.0, 50.0)
	var update = resolver.resolve_frame(
		spawner,
		run_state,
		run_director,
		Vector2.ZERO,
		Vector2(32.0, 64.0),
		12.0
	)

	assert_eq(run_state.hazards_dodged, 1)
	assert_eq(run_state.near_misses, 0)
	assert_true(update.bonus_callout_texts.is_empty())
	assert_true(hazard.get_meta("dodge_recorded", false))
	assert_false(hazard.get_meta("near_miss_awarded", false))


## Verifies side-passing hazards do not earn the near-miss bonus when they were never head-on threats.

func test_resolve_frame_when_side_pass_late_swerve_then_near_miss_is_not_awarded() -> void:
	var resolver = RunHazardResolverType.new()
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	var bound_rule_stack := _build_bound_rule_stack()
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType
	var hazard := _add_hazard(spawner, &"pothole", Vector2(72.0, -60.0))

	resolver.resolve_frame(spawner, run_state, run_director, Vector2.ZERO, Vector2(32.0, 64.0))
	hazard.position = Vector2(40.0, 0.0)
	resolver.resolve_frame(spawner, run_state, run_director, Vector2.ZERO, Vector2(32.0, 64.0))
	hazard.position = Vector2(40.0, 50.0)
	var update = resolver.resolve_frame(
		spawner,
		run_state,
		run_director,
		Vector2.ZERO,
		Vector2(32.0, 64.0),
		12.0
	)

	assert_eq(run_state.hazards_dodged, 1)
	assert_eq(run_state.near_misses, 0)
	assert_true(update.bonus_callout_texts.is_empty())
	assert_false(hazard.get_meta("was_head_on_threat", false))


## Verifies the resolver keeps tumbleweed and livestock failure mapping delegated through the director.

func test_attempt_failure_trigger_from_collision_when_tumbleweed_then_horse_panic_starts() -> void:
	var resolver = RunHazardResolverType.new()
	var bound_rule_stack := _build_bound_rule_stack(0.50)
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType

	var started: bool = resolver.attempt_failure_trigger_from_collision(run_director, &"tumbleweed")

	assert_true(started)
	assert_eq(run_state.active_failure, &"horse_panic")
	assert_eq(run_state.current_failure.source_hazard, &"tumbleweed")
