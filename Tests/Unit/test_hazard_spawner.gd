extends GutTest

const HazardSpawnerType := preload("res://Scripts/Hazards/hazard_spawner.gd")
const POTHOLE_TEXTURE := preload("res://Assets/Tilesets/Hazards/Pothole/Pothole-32x32.png")
const ROCK_TEXTURE := preload("res://Assets/Tilesets/Hazards/Boulder/Boulder-32x32.png")
const TUMBLEWEED_TEXTURE := preload("res://Assets/Tilesets/Hazards/Tumbleweed/Tumbleweed-32x32.png")
const LIVESTOCK_TEXTURE := preload("res://Assets/Tilesets/Hazards/Jackalope/Jackalope-48x32-Sheet.png")


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
	spawner._active_route_phase = spawner._get_route_phase(route_progress_ratio)
	spawner._prime_next_spawn()
	return spawner._next_spawn_plan


## Asserts that each authored route phase resolves to the expected spawn band.
func _assert_route_phase_band(
	spawner: Node,
	progress_ratio: float,
	expected_phase: StringName,
	expected_spacing_min: float,
	expected_spacing_max: float,
	pothole_weight: int,
	rock_weight: int,
	tumbleweed_weight: int,
	livestock_weight: int,
	allows_pressure_pair: bool,
	expected_lane_indices: Array[int]
) -> void:
	spawner._route_progress_ratio = progress_ratio
	var route_phase: StringName = spawner._get_route_phase(progress_ratio)
	var band: Object = spawner._get_active_band()

	assert_eq(route_phase, expected_phase)
	assert_eq(band.spacing_min, expected_spacing_min)
	assert_eq(band.spacing_max, expected_spacing_max)
	assert_eq(band.weights.pothole, pothole_weight)
	assert_eq(band.weights.rock, rock_weight)
	assert_eq(band.weights.tumbleweed, tumbleweed_weight)
	assert_eq(band.weights.livestock, livestock_weight)
	assert_eq(band.allows_pressure_pair, allows_pressure_pair)
	assert_eq(band.lane_indices, expected_lane_indices)


## Verifies the literal DG-26 phase windows switch to the authored spawn profiles.
func test_route_phase_profiles_define_expected_spacing_ranges_and_weights() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	_assert_route_phase_band(
		spawner,
		0.0,
		spawner.ROUTE_PHASE_WARM_UP,
		280.0,
		360.0,
		9,
		2,
		0,
		0,
		false,
		spawner.WARM_UP_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.199,
		spawner.ROUTE_PHASE_WARM_UP,
		280.0,
		360.0,
		9,
		2,
		0,
		0,
		false,
		spawner.WARM_UP_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.2,
		spawner.ROUTE_PHASE_FIRST_TROUBLE,
		220.0,
		320.0,
		4,
		3,
		3,
		0,
		false,
		spawner.FIRST_TROUBLE_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.449,
		spawner.ROUTE_PHASE_FIRST_TROUBLE,
		220.0,
		320.0,
		4,
		3,
		3,
		0,
		false,
		spawner.FIRST_TROUBLE_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.45,
		spawner.ROUTE_PHASE_CROSSING_BEAT,
		230.0,
		320.0,
		1,
		1,
		5,
		4,
		true,
		spawner.FULL_ROAD_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.599,
		spawner.ROUTE_PHASE_CROSSING_BEAT,
		230.0,
		320.0,
		1,
		1,
		5,
		4,
		true,
		spawner.FULL_ROAD_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.6,
		spawner.ROUTE_PHASE_CLUTTER_BEAT,
		210.0,
		290.0,
		3,
		6,
		1,
		0,
		true,
		spawner.FULL_ROAD_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.799,
		spawner.ROUTE_PHASE_CLUTTER_BEAT,
		210.0,
		290.0,
		3,
		6,
		1,
		0,
		true,
		spawner.FULL_ROAD_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.8,
		spawner.ROUTE_PHASE_RESET_BEFORE_FINALE,
		320.0,
		420.0,
		5,
		4,
		1,
		0,
		false,
		spawner.FULL_ROAD_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.879,
		spawner.ROUTE_PHASE_RESET_BEFORE_FINALE,
		320.0,
		420.0,
		5,
		4,
		1,
		0,
		false,
		spawner.FULL_ROAD_LANE_INDICES
	)
	_assert_route_phase_band(
		spawner,
		0.88,
		spawner.ROUTE_PHASE_FINAL_STRETCH,
		spawner.FINAL_STRETCH_SPACING_MIN,
		spawner.FINAL_STRETCH_SPACING_MAX,
		spawner.FINAL_STRETCH_POTHOLE_WEIGHT,
		spawner.FINAL_STRETCH_ROCK_WEIGHT,
		spawner.FINAL_STRETCH_TUMBLEWEED_WEIGHT,
		spawner.FINAL_STRETCH_LIVESTOCK_WEIGHT,
		true,
		spawner.FULL_ROAD_LANE_INDICES
	)


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
		assert_true(early_plan.spacing >= 280.0)
		assert_true(early_plan.spacing <= 360.0)

		var mid_plan = _prime_seeded_plan(spawner, 200 + roll_index, 0.5)
		assert_true(mid_plan.spacing >= 230.0)
		assert_true(mid_plan.spacing <= 320.0)

		var late_plan = _prime_seeded_plan(spawner, 300 + roll_index, 0.85)
		assert_true(late_plan.spacing >= 320.0)
		assert_true(late_plan.spacing <= 420.0)

		var final_stretch_plan = _prime_seeded_plan(spawner, 400 + roll_index, 0.9)
		assert_true(final_stretch_plan.spacing >= spawner.FINAL_STRETCH_SPACING_MIN)
		assert_true(final_stretch_plan.spacing <= spawner.FINAL_STRETCH_SPACING_MAX)


## Verifies the final stretch keeps RNG by varying hazard mix, lane use, spacing, and pressure pairs.
func test_final_stretch_when_sampled_then_hazard_order_lane_use_and_spacing_vary() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var final_stretch_hazard_types: Dictionary = {}
	var final_stretch_lane_indices: Dictionary = {}
	var min_spacing := INF
	var max_spacing := 0.0
	var pressure_pair_count := 0

	for roll_index in range(240):
		var final_stretch_plan = _prime_seeded_plan(spawner, 8000 + roll_index, 0.9)
		final_stretch_hazard_types[final_stretch_plan.hazard_type] = true
		final_stretch_lane_indices[final_stretch_plan.lane_index] = true
		min_spacing = minf(min_spacing, final_stretch_plan.spacing)
		max_spacing = maxf(max_spacing, final_stretch_plan.spacing)
		if final_stretch_plan.has_pressure_pair():
			pressure_pair_count += 1
			assert_ne(final_stretch_plan.pressure_pair_lane_index, final_stretch_plan.lane_index)
			assert_ne(
				spawner._is_static_hazard_type(final_stretch_plan.hazard_type),
				spawner._is_static_hazard_type(final_stretch_plan.pressure_pair_type)
			)

	assert_eq(spawner._get_route_phase(0.9), spawner.ROUTE_PHASE_FINAL_STRETCH)
	assert_has(final_stretch_hazard_types, &"rock")
	assert_has(final_stretch_hazard_types, &"tumbleweed")
	assert_has(final_stretch_hazard_types, &"livestock")
	assert_true(final_stretch_lane_indices.size() >= 6)
	assert_true(min_spacing >= spawner.FINAL_STRETCH_SPACING_MIN)
	assert_true(max_spacing <= spawner.FINAL_STRETCH_SPACING_MAX)
	assert_true(max_spacing - min_spacing > 40.0)
	assert_true(pressure_pair_count > 0)


## Verifies the queued spawn plan refreshes as soon as the run enters the final stretch.
func test_final_stretch_when_phase_changes_then_spawn_plan_resets_to_finale_profile() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 27
	spawner.advance(0.0, 0.85)

	assert_eq(spawner._active_route_phase, spawner.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_true(spawner._next_spawn_plan.spacing >= 320.0)
	assert_true(spawner._next_spawn_plan.spacing <= 420.0)

	spawner.advance(0.0, 0.9)

	assert_eq(spawner._active_route_phase, spawner.ROUTE_PHASE_FINAL_STRETCH)
	assert_true(spawner._next_spawn_plan.spacing >= spawner.FINAL_STRETCH_SPACING_MIN)
	assert_true(spawner._next_spawn_plan.spacing <= spawner.FINAL_STRETCH_SPACING_MAX)
	assert_true(spawner._next_spawn_plan.has_pressure_pair())


## Verifies the final stretch stops spawning before the finish and preserves a clear runway.
func test_final_stretch_when_route_remaining_distance_reaches_release_window_then_spawning_stops() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 53
	var route_distance := 10000.0
	var remaining_distance_before_last_spawn: float = (
		spawner.FINAL_STRETCH_RELEASE_DISTANCE
		+ spawner.FINAL_STRETCH_SPACING_MAX
		+ 1.0
	)
	spawner.advance(0.0, 0.9, remaining_distance_before_last_spawn, route_distance)

	assert_not_null(spawner._next_spawn_plan)

	var planned_spacing: float = spawner._next_spawn_plan.spacing
	var remaining_distance_after_last_spawn: float = remaining_distance_before_last_spawn - planned_spacing
	spawner.advance(
		planned_spacing,
		0.9,
		remaining_distance_after_last_spawn,
		route_distance
	)

	assert_true(spawner.get_child_count() > 0)

	var release_travel_distance: float = max(
		0.0,
		remaining_distance_after_last_spawn - spawner.FINAL_STRETCH_CLEAR_RUNWAY_DISTANCE
	)
	spawner.advance(
		release_travel_distance,
		0.98,
		spawner.FINAL_STRETCH_CLEAR_RUNWAY_DISTANCE,
		route_distance
	)
	await wait_process_frames(1)

	assert_eq(spawner.get_child_count(), 0)
	assert_eq(spawner._next_spawn_plan, null)
	assert_eq(spawner._distance_until_next_spawn, 0.0)
	assert_true(spawner._supports_final_stretch_release(route_distance))
	assert_eq(spawner._get_route_phase(0.98), spawner.ROUTE_PHASE_FINAL_STRETCH)


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


## Verifies the opener phases bias hazards toward the center lanes so idle center play is taught to dodge.
func test_opening_phases_when_sampled_then_lane_selection_stays_center_biased() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var warm_up_lane_indices: Dictionary = {}
	var first_trouble_lane_indices: Dictionary = {}
	for roll_index in range(240):
		var warm_up_plan = _prime_seeded_plan(spawner, 1400 + roll_index, 0.1)
		var first_trouble_plan = _prime_seeded_plan(spawner, 1800 + roll_index, 0.3)
		warm_up_lane_indices[warm_up_plan.lane_index] = true
		first_trouble_lane_indices[first_trouble_plan.lane_index] = true

	var warm_up_lane_keys: Array = warm_up_lane_indices.keys()
	var first_trouble_lane_keys: Array = first_trouble_lane_indices.keys()
	warm_up_lane_keys.sort()
	first_trouble_lane_keys.sort()

	assert_eq(warm_up_lane_keys, spawner.WARM_UP_LANE_INDICES)
	assert_eq(first_trouble_lane_keys, spawner.FIRST_TROUBLE_LANE_INDICES)


## Verifies pressure pairs only appear in the phases that author them.
func test_route_phase_pressure_pairs_follow_the_authoring_rules() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var lane_centers: Array = HazardSpawnerType.LANE_X_POSITIONS
	var crossing_pressure_pair_count := 0
	var clutter_pressure_pair_count := 0

	for roll_index in range(24):
		assert_false(_prime_seeded_plan(spawner, 500 + roll_index, 0.1).has_pressure_pair())
		assert_false(_prime_seeded_plan(spawner, 600 + roll_index, 0.3).has_pressure_pair())

		var crossing_plan = _prime_seeded_plan(spawner, 700 + roll_index, 0.5)
		if crossing_plan.has_pressure_pair():
			crossing_pressure_pair_count += 1
			assert_ne(crossing_plan.pressure_pair_lane_index, crossing_plan.lane_index)
			assert_has(lane_centers, HazardSpawnerType.LANE_X_POSITIONS[crossing_plan.lane_index])
			assert_has(
				lane_centers,
				HazardSpawnerType.LANE_X_POSITIONS[crossing_plan.pressure_pair_lane_index]
			)
			assert_ne(
				spawner._is_static_hazard_type(crossing_plan.hazard_type),
				spawner._is_static_hazard_type(crossing_plan.pressure_pair_type)
			)

		var clutter_plan = _prime_seeded_plan(spawner, 800 + roll_index, 0.7)
		if clutter_plan.has_pressure_pair():
			clutter_pressure_pair_count += 1
			assert_ne(clutter_plan.pressure_pair_lane_index, clutter_plan.lane_index)
			assert_has(lane_centers, HazardSpawnerType.LANE_X_POSITIONS[clutter_plan.lane_index])
			assert_has(
				lane_centers,
				HazardSpawnerType.LANE_X_POSITIONS[clutter_plan.pressure_pair_lane_index]
			)
			assert_ne(
				spawner._is_static_hazard_type(clutter_plan.hazard_type),
				spawner._is_static_hazard_type(clutter_plan.pressure_pair_type)
			)

		assert_false(_prime_seeded_plan(spawner, 900 + roll_index, 0.85).has_pressure_pair())

	assert_true(crossing_pressure_pair_count > 0)
	assert_true(clutter_pressure_pair_count > 0)


func test_spawned_static_hazards_only_use_allowed_lane_center_x_positions() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	for lane_index in range(HazardSpawnerType.LANE_X_POSITIONS.size()):
		spawner._spawn_hazard(&"rock", lane_index)
		var hazard := spawner.get_child(spawner.get_child_count() - 1) as Node2D
		assert_has(HazardSpawnerType.LANE_X_POSITIONS, hazard.position.x)
		assert_eq(hazard.position.x, HazardSpawnerType.LANE_X_POSITIONS[lane_index])


## Confirms moving hazards stay out of warm-up and show up once the first trouble phase starts.
func test_route_phase_when_sampled_then_moving_hazards_start_after_warm_up() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var warm_up_counts := _sample_primary_hazard_counts(spawner, 0.1, 120, 800)
	var first_trouble_counts := _sample_primary_hazard_counts(spawner, 0.3, 120, 1000)
	var crossing_counts := _sample_primary_hazard_counts(spawner, 0.5, 120, 1200)
	var clutter_counts := _sample_primary_hazard_counts(spawner, 0.7, 120, 1400)
	var reset_counts := _sample_primary_hazard_counts(spawner, 0.85, 120, 1600)

	assert_eq(warm_up_counts[&"tumbleweed"], 0)
	assert_eq(warm_up_counts[&"livestock"], 0)
	assert_true(warm_up_counts[&"pothole"] > warm_up_counts[&"rock"])
	assert_true(first_trouble_counts[&"tumbleweed"] > 0)
	assert_eq(first_trouble_counts[&"livestock"], 0)
	assert_true(first_trouble_counts[&"pothole"] > first_trouble_counts[&"rock"])
	assert_true(crossing_counts[&"tumbleweed"] > crossing_counts[&"pothole"])
	assert_true(crossing_counts[&"livestock"] > crossing_counts[&"rock"])
	assert_true(clutter_counts[&"rock"] > clutter_counts[&"pothole"])
	assert_true(clutter_counts[&"rock"] > clutter_counts[&"tumbleweed"])
	assert_true(reset_counts[&"pothole"] > reset_counts[&"rock"])
	assert_true(reset_counts[&"tumbleweed"] > 0)


func test_static_hazard_types_use_distinct_readable_sprites() -> void:
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


## Confirms livestock hazards use the exported jackalope sheet as a looping animation.
func test_livestock_hazard_uses_animated_sheet_frames() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var livestock := spawner._build_hazard_visual(&"livestock") as AnimatedSprite2D
	autofree(livestock)

	assert_not_null(livestock)
	assert_not_null(livestock.sprite_frames)
	assert_true(livestock.sprite_frames.has_animation("default"))
	assert_eq(livestock.sprite_frames.get_frame_count("default"), 4)
	assert_eq(livestock.sprite_frames.get_animation_speed("default"), spawner.LIVESTOCK_ANIMATION_FPS)
	assert_eq(livestock.sprite_frames.get_animation_loop("default"), true)
	assert_true(livestock.is_playing())

	var frame_0 := livestock.sprite_frames.get_frame_texture("default", 0) as AtlasTexture
	var frame_3 := livestock.sprite_frames.get_frame_texture("default", 3) as AtlasTexture

	assert_not_null(frame_0)
	assert_not_null(frame_3)
	assert_eq(frame_0.atlas, LIVESTOCK_TEXTURE)
	assert_eq(frame_3.atlas, LIVESTOCK_TEXTURE)
	assert_eq(frame_0.get_size(), Vector2(48.0, 32.0))
	assert_eq(frame_3.get_size(), Vector2(48.0, 32.0))


## Confirms the jackalope keeps its lane target centered on the visible animal instead of the raw sheet frame.
func test_livestock_hazard_uses_directional_crossing_offset_to_center_the_body_on_the_lane() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 77
	spawner._spawn_hazard(&"livestock", 2)

	var livestock := spawner.get_child(0) as AnimatedSprite2D
	var crossing_direction := int(livestock.get_meta("crossing_direction"))
	var lane_index := int(livestock.get_meta("lane_index"))
	var target_lane_x := float(livestock.get_meta("target_lane_x"))
	var lane_center_x: float = HazardSpawnerType.LANE_X_POSITIONS[lane_index]
	var expected_offset_x := (
		HazardSpawnerType.LIVESTOCK_VISUAL_CENTER_OFFSET_X * float(crossing_direction)
	)
	var crossing_distance := (
		absf(HazardSpawnerType.DEFAULT_SPAWN_Y - HazardSpawnerType.LIVESTOCK_CROSSING_TARGET_Y)
		* HazardSpawnerType.LIVESTOCK_CROSSING_X_PER_SCROLL_UNIT
	)

	assert_ne(crossing_direction, 0)
	assert_eq(target_lane_x, lane_center_x + expected_offset_x)
	assert_eq(
		livestock.position.x,
		lane_center_x - (crossing_distance * float(crossing_direction)) + expected_offset_x
	)
	assert_eq(absf(livestock.position.x - target_lane_x), crossing_distance)


## Confirms the livestock hazard uses a tighter collision footprint that matches the visible jackalope body.
func test_livestock_hazard_uses_tighter_collision_size_matching_the_body() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var profile: Dictionary = spawner._get_hazard_profile(&"livestock")

	assert_eq(profile["size"], spawner.LIVESTOCK_COLLISION_SIZE)
	assert_eq(profile["size"], Vector2(36.0, 32.0))


## Verifies livestock crosses toward the road and cleans itself up after leaving the playable area.
func test_livestock_when_spawned_then_crosses_toward_lane_and_despawns_offscreen() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	spawner._rng.seed = 77
	spawner._spawn_hazard(&"livestock", 1)

	var livestock := spawner.get_child(0) as AnimatedSprite2D
	var starting_position := livestock.position
	var target_lane_x := float(livestock.get_meta("target_lane_x"))

	assert_ne(target_lane_x, HazardSpawnerType.LANE_X_POSITIONS[int(livestock.get_meta("lane_index"))])
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

	var livestock := spawner.get_child(0) as AnimatedSprite2D
	var target_lane_x := float(livestock.get_meta("target_lane_x"))

	assert_true(absf(livestock.position.x) > absf(target_lane_x))
	assert_false(HazardSpawnerType.LANE_X_POSITIONS.has(target_lane_x))


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


## Verifies the lighter phases still keep potholes more common than rocks.
func test_spawn_bands_when_sampled_many_times_then_potholes_outnumber_rocks() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	for progress_ratio in [0.1, 0.3, 0.85]:
		var pothole_count := 0
		var rock_count := 0
		for roll_index in range(240):
			var plan = _prime_seeded_plan(spawner, 1600 + roll_index + int(progress_ratio * 1000.0), progress_ratio)
			if plan.hazard_type == &"pothole":
				pothole_count += 1
			elif plan.hazard_type == &"rock":
				rock_count += 1

		assert_true(pothole_count > rock_count)


## Verifies the clutter beat makes rocks the dominant blocker instead of a rarity.
func test_clutter_beat_when_sampled_many_times_then_rocks_outnumber_potholes() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var clutter_counts := _sample_primary_hazard_counts(spawner, 0.7, 600, 9000)

	assert_true(clutter_counts[&"rock"] > clutter_counts[&"pothole"])
	assert_true(clutter_counts[&"rock"] > clutter_counts[&"tumbleweed"])


## Verifies each authored route phase produces the intended hazard mix.
func test_spawn_usage_when_sampled_across_route_phases_then_roles_follow_the_intended_mix() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var warm_up_counts := _sample_primary_hazard_counts(spawner, 0.1, 600, 3000)
	var first_trouble_counts := _sample_primary_hazard_counts(spawner, 0.3, 600, 4000)
	var crossing_counts := _sample_primary_hazard_counts(spawner, 0.5, 600, 5000)
	var clutter_counts := _sample_primary_hazard_counts(spawner, 0.7, 600, 6000)
	var reset_counts := _sample_primary_hazard_counts(spawner, 0.85, 600, 7000)
	var final_stretch_counts := _sample_primary_hazard_counts(spawner, 0.9, 600, 8000)

	assert_eq(warm_up_counts[&"tumbleweed"], 0)
	assert_eq(warm_up_counts[&"livestock"], 0)
	assert_true(warm_up_counts[&"pothole"] > warm_up_counts[&"rock"])

	assert_true(first_trouble_counts[&"pothole"] > first_trouble_counts[&"rock"])
	assert_true(first_trouble_counts[&"rock"] > 0)
	assert_true(first_trouble_counts[&"tumbleweed"] > 0)
	assert_eq(first_trouble_counts[&"livestock"], 0)

	assert_true(crossing_counts[&"tumbleweed"] > 0)
	assert_true(crossing_counts[&"livestock"] > 0)
	assert_true(
		crossing_counts[&"tumbleweed"] + crossing_counts[&"livestock"]
			> crossing_counts[&"pothole"] + crossing_counts[&"rock"]
	)

	assert_true(clutter_counts[&"rock"] > clutter_counts[&"pothole"])
	assert_true(clutter_counts[&"rock"] > clutter_counts[&"livestock"])
	assert_true(
		clutter_counts[&"pothole"] + clutter_counts[&"rock"]
			> clutter_counts[&"tumbleweed"] + clutter_counts[&"livestock"]
	)

	assert_true(reset_counts[&"pothole"] > reset_counts[&"rock"])
	assert_true(reset_counts[&"tumbleweed"] > 0)
	assert_eq(reset_counts[&"livestock"], 0)

	assert_true(final_stretch_counts[&"rock"] > final_stretch_counts[&"pothole"])
	assert_true(final_stretch_counts[&"tumbleweed"] > 0)
	assert_true(final_stretch_counts[&"livestock"] > 0)
	assert_true(
		final_stretch_counts[&"rock"] + final_stretch_counts[&"tumbleweed"]
			> final_stretch_counts[&"pothole"] + final_stretch_counts[&"livestock"]
	)


## Verifies pressure pairs mix static and timing roles everywhere the authored profiles allow them.
func test_route_phase_when_sampled_then_pressure_pairs_mix_static_and_timing_roles() -> void:
	var spawner := _create_seeded_spawner()
	await wait_process_frames(1)

	var static_primary_count := 0
	var timing_primary_count := 0
	var final_stretch_pressure_pair_count := 0
	for roll_index in range(180):
		var crossing_plan = _prime_seeded_plan(spawner, 6000 + roll_index, 0.5)
		assert_true(crossing_plan.has_pressure_pair())
		if spawner._is_static_hazard_type(crossing_plan.hazard_type):
			static_primary_count += 1
			assert_false(spawner._is_static_hazard_type(crossing_plan.pressure_pair_type))
		else:
			timing_primary_count += 1
			assert_true(spawner._is_static_hazard_type(crossing_plan.pressure_pair_type))

		var clutter_plan = _prime_seeded_plan(spawner, 7000 + roll_index, 0.7)
		assert_true(clutter_plan.has_pressure_pair())
		if spawner._is_static_hazard_type(clutter_plan.hazard_type):
			static_primary_count += 1
			assert_false(spawner._is_static_hazard_type(clutter_plan.pressure_pair_type))
		else:
			timing_primary_count += 1
			assert_true(spawner._is_static_hazard_type(clutter_plan.pressure_pair_type))

		var final_stretch_plan = _prime_seeded_plan(spawner, 8000 + roll_index, 0.9)
		if final_stretch_plan.has_pressure_pair():
			final_stretch_pressure_pair_count += 1
			if spawner._is_static_hazard_type(final_stretch_plan.hazard_type):
				static_primary_count += 1
				assert_false(spawner._is_static_hazard_type(final_stretch_plan.pressure_pair_type))
			else:
				timing_primary_count += 1
				assert_true(spawner._is_static_hazard_type(final_stretch_plan.pressure_pair_type))

	assert_true(static_primary_count > 0)
	assert_true(timing_primary_count > 0)
	assert_true(final_stretch_pressure_pair_count > 0)


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
