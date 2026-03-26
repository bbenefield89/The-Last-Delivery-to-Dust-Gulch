extends GutTest

# Constants

const HazardInstanceType := preload(ProjectPaths.HAZARD_INSTANCE_SCRIPT_PATH)
const HazardSpawnerType := preload(ProjectPaths.HAZARD_SPAWNER_SCRIPT_PATH)
const RecoverySequenceGeneratorType := preload(ProjectPaths.RECOVERY_SEQUENCE_GENERATOR_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunHazardResolverType := preload(ProjectPaths.RUN_HAZARD_RESOLVER_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const HAZARD_COLLISION_LAYER := 1
const WAGON_COLLISION_LAYER := 2
const HAZARD_CLEANUP_COLLISION_LAYER := 4

# Private Methods




## Creates one bound run-state stack at the supplied delivery progress ratio.
func _build_bound_rule_stack(progress_ratio: float = 0.30) -> Array[Variant]:
	var run_state := RunStateType.new()
	var run_director := RunDirectorType.new()
	var recovery_sequence_generator := RecoverySequenceGeneratorType.new()
	run_state.distance_remaining = run_state.route_distance * (1.0 - progress_ratio)
	run_director.bind_run_state(run_state, recovery_sequence_generator)
	return [run_state, run_director]


## Spawns one configured hazard instance and places it at the supplied test position.
func _spawn_hazard(spawner: HazardSpawnerType, hazard_type: StringName, position: Vector2) -> HazardInstanceType:
	var center_lane_index := spawner.LANE_X_POSITIONS.find(0.0)
	spawner._spawn_hazard(hazard_type, center_lane_index)
	var hazard := spawner.get_child(spawner.get_child_count() - 1) as HazardInstanceType
	hazard.position = position
	return hazard


## Builds one lightweight wagon collision area that hazard scenes can overlap in tests.
func _build_wagon_collision_area(
	spawner: HazardSpawnerType,
	position: Vector2,
	size: Vector2
) -> Area2D:
	var wagon_area := Area2D.new()
	add_child_autofree(wagon_area)
	wagon_area.position = position
	wagon_area.monitoring = true
	wagon_area.monitorable = true
	wagon_area.collision_layer = WAGON_COLLISION_LAYER
	wagon_area.collision_mask = HAZARD_COLLISION_LAYER

	var collision_shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	collision_shape.shape = rectangle_shape
	wagon_area.add_child(collision_shape)
	spawner.bind_wagon_collision_area(wagon_area)
	return wagon_area


## Builds one lightweight wagon near-miss area that hazard scenes can overlap in tests.
func _build_wagon_near_miss_area(
	spawner: HazardSpawnerType,
	position: Vector2,
	size: Vector2
) -> Area2D:
	var wagon_area := Area2D.new()
	add_child_autofree(wagon_area)
	wagon_area.position = position
	wagon_area.monitoring = true
	wagon_area.monitorable = true
	wagon_area.collision_layer = WAGON_COLLISION_LAYER
	wagon_area.collision_mask = HAZARD_COLLISION_LAYER

	var collision_shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	collision_shape.shape = rectangle_shape
	wagon_area.add_child(collision_shape)
	spawner.bind_wagon_near_miss_area(wagon_area)
	return wagon_area


## Builds one lightweight cleanup area that hazard scenes can exit through in tests.
func _build_hazard_cleanup_area(position: Vector2, size: Vector2) -> Area2D:
	var cleanup_area := Area2D.new()
	add_child_autofree(cleanup_area)
	cleanup_area.position = position
	cleanup_area.monitoring = true
	cleanup_area.monitorable = true
	cleanup_area.collision_layer = HAZARD_CLEANUP_COLLISION_LAYER
	cleanup_area.collision_mask = HAZARD_COLLISION_LAYER

	var collision_shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	collision_shape.shape = rectangle_shape
	cleanup_area.add_child(collision_shape)
	return cleanup_area
# Public Methods

# Public Methods



## Verifies collisions still apply damage, cargo loss, impact metadata, and wheel-loose handoff.

func test_resolve_frame_when_rock_hits_then_damage_and_failure_handoff_match_scene_behavior() -> void:
	var resolver = RunHazardResolverType.new()
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	await wait_process_frames(1)
	var bound_rule_stack := _build_bound_rule_stack(0.30)
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType
	_build_wagon_collision_area(spawner, Vector2.ZERO, Vector2(32.0, 64.0))
	_build_wagon_near_miss_area(spawner, Vector2.ZERO, Vector2(54.0, 79.0))
	var hazard := _spawn_hazard(spawner, &"rock", Vector2.ZERO)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var update = resolver.resolve_frame(spawner, run_state, run_director)

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
	await wait_process_frames(1)
	var bound_rule_stack := _build_bound_rule_stack()
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType
	_build_wagon_near_miss_area(spawner, Vector2.ZERO, Vector2(54.0, 79.0))
	var cleanup_area := _build_hazard_cleanup_area(Vector2(0.0, 100.0), Vector2(300.0, 40.0))
	spawner.bind_hazard_cleanup_areas([cleanup_area])
	var hazard := _spawn_hazard(spawner, &"pothole", Vector2(0.0, -80.0))
	await get_tree().physics_frame
	await get_tree().physics_frame

	resolver.resolve_frame(spawner, run_state, run_director)
	hazard.position = Vector2(40.0, -30.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	resolver.resolve_frame(spawner, run_state, run_director)
	hazard.position = Vector2(40.0, 60.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var near_miss_update = resolver.resolve_frame(spawner, run_state, run_director)

	assert_eq(run_state.hazards_dodged, 0)
	assert_eq(run_state.near_misses, 1)
	assert_eq(run_state.bonus_score, RunStateType.NEAR_MISS_BONUS_SCORE)
	assert_eq(near_miss_update.bonus_callout_texts, ["NEAR MISS +50"])

	hazard.position = Vector2(40.0, 100.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var cleanup_update = resolver.resolve_frame(spawner, run_state, run_director)

	assert_eq(run_state.hazards_dodged, 1)
	assert_eq(run_state.near_misses, 1)
	assert_true(cleanup_update.bonus_callout_texts.is_empty())
	await wait_process_frames(1)
	assert_eq(spawner.get_child_count(), 0)


## Verifies a wide safe pass still counts as a dodge without incorrectly awarding a near miss.

func test_resolve_frame_when_hazard_passes_wide_then_only_dodge_is_recorded() -> void:
	var resolver = RunHazardResolverType.new()
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	await wait_process_frames(1)
	var bound_rule_stack := _build_bound_rule_stack()
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType
	_build_wagon_near_miss_area(spawner, Vector2.ZERO, Vector2(54.0, 79.0))
	var cleanup_area := _build_hazard_cleanup_area(Vector2(0.0, 100.0), Vector2(300.0, 40.0))
	spawner.bind_hazard_cleanup_areas([cleanup_area])
	var hazard := _spawn_hazard(spawner, &"pothole", Vector2(0.0, -80.0))
	await get_tree().physics_frame
	await get_tree().physics_frame

	resolver.resolve_frame(spawner, run_state, run_director)
	hazard.position = Vector2(72.0, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	resolver.resolve_frame(spawner, run_state, run_director)
	hazard.position = Vector2(72.0, 100.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var update = resolver.resolve_frame(spawner, run_state, run_director)

	assert_eq(run_state.hazards_dodged, 1)
	assert_eq(run_state.near_misses, 0)
	assert_true(update.bonus_callout_texts.is_empty())
	await wait_process_frames(1)
	assert_eq(spawner.get_child_count(), 0)


## Verifies side-passing hazards do not earn the near-miss bonus when they were never head-on threats.

func test_resolve_frame_when_side_pass_late_swerve_then_near_miss_is_not_awarded() -> void:
	var resolver = RunHazardResolverType.new()
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	await wait_process_frames(1)
	var bound_rule_stack := _build_bound_rule_stack()
	var run_state := bound_rule_stack[0] as RunStateType
	var run_director := bound_rule_stack[1] as RunDirectorType
	_build_wagon_near_miss_area(spawner, Vector2.ZERO, Vector2(54.0, 79.0))
	var cleanup_area := _build_hazard_cleanup_area(Vector2(0.0, 100.0), Vector2(300.0, 40.0))
	spawner.bind_hazard_cleanup_areas([cleanup_area])
	var hazard := _spawn_hazard(spawner, &"pothole", Vector2(72.0, -80.0))
	await get_tree().physics_frame
	await get_tree().physics_frame

	resolver.resolve_frame(spawner, run_state, run_director)
	hazard.position = Vector2(40.0, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	resolver.resolve_frame(spawner, run_state, run_director)
	hazard.position = Vector2(40.0, 100.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var update = resolver.resolve_frame(spawner, run_state, run_director)

	assert_eq(run_state.hazards_dodged, 1)
	assert_eq(run_state.near_misses, 0)
	assert_true(update.bonus_callout_texts.is_empty())
	await wait_process_frames(1)
	assert_eq(spawner.get_child_count(), 0)


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
