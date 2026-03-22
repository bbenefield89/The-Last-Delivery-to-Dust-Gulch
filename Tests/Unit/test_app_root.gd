extends GutTest

const APP_ROOT_SCENE := preload("res://Scenes/AppRoot/AppRoot.tscn")


## Sends a keyboard key press and release through the input pipeline for loop tests.
func _send_key_input(keycode_value: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode_value
	press.physical_keycode = keycode_value
	press.pressed = true
	Input.parse_input_event(press)
	await wait_process_frames(1)

	var release := InputEventKey.new()
	release.keycode = keycode_value
	release.physical_keycode = keycode_value
	release.pressed = false
	Input.parse_input_event(release)
	await wait_process_frames(1)


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

	await app_root._title_screen._on_play_pressed()
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
	await app_root._title_screen._on_play_pressed()
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
	assert_true(app_root._run_scene.has_node("World/Wagon/CarriageSprite"))
	var carriage_sprite := app_root._run_scene.get_node(
		"World/Wagon/CarriageSprite"
	) as AnimatedSprite2D
	var shadow_sprite := app_root._run_scene.get_node(
		"World/Wagon/Shadow"
	) as AnimatedSprite2D
	assert_not_null(carriage_sprite)
	assert_not_null(shadow_sprite)
	assert_not_null(carriage_sprite.sprite_frames)
	assert_not_null(shadow_sprite.sprite_frames)
	assert_true(carriage_sprite.sprite_frames.has_animation("default"))
	assert_true(shadow_sprite.sprite_frames.has_animation("default"))
	assert_true(carriage_sprite.is_playing())
	assert_true(shadow_sprite.is_playing())


func test_app_root_quit_request_is_wired_from_title_screen() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)

	await app_root._title_screen._on_quit_pressed()

	assert_true(app_root._quit_requested)


## Verifies the keyboard-only loop can restart the run from the result screen.
func test_app_root_when_keyboard_only_loop_reaches_result_then_restart_starts_new_run() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)

	var title_click_player: AudioStreamPlayer = app_root._title_screen.get_node("UIClickPlayer")
	title_click_player.stream = null
	await _send_key_input(KEY_ENTER)
	await wait_process_frames(1)

	var original_run_state = app_root.run_state
	var original_run_scene = app_root._run_scene
	var result_click_player: AudioStreamPlayer = app_root._run_scene.get_node("%UIClickPlayer")
	result_click_player.stream = null
	app_root.run_state.result = &"success"
	app_root._run_scene._refresh_result_screen()
	await wait_process_frames(1)

	var restart_button: Button = app_root._run_scene.get_node(
		"ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton"
	)
	assert_true(restart_button.has_focus())

	await _send_key_input(KEY_ENTER)
	await wait_process_frames(1)

	assert_ne(app_root.run_state, original_run_state)
	assert_ne(app_root._run_scene, original_run_scene)
	assert_eq(app_root.run_state.result, &"in_progress")


## Verifies the keyboard-only loop can return to title from the result screen.
func test_app_root_when_keyboard_only_loop_reaches_result_then_return_goes_back_to_title() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)

	var title_click_player: AudioStreamPlayer = app_root._title_screen.get_node("UIClickPlayer")
	title_click_player.stream = null
	await _send_key_input(KEY_ENTER)
	await wait_process_frames(1)

	var result_click_player: AudioStreamPlayer = app_root._run_scene.get_node("%UIClickPlayer")
	result_click_player.stream = null
	app_root.run_state.result = &"success"
	app_root._run_scene._refresh_result_screen()
	await wait_process_frames(1)
	await _send_key_input(KEY_RIGHT)
	await _send_key_input(KEY_ENTER)
	await wait_process_frames(1)

	assert_not_null(app_root._title_screen)
	assert_null(app_root.run_state)
	assert_null(app_root._run_scene)


func test_app_root_return_to_title_rebuilds_title_after_success() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)
	await app_root._title_screen._on_play_pressed()
	await wait_process_frames(1)

	app_root.run_state.result = &"success"
	await app_root._run_scene._on_result_return_to_title_pressed()
	await wait_process_frames(1)

	assert_not_null(app_root._title_screen)
	assert_null(app_root.run_state)
	assert_null(app_root._run_scene)


## Verifies a new run started after returning to title still wires the animated carriage rig.
func test_app_root_when_returning_to_title_then_starting_again_keeps_animated_carriage_rig() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)
	await app_root._title_screen._on_play_pressed()
	await wait_process_frames(1)

	app_root.run_state.result = &"success"
	await app_root._run_scene._on_result_return_to_title_pressed()
	await wait_process_frames(1)

	await app_root._title_screen._on_play_pressed()
	await wait_process_frames(1)

	assert_not_null(app_root._run_scene)
	var carriage_sprite := app_root._run_scene.get_node(
		"World/Wagon/CarriageSprite"
	) as AnimatedSprite2D
	var shadow_sprite := app_root._run_scene.get_node(
		"World/Wagon/Shadow"
	) as AnimatedSprite2D
	assert_not_null(carriage_sprite)
	assert_not_null(shadow_sprite)
	assert_not_null(carriage_sprite.sprite_frames)
	assert_not_null(shadow_sprite.sprite_frames)
	assert_true(carriage_sprite.sprite_frames.has_animation("default"))
	assert_true(shadow_sprite.sprite_frames.has_animation("default"))
	assert_true(carriage_sprite.is_playing())
	assert_true(shadow_sprite.is_playing())


func test_app_root_clears_tree_pause_when_restarting_or_returning_to_title() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	add_child_autofree(app_root)
	await wait_process_frames(1)
	await app_root._title_screen._on_play_pressed()
	await wait_process_frames(1)

	get_tree().paused = true
	app_root._start_new_run()
	assert_false(get_tree().paused)

	get_tree().paused = true
	app_root._show_title_screen()
	assert_false(get_tree().paused)
