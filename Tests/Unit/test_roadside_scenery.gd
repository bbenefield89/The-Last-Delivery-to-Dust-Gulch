extends GutTest

# Constants
const RoadsideSceneryType := preload(ProjectPaths.ROADSIDE_SCENERY_SCRIPT_PATH)


# Private Methods

## Builds a small solid-color texture for focused roadside scenery tests.
func _make_texture(size: Vector2i, color: Color) -> Texture2D:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Creates a cleanup area that matches the run-scene bottom cleanup flow closely enough for unit tests.
func _make_bottom_cleanup_area() -> Area2D:
	var cleanup_area := Area2D.new()
	cleanup_area.position = Vector2(320.0, 720.0)
	cleanup_area.monitoring = true
	cleanup_area.monitorable = true
	cleanup_area.collision_layer = 4
	cleanup_area.collision_mask = 1

	var collision_shape := CollisionShape2D.new()
	collision_shape.position = Vector2(0.0, -130.0)
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = Vector2(720.0, 320.0)
	collision_shape.shape = rectangle_shape
	cleanup_area.add_child(collision_shape)
	return cleanup_area


## Creates one configured roadside scenery owner inside a lightweight scene harness.
func _create_roadside_owner() -> RoadsideSceneryType:
	var root := Node2D.new()
	add_child_autofree(root)

	var cleanup_area := _make_bottom_cleanup_area()
	root.add_child(cleanup_area)

	var roadside_scenery := RoadsideSceneryType.new()
	roadside_scenery.position = Vector2(320.0, 300.0)
	root.add_child(roadside_scenery)
	await wait_process_frames(1)

	roadside_scenery._rng.seed = 7
	roadside_scenery.configure_scenery_art(
		[
			_make_texture(Vector2i(24, 20), Color(0.35, 0.45, 0.18, 1.0)),
			_make_texture(Vector2i(28, 24), Color(0.42, 0.51, 0.21, 1.0)),
		],
		_make_texture(Vector2i(34, 42), Color(0.62, 0.49, 0.29, 1.0))
	)
	roadside_scenery.bind_cleanup_areas([cleanup_area])
	return roadside_scenery


## Captures the current spawned roadside stream with the metadata needed by focused roadside tests.
func _build_scenery_snapshot(roadside_scenery: RoadsideSceneryType) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for child in roadside_scenery.get_children():
		var scenery := child as Area2D
		if scenery == null:
			continue

		snapshot.append({
			"distance_spawned": scenery.get_meta("travel_distance_spawned", 0.0),
			"spawn_sequence_id": scenery.get_meta("spawn_sequence_id", -1),
			"y": scenery.position.y,
			"type": scenery.get_meta("scenery_type", &""),
			"roadside_side": scenery.get_meta("roadside_side", 0),
			"texture_index": scenery.get_meta("texture_index", -1),
			"scrub_variant": scenery.get_meta("scrub_variant", &""),
		})

	return snapshot


## Captures the current spawned roadside stream ordered by on-screen y for spacing comparisons.
func _snapshot_scenery(roadside_scenery: RoadsideSceneryType) -> Array[Dictionary]:
	var snapshot := _build_scenery_snapshot(roadside_scenery)
	snapshot.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["y"]) < float(b["y"])
	)
	return snapshot


## Captures the current spawned roadside stream in original spawn order for variety and cadence assertions.
func _snapshot_scenery_by_spawn_order(roadside_scenery: RoadsideSceneryType) -> Array[Dictionary]:
	var snapshot := _build_scenery_snapshot(roadside_scenery)
	snapshot.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["spawn_sequence_id"]) < int(b["spawn_sequence_id"])
	)
	return snapshot


## Returns the live spawned roadside item for one spawn sequence id, or null when it has despawned.
func _find_spawned_scenery_by_spawn_sequence_id(
	roadside_scenery: RoadsideSceneryType,
	spawn_sequence_id: int
) -> Area2D:
	for child in roadside_scenery.get_children():
		var scenery := child as Area2D
		if scenery == null:
			continue
		if int(scenery.get_meta("spawn_sequence_id", -1)) == spawn_sequence_id:
			return scenery

	return null


## Returns the current live spawned signs under one roadside scenery owner.
func _get_live_signs(roadside_scenery: RoadsideSceneryType) -> Array[Area2D]:
	var signs: Array[Area2D] = []
	for child in roadside_scenery.get_children():
		var scenery := child as Area2D
		if scenery == null:
			continue
		if scenery.get_meta("scenery_type", &"") != roadside_scenery.SCENERY_TYPE_SIGN:
			continue

		signs.append(scenery)

	return signs


# Public Methods

## Verifies the roadside owner spawns by traveled distance instead of wall-clock chunking.
func test_advance_when_distance_is_equal_then_spawn_count_stays_stable_across_step_sizes() -> void:
	var coarse_owner := await _create_roadside_owner()
	coarse_owner.advance(360.0)
	var coarse_snapshot := _snapshot_scenery(coarse_owner)

	var fine_owner := await _create_roadside_owner()
	for _step in range(12):
		fine_owner.advance(30.0)
	var fine_snapshot := _snapshot_scenery(fine_owner)

	assert_eq(coarse_snapshot.size(), fine_snapshot.size())
	assert_true(coarse_snapshot.size() > 0)
	for index in range(coarse_snapshot.size()):
		assert_eq(coarse_snapshot[index]["type"], fine_snapshot[index]["type"])
		assert_eq(coarse_snapshot[index]["roadside_side"], fine_snapshot[index]["roadside_side"])
		assert_eq(coarse_snapshot[index]["texture_index"], fine_snapshot[index]["texture_index"])
		assert_eq(coarse_snapshot[index]["scrub_variant"], fine_snapshot[index]["scrub_variant"])
		assert_almost_eq(float(coarse_snapshot[index]["y"]), float(fine_snapshot[index]["y"]), 0.01)


## Verifies one large advance preserves the same ordered spawn spacing as many small advances.
func test_advance_when_chunk_sizes_change_then_y_ordering_and_spacing_match() -> void:
	var large_step_owner := await _create_roadside_owner()
	large_step_owner.advance(960.0)
	var large_snapshot := _snapshot_scenery(large_step_owner)

	var small_step_owner := await _create_roadside_owner()
	for _step in range(32):
		small_step_owner.advance(30.0)
	var small_snapshot := _snapshot_scenery(small_step_owner)

	assert_eq(large_snapshot.size(), small_snapshot.size())
	assert_true(large_snapshot.size() >= 5)
	for index in range(large_snapshot.size()):
		assert_eq(large_snapshot[index]["type"], small_snapshot[index]["type"])
		assert_eq(large_snapshot[index]["roadside_side"], small_snapshot[index]["roadside_side"])
		assert_almost_eq(float(large_snapshot[index]["y"]), float(small_snapshot[index]["y"]), 0.01)

	for index in range(1, large_snapshot.size()):
		var large_spacing := float(large_snapshot[index]["y"]) - float(large_snapshot[index - 1]["y"])
		var small_spacing := float(small_snapshot[index]["y"]) - float(small_snapshot[index - 1]["y"])
		assert_true(large_spacing > 0.0)
		assert_true(small_spacing > 0.0)
		assert_almost_eq(large_spacing, small_spacing, 0.01)


## Verifies spawned scenery stays on roadside margins, above view at spawn time, and avoids long same-side streaks.
func test_spawned_scenery_when_advanced_then_items_use_margin_positions_and_controlled_side_streaks() -> void:
	var roadside_scenery := await _create_roadside_owner()
	roadside_scenery.advance(960.0)

	var previous_roadside_side := 0
	var same_roadside_side_streak := 0
	assert_true(roadside_scenery.get_child_count() >= 5)
	for child in roadside_scenery.get_children():
		var scenery := child as Area2D
		assert_not_null(scenery)

		var roadside_side := int(scenery.get_meta("roadside_side", 0))
		if roadside_side == previous_roadside_side:
			same_roadside_side_streak += 1
		else:
			same_roadside_side_streak = 1
			previous_roadside_side = roadside_side

		assert_true(absf(scenery.position.x) >= 160.0)
		assert_true(absf(scenery.position.x) <= 262.0)
		assert_true(float(scenery.get_meta("spawn_y", 0.0)) < 0.0)
		assert_true(same_roadside_side_streak <= roadside_scenery.MAX_SAME_SIDE_STREAK)


## Verifies the step-2 feel pass keeps the desert more populated with scrub than before.
func test_spawned_scenery_when_advanced_then_scrub_density_feels_more_populated() -> void:
	var roadside_scenery := await _create_roadside_owner()
	roadside_scenery.advance(960.0)
	var spawn_order_snapshot := _snapshot_scenery_by_spawn_order(roadside_scenery)

	var scrub_count := 0
	var sign_count := 0
	for entry in spawn_order_snapshot:
		if entry["type"] == roadside_scenery.SCENERY_TYPE_SIGN:
			sign_count += 1
			continue

		if entry["type"] == roadside_scenery.SCENERY_TYPE_SCRUB:
			scrub_count += 1

	assert_true(spawn_order_snapshot.size() >= 7)
	assert_true(scrub_count >= 5)
	assert_true(scrub_count > sign_count)


## Verifies scrub spawning stays varied without allowing long texture or silhouette repetition streaks.
func test_spawned_scenery_when_scrubs_repeat_then_texture_and_variant_streaks_stay_limited() -> void:
	var roadside_scenery := await _create_roadside_owner()
	roadside_scenery.advance(3200.0)
	var spawn_order_snapshot := _snapshot_scenery_by_spawn_order(roadside_scenery)

	var scrub_texture_indices: Array[int] = []
	var scrub_variants: Array[StringName] = []
	var texture_streak := 0
	var variant_streak := 0
	var previous_texture_index := -1
	var previous_variant := StringName()
	for entry in spawn_order_snapshot:
		if entry["type"] != roadside_scenery.SCENERY_TYPE_SCRUB:
			continue

		var scrub_texture_index := int(entry["texture_index"])
		var scrub_variant := entry["scrub_variant"] as StringName
		scrub_texture_indices.append(scrub_texture_index)
		scrub_variants.append(scrub_variant)

		if scrub_texture_index == previous_texture_index:
			texture_streak += 1
		else:
			texture_streak = 1
			previous_texture_index = scrub_texture_index

		if scrub_variant == previous_variant:
			variant_streak += 1
		else:
			variant_streak = 1
			previous_variant = scrub_variant

		assert_true(scrub_texture_index >= 0)
		assert_true(scrub_variant != &"")
		assert_true(texture_streak <= roadside_scenery.MAX_SAME_SCRUB_TEXTURE_STREAK)
		assert_true(variant_streak <= roadside_scenery.MAX_SAME_SCRUB_VARIANT_STREAK)

	assert_true(scrub_texture_indices.size() >= 8)
	var first_scrub_texture_index := scrub_texture_indices[0]
	var saw_second_texture_index := false
	for texture_index in scrub_texture_indices:
		if texture_index == first_scrub_texture_index:
			continue

		saw_second_texture_index = true
		break

	assert_true(saw_second_texture_index)

	var first_scrub_variant := scrub_variants[0]
	var saw_second_scrub_variant := false
	for scrub_variant in scrub_variants:
		if scrub_variant == first_scrub_variant:
			continue

		saw_second_scrub_variant = true
		break

	assert_true(saw_second_scrub_variant)


## Verifies roadside signs obey explicit cooldown and side rules so they stay readable instead of dominating.
func test_spawned_scenery_when_signs_spawn_then_sign_spacing_and_side_rules_hold() -> void:
	var roadside_scenery := await _create_roadside_owner()
	roadside_scenery.advance(3200.0)
	var spawn_order_snapshot := _snapshot_scenery_by_spawn_order(roadside_scenery)

	var sign_entries: Array[Dictionary] = []
	var previous_sign_side := 0
	for entry in spawn_order_snapshot:
		if entry["type"] != roadside_scenery.SCENERY_TYPE_SIGN:
			continue

		sign_entries.append(entry)
		var sign_side := int(entry["roadside_side"])
		assert_true(absf(float(entry["y"])) <= 3200.0)
		assert_true(absf(sign_side) == 1)
		if previous_sign_side != 0:
			assert_ne(sign_side, previous_sign_side)
		previous_sign_side = sign_side

	assert_true(sign_entries.size() >= 3)
	for sign_index in range(1, sign_entries.size()):
		var previous_entry := sign_entries[sign_index - 1]
		var current_entry := sign_entries[sign_index]
		var traveled_spacing := float(current_entry["distance_spawned"]) - float(previous_entry["distance_spawned"])
		assert_true(traveled_spacing >= roadside_scenery.SIGN_DISTANCE_INTERVAL)

		var scrub_entries_between_signs := 0
		for entry in spawn_order_snapshot:
			var entry_sequence_id := int(entry["spawn_sequence_id"])
			if (
				entry_sequence_id <= int(previous_entry["spawn_sequence_id"])
				or entry_sequence_id >= int(current_entry["spawn_sequence_id"])
			):
				continue
			if entry["type"] == roadside_scenery.SCENERY_TYPE_SCRUB:
				scrub_entries_between_signs += 1

		assert_true(scrub_entries_between_signs >= roadside_scenery.MIN_SCRUB_SPAWNS_BETWEEN_SIGNS)


## Verifies regular sign cadence can be disabled without clearing live roadside signs that already spawned.
func test_regular_sign_spawning_when_disabled_then_existing_signs_stay_and_new_spawns_switch_to_scrub() -> void:
	var roadside_scenery := await _create_roadside_owner()
	roadside_scenery._distance_until_next_spawn = 1.0
	roadside_scenery.advance(2.0)

	var live_signs := _get_live_signs(roadside_scenery)
	assert_eq(live_signs.size(), 1)

	roadside_scenery.set_regular_sign_spawning_enabled(false)
	roadside_scenery._distance_since_last_sign = roadside_scenery.SIGN_DISTANCE_INTERVAL
	roadside_scenery._scrub_spawns_since_last_sign = roadside_scenery.MIN_SCRUB_SPAWNS_BETWEEN_SIGNS
	roadside_scenery._distance_until_next_spawn = 1.0
	roadside_scenery.advance(2.0)

	live_signs = _get_live_signs(roadside_scenery)
	assert_eq(live_signs.size(), 1)
	assert_eq(roadside_scenery.get_child_count(), 2)
	assert_eq(
		roadside_scenery.get_child(1).get_meta("scenery_type", &""),
		roadside_scenery.SCENERY_TYPE_SCRUB
	)


## Verifies the forced finish-sign path creates one deterministic right-side sign and never duplicates it.
func test_forced_finish_sign_when_spawned_then_one_right_side_sign_appears_without_duplicates() -> void:
	var roadside_scenery := await _create_roadside_owner()

	roadside_scenery.spawn_forced_finish_sign()
	roadside_scenery.spawn_forced_finish_sign()

	var live_signs := _get_live_signs(roadside_scenery)
	assert_eq(live_signs.size(), 1)

	var finish_sign := live_signs[0]
	assert_eq(int(finish_sign.get_meta("roadside_side", 0)), roadside_scenery.ROADSIDE_SIDE_RIGHT)
	assert_eq(
		finish_sign.position,
		Vector2(
			float(roadside_scenery.ROADSIDE_SIDE_RIGHT) * roadside_scenery.SIGN_MARGIN_X,
			roadside_scenery.DEFAULT_SPAWN_Y
		)
	)


## Verifies a spawned roadside item stays live and keeps moving until it reaches the bottom cleanup boundary.
func test_cleanup_area_when_spawned_scenery_is_above_bottom_boundary_then_item_stays_live_without_resetting() -> void:
	var roadside_scenery := await _create_roadside_owner()
	roadside_scenery._distance_until_next_spawn = 1.0
	roadside_scenery.advance(2.0)

	assert_eq(roadside_scenery.get_child_count(), 1)
	var spawned_scenery := roadside_scenery.get_child(0) as Area2D
	assert_not_null(spawned_scenery)
	var spawn_sequence_id := int(spawned_scenery.get_meta("spawn_sequence_id", -1))
	var spawned_y := spawned_scenery.position.y

	roadside_scenery._distance_until_next_spawn = 100000.0
	roadside_scenery.advance(300.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await wait_process_frames(1)

	var persisted_scenery := _find_spawned_scenery_by_spawn_sequence_id(roadside_scenery, spawn_sequence_id)
	assert_not_null(persisted_scenery)
	assert_eq(persisted_scenery, spawned_scenery)
	assert_true(persisted_scenery.position.y > spawned_y)


## Verifies spawned scenery is removed only after entering the cleanup boundary.
func test_cleanup_area_when_spawned_scenery_reaches_bottom_boundary_then_item_is_freed() -> void:
	var roadside_scenery := await _create_roadside_owner()
	roadside_scenery._distance_until_next_spawn = 1.0
	roadside_scenery.advance(2.0)

	assert_eq(roadside_scenery.get_child_count(), 1)
	var spawned_scenery := roadside_scenery.get_child(0) as Area2D
	assert_not_null(spawned_scenery)
	var spawn_sequence_id := int(spawned_scenery.get_meta("spawn_sequence_id", -1))

	roadside_scenery._distance_until_next_spawn = 100000.0
	roadside_scenery.advance(560.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await wait_process_frames(1)

	assert_eq(roadside_scenery.get_child_count(), 0)
	assert_eq(_find_spawned_scenery_by_spawn_sequence_id(roadside_scenery, spawn_sequence_id), null)
