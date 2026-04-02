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


## Captures the current spawned roadside stream as ordered y/type/roadside-side tuples for comparison.
func _snapshot_scenery(roadside_scenery: RoadsideSceneryType) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for child in roadside_scenery.get_children():
		var scenery := child as Area2D
		if scenery == null:
			continue

		snapshot.append({
			"y": scenery.position.y,
			"type": scenery.get_meta("scenery_type", &""),
			"roadside_side": scenery.get_meta("roadside_side", 0),
		})

	snapshot.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["y"]) < float(b["y"])
	)
	return snapshot


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


## Verifies spawned scenery is removed only after entering the cleanup boundary.
func test_cleanup_area_when_spawned_scenery_reaches_bottom_boundary_then_item_is_freed() -> void:
	var roadside_scenery := await _create_roadside_owner()
	roadside_scenery._distance_until_next_spawn = 1.0
	roadside_scenery.advance(2.0)

	assert_eq(roadside_scenery.get_child_count(), 1)

	roadside_scenery._distance_until_next_spawn = 100000.0
	roadside_scenery.advance(560.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await wait_process_frames(1)

	assert_eq(roadside_scenery.get_child_count(), 0)
