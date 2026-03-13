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
