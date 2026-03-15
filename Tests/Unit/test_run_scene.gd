extends GutTest

const RUN_SCENE := preload("res://Scenes/RunScene/RunScene.tscn")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")


func _dismiss_onboarding(scene: Node) -> void:
	var dismiss_event := InputEventAction.new()
	dismiss_event.action = &"steer_left"
	dismiss_event.pressed = true
	scene._input(dismiss_event)


func _setup_active_run(scene: Node, state: RunStateType) -> void:
	scene.setup(state)
	_dismiss_onboarding(scene)


func _click_control(control: Control) -> void:
	var center := control.get_global_rect().get_center()

	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	Input.parse_input_event(motion)
	await wait_process_frames(1)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	press.global_position = center
	Input.parse_input_event(press)
	await wait_process_frames(1)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	release.global_position = center
	Input.parse_input_event(release)
	await wait_process_frames(1)


func test_setup_populates_hud_labels_with_run_state_values() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = 876.0
	state.wagon_health = 77
	state.cargo_value = 63
	state.current_speed = 345.0
	state.lateral_position = 12.0
	state.active_failure = &"wheel_loose"
	scene.setup(state)

	var health_label: Label = scene.get_node("%HealthLabel")
	var cargo_label: Label = scene.get_node("%CargoLabel")
	var speed_label: Label = scene.get_node("%SpeedLabel")
	var progress_label: Label = scene.get_node("%ProgressLabel")
	var progress_bar: ProgressBar = scene.get_node("%ProgressBar")
	assert_eq(health_label.text, "Health: 77")
	assert_eq(cargo_label.text, "Cargo: 63")
	assert_eq(speed_label.text, "Speed: 345")
	assert_eq(progress_label.text, "Distance: 876 / 500")
	assert_almost_eq(progress_bar.value, 0.0, 0.01)
	assert_false(scene.has_node("%OutcomeLabel"))


func test_setup_shows_onboarding_panel_at_run_start() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var onboarding_panel: PanelContainer = scene.get_node("%OnboardingPanel")
	var onboarding_title: Label = scene.get_node("%OnboardingTitle")
	assert_true(scene._onboarding_active)
	assert_true(onboarding_panel.visible)
	assert_eq(onboarding_title.text, scene.ONBOARDING_TITLE)


func test_onboarding_freezes_distance_and_hazard_spawning_while_road_scrolls() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	var starting_distance := state.distance_remaining
	var starting_scroll: float = scene._scroll_offset

	scene._process(0.5)

	var spawner = scene.get_node("%HazardSpawner")
	assert_eq(state.distance_remaining, starting_distance)
	assert_eq(spawner.get_child_count(), 0)
	assert_true(scene._scroll_offset > starting_scroll)


func test_dismissing_onboarding_with_steer_input_starts_normal_gameplay() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	var dismiss_event := InputEventAction.new()
	dismiss_event.action = &"steer_left"
	dismiss_event.pressed = true
	scene._input(dismiss_event)

	var distance_before_process := state.distance_remaining
	scene._process(2.0)

	var onboarding_panel: PanelContainer = scene.get_node("%OnboardingPanel")
	var spawner = scene.get_node("%HazardSpawner")
	assert_false(scene._onboarding_active)
	assert_false(onboarding_panel.visible)
	assert_true(state.distance_remaining < distance_before_process)
	assert_true(spawner.get_child_count() > 0)


func test_ready_registers_steering_input_actions() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_true(InputMap.has_action("steer_left"))
	assert_true(InputMap.has_action("steer_right"))
	assert_true(InputMap.has_action("pause_run"))


func test_process_moves_right_and_reduces_distance() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	Input.action_press("steer_right")
	scene._process(0.5)
	Input.action_release("steer_right")

	assert_almost_eq(state.lateral_position, 150.0, 0.01)
	assert_almost_eq(
		state.distance_remaining,
		RunStateType.DEFAULT_DISTANCE_REMAINING - (RunStateType.DEFAULT_FORWARD_SPEED * 0.5),
		0.01
	)


func test_process_clamps_lateral_position_to_road_bounds() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.lateral_position = 170.0
	_setup_active_run(scene, state)

	Input.action_press("steer_right")
	scene._process(1.0)
	Input.action_release("steer_right")

	assert_eq(state.lateral_position, 180.0)


func test_hazard_collision_reduces_health_and_records_last_hit_type() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var spawner = scene.get_node("%HazardSpawner")
	spawner.advance(540.0)
	var hazard: Polygon2D = spawner.get_child(0)
	for i in range(1, spawner.get_child_count()):
		spawner.get_child(i).queue_free()
	hazard.position = Vector2(0.0, 0.0)
	await wait_process_frames(1)
	scene._process(0.0)
	await wait_process_frames(1)

	assert_eq(state.wagon_health, 90)
	assert_eq(state.cargo_value, 96)
	assert_eq(state.last_hit_hazard, &"pothole")

	var pothole_impact_player: AudioStreamPlayer = scene.get_node("%PotholeImpactPlayer")
	var fallback_impact_player: AudioStreamPlayer = scene.get_node("%ImpactPlayer")
	assert_true(pothole_impact_player.playing)
	assert_false(fallback_impact_player.playing)


func test_hazard_collision_triggers_hit_flash_wobble_and_camera_shake() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var spawner = scene.get_node("%HazardSpawner")
	spawner.advance(540.0)
	var hazard: Polygon2D = spawner.get_child(0)
	for i in range(1, spawner.get_child_count()):
		spawner.get_child(i).queue_free()
	hazard.position = Vector2(0.0, 0.0)
	await wait_process_frames(1)
	scene._process(0.05)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	var camera: Camera2D = scene.get_node("%Camera")

	assert_eq(wagon.color, scene.WAGON_HIT_COLOR)
	assert_ne(wagon.rotation, 0.0)
	assert_ne(camera.position, Vector2(0.0, -260.0))


func test_impact_feedback_recovers_after_timers_expire() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var spawner = scene.get_node("%HazardSpawner")
	spawner.advance(540.0)
	var hazard: Polygon2D = spawner.get_child(0)
	for i in range(1, spawner.get_child_count()):
		spawner.get_child(i).queue_free()
	hazard.position = Vector2(0.0, 0.0)
	await wait_process_frames(1)
	scene._process(0.05)
	state.clear_failure()
	scene._process(0.4)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	var camera: Camera2D = scene.get_node("%Camera")

	assert_eq(wagon.color, scene.WAGON_BASE_COLOR)
	assert_eq(wagon.rotation, 0.0)
	assert_eq(camera.position, Vector2(0.0, -260.0))


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


func test_late_route_progress_spawns_more_hazard_pressure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.2
	_setup_active_run(scene, state)

	var spawner = scene.get_node("%HazardSpawner")
	scene._process(2.0)

	assert_true(spawner.get_child_count() >= 2)


func test_reaching_dust_gulch_triggers_success_and_stops_forward_motion() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = 20.0
	state.current_speed = 280.0
	_setup_active_run(scene, state)

	scene._process(0.1)

	assert_eq(state.distance_remaining, 0.0)
	assert_eq(state.result, RunStateType.RESULT_SUCCESS)
	assert_eq(state.current_speed, 0.0)


func test_success_state_freezes_progress_on_later_frames() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = 0.0
	state.current_speed = 0.0
	state.result = RunStateType.RESULT_SUCCESS
	state.lateral_position = 25.0
	scene.setup(state)

	scene._process(1.0)

	assert_eq(state.distance_remaining, 0.0)
	assert_eq(state.current_speed, 0.0)
	assert_eq(state.lateral_position, 25.0)

	var result_panel: PanelContainer = scene.get_node("%ResultPanel")
	var result_title: Label = scene.get_node("%ResultTitle")
	assert_true(result_panel.visible)
	assert_eq(result_title.text, "Delivered to Dust Gulch")


func test_zero_health_triggers_collapse_and_stops_forward_motion() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.wagon_health = 0
	state.current_speed = 280.0
	_setup_active_run(scene, state)

	scene._process(0.1)

	assert_eq(state.result, RunStateType.RESULT_COLLAPSED)
	assert_eq(state.current_speed, 0.0)

	var result_panel: PanelContainer = scene.get_node("%ResultPanel")
	var result_title: Label = scene.get_node("%ResultTitle")
	assert_true(result_panel.visible)
	assert_eq(result_title.text, "Wagon Collapsed")


func test_rock_collision_triggers_wheel_loose_failure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	scene._attempt_failure_trigger_from_collision(&"rock")

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")


func test_tumbleweed_collision_triggers_horse_panic_failure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	scene._attempt_failure_trigger_from_collision(&"tumbleweed")

	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"tumbleweed")


func test_bad_luck_timer_triggers_failure_when_no_active_failure_exists() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.2
	scene.setup(state)

	scene._advance_failure_triggers(13.0)

	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"bad_luck")


func test_bad_luck_interval_uses_tuned_fairness_values() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var early_state := RunStateType.new()
	scene.setup(early_state)
	assert_eq(scene._get_bad_luck_interval(), 13.0)

	var late_state := RunStateType.new()
	late_state.distance_remaining = late_state.route_distance * 0.1
	scene.setup(late_state)
	assert_eq(scene._get_bad_luck_interval(), 8.5)


func test_bad_luck_timer_does_not_replace_existing_failure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)

	scene._advance_failure_triggers(10.0)

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")


func test_wheel_loose_reduces_steering_authority_without_one_side_lock() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)

	Input.action_press("steer_left")
	scene._process(1.0)
	Input.action_release("steer_left")

	assert_almost_eq(state.lateral_position, -180.0, 0.01)


func test_wheel_loose_drift_oscillates_instead_of_always_pulling_right() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)

	scene._process(0.25)
	var first_position := state.lateral_position
	scene._process(0.25)
	var second_position := state.lateral_position

	assert_ne(first_position, second_position)
	assert_true(first_position != 0.0 or second_position != 0.0)


func test_wheel_loose_adds_persistent_wobble_to_wagon_visual() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)

	scene._process(0.2)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	assert_ne(wagon.rotation, 0.0)


func test_horse_panic_adds_stronger_side_to_side_instability() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	_setup_active_run(scene, state)

	scene._process(0.2)
	var first_position := state.lateral_position
	scene._process(0.2)
	var second_position := state.lateral_position

	assert_true(absf(second_position - first_position) > 10.0)


func test_horse_panic_adds_distinct_wobble_to_wagon_visual() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)

	scene._process(0.2)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	assert_ne(wagon.rotation, 0.0)


func test_collision_trigger_does_not_replace_existing_failure_type() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)

	scene._attempt_failure_trigger_from_collision(&"tumbleweed")

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")


func test_wheel_loose_starts_recovery_sequence_prompt() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)

	scene._advance_failure_triggers(0.0)

	assert_true(state.has_active_recovery_sequence())
	assert_eq(state.get_current_recovery_prompt(), &"steer_left")

	var recovery_panel: PanelContainer = scene.get_node("%RecoveryPanel")
	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	scene._refresh_recovery_prompt()

	assert_true(recovery_panel.visible)
	assert_eq(recovery_steps.get_child_count(), 3)
	assert_eq((recovery_steps.get_child(0).get_child(0) as Label).text, char(0xE020))
	assert_eq((recovery_steps.get_child(1).get_child(0) as Label).text, char(0xE022))
	assert_eq((recovery_steps.get_child(2).get_child(0) as Label).text, char(0xE020))


func test_recovery_prompt_steps_use_embedded_arrow_font() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)
	scene._advance_failure_triggers(0.0)
	scene._refresh_recovery_prompt()

	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	var arrow_label := recovery_steps.get_child(0).get_child(0) as Label
	assert_not_null(arrow_label)
	assert_eq(arrow_label.get_theme_font("font"), scene.ARROW_FONT)
	assert_eq(arrow_label.get_theme_font_size("font_size"), 52)


func test_wheel_loose_recovery_sequence_clears_failure_on_success() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	scene._advance_failure_triggers(0.0)

	var recovery_step_player: AudioStreamPlayer = scene.get_node("%RecoveryStepPlayer")
	var recovery_success_player: AudioStreamPlayer = scene.get_node("%RecoverySuccessPlayer")

	for action_name in [&"steer_left", &"steer_right", &"steer_left"]:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	assert_eq(state.active_failure, &"")
	assert_false(state.has_active_recovery_sequence())
	assert_true(recovery_step_player.playing)
	assert_eq(recovery_step_player.stream, scene.RECOVERY_STEP_SOUND)
	assert_true(recovery_success_player.playing)
	assert_eq(recovery_success_player.stream, scene.RECOVERY_SUCCESS_SOUND)


func test_recovery_prompt_advances_highlight_with_direct_input_actions() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	scene._advance_failure_triggers(0.0)

	var left_event := InputEventAction.new()
	left_event.action = &"steer_left"
	left_event.pressed = true
	scene._input(left_event)

	assert_eq(state.get_current_recovery_prompt(), &"steer_right")

	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	var first_step: PanelContainer = recovery_steps.get_child(0)
	var second_step: PanelContainer = recovery_steps.get_child(1)
	assert_eq(first_step.modulate, scene.RECOVERY_STEP_DONE_COLOR)
	assert_eq(second_step.modulate, scene.RECOVERY_STEP_ACTIVE_COLOR)


func test_recovery_step_audio_plays_on_non_final_correct_input() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	scene._advance_failure_triggers(0.0)

	var recovery_step_player: AudioStreamPlayer = scene.get_node("%RecoveryStepPlayer")
	var recovery_success_player: AudioStreamPlayer = scene.get_node("%RecoverySuccessPlayer")
	var left_event := InputEventAction.new()
	left_event.action = &"steer_left"
	left_event.pressed = true

	scene._input(left_event)

	assert_true(recovery_step_player.playing)
	assert_eq(recovery_step_player.stream, scene.RECOVERY_STEP_SOUND)
	assert_false(recovery_success_player.playing)


func test_horse_panic_starts_distinct_recovery_sequence_prompt() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)
	scene._advance_failure_triggers(0.0)

	assert_eq(state.recovery_sequence, scene.HORSE_PANIC_RECOVERY_SEQUENCE)

	var recovery_title: Label = scene.get_node("%RecoveryTitle")
	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	scene._refresh_recovery_prompt()

	assert_eq(recovery_title.text, "Horse Panic: Calm the Team")
	assert_eq(recovery_steps.get_child_count(), 4)
	assert_eq((recovery_steps.get_child(0).get_child(0) as Label).text, char(0xE020))
	assert_eq((recovery_steps.get_child(1).get_child(0) as Label).text, char(0xE022))
	assert_eq((recovery_steps.get_child(2).get_child(0) as Label).text, char(0xE020))
	assert_eq((recovery_steps.get_child(3).get_child(0) as Label).text, char(0xE022))


func test_horse_panic_recovery_sequence_clears_failure_on_success() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	_setup_active_run(scene, state)
	scene._advance_failure_triggers(0.0)

	for action_name in scene.HORSE_PANIC_RECOVERY_SEQUENCE:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	assert_eq(state.active_failure, &"")
	assert_false(state.has_active_recovery_sequence())


func test_wheel_loose_recovery_timeout_applies_health_and_speed_penalty() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)
	var recovery_fail_player: AudioStreamPlayer = scene.get_node("%RecoveryFailPlayer")

	scene._advance_failure_triggers(0.0)
	scene._advance_failure_triggers(scene.WHEEL_LOOSE_RECOVERY_DURATION)

	assert_eq(state.active_failure, &"")
	assert_eq(state.last_recovery_outcome, &"failure")
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH - scene.WHEEL_LOOSE_FAILURE_HEALTH_LOSS)
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE - scene.WHEEL_LOOSE_FAILURE_CARGO_LOSS)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED - scene.WHEEL_LOOSE_FAILURE_SPEED_LOSS)
	assert_true(state.has_temporary_control_instability())
	assert_true(recovery_fail_player.playing)
	assert_eq(recovery_fail_player.stream, scene.RECOVERY_FAIL_SOUND)


func test_horse_panic_recovery_timeout_applies_cargo_and_speed_penalty() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)

	scene._advance_failure_triggers(0.0)
	scene._advance_failure_triggers(scene.HORSE_PANIC_RECOVERY_DURATION)

	assert_eq(state.active_failure, &"")
	assert_eq(state.last_recovery_outcome, &"failure")
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE - scene.HORSE_PANIC_FAILURE_CARGO_LOSS)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED - scene.HORSE_PANIC_FAILURE_SPEED_LOSS)
	assert_true(state.has_temporary_control_instability())


func test_successful_recovery_sets_success_outcome_without_resource_penalty() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	scene._advance_failure_triggers(0.0)

	for action_name in scene.WHEEL_LOOSE_RECOVERY_SEQUENCE:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	assert_eq(state.last_recovery_outcome, &"success")
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_false(state.has_temporary_control_instability())


func test_failed_recovery_causes_temporary_control_instability_after_failure_clears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)

	scene._advance_failure_triggers(0.0)
	scene._advance_failure_triggers(scene.WHEEL_LOOSE_RECOVERY_DURATION)
	scene._process(0.17)
	scene._process(0.19)

	assert_ne(state.lateral_position, 0.0)


func test_speed_penalty_recovers_toward_default_speed_over_time() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = 10000.0
	state.current_speed = 150.0
	_setup_active_run(scene, state)

	scene._process(1.0)

	assert_eq(state.current_speed, 190.0)
	scene._process(3.0)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)


func test_recovery_outcome_message_and_cooldown_clear_after_post_failure_window() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	scene._advance_failure_triggers(0.0)
	scene._advance_failure_triggers(scene.WHEEL_LOOSE_RECOVERY_DURATION)

	scene._process(3.0)
	scene._refresh_status()

	assert_eq(state.last_recovery_outcome, &"")
	assert_eq(state.recovery_cooldown_remaining, 0.0)


func test_progress_bar_tracks_delivery_completion_ratio() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = 125.0
	scene.setup(state)

	var progress_bar: ProgressBar = scene.get_node("%ProgressBar")
	assert_almost_eq(progress_bar.value, 75.0, 0.01)


func test_temporary_instability_resolves_back_to_normal_driving() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = 10000.0
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	scene._advance_failure_triggers(0.0)
	scene._advance_failure_triggers(scene.WHEEL_LOOSE_RECOVERY_DURATION)
	scene._process(0.2)
	scene._process(3.0)

	var lateral_before := state.lateral_position
	scene._process(0.2)
	var lateral_after := state.lateral_position
	var wagon: Polygon2D = scene.get_node("%Wagon")

	assert_eq(state.temporary_control_instability_remaining, 0.0)
	assert_almost_eq(lateral_after - lateral_before, 0.0, 0.01)
	assert_eq(wagon.rotation, 0.0)


func test_recovery_panel_title_shows_active_failure_warning() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)
	scene._advance_failure_triggers(0.0)
	scene._refresh_recovery_prompt()

	var recovery_title: Label = scene.get_node("%RecoveryTitle")
	var recovery_hint: Label = scene.get_node("%RecoveryHint")
	assert_string_contains(recovery_title.text, "Wheel Loose")
	assert_string_contains(recovery_hint.text, "lock the wheel")


func test_no_persistent_failure_banner_exists_in_scene() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_false(scene.has_node("%FailureBanner"))


func test_recovery_hint_matches_active_failure_type() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)
	scene._advance_failure_triggers(0.0)
	scene._refresh_recovery_prompt()

	var recovery_hint: Label = scene.get_node("%RecoveryHint")
	assert_string_contains(recovery_hint.text, "left-right pattern")


func test_result_panel_stays_hidden_during_active_run() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	scene._refresh_result_screen()

	var result_panel: PanelContainer = scene.get_node("%ResultPanel")
	assert_false(result_panel.visible)


func test_result_panel_includes_small_stats_summary() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.cargo_value = 72
	state.wagon_health = 41
	state.current_speed = 0.0
	scene.setup(state)
	scene._refresh_result_screen()

	var result_stats: Label = scene.get_node("%ResultStats")
	assert_string_contains(result_stats.text, "Health: 41")
	assert_string_contains(result_stats.text, "Cargo: 72")
	assert_string_contains(result_stats.text, "Distance traveled: 500 / 500")
	assert_false(result_stats.text.contains("Speed:"))

	var restart_button: Button = scene.get_node("ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton")
	var return_button: Button = scene.get_node("ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultReturnButton")
	assert_eq(restart_button.text, "Restart")
	assert_eq(return_button.text, "Title")


func test_result_panel_buttons_emit_restart_and_return_signals() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	watch_signals(scene)
	var ui_click_player: AudioStreamPlayer = scene.get_node("%UIClickPlayer")
	var restart_button: Button = scene.get_node(
		"ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton"
	)
	var return_button: Button = scene.get_node(
		"ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultReturnButton"
	)
	restart_button.pressed.emit()
	assert_true(ui_click_player.playing)
	assert_eq(ui_click_player.stream, scene.UI_CLICK_SOUND)
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout
	return_button.pressed.emit()
	assert_true(ui_click_player.playing)
	assert_eq(ui_click_player.stream, scene.UI_CLICK_SOUND)
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout

	assert_signal_emitted(scene, "restart_requested")
	assert_signal_emitted(scene, "return_to_title_requested")


func test_pause_menu_toggles_tree_pause_and_visibility() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	scene._set_pause_state(true)
	await wait_process_frames(1)
	var pause_overlay: Control = scene.get_node("%PauseOverlay")
	var pause_panel: PanelContainer = scene.get_node("%PausePanel")
	var resume_button: Button = scene.get_node("%PauseResumeButton")
	var pause_toggle_player: AudioStreamPlayer = scene.get_node("%PauseTogglePlayer")
	assert_true(scene._pause_menu_open)
	assert_false(get_tree().paused)
	assert_true(pause_overlay.visible)
	assert_true(pause_panel.visible)
	assert_eq(pause_overlay.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_false(resume_button.has_focus())
	assert_true(pause_toggle_player.playing)
	assert_eq(pause_toggle_player.stream, scene.PAUSE_TOGGLE_SOUND)

	pause_toggle_player.stop()
	scene._set_pause_state(false)
	assert_false(scene._pause_menu_open)
	assert_false(get_tree().paused)
	assert_false(pause_overlay.visible)
	assert_false(pause_panel.visible)
	assert_eq(pause_panel.process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_true(pause_toggle_player.playing)


func test_pause_menu_buttons_emit_restart_and_return_after_unpausing() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	scene._set_pause_state(true)
	await wait_process_frames(1)
	watch_signals(scene)
	var restart_button: Button = scene.get_node("%PauseRestartButton")
	var return_button: Button = scene.get_node("%PauseReturnButton")

	await _click_control(restart_button)
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout
	assert_false(scene._pause_menu_open)
	assert_false(get_tree().paused)
	assert_signal_emitted(scene, "restart_requested")

	scene._set_pause_state(true)
	await wait_process_frames(1)
	await _click_control(return_button)
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout
	assert_false(scene._pause_menu_open)
	assert_false(get_tree().paused)
	assert_signal_emitted(scene, "return_to_title_requested")


func test_pause_resume_button_unpauses_through_button_signal() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	scene._set_pause_state(true)
	await wait_process_frames(1)

	var resume_button: Button = scene.get_node("%PauseResumeButton")
	await _click_control(resume_button)

	assert_false(scene._pause_menu_open)
	assert_false(get_tree().paused)
	var pause_panel: PanelContainer = scene.get_node("%PausePanel")
	assert_false(pause_panel.visible)


func test_pause_menu_and_result_buttons_share_ui_click_sound() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	var ui_click_player: AudioStreamPlayer = scene.get_node("%UIClickPlayer")

	scene._on_pause_resume_pressed()
	assert_true(ui_click_player.playing)
	assert_eq(ui_click_player.stream, scene.UI_CLICK_SOUND)

	ui_click_player.stop()
	var restart_button: Button = scene.get_node(
		"ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton"
	)
	restart_button.pressed.emit()
	assert_true(ui_click_player.playing)
	assert_eq(ui_click_player.stream, scene.UI_CLICK_SOUND)
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout


func test_pause_menu_does_not_show_after_run_is_over() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	scene.setup(state)

	scene._set_pause_state(true)
	var pause_panel: PanelContainer = scene.get_node("%PausePanel")
	assert_false(scene._pause_menu_open)
	assert_false(get_tree().paused)
	assert_false(pause_panel.visible)


func test_recovery_panel_hides_when_run_is_over() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	state.result = RunStateType.RESULT_COLLAPSED
	scene.setup(state)
	scene._advance_failure_triggers(0.0)
	scene._refresh_recovery_prompt()

	var recovery_panel: PanelContainer = scene.get_node("%RecoveryPanel")
	assert_false(recovery_panel.visible)


func test_result_panel_is_darkened_without_full_screen_backdrop() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_false(scene.has_node("%ResultBackdrop"))

	var result_panel: PanelContainer = scene.get_node("%ResultPanel")
	var panel_style := result_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(panel_style)
	assert_eq(panel_style.bg_color, Color(0.156863, 0.101961, 0.0666667, 0.94))
	assert_eq(panel_style.border_color, Color(0.745098, 0.592157, 0.305882, 0.95))

	var result_title: Label = scene.get_node("%ResultTitle")
	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats: Label = scene.get_node("%ResultStats")
	assert_eq(result_title.get_theme_color("font_color"), Color(1, 1, 1, 1))
	assert_eq(result_summary.get_theme_color("font_color"), Color(1, 1, 1, 1))
	assert_eq(result_stats.get_theme_color("font_color"), Color(1, 1, 1, 1))


func test_step4_presentation_nodes_exist_for_dust_and_audio() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_true(scene.has_node("%DustTrail"))
	assert_true(scene.has_node("%MusicPlayer"))
	assert_true(scene.has_node("%WagonLoopPlayer"))
	assert_true(scene.has_node("%ImpactPlayer"))
	assert_true(scene.has_node("%PotholeImpactPlayer"))
	assert_true(scene.has_node("%RockImpactPlayer"))
	assert_true(scene.has_node("%TumbleweedImpactPlayer"))
	assert_true(scene.has_node("%WheelLooseAmbientPlayer"))
	assert_true(scene.has_node("%HorsePanicAmbientPlayer"))
	assert_true(scene.has_node("%RecoveryStepPlayer"))
	assert_true(scene.has_node("%RecoverySuccessPlayer"))
	assert_true(scene.has_node("%RecoveryFailPlayer"))
	assert_true(scene.has_node("%PauseTogglePlayer"))
	assert_true(scene.has_node("%FailurePlayer"))
	assert_true(scene.has_node("%ResultPlayer"))
	assert_true(scene.has_node("%UIClickPlayer"))


func test_ready_starts_music_and_dust_presentation() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var dust_trail: CPUParticles2D = scene.get_node("%DustTrail")
	var music_player: AudioStreamPlayer = scene.get_node("%MusicPlayer")
	var wagon_loop_player: AudioStreamPlayer = scene.get_node("%WagonLoopPlayer")
	assert_true(dust_trail.emitting)
	assert_true(music_player.playing)
	assert_eq(music_player.stream, scene.BACKGROUND_MUSIC)
	assert_true(wagon_loop_player.playing)
	assert_eq(wagon_loop_player.stream, scene.WAGON_LOOP_SOUND)
	assert_true(wagon_loop_player.get_playback_position() >= scene.WAGON_LOOP_START_SECONDS)


func test_hazard_impact_audio_dispatches_to_specific_players_and_fallback() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var pothole_impact_player: AudioStreamPlayer = scene.get_node("%PotholeImpactPlayer")
	var rock_impact_player: AudioStreamPlayer = scene.get_node("%RockImpactPlayer")
	var tumbleweed_impact_player: AudioStreamPlayer = scene.get_node("%TumbleweedImpactPlayer")
	var impact_player: AudioStreamPlayer = scene.get_node("%ImpactPlayer")

	scene._play_hazard_impact(&"pothole")
	assert_true(pothole_impact_player.playing)
	assert_eq(pothole_impact_player.stream, scene.POTHOLE_IMPACT_SOUND)

	pothole_impact_player.stop()
	scene._play_hazard_impact(&"rock")
	assert_true(rock_impact_player.playing)
	assert_eq(rock_impact_player.stream, scene.ROCK_IMPACT_SOUND)
	assert_eq(rock_impact_player.stream, scene.POTHOLE_IMPACT_SOUND)

	rock_impact_player.stop()
	scene._play_hazard_impact(&"tumbleweed")
	assert_true(tumbleweed_impact_player.playing)
	assert_eq(tumbleweed_impact_player.stream, scene.TUMBLEWEED_IMPACT_SOUND)
	await get_tree().create_timer(scene.IMPACT_SOUND.get_length() + 0.05, false).timeout
	assert_false(tumbleweed_impact_player.playing)

	tumbleweed_impact_player.stop()
	scene._play_hazard_impact(&"unknown")
	assert_true(impact_player.playing)
	assert_eq(impact_player.stream, scene.IMPACT_SOUND)
	assert_eq(impact_player.volume_db, -4.5)


func test_new_failure_plays_failure_audio_cue() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	state.start_failure(&"wheel_loose", &"rock")
	scene._refresh_audio_presentation()

	var failure_player: AudioStreamPlayer = scene.get_node("%FailurePlayer")
	assert_true(failure_player.playing)
	assert_eq(failure_player.stream, scene.HORSE_SPOOK_SOUND)


func test_failure_ambient_audio_tracks_active_failure_and_run_end() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var wheel_loose_ambient_player: AudioStreamPlayer = scene.get_node("%WheelLooseAmbientPlayer")
	var horse_panic_ambient_player: AudioStreamPlayer = scene.get_node("%HorsePanicAmbientPlayer")

	state.start_failure(&"wheel_loose", &"rock")
	scene._refresh_audio_presentation()
	assert_true(wheel_loose_ambient_player.playing)
	assert_eq(wheel_loose_ambient_player.stream, scene.WHEEL_LOOSE_AMBIENT_SOUND)
	assert_false(horse_panic_ambient_player.playing)

	state.clear_failure()
	scene._refresh_audio_presentation()
	assert_false(wheel_loose_ambient_player.playing)

	state.start_failure(&"horse_panic", &"tumbleweed")
	scene._refresh_audio_presentation()
	assert_true(horse_panic_ambient_player.playing)
	assert_eq(horse_panic_ambient_player.stream, scene.HORSE_PANIC_AMBIENT_SOUND)
	assert_false(wheel_loose_ambient_player.playing)

	state.result = RunStateType.RESULT_COLLAPSED
	scene._refresh_audio_presentation()
	assert_false(horse_panic_ambient_player.playing)


func test_success_result_stops_dust_and_plays_result_cue() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	state.result = RunStateType.RESULT_SUCCESS
	state.current_speed = 0.0
	scene._refresh_audio_presentation()

	var dust_trail: CPUParticles2D = scene.get_node("%DustTrail")
	var result_player: AudioStreamPlayer = scene.get_node("%ResultPlayer")
	var music_player: AudioStreamPlayer = scene.get_node("%MusicPlayer")
	var wagon_loop_player: AudioStreamPlayer = scene.get_node("%WagonLoopPlayer")
	assert_false(dust_trail.emitting)
	assert_true(result_player.playing)
	assert_eq(result_player.stream, scene.WIN_STINGER)
	assert_false(music_player.playing)
	assert_false(wagon_loop_player.playing)


func test_collapse_result_plays_collapse_stinger() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	state.result = RunStateType.RESULT_COLLAPSED
	state.current_speed = 0.0
	scene._refresh_audio_presentation()

	var result_player: AudioStreamPlayer = scene.get_node("%ResultPlayer")
	assert_true(result_player.playing)
	assert_eq(result_player.stream, scene.COLLAPSE_STINGER)


func test_wagon_loop_audio_wraps_back_to_five_second_mark() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var wagon_loop_player: AudioStreamPlayer = scene.get_node("%WagonLoopPlayer")
	wagon_loop_player.seek(scene.WAGON_LOOP_END_SECONDS + 0.25)
	scene._refresh_audio_presentation()

	assert_true(wagon_loop_player.get_playback_position() >= scene.WAGON_LOOP_START_SECONDS)
	assert_true(wagon_loop_player.get_playback_position() < scene.WAGON_LOOP_END_SECONDS)


func test_scroll_segment_includes_roadside_dust_gulch_sign() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var segment_a: Node2D = scene.get_node("%ScrollSegmentA")
	var sign_found := false
	for child in segment_a.get_children():
		if child.name == "RoadsideSign":
			var label := child.get_child(child.get_child_count() - 1) as Label
			if label != null and label.text == "Dust Gulch":
				sign_found = true
				break

	assert_true(sign_found)


func test_step3_cohesion_nodes_exist_on_wagon() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_true(scene.has_node("World/Wagon/Shadow"))
	assert_true(scene.has_node("World/Wagon/Canopy"))
	assert_true(scene.has_node("World/Wagon/HorseTeam/HorseLeft"))
	assert_true(scene.has_node("World/Wagon/HorseTeam/HorseRight"))


func test_step3_panel_styles_use_western_palette() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var hud_panel: PanelContainer = scene.get_node("HUDLayer/HUDPanel")
	var recovery_panel: PanelContainer = scene.get_node("%RecoveryPanel")
	var hud_style := hud_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var recovery_style := recovery_panel.get_theme_stylebox("panel") as StyleBoxFlat

	assert_not_null(hud_style)
	assert_not_null(recovery_style)
	assert_true(hud_style.bg_color.r < 0.3)
	assert_true(recovery_style.border_color.g > 0.5)

