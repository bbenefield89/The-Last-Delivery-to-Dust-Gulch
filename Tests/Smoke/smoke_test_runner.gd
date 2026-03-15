extends SceneTree

const APP_ROOT_SCENE := preload("res://Scenes/AppRoot/AppRoot.tscn")
const RUN_STATE_SCRIPT := preload("res://Scripts/RunState/run_state.gd")


func _click_control(control: Control) -> void:
	var center := control.get_global_rect().get_center()

	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	Input.parse_input_event(motion)
	await process_frame

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	press.global_position = center
	Input.parse_input_event(press)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	release.global_position = center
	Input.parse_input_event(release)
	await process_frame


func _wait_for_ui_click(control_owner: Node) -> void:
	var ui_click_player := control_owner.get_node_or_null("%UIClickPlayer") as AudioStreamPlayer
	if ui_click_player == null or ui_click_player.stream == null:
		return
	await create_timer(ui_click_player.stream.get_length()).timeout


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	app_root.allow_quit = false
	get_root().add_child(app_root)
	await process_frame

	if not _assert_title_screen(app_root):
		return
	if not await _start_run_from_title(app_root):
		return
	if not await _assert_bootstrap(app_root):
		return
	if not await _assert_pause_path(app_root):
		return
	if not await _assert_pause_restart_path(app_root):
		return
	if not await _assert_pause_return_to_title_path(app_root):
		return
	if not await _start_run_from_title(app_root):
		return
	if not await _assert_bootstrap(app_root):
		return
	if not await _assert_success_path(app_root):
		return
	if not await _assert_restart_path(app_root, "success"):
		return
	if not await _assert_return_to_title_path(app_root, "success"):
		return
	if not await _start_run_from_title(app_root):
		return
	if not await _assert_collapse_path(app_root):
		return
	if not await _assert_restart_path(app_root, "collapse"):
		return
	if not await _assert_return_to_title_path(app_root, "collapse"):
		return

	print("Smoke test passed: title, boot, pause, success, collapse, and restart paths are healthy.")
	quit(0)


func _assert_title_screen(app_root: Node) -> bool:
	if not is_instance_valid(app_root._title_screen):
		push_error("Smoke test failed: AppRoot did not start on the title screen.")
		quit(1)
		return false
	if app_root.run_state != null:
		push_error("Smoke test failed: run state existed before starting from title.")
		quit(1)
		return false
	return true


func _start_run_from_title(app_root: Node) -> bool:
	await app_root._title_screen._on_play_pressed()
	await _dismiss_onboarding(app_root._run_scene)
	return true


func _assert_bootstrap(app_root: Node) -> bool:
	if app_root.run_state == null:
		push_error("Smoke test failed: AppRoot did not create a run state.")
		quit(1)
		return false

	if not is_instance_valid(app_root._run_scene):
		push_error("Smoke test failed: AppRoot did not add the run scene.")
		quit(1)
		return false
		
	await _dismiss_onboarding(app_root._run_scene)
	return true


func _dismiss_onboarding(run_scene: Node) -> void:
	if run_scene == null or not run_scene.has_method("_input") or not run_scene._onboarding_active:
		return

	var event := InputEventAction.new()
	event.action = &"steer_left"
	event.pressed = true
	run_scene._input(event)
	await process_frame


func _assert_success_path(app_root: Node) -> bool:
	var run_scene = app_root._run_scene
	app_root.run_state.distance_remaining = 0.0
	run_scene._process(0.0)
	await process_frame

	var result_panel: PanelContainer = run_scene.get_node("%ResultPanel")
	var result_title: Label = run_scene.get_node("%ResultTitle")
	var recovery_panel: PanelContainer = run_scene.get_node("%RecoveryPanel")
	if app_root.run_state.result != RUN_STATE_SCRIPT.RESULT_SUCCESS:
		push_error("Smoke test failed: forced success did not set success result.")
		quit(1)
		return false
	if not result_panel.visible or result_title.text != "Delivered to Dust Gulch":
		push_error("Smoke test failed: success overlay was not visible and readable.")
		quit(1)
		return false
	if recovery_panel.visible:
		push_error("Smoke test failed: recovery panel remained visible after success.")
		quit(1)
		return false
	return true


func _assert_pause_path(app_root: Node) -> bool:
	var run_scene = app_root._run_scene
	run_scene._set_pause_state(true)
	await process_frame

	var pause_overlay: Control = run_scene.get_node("%PauseOverlay")
	var pause_panel: PanelContainer = run_scene.get_node("%PausePanel")
	var resume_button: Button = run_scene.get_node("%PauseResumeButton")
	if not run_scene._pause_menu_open:
		push_error("Smoke test failed: pause menu did not enter paused gameplay state.")
		quit(1)
		return false
	if not pause_overlay.visible:
		push_error("Smoke test failed: pause overlay did not appear.")
		quit(1)
		return false
	if not pause_panel.visible:
		push_error("Smoke test failed: pause panel did not appear.")
		quit(1)
		return false

	await _click_control(resume_button)
	if run_scene._pause_menu_open:
		push_error("Smoke test failed: resume did not close the pause state.")
		quit(1)
		return false
	if pause_panel.visible:
		push_error("Smoke test failed: pause panel stayed visible after resume.")
		quit(1)
		return false
	return true


func _assert_pause_restart_path(app_root: Node) -> bool:
	var prior_run_state = app_root.run_state
	var prior_run_scene = app_root._run_scene
	var run_scene = app_root._run_scene
	run_scene._set_pause_state(true)
	await process_frame

	var restart_button: Button = run_scene.get_node("%PauseRestartButton")
	await _click_control(restart_button)
	await _wait_for_ui_click(run_scene)
	await process_frame
	await process_frame

	if app_root.run_state == prior_run_state:
		push_error("Smoke test failed: pause-menu restart did not rebuild run state.")
		quit(1)
		return false
	if app_root._run_scene == prior_run_scene:
		push_error("Smoke test failed: pause-menu restart did not rebuild run scene.")
		quit(1)
		return false
	if app_root.run_state.result != RUN_STATE_SCRIPT.RESULT_IN_PROGRESS:
		push_error("Smoke test failed: pause-menu restart did not return to in-progress state.")
		quit(1)
		return false
	return await _assert_bootstrap(app_root)


func _assert_pause_return_to_title_path(app_root: Node) -> bool:
	var run_scene = app_root._run_scene
	run_scene._set_pause_state(true)
	await process_frame

	var return_button: Button = run_scene.get_node("%PauseReturnButton")
	await _click_control(return_button)
	await _wait_for_ui_click(run_scene)
	await process_frame
	await process_frame

	if not is_instance_valid(app_root._title_screen):
		push_error("Smoke test failed: pause-menu title return did not show the title screen.")
		quit(1)
		return false
	if app_root.run_state != null:
		push_error("Smoke test failed: pause-menu title return left run state alive.")
		quit(1)
		return false
	if app_root._run_scene != null:
		push_error("Smoke test failed: pause-menu title return left run scene alive.")
		quit(1)
		return false
	return true


func _assert_collapse_path(app_root: Node) -> bool:
	var run_scene = app_root._run_scene
	app_root.run_state.start_failure(&"wheel_loose", &"rock")
	run_scene._advance_failure_triggers(0.0)
	app_root.run_state.wagon_health = 0
	run_scene._process(0.0)
	await process_frame

	var result_panel: PanelContainer = run_scene.get_node("%ResultPanel")
	var result_title: Label = run_scene.get_node("%ResultTitle")
	var recovery_panel: PanelContainer = run_scene.get_node("%RecoveryPanel")
	if app_root.run_state.result != RUN_STATE_SCRIPT.RESULT_COLLAPSED:
		push_error("Smoke test failed: forced collapse did not set collapsed result.")
		quit(1)
		return false
	if not result_panel.visible or result_title.text != "Wagon Collapsed":
		push_error("Smoke test failed: collapse overlay was not visible and readable.")
		quit(1)
		return false
	if recovery_panel.visible:
		push_error("Smoke test failed: recovery panel remained visible after collapse.")
		quit(1)
		return false
	return true


func _assert_restart_path(app_root: Node, label: String) -> bool:
	var prior_run_state = app_root.run_state
	var prior_run_scene = app_root._run_scene

	var event := InputEventAction.new()
	event.action = "restart_run"
	event.pressed = true
	app_root._unhandled_input(event)
	await process_frame
	await process_frame

	if app_root.run_state == prior_run_state:
		push_error("Smoke test failed: restart after %s did not rebuild run state." % label)
		quit(1)
		return false
	if app_root._run_scene == prior_run_scene:
		push_error("Smoke test failed: restart after %s did not rebuild run scene." % label)
		quit(1)
		return false
	if app_root.run_state.result != RUN_STATE_SCRIPT.RESULT_IN_PROGRESS:
		push_error("Smoke test failed: restart after %s did not return to in-progress state." % label)
		quit(1)
		return false

	return await _assert_bootstrap(app_root)


func _assert_return_to_title_path(app_root: Node, label: String) -> bool:
	var run_scene = app_root._run_scene
	await run_scene._on_result_return_to_title_pressed()
	await process_frame
	await process_frame

	if not is_instance_valid(app_root._title_screen):
		push_error("Smoke test failed: return to title after %s did not show the title screen." % label)
		quit(1)
		return false
	if app_root.run_state != null:
		push_error("Smoke test failed: return to title after %s left run state alive." % label)
		quit(1)
		return false
	if app_root._run_scene != null:
		push_error("Smoke test failed: return to title after %s left run scene alive." % label)
		quit(1)
		return false
	return true
