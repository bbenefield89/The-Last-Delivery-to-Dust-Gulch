extends GutTest

const HazardSpawnerType := preload("res://Scripts/Hazards/hazard_spawner.gd")


func test_advance_spawns_pattern_entries_with_lane_and_type_metadata() -> void:
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	await wait_process_frames(1)

	spawner.advance(500.0)

	var hazard: Polygon2D = spawner.get_child(0)
	assert_eq(hazard.get_meta("hazard_type"), &"pothole")
	assert_eq(hazard.get_meta("lane_index"), 1)
	assert_eq(hazard.position.x, 0.0)


func test_advance_cycles_through_multiple_hazard_types() -> void:
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	await wait_process_frames(1)

	spawner.advance(1500.0)

	var spawned_types: Array[StringName] = []
	for child in spawner.get_children():
		if child is Polygon2D:
			spawned_types.append(child.get_meta("hazard_type"))

	assert_true(spawned_types.has(&"pothole"))
	assert_true(spawned_types.has(&"rock"))
	assert_true(spawned_types.has(&"tumbleweed"))


func test_each_hazard_type_has_a_distinct_readable_shape() -> void:
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	await wait_process_frames(1)

	var pothole := spawner._build_hazard_visual(&"pothole")
	var rock := spawner._build_hazard_visual(&"rock")
	var tumbleweed := spawner._build_hazard_visual(&"tumbleweed")
	autofree(pothole)
	autofree(rock)
	autofree(tumbleweed)

	assert_ne(pothole.polygon, rock.polygon)
	assert_ne(rock.polygon, tumbleweed.polygon)
	assert_ne(pothole.polygon, tumbleweed.polygon)


func test_advance_removes_hazards_after_they_leave_the_screen() -> void:
	var spawner := HazardSpawnerType.new()
	add_child_autofree(spawner)
	await wait_process_frames(1)

	spawner.advance(500.0)

	for child in spawner.get_children():
		if child is Polygon2D:
			child.position.y = 1200.0

	spawner._cleanup_hazards()
	await wait_process_frames(1)

	assert_eq(spawner.get_child_count(), 0)
