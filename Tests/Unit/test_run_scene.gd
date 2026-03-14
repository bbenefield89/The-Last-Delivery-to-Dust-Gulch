extends GutTest

const RUN_SCENE := preload("res://Scenes/RunScene/RunScene.tscn")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")


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
	assert_eq(state.cargo_value, 96)
	assert_eq(state.last_hit_hazard, &"pothole")


func test_hazard_collision_triggers_hit_flash_wobble_and_camera_shake() -> void:
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
	spawner.advance(500.0)
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
	scene.setup(state)

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
	scene.setup(state)

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
	scene.setup(state)

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

	scene._advance_failure_triggers(6.0)

	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"bad_luck")


func test_bad_luck_timer_does_not_replace_existing_failure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)

	scene._advance_failure_triggers(10.0)

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")


func test_wheel_loose_reduces_steering_authority_without_one_side_lock() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)

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
	scene.setup(state)

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
	scene.setup(state)

	scene._process(0.2)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	assert_ne(wagon.rotation, 0.0)


func test_horse_panic_adds_stronger_side_to_side_instability() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)

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
	assert_eq((recovery_steps.get_child(0).get_child(0) as Label).text, "LEFT")
	assert_eq((recovery_steps.get_child(1).get_child(0) as Label).text, "RIGHT")
	assert_eq((recovery_steps.get_child(2).get_child(0) as Label).text, "LEFT")


func test_wheel_loose_recovery_sequence_clears_failure_on_success() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)
	scene._advance_failure_triggers(0.0)

	for action_name in [&"steer_left", &"steer_right", &"steer_left"]:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	assert_eq(state.active_failure, &"")
	assert_false(state.has_active_recovery_sequence())


func test_recovery_prompt_advances_highlight_with_direct_input_actions() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)
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


func test_horse_panic_starts_distinct_recovery_sequence_prompt() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)

	scene._advance_failure_triggers(0.0)

	assert_true(state.has_active_recovery_sequence())
	assert_eq(state.get_current_recovery_prompt(), &"steer_left")
	assert_eq(state.recovery_sequence, scene.HORSE_PANIC_RECOVERY_SEQUENCE)

	var recovery_title: Label = scene.get_node("%RecoveryTitle")
	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	scene._refresh_recovery_prompt()

	assert_eq(recovery_title.text, "Horse Panic: Calm the Team")
	assert_eq(recovery_steps.get_child_count(), 4)
	assert_eq((recovery_steps.get_child(0).get_child(0) as Label).text, "LEFT")
	assert_eq((recovery_steps.get_child(1).get_child(0) as Label).text, "RIGHT")
	assert_eq((recovery_steps.get_child(2).get_child(0) as Label).text, "LEFT")
	assert_eq((recovery_steps.get_child(3).get_child(0) as Label).text, "RIGHT")


func test_horse_panic_recovery_sequence_clears_failure_on_success() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)
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

	scene._advance_failure_triggers(0.0)
	scene._advance_failure_triggers(scene.WHEEL_LOOSE_RECOVERY_DURATION)

	assert_eq(state.active_failure, &"")
	assert_eq(state.last_recovery_outcome, &"failure")
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH - scene.WHEEL_LOOSE_FAILURE_HEALTH_LOSS)
	assert_eq(state.cargo_value, RunStateType.DEFAULT_CARGO_VALUE - scene.WHEEL_LOOSE_FAILURE_CARGO_LOSS)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED - scene.WHEEL_LOOSE_FAILURE_SPEED_LOSS)
	assert_true(state.has_temporary_control_instability())


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
	scene.setup(state)
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
	scene.setup(state)

	scene._advance_failure_triggers(0.0)
	scene._advance_failure_triggers(scene.WHEEL_LOOSE_RECOVERY_DURATION)
	scene._process(0.2)
	scene._process(0.2)

	assert_ne(state.lateral_position, 0.0)


func test_speed_penalty_recovers_toward_default_speed_over_time() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = 10000.0
	state.current_speed = 150.0
	scene.setup(state)

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
	scene.setup(state)
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
	scene.setup(state)
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
	assert_eq(panel_style.bg_color, Color(0, 0, 0, 1))

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
	assert_true(scene.has_node("%ImpactPlayer"))
	assert_true(scene.has_node("%FailurePlayer"))
	assert_true(scene.has_node("%ResultPlayer"))


func test_ready_starts_music_and_dust_presentation() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var dust_trail: CPUParticles2D = scene.get_node("%DustTrail")
	var music_player: AudioStreamPlayer = scene.get_node("%MusicPlayer")
	assert_true(dust_trail.emitting)
	assert_true(music_player.playing)
	assert_eq(music_player.stream, scene.BACKGROUND_MUSIC)


func test_impact_feedback_plays_impact_audio_cue() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	scene._trigger_impact_feedback()

	var impact_player: AudioStreamPlayer = scene.get_node("%ImpactPlayer")
	assert_true(impact_player.playing)
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
	assert_false(dust_trail.emitting)
	assert_true(result_player.playing)
	assert_false(music_player.playing)


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
