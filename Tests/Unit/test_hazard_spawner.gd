extends GutTest

const HazardSpawnerType := preload("res://Scripts/Hazards/hazard_spawner.gd")
const POTHOLE_TEXTURE := preload("res://Assets/Tilesets/Hazards/Pothole/Pothole-32x32.png")
const ROCK_TEXTURE := preload("res://Assets/Tilesets/Hazards/Boulder/Boulder-32x32.png")
const TUMBLEWEED_TEXTURE := preload("res://Assets/Tilesets/Hazards/Tumbleweed/Tumbleweed-32x32.png")
const LIVESTOCK_TEXTURE := preload("res://Assets/Tilesets/Hazards/Jackalope/Jackalope-32x32.png")


func _create_seeded_spawner() -> Node:
	var spawner := HazardSpawnerType.new()
	spawner.pothole_texture = POTHOLE_TEXTURE
	spawner.rock_texture = ROCK_TEXTURE
	spawner.tumbleweed_texture = TUMBLEWEED_TEXTURE
	spawner.livestock_texture = LIVESTOCK_TEXTURE
	add_child_autofree(spawner)
	return spawner


func _prime_seeded_plan(spawner: Node, seed: int, route_progress_ratio: float) -> Variant:
	spawner._rng.seed = seed
	spawner._route_progress_ratio = route_progress_ratio
	spawner._prime_next_spawn()
	return spawner._next_spawn_plan


func test_progress_bands_define_expected_spacing_ranges_and_weights() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._route_progress_ratio = 0.0
	var early_band = spawner._get_active_band()
	assert_eq(early_band.spacing_min, 500.0)
	assert_eq(early_band.spacing_max, 620.0)
	assert_eq(early_band.weights.pothole, 8)
	assert_eq(early_band.weights.rock, 1)
	assert_eq(early_band.weights.tumbleweed, 2)
	assert_eq(early_band.weights.livestock, 0)
	assert_false(early_band.allows_pressure_pair)

	spawner._route_progress_ratio = 0.5
	var mid_band = spawner._get_active_band()
	assert_eq(mid_band.spacing_min, 400.0)
	assert_eq(mid_band.spacing_max, 520.0)
	assert_eq(mid_band.weights.pothole, 5)
	assert_eq(mid_band.weights.rock, 2)
	assert_eq(mid_band.weights.tumbleweed, 4)
	assert_eq(mid_band.weights.livestock, 1)
	assert_false(mid_band.allows_pressure_pair)

	spawner._route_progress_ratio = 0.8
	var late_band = spawner._get_active_band()
	assert_eq(late_band.spacing_min, 300.0)
	assert_eq(late_band.spacing_max, 420.0)
	assert_eq(late_band.weights.pothole, 4)
	assert_eq(late_band.weights.rock, 2)
	assert_eq(late_band.weights.tumbleweed, 5)
	assert_eq(late_band.weights.livestock, 1)
	assert_true(late_band.allows_pressure_pair)


func test_seeded_spawn_plan_advance_uses_rolled_lane_and_type_metadata() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var plan = _prime_seeded_plan(spawner, 12, 0.1)
	spawner.advance(plan.spacing, 0.1)

	assert_eq(spawner.get_child_count(), 1)

	var hazard: Sprite2D = spawner.get_child(0)
	assert_eq(hazard.get_meta("hazard_type"), plan.hazard_type)
	assert_eq(hazard.get_meta("lane_index"), plan.lane_index)
	assert_eq(hazard.position.x, HazardSpawnerType.LANE_X_POSITIONS[plan.lane_index])
	assert_has(HazardSpawnerType.LANE_X_POSITIONS, hazard.position.x)
	assert_eq(hazard.texture, spawner._get_hazard_profile(plan.hazard_type)["texture"])


func test_seeded_spawn_rolls_keep_spacing_inside_band_ranges() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	for roll_index in range(12):
		var early_plan = _prime_seeded_plan(spawner, 100 + roll_index, 0.1)
		assert_true(early_plan.spacing >= 500.0)
		assert_true(early_plan.spacing <= 620.0)

		var mid_plan = _prime_seeded_plan(spawner, 200 + roll_index, 0.5)
		assert_true(mid_plan.spacing >= 400.0)
		assert_true(mid_plan.spacing <= 520.0)

		var late_plan = _prime_seeded_plan(spawner, 300 + roll_index, 0.9)
		assert_true(late_plan.spacing >= 300.0)
		assert_true(late_plan.spacing <= 420.0)


func test_seeded_rolls_randomize_lane_selection_across_seven_lanes() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var lane_indices: Dictionary = {}
	for roll_index in range(240):
		var plan = _prime_seeded_plan(spawner, 400 + roll_index, 0.5)
		lane_indices[plan.lane_index] = true

	assert_eq(lane_indices.size(), HazardSpawnerType.LANE_X_POSITIONS.size())
	assert_eq(
		HazardSpawnerType.LANE_X_POSITIONS,
		[-96.0, -64.0, -32.0, 0.0, 32.0, 64.0, 96.0]
	)


func test_late_band_rolls_add_pressure_pairs_but_earlier_bands_do_not() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var pressure_pair_lane_indices: Dictionary = {}
	var lane_centers: Array = HazardSpawnerType.LANE_X_POSITIONS

	for roll_index in range(12):
		var early_plan = _prime_seeded_plan(spawner, 500 + roll_index, 0.2)
		assert_false(early_plan.has_pressure_pair())

		var mid_plan = _prime_seeded_plan(spawner, 600 + roll_index, 0.65)
		assert_false(mid_plan.has_pressure_pair())

		var late_plan = _prime_seeded_plan(spawner, 700 + roll_index, 0.75)
		assert_true(late_plan.has_pressure_pair())
		assert_ne(late_plan.pressure_pair_lane_index, late_plan.lane_index)
		assert_has(lane_centers, HazardSpawnerType.LANE_X_POSITIONS[late_plan.lane_index])
		assert_has(lane_centers, HazardSpawnerType.LANE_X_POSITIONS[late_plan.pressure_pair_lane_index])
		assert_ne(
			spawner._is_static_hazard_type(late_plan.hazard_type),
			spawner._is_static_hazard_type(late_plan.pressure_pair_type)
		)
		pressure_pair_lane_indices[late_plan.pressure_pair_lane_index] = true

	assert_true(pressure_pair_lane_indices.size() > 1)


func test_spawned_static_hazards_only_use_allowed_lane_center_x_positions() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	for lane_index in range(HazardSpawnerType.LANE_X_POSITIONS.size()):
		spawner._spawn_hazard(&"rock", lane_index)
		var hazard := spawner.get_child(spawner.get_child_count() - 1) as Node2D
		assert_has(HazardSpawnerType.LANE_X_POSITIONS, hazard.position.x)
		assert_eq(hazard.position.x, HazardSpawnerType.LANE_X_POSITIONS[lane_index])


## Confirms livestock remains absent from the opening band but can roll once the run advances.
func test_spawn_plan_when_band_progress_advances_then_livestock_only_rolls_after_opening() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var early_rolls: Array[StringName] = []
	var mid_found := false
	var late_found := false

	for roll_index in range(120):
		early_rolls.append(_prime_seeded_plan(spawner, 800 + roll_index, 0.2).hazard_type)

		if _prime_seeded_plan(spawner, 1000 + roll_index, 0.5).hazard_type == &"livestock":
			mid_found = true

		if _prime_seeded_plan(spawner, 1200 + roll_index, 0.85).hazard_type == &"livestock":
			late_found = true

	assert_false(early_rolls.has(&"livestock"))
	assert_true(mid_found)
	assert_true(late_found)


func test_each_hazard_type_uses_a_distinct_readable_sprite() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var pothole: Sprite2D = spawner._build_hazard_visual(&"pothole")
	var rock: Sprite2D = spawner._build_hazard_visual(&"rock")
	var tumbleweed: Sprite2D = spawner._build_hazard_visual(&"tumbleweed")
	autofree(pothole)
	autofree(rock)
	autofree(tumbleweed)

	assert_eq(pothole.texture, POTHOLE_TEXTURE)
	assert_eq(rock.texture, ROCK_TEXTURE)
	assert_eq(tumbleweed.texture, TUMBLEWEED_TEXTURE)
	assert_ne(pothole.texture, rock.texture)
	assert_ne(rock.texture, tumbleweed.texture)
	assert_ne(pothole.texture, tumbleweed.texture)


## Verifies livestock crosses toward the road and cleans itself up after leaving the playable area.
func test_livestock_when_spawned_then_crosses_toward_lane_and_despawns_offscreen() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 77
	spawner._spawn_hazard(&"livestock", 1)

	var livestock := spawner.get_child(0) as Node2D
	var starting_position := livestock.position
	var target_lane_x := float(livestock.get_meta("target_lane_x"))

	assert_has(HazardSpawnerType.LANE_X_POSITIONS, target_lane_x)
	spawner._move_hazards(40.0)

	assert_true(absf(livestock.position.x - target_lane_x) < absf(starting_position.x - target_lane_x))
	assert_eq(livestock.position.y, starting_position.y + 40.0)

	livestock.position.x = HazardSpawnerType.HAZARD_SIDE_DESPAWN_X + 1.0
	spawner._cleanup_hazards()
	await wait_process_frames(1)

	assert_eq(spawner.get_child_count(), 0)


## Verifies tumbleweeds drift laterally across lanes instead of only falling straight down.
func test_tumbleweed_when_spawned_then_drifts_sideways_toward_a_future_lane_target() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 91
	spawner._spawn_hazard(&"tumbleweed", 3)

	var tumbleweed := spawner.get_child(0) as Node2D
	var starting_position := tumbleweed.position
	var target_lane_x := float(tumbleweed.get_meta("target_lane_x"))
	var drift_ratio_x := float(tumbleweed.get_meta("crossing_scroll_ratio_x"))

	assert_ne(drift_ratio_x, 0.0)
	assert_true(absf(drift_ratio_x) >= HazardSpawnerType.TUMBLEWEED_DRIFT_X_PER_SCROLL_UNIT_MIN)
	assert_true(absf(drift_ratio_x) <= HazardSpawnerType.TUMBLEWEED_DRIFT_X_PER_SCROLL_UNIT_MAX)
	spawner._move_hazards(40.0)

	assert_true(absf(tumbleweed.position.x - target_lane_x) < absf(starting_position.x - target_lane_x))
	assert_eq(tumbleweed.position.y, starting_position.y + 40.0)


## Verifies tumbleweeds rotate in the same signed direction as their drift and scale with travel distance.
func test_tumbleweed_when_moving_then_rotation_matches_scroll_scaled_drift_speed() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 91
	spawner._spawn_hazard(&"tumbleweed", 3)

	var tumbleweed := spawner.get_child(0) as Node2D
	var rotation_per_scroll_unit := float(tumbleweed.get_meta("rotation_radians_per_scroll_unit"))
	assert_ne(rotation_per_scroll_unit, 0.0)

	spawner._move_hazards(40.0)

	assert_almost_eq(tumbleweed.rotation, rotation_per_scroll_unit * 40.0, 0.0001)
	assert_eq(sign(tumbleweed.rotation), sign(rotation_per_scroll_unit))


## Verifies tumbleweeds roll with varying lateral speeds instead of one fixed drift rate.
func test_tumbleweed_when_sampled_then_drift_speed_ranges_from_slow_to_fast() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var slowest_drift_ratio := INF
	var fastest_drift_ratio := 0.0
	for roll_index in range(60):
		spawner._rng.seed = 2000 + roll_index
		spawner._spawn_hazard(&"tumbleweed", 3)
		var tumbleweed := spawner.get_child(spawner.get_child_count() - 1) as Node2D
		var drift_ratio := absf(float(tumbleweed.get_meta("crossing_scroll_ratio_x")))
		slowest_drift_ratio = minf(slowest_drift_ratio, drift_ratio)
		fastest_drift_ratio = maxf(fastest_drift_ratio, drift_ratio)

	assert_true(slowest_drift_ratio >= HazardSpawnerType.TUMBLEWEED_DRIFT_X_PER_SCROLL_UNIT_MIN)
	assert_true(fastest_drift_ratio <= HazardSpawnerType.TUMBLEWEED_DRIFT_X_PER_SCROLL_UNIT_MAX)
	assert_true(fastest_drift_ratio - slowest_drift_ratio > 0.20)


## Verifies tumbleweeds get a small visual bounce without changing their gameplay position.
func test_tumbleweed_when_moving_then_sprite_offset_bounces_within_configured_amplitude() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 91
	spawner._spawn_hazard(&"tumbleweed", 3)

	var tumbleweed := spawner.get_child(0) as Sprite2D
	var starting_position := tumbleweed.position
	var bounce_amplitude := float(tumbleweed.get_meta("bounce_amplitude"))

	spawner._move_hazards(20.0)

	assert_eq(tumbleweed.position.y, starting_position.y + 20.0)
	assert_true(absf(tumbleweed.offset.y) > 0.0)
	assert_true(absf(tumbleweed.offset.y) <= bounce_amplitude)


## Verifies livestock enters from off-road so its crossing reads as a full surprise pass.
func test_livestock_when_spawned_then_starts_offroad_before_crossing_through_target_lane() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 77
	spawner._spawn_hazard(&"livestock", 2)

	var livestock := spawner.get_child(0) as Node2D
	var target_lane_x := float(livestock.get_meta("target_lane_x"))

	assert_true(absf(livestock.position.x) > absf(target_lane_x))
	assert_false(HazardSpawnerType.LANE_X_POSITIONS.has(livestock.position.x))


func test_advance_removes_hazards_after_they_leave_the_screen() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._spawn_hazard(&"pothole", 1)

	for child in spawner.get_children():
		if child is Sprite2D:
			child.position.y = HazardSpawnerType.DEFAULT_DESPAWN_Y + 40.0

	spawner._cleanup_hazards()
	await wait_process_frames(1)

	assert_eq(spawner.get_child_count(), 0)


func test_collect_collisions_reports_profile_damage_for_intersecting_hazard() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var center_lane_index := HazardSpawnerType.LANE_X_POSITIONS.find(0.0)
	assert_ne(center_lane_index, -1)
	spawner._spawn_hazard(&"pothole", center_lane_index)

	var collisions: Array[Dictionary] = spawner.collect_collisions(
		Vector2(0.0, HazardSpawnerType.DEFAULT_SPAWN_Y),
		Vector2(32.0, 64.0)
	)
	assert_eq(collisions.size(), 1)
	assert_eq(collisions[0]["type"], &"pothole")
	assert_eq(collisions[0]["damage"], 6)
	assert_eq(collisions[0]["cargo_damage"], 2)


func test_spawn_bands_when_sampled_many_times_then_potholes_outnumber_rocks() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	for progress_ratio in [0.1, 0.5, 0.85]:
		var pothole_count := 0
		var rock_count := 0
		for roll_index in range(240):
			var plan = _prime_seeded_plan(spawner, 1600 + roll_index + int(progress_ratio * 1000.0), progress_ratio)
			if plan.hazard_type == &"pothole":
				pothole_count += 1
			elif plan.hazard_type == &"rock":
				rock_count += 1

		assert_true(pothole_count > rock_count)


func test_spawn_usage_when_sampled_across_progress_bands_then_roles_follow_the_intended_mix() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var early_counts := _sample_primary_hazard_counts(spawner, 0.2, 600, 3000)
	var mid_counts := _sample_primary_hazard_counts(spawner, 0.5, 600, 4000)
	var late_counts := _sample_primary_hazard_counts(spawner, 0.85, 600, 5000)

	assert_true(early_counts[&"pothole"] > early_counts[&"tumbleweed"])
	assert_true(early_counts[&"tumbleweed"] > early_counts[&"rock"])
	assert_eq(early_counts[&"livestock"], 0)

	assert_true(mid_counts[&"pothole"] > mid_counts[&"tumbleweed"])
	assert_true(mid_counts[&"tumbleweed"] > mid_counts[&"rock"])
	assert_true(mid_counts[&"rock"] > mid_counts[&"livestock"])

	assert_true(late_counts[&"tumbleweed"] > late_counts[&"pothole"])
	assert_true(late_counts[&"pothole"] > late_counts[&"rock"])
	assert_true(late_counts[&"rock"] >= late_counts[&"livestock"])


func test_pressure_pairs_when_sampled_late_then_static_and_timing_roles_are_mixed() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var static_primary_count := 0
	var timing_primary_count := 0
	for roll_index in range(180):
		var late_plan = _prime_seeded_plan(spawner, 6000 + roll_index, 0.85)
		assert_true(late_plan.has_pressure_pair())
		if spawner._is_static_hazard_type(late_plan.hazard_type):
			static_primary_count += 1
			assert_false(spawner._is_static_hazard_type(late_plan.pressure_pair_type))
		else:
			timing_primary_count += 1
			assert_true(spawner._is_static_hazard_type(late_plan.pressure_pair_type))

	assert_true(static_primary_count > 0)
	assert_true(timing_primary_count > 0)


func test_hazard_profiles_when_comparing_pothole_and_rock_then_rock_is_the_punishing_hit() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var pothole_profile: Dictionary = spawner._get_hazard_profile(&"pothole")
	var rock_profile: Dictionary = spawner._get_hazard_profile(&"rock")

	assert_true(rock_profile["damage"] > pothole_profile["damage"])
	assert_true(rock_profile["cargo_damage"] > pothole_profile["cargo_damage"])


func _sample_primary_hazard_counts(
	spawner: Node,
	progress_ratio: float,
	sample_count: int,
	seed_offset: int
) -> Dictionary:
	var counts: Dictionary = {
		&"pothole": 0,
		&"rock": 0,
		&"tumbleweed": 0,
		&"livestock": 0,
	}

	for roll_index in range(sample_count):
		var plan = _prime_seeded_plan(spawner, seed_offset + roll_index, progress_ratio)
		counts[plan.hazard_type] += 1

	return counts
