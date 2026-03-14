extends GutTest

const APP_ROOT_SCENE := preload("res://Scenes/AppRoot/AppRoot.tscn")


func test_app_root_starts_on_title_screen() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)

	assert_not_null(app_root._title_screen)
	assert_null(app_root.run_state)
	assert_null(app_root._run_scene)


func test_app_root_play_from_title_bootstraps_run_state_and_run_scene() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)

	app_root._title_screen._on_play_pressed()
	await wait_process_frames(1)

	assert_not_null(app_root.run_state)
	assert_not_null(app_root._run_scene)
	assert_null(app_root._title_screen)
	assert_eq(app_root.run_state.route_distance, app_root.starting_distance)
	assert_true(app_root.run_state.distance_remaining <= app_root.starting_distance)
	assert_true(app_root.run_state.distance_remaining >= 0.0)


func test_app_root_restart_rebuilds_run_state_for_completed_run() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)
	app_root._title_screen._on_play_pressed()
	await wait_process_frames(1)

	var original_run_state = app_root.run_state
	var original_run_scene = app_root._run_scene
	app_root.run_state.result = &"collapsed"
	app_root.run_state.distance_remaining = 0.0

	var event := InputEventAction.new()
	event.action = "restart_run"
	event.pressed = true
	app_root._unhandled_input(event)
	await wait_process_frames(1)

	assert_ne(app_root.run_state, original_run_state)
	assert_ne(app_root._run_scene, original_run_scene)
	assert_eq(app_root.run_state.result, &"in_progress")
	assert_eq(app_root.run_state.route_distance, app_root.starting_distance)
	assert_true(app_root.run_state.distance_remaining <= app_root.starting_distance)


func test_app_root_quit_request_is_wired_from_title_screen() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)

	app_root._title_screen._on_quit_pressed()

	assert_true(app_root._quit_requested)


func test_app_root_return_to_title_rebuilds_title_after_success() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)
	app_root._title_screen._on_play_pressed()
	await wait_process_frames(1)

	app_root.run_state.result = &"success"
	app_root._run_scene._on_result_return_to_title_pressed()
	await wait_process_frames(1)

	assert_not_null(app_root._title_screen)
	assert_null(app_root.run_state)
	assert_null(app_root._run_scene)
