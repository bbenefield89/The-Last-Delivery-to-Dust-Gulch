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
	assert_eq(early_band.spacing_min, 520.0)
	assert_eq(early_band.spacing_max, 660.0)
	assert_eq(early_band.weights.pothole, 6)
	assert_eq(early_band.weights.rock, 2)
	assert_eq(early_band.weights.tumbleweed, 4)
	assert_eq(early_band.weights.livestock, 0)
	assert_false(early_band.allows_pressure_pair)

	spawner._route_progress_ratio = 0.5
	var mid_band = spawner._get_active_band()
	assert_eq(mid_band.spacing_min, 420.0)
	assert_eq(mid_band.spacing_max, 560.0)
	assert_eq(mid_band.weights.pothole, 4)
	assert_eq(mid_band.weights.rock, 3)
	assert_eq(mid_band.weights.tumbleweed, 3)
	assert_eq(mid_band.weights.livestock, 2)
	assert_false(mid_band.allows_pressure_pair)

	spawner._route_progress_ratio = 0.8
	var late_band = spawner._get_active_band()
	assert_eq(late_band.spacing_min, 320.0)
	assert_eq(late_band.spacing_max, 460.0)
	assert_eq(late_band.weights.pothole, 4)
	assert_eq(late_band.weights.rock, 5)
	assert_eq(late_band.weights.tumbleweed, 3)
	assert_eq(late_band.weights.livestock, 2)
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
	assert_eq(hazard.texture, spawner._get_hazard_profile(plan.hazard_type)["texture"])


func test_seeded_spawn_rolls_keep_spacing_inside_band_ranges() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	for roll_index in range(12):
		var early_plan = _prime_seeded_plan(spawner, 100 + roll_index, 0.1)
		assert_true(early_plan.spacing >= 520.0)
		assert_true(early_plan.spacing <= 660.0)

		var mid_plan = _prime_seeded_plan(spawner, 200 + roll_index, 0.5)
		assert_true(mid_plan.spacing >= 420.0)
		assert_true(mid_plan.spacing <= 560.0)

		var late_plan = _prime_seeded_plan(spawner, 300 + roll_index, 0.9)
		assert_true(late_plan.spacing >= 320.0)
		assert_true(late_plan.spacing <= 460.0)


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

	for roll_index in range(12):
		var early_plan = _prime_seeded_plan(spawner, 500 + roll_index, 0.2)
		assert_false(early_plan.has_pressure_pair())

		var mid_plan = _prime_seeded_plan(spawner, 600 + roll_index, 0.65)
		assert_false(mid_plan.has_pressure_pair())

		var late_plan = _prime_seeded_plan(spawner, 700 + roll_index, 0.75)
		assert_true(late_plan.has_pressure_pair())
		assert_ne(late_plan.pressure_pair_lane_index, late_plan.lane_index)
		pressure_pair_lane_indices[late_plan.pressure_pair_lane_index] = true

	assert_true(pressure_pair_lane_indices.size() > 1)


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

	spawner._move_hazards(40.0)

	assert_true(absf(livestock.position.x - target_lane_x) < absf(starting_position.x - target_lane_x))
	assert_eq(livestock.position.y, starting_position.y + 40.0)

	livestock.position.x = HazardSpawnerType.HAZARD_SIDE_DESPAWN_X + 1.0
	spawner._cleanup_hazards()
	await wait_process_frames(1)

	assert_eq(spawner.get_child_count(), 0)


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
	assert_eq(collisions[0]["damage"], 10)
	assert_eq(collisions[0]["cargo_damage"], 4)
