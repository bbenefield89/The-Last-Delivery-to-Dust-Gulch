extends GutTest

const RUN_SCENE := preload("res://Scenes/RunScene/RunScene.tscn")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")


func test_setup_populates_status_label_with_run_state_values() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = 876.0
	state.wagon_health = 77
	state.current_speed = 345.0
	state.lateral_position = 12.0
	scene.setup(state)

	var status_label: Label = scene.get_node("%StatusLabel")
	assert_string_contains(status_label.text, "Distance: 876")
	assert_string_contains(status_label.text, "Health: 77")
	assert_string_contains(status_label.text, "Speed: 345")
	assert_string_contains(status_label.text, "Lane offset: 12")


func test_ready_registers_steering_input_actions() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_true(InputMap.has_action("steer_left"))
	assert_true(InputMap.has_action("steer_right"))


func test_process_moves_right_and_reduces_distance() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	Input.action_press("steer_right")
	scene._process(0.5)
	Input.action_release("steer_right")

	assert_almost_eq(state.lateral_position, 150.0, 0.01)
	assert_almost_eq(state.distance_remaining, 860.0, 0.01)


func test_process_clamps_lateral_position_to_road_bounds() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.lateral_position = 210.0
	scene.setup(state)

	Input.action_press("steer_right")
	scene._process(1.0)
	Input.action_release("steer_right")

	assert_eq(state.lateral_position, 220.0)


func test_hazard_collision_reduces_health_and_records_last_hit_type() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var spawner = scene.get_node("%HazardSpawner")
	spawner.advance(500.0)
	var hazard: Polygon2D = spawner.get_child(0)
	for i in range(1, spawner.get_child_count()):
		spawner.get_child(i).queue_free()
	hazard.position = Vector2(0.0, 0.0)
	await wait_process_frames(1)
	scene._process(0.0)
	await wait_process_frames(1)

	assert_eq(state.wagon_health, 90)
	assert_eq(state.last_hit_hazard, &"pothole")


func test_camera_tracks_wagon_with_below_center_offset() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.lateral_position = -80.0
	scene.setup(state)
	scene._process(0.0)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	var camera: Camera2D = scene.get_node("%Camera")

	assert_eq(wagon.position, Vector2(-80.0, 0.0))
	assert_eq(camera.position, Vector2(0.0, -260.0))


func test_forward_motion_scrolls_the_environment() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	scene._process(0.5)

	var segment_a: Node2D = scene.get_node("%ScrollSegmentA")
	var segment_b: Node2D = scene.get_node("%ScrollSegmentB")
	assert_almost_eq(segment_a.position.y, 140.0, 0.01)
	assert_almost_eq(segment_b.position.y, -2740.0, 0.01)


func test_scroll_environment_wraps_for_continuous_travel() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.current_speed = 3000.0
	scene.setup(state)
	scene._process(1.0)

	var segment_a: Node2D = scene.get_node("%ScrollSegmentA")
	var segment_b: Node2D = scene.get_node("%ScrollSegmentB")
	assert_almost_eq(segment_a.position.y, 120.0, 0.01)
	assert_almost_eq(segment_b.position.y, -2760.0, 0.01)


func test_scroll_segment_populates_enough_roadside_scrub_to_cover_loop_end() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var segment_a: Node2D = scene.get_node("%ScrollSegmentA")
	var left_scrub_positions: Array[float] = []

	for child in segment_a.get_children():
		if child is Polygon2D and child.color == Color(0.47451, 0.443137, 0.219608, 0.95) and child.scale.x > 0.0:
			left_scrub_positions.append(child.position.y)

	left_scrub_positions.sort()
	assert_true(left_scrub_positions.size() >= 10)
	assert_true(left_scrub_positions.back() >= 0.0)


func test_scroll_segment_populates_enough_center_dashes_to_cover_loop_end() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var segment_a: Node2D = scene.get_node("%ScrollSegmentA")
	var dash_positions: Array[float] = []

	for child in segment_a.get_children():
		if child is Polygon2D and child.color == Color(0.886275, 0.811765, 0.572549, 0.8):
			dash_positions.append(child.position.y)

	dash_positions.sort()
	assert_true(dash_positions.size() >= 13)
	assert_true(dash_positions.back() >= 0.0)
