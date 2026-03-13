extends GutTest

const APP_ROOT_SCENE := preload("res://Scenes/AppRoot/AppRoot.tscn")


func test_app_root_bootstraps_run_state_and_run_scene() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	add_child_autofree(app_root)
	await wait_process_frames(1)

	assert_not_null(app_root.run_state)
	assert_not_null(app_root.get_node_or_null("RunScene"))
	assert_eq(app_root.starting_distance, 500.0)
	assert_eq(app_root.run_state.route_distance, 500.0)
	assert_true(app_root.run_state.distance_remaining <= 500.0)
	assert_true(app_root.run_state.distance_remaining >= 0.0)
