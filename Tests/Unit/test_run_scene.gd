extends GutTest

const RUN_SCENE := preload("res://Scenes/RunScene/RunScene.tscn")
const RecoverySequenceGeneratorType := preload("res://Scripts/Failures/recovery_sequence_generator.gd")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")
const TEST_BEST_RUN_SAVE_PATH := "user://dg30_test_run_scene_best_run.cfg"


## Clears the scene-level best-run fixture before each test uses the override save path.
func before_each() -> void:
	_delete_test_best_run_file()


## Clears the scene-level best-run fixture after each test completes.
func after_each() -> void:
	_delete_test_best_run_file()


## Sends a keyboard key press and release through the input pipeline for focus and menu tests.
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


func _dismiss_onboarding(scene: Node) -> void:
	var dismiss_event := InputEventAction.new()
	dismiss_event.action = &"steer_left"
	dismiss_event.pressed = true
	scene._input(dismiss_event)


func _setup_active_run(scene: Node, state: RunStateType) -> void:
	scene.setup(state)
	_dismiss_onboarding(scene)


## Starts a run at a specific delivery progress ratio before dismissing onboarding.
func _setup_active_run_at_progress(scene: Node, state: RunStateType, progress_ratio: float) -> void:
	state.distance_remaining = state.route_distance * (1.0 - progress_ratio)
	scene.setup(state)
	_dismiss_onboarding(scene)


## Confirms the route-phase callout is anchored as a small top-center overlay.
func test_route_phase_callout_panel_uses_top_center_overlay_layout() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var phase_callout_panel: PanelContainer = scene.get_node("%PhaseCalloutPanel")
	var phase_callout_label: Label = scene.get_node("%PhaseCalloutLabel")

	assert_not_null(phase_callout_panel)
	assert_not_null(phase_callout_label)
	assert_false(phase_callout_panel.visible)
	assert_eq(phase_callout_panel.anchor_left, 0.5)
	assert_eq(phase_callout_panel.anchor_right, 0.5)
	assert_eq(phase_callout_panel.offset_top, 12.0)
	assert_eq(phase_callout_panel.offset_bottom, 42.0)
	assert_eq(phase_callout_panel.custom_minimum_size, Vector2(216, 30))


## Asserts that a phase transition shows a short readable banner and then hides again.
func _assert_phase_callout_for_transition(
	scene: Node,
	state: RunStateType,
	start_progress_ratio: float,
	delta: float,
	expected_text: String
) -> void:
	_setup_active_run_at_progress(scene, state, start_progress_ratio)

	var phase_callout_panel: PanelContainer = scene.get_node("%PhaseCalloutPanel")
	var phase_callout_label: Label = scene.get_node("%PhaseCalloutLabel")
	if phase_callout_panel.visible:
		scene._tick_phase_callout(scene.PHASE_CALLOUT_DURATION)
	assert_false(phase_callout_panel.visible)

	scene._process(delta)

	assert_true(phase_callout_panel.visible)
	assert_eq(phase_callout_label.text, expected_text)
	var phase_callout_rect: Rect2 = phase_callout_panel.get_global_rect()
	var viewport_size: Vector2 = scene.get_viewport().get_visible_rect().size
	assert_true(phase_callout_rect.position.y >= 0.0)
	assert_true(phase_callout_rect.end.y <= viewport_size.y)
	assert_true(phase_callout_rect.position.x >= 0.0)
	assert_true(phase_callout_rect.end.x <= viewport_size.x)

	scene._tick_phase_callout(scene.PHASE_CALLOUT_DURATION)

	assert_false(phase_callout_panel.visible)
	assert_eq(phase_callout_label.text, "")


func test_route_phase_when_transitioning_from_warm_up_then_first_trouble_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.19, 0.05, "First Trouble")


func test_route_phase_when_transitioning_from_first_trouble_then_crossing_beats_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.44, 0.05, "Crossing Beat")


func test_route_phase_when_transitioning_from_crossing_then_clutter_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.59, 0.05, "Clutter Beat")


func test_route_phase_when_transitioning_from_clutter_then_reset_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.79, 0.05, "Reset Before Finale")


func test_route_phase_when_transitioning_from_reset_then_final_stretch_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.87, 0.05, "FINAL STRETCH")


## Verifies the finale state takes over at 0.88 progress and clears any armed timer bad luck.
func test_route_phase_when_progress_enters_final_stretch_then_bad_luck_is_disabled() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene._bad_luck_rng.seed = 7
	_setup_active_run_at_progress(scene, state, 0.879)

	assert_eq(scene._route_phase, scene.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_true(scene._is_timer_bad_luck_enabled())
	assert_true(scene._scheduled_bad_luck_interval > 0.0)

	state.distance_remaining = state.route_distance * 0.12
	scene._process(0.0)

	assert_eq(scene._route_phase, scene.ROUTE_PHASE_FINAL_STRETCH)
	assert_false(scene._is_timer_bad_luck_enabled())
	assert_eq(scene._scheduled_bad_luck_interval, 0.0)
	assert_eq(scene._bad_luck_elapsed, 0.0)
	assert_false(scene._pending_bad_luck_trigger)

	scene._advance_failure_triggers(999.0)

	assert_eq(scene._route_phase, scene.ROUTE_PHASE_FINAL_STRETCH)
	assert_eq(state.active_failure, &"")
	assert_eq(scene._scheduled_bad_luck_interval, 0.0)
	assert_eq(scene._bad_luck_elapsed, 0.0)
	assert_false(scene._pending_bad_luck_trigger)


## Verifies the run scene passes remaining distance into the spawner so the release runway can clear.
func test_final_stretch_when_route_reaches_release_window_then_spawner_holds_clear_runway() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.route_distance = 10000.0
	state.distance_remaining = (
		scene._hazard_spawner.FINAL_STRETCH_RELEASE_DISTANCE
		+ scene._hazard_spawner.FINAL_STRETCH_SPACING_MAX
		+ 1.0
	)
	scene.setup(state)
	_dismiss_onboarding(scene)

	scene._bad_luck_rng.seed = 23
	scene._process(0.0)

	assert_eq(scene._route_phase, scene.ROUTE_PHASE_FINAL_STRETCH)
	assert_not_null(scene._hazard_spawner._next_spawn_plan)

	var planned_spacing: float = scene._hazard_spawner._next_spawn_plan.spacing
	scene._process(planned_spacing / state.current_speed)

	assert_true(scene._hazard_spawner.get_child_count() > 0)

	var runway_delta: float = (
		state.distance_remaining - scene._hazard_spawner.FINAL_STRETCH_CLEAR_RUNWAY_DISTANCE
	) / state.current_speed
	scene._process(runway_delta)
	await wait_process_frames(1)

	assert_true(state.distance_remaining <= scene._hazard_spawner.FINAL_STRETCH_CLEAR_RUNWAY_DISTANCE)
	assert_eq(scene._hazard_spawner.get_child_count(), 0)
	assert_eq(scene._hazard_spawner._next_spawn_plan, null)
	assert_eq(scene._hazard_spawner._distance_until_next_spawn, 0.0)
	assert_eq(scene._hazard_spawner._get_route_phase(0.98), scene._hazard_spawner.ROUTE_PHASE_FINAL_STRETCH)


func test_dismissing_onboarding_when_run_starts_then_warm_up_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var phase_callout_panel: PanelContainer = scene.get_node("%PhaseCalloutPanel")
	var phase_callout_label: Label = scene.get_node("%PhaseCalloutLabel")
	assert_false(phase_callout_panel.visible)

	_dismiss_onboarding(scene)

	assert_true(phase_callout_panel.visible)
	assert_eq(phase_callout_label.text, "Warm-Up")


## Forces touch controls on for tests that exercise the native mobile runtime path.
func _enable_touch_controls_for_native_mobile(scene: Node) -> void:
	scene._has_native_mobile_runtime_override = true
	scene._native_mobile_runtime_override = true
	scene._refresh_touch_controls()


## Configures the test scene to behave like a mobile web runtime with controllable touch capability.
func _configure_mobile_web_touch_runtime(scene: Node, touchscreen_available: bool) -> void:
	scene._has_mobile_web_runtime_override = true
	scene._mobile_web_runtime_override = true
	scene._has_touchscreen_available_override = true
	scene._touchscreen_available_override = touchscreen_available
	scene._refresh_touch_controls()


func _build_expected_recovery_sequence(scene: Node, progress: float, seed: int) -> Array[StringName]:
	var generator := RecoverySequenceGeneratorType.new()
	generator.set_seed(seed)
	return generator.generate_sequence(progress, scene.RECOVERY_PROMPT_POOL)


func _start_seeded_recovery_sequence(scene: Node, state: RunStateType, seed: int) -> Array[StringName]:
	scene._recovery_sequence_generator.set_seed(seed)
	scene._advance_failure_triggers(0.0)
	return _build_expected_recovery_sequence(scene, state.get_delivery_progress_ratio(), seed)


## Spawns a hazard directly into the run scene and places it on the wagon line for deterministic assertions.
func _spawn_test_hazard(scene: Node, hazard_type: StringName, lane_index: int = -1) -> Node2D:
	var spawner = scene.get_node("%HazardSpawner")
	if lane_index < 0:
		lane_index = spawner.LANE_X_POSITIONS.find(0.0)
	spawner._spawn_hazard(hazard_type, lane_index)
	var hazard: Node2D = spawner.get_child(spawner.get_child_count() - 1)
	hazard.position = Vector2(0.0, 0.0)
	return hazard


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
	state.lateral_position = 12.0
	state.active_failure = &"wheel_loose"
	scene.setup(state)

	var health_tag: Label = scene.get_node("HUDLayer/HUDPanel/MarginContainer/VBoxContainer/HealthRow/HealthTag")
	var health_bar_margin: MarginContainer = scene.get_node("HUDLayer/HUDPanel/MarginContainer/VBoxContainer/HealthRow/HealthBarMargin")
	var health_bar: ProgressBar = scene.get_node("%HealthBar")
	var health_label: Label = scene.get_node("%HealthLabel")
	var cargo_label: Label = scene.get_node("%CargoLabel")
	assert_eq(health_tag.text, "HP")
	assert_eq(health_bar_margin.get_theme_constant("margin_top"), 5)
	assert_eq(health_label.text, "77")
	assert_eq(cargo_label.text, "Cargo 63")
	assert_eq(health_bar.value, 77.0)
	assert_false(scene.has_node("%SpeedLabel"))
	assert_false(scene.has_node("%ProgressLabel"))
	assert_false(scene.has_node("%ProgressBar"))
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
	scene._process(3.0)

	var onboarding_panel: PanelContainer = scene.get_node("%OnboardingPanel")
	var spawner = scene.get_node("%HazardSpawner")
	assert_false(scene._onboarding_active)
	assert_false(onboarding_panel.visible)
	assert_true(state.distance_remaining < distance_before_process)
	assert_true(spawner.get_child_count() > 0)


## Verifies the onboarding overlay can be dismissed using keyboard confirm input alone.
func test_dismissing_onboarding_with_keyboard_confirm_starts_normal_gameplay() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	await _send_key_input(KEY_ENTER)
	var distance_before_process := state.distance_remaining
	scene._process(3.0)

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


## Verifies Escape opens the pause menu and gives the resume button default focus.
func test_pause_menu_when_opened_with_escape_then_resume_button_has_default_focus() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	await _send_key_input(KEY_ENTER)
	await _send_key_input(KEY_ESCAPE)

	var pause_overlay: Control = scene.get_node("%PauseOverlay")
	var pause_panel: PanelContainer = scene.get_node("%PausePanel")
	var resume_button: Button = scene.get_node("%PauseResumeButton")
	assert_true(scene._pause_menu_open)
	assert_true(pause_overlay.visible)
	assert_true(pause_panel.visible)
	assert_true(resume_button.has_focus())


## Verifies pause-menu keyboard navigation and confirm activate the expected action.
func test_pause_menu_when_open_then_keyboard_navigation_and_restart_confirm_work() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	await _send_key_input(KEY_ENTER)
	await _send_key_input(KEY_ESCAPE)

	var resume_button: Button = scene.get_node("%PauseResumeButton")
	var restart_button: Button = scene.get_node("%PauseRestartButton")
	var return_button: Button = scene.get_node("%PauseReturnButton")
	assert_true(resume_button.has_focus())

	await _send_key_input(KEY_DOWN)
	assert_true(restart_button.has_focus())
	assert_false(resume_button.has_focus())
	assert_false(return_button.has_focus())

	await _send_key_input(KEY_DOWN)
	assert_true(return_button.has_focus())
	assert_false(resume_button.has_focus())
	assert_false(restart_button.has_focus())

	await _send_key_input(KEY_UP)
	assert_true(restart_button.has_focus())

	watch_signals(scene)
	await _send_key_input(KEY_ENTER)
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout

	assert_signal_emitted(scene, "restart_requested")
	assert_false(scene._pause_menu_open)


## Verifies the existing cancel input closes the pause menu without needing a mouse click.
func test_pause_menu_when_open_then_escape_closes_it() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	await _send_key_input(KEY_ENTER)
	await _send_key_input(KEY_ESCAPE)
	assert_true(scene._pause_menu_open)

	await _send_key_input(KEY_ESCAPE)

	var pause_overlay: Control = scene.get_node("%PauseOverlay")
	var pause_panel: PanelContainer = scene.get_node("%PausePanel")
	assert_false(scene._pause_menu_open)
	assert_false(pause_overlay.visible)
	assert_false(pause_panel.visible)


func test_process_moves_right_and_reduces_distance() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	Input.action_press("steer_right")
	scene._process(0.5)
	Input.action_release("steer_right")

	assert_almost_eq(state.lateral_position, 90.0, 0.01)
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
	state.lateral_position = 96.0
	_setup_active_run(scene, state)

	Input.action_press("steer_right")
	scene._process(1.0)
	Input.action_release("steer_right")

	assert_eq(state.lateral_position, scene.ROAD_HALF_WIDTH)


func test_hazard_collision_reduces_health_and_records_last_hit_type() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"pothole")
	await wait_process_frames(1)
	scene._process(0.0)
	await wait_process_frames(1)

	assert_eq(state.wagon_health, 94)
	assert_eq(state.cargo_value, 98)
	assert_eq(state.last_hit_hazard, &"pothole")
	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"pothole")

	var pothole_impact_player: AudioStreamPlayer = scene.get_node("%PotholeImpactPlayer")
	var fallback_impact_player: AudioStreamPlayer = scene.get_node("%ImpactPlayer")
	assert_true(pothole_impact_player.playing)
	assert_false(fallback_impact_player.playing)


func test_rock_collision_when_it_hits_then_it_causes_the_heavier_wheel_loose_punishment() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"rock")
	await wait_process_frames(1)
	scene._process(0.0)
	await wait_process_frames(1)

	assert_eq(state.wagon_health, 82)
	assert_eq(state.cargo_value, 91)
	assert_eq(state.last_hit_hazard, &"rock")
	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")


func test_near_miss_when_hazard_passes_close_without_collision_then_bonus_and_callout_are_awarded_once() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var hazard: Node2D = _spawn_test_hazard(scene, &"pothole")
	hazard.position = Vector2(0.0, -120.0)
	scene._process(0.1)
	await wait_process_frames(1)
	state.lateral_position = 44.0
	scene._update_wagon_visual()
	for _step in range(5):
		scene._process(0.1)
		await wait_process_frames(1)

	var bonus_callout_panel: Control = scene.get_node("%BonusCalloutPanel")
	var bonus_callout_label: Label = scene.get_node("%BonusCalloutLabel")
	var wagon: Polygon2D = scene.get_node("%Wagon")
	var wagon_canvas_position: Vector2 = scene.get_viewport().get_canvas_transform() * wagon.global_position
	var bonus_callout_center: Vector2 = bonus_callout_panel.get_global_rect().get_center()

	assert_eq(state.bonus_score, RunStateType.NEAR_MISS_BONUS_SCORE)
	assert_eq(state.hazards_dodged, 1)
	assert_eq(state.near_misses, 1)
	assert_eq(
		state.get_score(),
		state.get_completion_score() + state.get_health_score() + state.get_cargo_score() + RunStateType.NEAR_MISS_BONUS_SCORE
	)
	assert_true(bonus_callout_panel.visible)
	assert_eq(bonus_callout_label.text, "NEAR MISS +50")
	assert_true(absf(bonus_callout_center.x - wagon_canvas_position.x) <= 4.0)
	assert_true(bonus_callout_center.y < wagon_canvas_position.y - 32.0)

	scene._process(0.6)
	scene._process(0.6)

	assert_eq(state.bonus_score, RunStateType.NEAR_MISS_BONUS_SCORE)
	assert_false(bonus_callout_panel.visible)


func test_clean_dodge_when_hazard_passes_safely_then_only_hazards_dodged_increments() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var hazard: Node2D = _spawn_test_hazard(scene, &"pothole")
	hazard.position = Vector2(72.0, -120.0)
	for _step in range(6):
		scene._process(0.1)
		await wait_process_frames(1)

	assert_eq(state.hazards_dodged, 1)
	assert_eq(state.near_misses, 0)
	assert_eq(state.bonus_score, 0)


func test_near_miss_bonus_is_not_awarded_for_a_real_collision() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"pothole")
	await wait_process_frames(1)
	scene._process(0.0)

	var bonus_callout_panel: Control = scene.get_node("%BonusCalloutPanel")
	assert_eq(state.bonus_score, 0)
	assert_false(bonus_callout_panel.visible)


func test_near_miss_bonus_is_not_awarded_for_side_pass_then_late_swerve_toward_hazard() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var hazard: Node2D = _spawn_test_hazard(scene, &"pothole")
	hazard.position = Vector2(72.0, -120.0)
	scene._process(0.2)
	await wait_process_frames(1)
	state.lateral_position = 44.0
	scene._update_wagon_visual()
	for _step in range(4):
		scene._process(0.1)
		await wait_process_frames(1)

	var bonus_callout_panel: Control = scene.get_node("%BonusCalloutPanel")
	assert_eq(state.bonus_score, 0)
	assert_false(bonus_callout_panel.visible)


## Verifies a live livestock collision uses the existing damage and horse-panic failure flow.
func test_livestock_collision_when_it_hits_the_wagon_then_existing_failure_flow_is_used() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"livestock")
	await wait_process_frames(1)
	scene._process(0.0)
	await wait_process_frames(1)

	assert_eq(state.wagon_health, 88)
	assert_eq(state.cargo_value, 95)
	assert_eq(state.last_hit_hazard, &"livestock")
	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"livestock")


func test_hazard_collision_triggers_hit_flash_wobble_and_camera_shake() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"pothole")
	await wait_process_frames(1)
	scene._process(0.05)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	var camera: Camera2D = scene.get_node("%Camera")

	assert_eq(wagon.modulate, scene.WAGON_HIT_COLOR)
	assert_ne(wagon.rotation, 0.0)
	assert_ne(camera.position, Vector2(0.0, -scene.CAMERA_VERTICAL_OFFSET))


func test_impact_feedback_recovers_after_timers_expire() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"pothole")
	await wait_process_frames(1)
	scene._process(0.05)
	state.clear_failure()
	scene._process(0.4)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	var camera: Camera2D = scene.get_node("%Camera")

	assert_eq(wagon.modulate, scene.WAGON_BASE_COLOR)
	assert_eq(wagon.rotation, 0.0)
	assert_eq(camera.position, Vector2(0.0, -scene.CAMERA_VERTICAL_OFFSET))


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
	assert_eq(camera.position, Vector2(0.0, -scene.CAMERA_VERTICAL_OFFSET))


func test_forward_motion_scrolls_the_environment() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	scene._process(0.5)

	var segment_a: Node2D = scene.get_node("%ScrollSegmentA")
	var segment_b: Node2D = scene.get_node("%ScrollSegmentB")
	assert_almost_eq(segment_a.position.y, state.current_speed * 0.5, 0.01)
	assert_almost_eq(segment_b.position.y, (state.current_speed * 0.5) - scene.SCROLL_LOOP_HEIGHT, 0.01)


func test_scroll_environment_wraps_for_continuous_travel() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.current_speed = scene.SCROLL_LOOP_HEIGHT + 140.0
	scene.setup(state)
	scene._process(1.0)

	var segment_a: Node2D = scene.get_node("%ScrollSegmentA")
	var segment_b: Node2D = scene.get_node("%ScrollSegmentB")
	assert_almost_eq(segment_a.position.y, 140.0, 0.01)
	assert_almost_eq(segment_b.position.y, 140.0 - scene.SCROLL_LOOP_HEIGHT, 0.01)


func test_scroll_segment_populates_enough_roadside_scrub_to_cover_loop_end() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var segment_a: Node2D = scene.get_node("%ScrollSegmentA")
	var left_scrub_positions: Array[float] = []

	for child in segment_a.get_children():
		if child is Sprite2D and scene.SHRUB_TEXTURES.has(child.texture) and child.scale.x > 0.0:
			left_scrub_positions.append(child.position.y)

	left_scrub_positions.sort()
	assert_true(left_scrub_positions.size() >= scene.ROADSIDE_DECOR_COUNT)
	assert_true(left_scrub_positions.back() >= 0.0)


## Verifies the scene flow keeps crossing beat pressure pairs enabled and the reset phase disabled.
func test_crossing_beat_and_reset_before_finale_switch_hazard_pressure_rules() -> void:
	var crossing_scene = RUN_SCENE.instantiate()
	add_child_autofree(crossing_scene)
	await wait_process_frames(1)

	var crossing_state := RunStateType.new()
	crossing_state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.5
	_setup_active_run(crossing_scene, crossing_state)
	var crossing_spawner = crossing_scene.get_node("%HazardSpawner")
	crossing_scene._process(0.0)
	assert_eq(crossing_scene._route_phase, crossing_scene.ROUTE_PHASE_CROSSING_BEAT)
	assert_true(crossing_spawner._get_active_band().allows_pressure_pair)

	var reset_scene = RUN_SCENE.instantiate()
	add_child_autofree(reset_scene)
	await wait_process_frames(1)

	var reset_state := RunStateType.new()
	reset_state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.2
	_setup_active_run(reset_scene, reset_state)
	var reset_spawner = reset_scene.get_node("%HazardSpawner")
	reset_scene._process(0.0)
	assert_eq(reset_scene._route_phase, reset_scene.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_false(reset_spawner._get_active_band().allows_pressure_pair)


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


## Verifies timer bad luck still fires in the reset-before-finale phase.
func test_bad_luck_timer_triggers_failure_when_no_active_failure_exists() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene._bad_luck_rng.seed = 7
	_setup_active_run_at_progress(scene, state, 0.8)

	scene._advance_failure_triggers(scene._scheduled_bad_luck_interval)

	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"bad_luck")
	assert_eq(scene._bad_luck_elapsed, 0.0)
	assert_false(scene._pending_bad_luck_trigger)
	assert_eq(scene._route_phase, scene.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_true(
		scene._scheduled_bad_luck_interval >= scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN
	)
	assert_true(
		scene._scheduled_bad_luck_interval <= scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX
	)


## Verifies the timer bad-luck ranges line up with the authored phase windows.
func test_bad_luck_interval_range_uses_route_phase_windows() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_eq(
		scene._get_bad_luck_interval_range(0.1),
		Vector2.ZERO
	)
	assert_eq(
		scene._get_bad_luck_interval_range(0.2),
		Vector2(
			scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN,
			scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX
		)
	)
	assert_eq(
		scene._get_bad_luck_interval_range(0.45),
		Vector2(
			scene.BAD_LUCK_INTERVAL_CROSSING_BEAT_MIN,
			scene.BAD_LUCK_INTERVAL_CROSSING_BEAT_MAX
		)
	)
	assert_eq(
		scene._get_bad_luck_interval_range(0.6),
		Vector2(
			scene.BAD_LUCK_INTERVAL_CLUTTER_BEAT_MIN,
			scene.BAD_LUCK_INTERVAL_CLUTTER_BEAT_MAX
		)
	)
	assert_eq(
		scene._get_bad_luck_interval_range(0.85),
		Vector2(
			scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN,
			scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX
		)
	)
	assert_eq(scene._get_route_phase(0.88), scene.ROUTE_PHASE_FINAL_STRETCH)
	assert_eq(scene._get_bad_luck_interval_range(0.88), Vector2.ZERO)


## Verifies warm-up suppresses timer bad luck until the first trouble phase starts.
func test_bad_luck_timer_when_run_starts_in_warm_up_then_it_stays_disabled() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	scene._advance_failure_triggers(10.0)

	assert_eq(scene._route_phase, scene.ROUTE_PHASE_WARM_UP)
	assert_eq(scene._scheduled_bad_luck_interval, 0.0)
	assert_eq(scene._bad_luck_elapsed, 0.0)
	assert_eq(state.active_failure, &"")


## Verifies setup disables timer bad luck in warm-up and schedules it once phases activate.
func test_setup_rolls_first_bad_luck_interval_from_current_progress_band() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	scene._bad_luck_rng.seed = 19

	var warm_up_state := RunStateType.new()
	scene.setup(warm_up_state)
	assert_eq(scene._route_phase, scene.ROUTE_PHASE_WARM_UP)
	assert_eq(scene._scheduled_bad_luck_interval, 0.0)

	var first_trouble_state := RunStateType.new()
	_setup_active_run_at_progress(scene, first_trouble_state, 0.2)
	assert_eq(scene._route_phase, scene.ROUTE_PHASE_FIRST_TROUBLE)
	assert_true(
		scene._scheduled_bad_luck_interval >= scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN
	)
	assert_true(
		scene._scheduled_bad_luck_interval <= scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX
	)

	var reset_state := RunStateType.new()
	_setup_active_run_at_progress(scene, reset_state, 0.85)
	assert_eq(scene._route_phase, scene.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_true(
		scene._scheduled_bad_luck_interval >= scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN
	)
	assert_true(
		scene._scheduled_bad_luck_interval <= scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX
	)


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


## Verifies collision-triggered failures reschedule timer bad luck using the active phase.
func test_collision_trigger_reschedules_bad_luck_interval_when_failure_starts() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene._bad_luck_rng.seed = 31
	_setup_active_run_at_progress(scene, state, 0.3)
	scene._scheduled_bad_luck_interval = 99.0
	scene._bad_luck_elapsed = 5.0
	scene._pending_bad_luck_trigger = true

	scene._attempt_failure_trigger_from_collision(&"rock")

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")
	assert_eq(scene._bad_luck_elapsed, 0.0)
	assert_false(scene._pending_bad_luck_trigger)
	assert_eq(scene._route_phase, scene.ROUTE_PHASE_FIRST_TROUBLE)
	assert_true(
		scene._scheduled_bad_luck_interval >= scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN
	)
	assert_true(
		scene._scheduled_bad_luck_interval <= scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX
	)


func test_bad_luck_timer_arms_one_pending_trigger_during_recovery_cooldown() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run_at_progress(scene, state, 0.3)
	state.recovery_cooldown_remaining = 0.5
	scene._scheduled_bad_luck_interval = 0.2
	scene._bad_luck_elapsed = 0.0

	scene._advance_failure_triggers(0.2)

	assert_eq(state.active_failure, &"")
	assert_true(scene._pending_bad_luck_trigger)
	assert_eq(scene._bad_luck_elapsed, 0.0)

	scene._advance_failure_triggers(0.1)

	assert_eq(state.active_failure, &"")
	assert_true(scene._pending_bad_luck_trigger)
	assert_eq(scene._bad_luck_elapsed, 0.0)


func test_bad_luck_timer_arms_one_pending_trigger_during_active_failure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run_at_progress(scene, state, 0.3)
	state.start_failure(&"wheel_loose", &"rock")
	scene._scheduled_bad_luck_interval = 0.2
	scene._bad_luck_elapsed = 0.0

	scene._advance_failure_triggers(0.2)

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")
	assert_true(scene._pending_bad_luck_trigger)
	assert_eq(scene._bad_luck_elapsed, 0.0)


func test_pending_bad_luck_fires_on_first_frame_after_cooldown_clears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene._bad_luck_rng.seed = 47
	_setup_active_run_at_progress(scene, state, 0.3)
	state.recovery_cooldown_remaining = 0.1
	scene._scheduled_bad_luck_interval = 0.05

	scene._advance_failure_triggers(0.05)
	scene._advance_failure_triggers(0.05)

	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"bad_luck")
	assert_false(scene._pending_bad_luck_trigger)
	assert_eq(scene._bad_luck_elapsed, 0.0)


func test_pending_bad_luck_does_not_stack_or_reroll_while_blocked() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run_at_progress(scene, state, 0.3)
	state.recovery_cooldown_remaining = 0.6
	scene._scheduled_bad_luck_interval = 0.2
	scene._bad_luck_elapsed = 0.0

	scene._advance_failure_triggers(0.2)
	var scheduled_interval_after_pending: float = scene._scheduled_bad_luck_interval

	scene._advance_failure_triggers(0.2)
	scene._advance_failure_triggers(0.1)

	assert_true(scene._pending_bad_luck_trigger)
	assert_eq(scene._bad_luck_elapsed, 0.0)
	assert_eq(scene._scheduled_bad_luck_interval, scheduled_interval_after_pending)
	assert_eq(state.active_failure, &"")


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

	assert_almost_eq(state.lateral_position, -scene.ROAD_HALF_WIDTH, 0.01)


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

	var expected_sequence := _start_seeded_recovery_sequence(scene, state, 10)

	assert_true(state.has_active_recovery_sequence())
	assert_eq(state.recovery_sequence, expected_sequence)
	assert_eq(state.get_current_recovery_prompt(), expected_sequence[0])

	var recovery_panel: PanelContainer = scene.get_node("%RecoveryPanel")
	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	scene._refresh_recovery_prompt()

	assert_true(recovery_panel.visible)
	assert_eq(recovery_steps.get_child_count(), expected_sequence.size())
	for index in range(expected_sequence.size()):
		assert_eq((recovery_steps.get_child(index).get_child(0) as Label).text, scene._format_recovery_action(expected_sequence[index]))


func test_recovery_prompt_steps_use_embedded_arrow_font() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)
	_start_seeded_recovery_sequence(scene, state, 10)
	scene._refresh_recovery_prompt()

	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	var first_step := recovery_steps.get_child(0) as PanelContainer
	var arrow_label := recovery_steps.get_child(0).get_child(0) as Label
	assert_not_null(arrow_label)
	assert_not_null(first_step)
	assert_eq(arrow_label.get_theme_font("font"), scene.ARROW_FONT)
	assert_eq(recovery_steps.custom_minimum_size.x, scene.RECOVERY_STEP_ROW_MAX_WIDTH)
	assert_eq(arrow_label.get_theme_font_size("font_size"), scene._get_recovery_step_font_size())
	assert_eq(first_step.custom_minimum_size, scene._get_recovery_step_minimum_size())


func test_long_recovery_sequence_uses_same_row_width_with_smaller_prompt_chips() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)
	state.start_recovery_sequence([
		&"steer_left",
		&"steer_right",
		&"steer_left",
		&"steer_right",
		&"steer_left",
		&"steer_right",
	], 3.0)
	scene._refresh_recovery_prompt()

	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	var first_step := recovery_steps.get_child(0) as PanelContainer
	var arrow_label := first_step.get_child(0) as Label
	assert_eq(recovery_steps.custom_minimum_size.x, scene.RECOVERY_STEP_ROW_MAX_WIDTH)
	assert_eq(first_step.custom_minimum_size, Vector2(36.0, scene.RECOVERY_STEP_HEIGHT))
	assert_eq(arrow_label.get_theme_font_size("font_size"), scene.RECOVERY_STEP_MIN_FONT_SIZE)


func test_recovery_panel_stays_inside_viewport_during_touch_recovery() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	_setup_active_run(scene, state)
	_start_seeded_recovery_sequence(scene, state, 10)
	_enable_touch_controls_for_native_mobile(scene)
	scene._refresh_recovery_prompt()
	scene._refresh_touch_controls()
	await wait_process_frames(1)

	var viewport_rect := scene.get_viewport().get_visible_rect()
	var recovery_panel: PanelContainer = scene.get_node("%RecoveryPanel")
	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	var panel_rect := recovery_panel.get_global_rect()
	var steps_rect := recovery_steps.get_global_rect()

	assert_true(recovery_panel.visible)
	assert_true(panel_rect.position.x >= viewport_rect.position.x)
	assert_true(panel_rect.position.y >= viewport_rect.position.y)
	assert_true(panel_rect.end.x <= viewport_rect.end.x)
	assert_true(panel_rect.end.y <= viewport_rect.end.y)
	assert_true(steps_rect.position.y >= panel_rect.position.y)
	assert_true(steps_rect.end.y <= panel_rect.end.y)


func test_recovery_panel_does_not_overlap_touch_steering_buttons() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	_setup_active_run(scene, state)
	state.start_recovery_sequence([
		&"steer_left",
		&"steer_right",
		&"steer_left",
		&"steer_right",
		&"steer_left",
		&"steer_right",
	], 3.0)
	_enable_touch_controls_for_native_mobile(scene)
	scene._refresh_recovery_prompt()
	scene._refresh_touch_controls()
	await wait_process_frames(1)

	var recovery_panel: PanelContainer = scene.get_node("%RecoveryPanel")
	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var panel_rect := recovery_panel.get_global_rect()
	var left_rect := touch_left.get_global_rect()
	var right_rect := touch_right.get_global_rect()

	assert_true(recovery_panel.visible)
	assert_true(touch_left.visible)
	assert_true(touch_right.visible)
	assert_false(panel_rect.intersects(left_rect))
	assert_false(panel_rect.intersects(right_rect))


func test_wheel_loose_recovery_sequence_clears_failure_on_success() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	var expected_sequence := _start_seeded_recovery_sequence(scene, state, 10)

	var recovery_step_player: AudioStreamPlayer = scene.get_node("%RecoveryStepPlayer")
	var recovery_success_player: AudioStreamPlayer = scene.get_node("%RecoverySuccessPlayer")

	for action_name in expected_sequence:
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
	var expected_sequence := _start_seeded_recovery_sequence(scene, state, 10)

	var left_event := InputEventAction.new()
	left_event.action = expected_sequence[0]
	left_event.pressed = true
	scene._input(left_event)

	assert_eq(state.get_current_recovery_prompt(), expected_sequence[1])

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
	var expected_sequence := _start_seeded_recovery_sequence(scene, state, 10)

	var recovery_step_player: AudioStreamPlayer = scene.get_node("%RecoveryStepPlayer")
	var recovery_success_player: AudioStreamPlayer = scene.get_node("%RecoverySuccessPlayer")
	var left_event := InputEventAction.new()
	left_event.action = expected_sequence[0]
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
	state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.2
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)
	var expected_sequence := _start_seeded_recovery_sequence(scene, state, 24)

	assert_eq(state.recovery_sequence, expected_sequence)

	var recovery_title: Label = scene.get_node("%RecoveryTitle")
	var recovery_steps: HBoxContainer = scene.get_node("%RecoverySteps")
	scene._refresh_recovery_prompt()

	assert_eq(recovery_title.text, "Horse Panic: Calm the Team")
	assert_eq(recovery_steps.get_child_count(), expected_sequence.size())
	for index in range(expected_sequence.size()):
		assert_eq((recovery_steps.get_child(index).get_child(0) as Label).text, scene._format_recovery_action(expected_sequence[index]))


func test_horse_panic_recovery_sequence_clears_failure_on_success() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	_setup_active_run(scene, state)
	_start_seeded_recovery_sequence(scene, state, 24)

	for action_name in state.recovery_sequence:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	assert_eq(state.active_failure, &"")
	assert_false(state.has_active_recovery_sequence())


func test_perfect_recovery_counter_when_recovery_finishes_clean_then_result_stat_increments() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	_start_seeded_recovery_sequence(scene, state, 10)

	for action_name in state.recovery_sequence:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	assert_eq(state.perfect_recoveries, 1)
	assert_eq(state.recovery_failures, 0)


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
	assert_eq(state.perfect_recoveries, 0)
	assert_eq(state.recovery_failures, 1)
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
	assert_eq(state.perfect_recoveries, 0)
	assert_eq(state.recovery_failures, 1)
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
	_start_seeded_recovery_sequence(scene, state, 10)

	for action_name in state.recovery_sequence:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	assert_eq(state.perfect_recoveries, 1)
	assert_eq(state.recovery_failures, 0)
	assert_eq(state.last_recovery_outcome, &"success")
	assert_eq(state.wagon_health, RunStateType.DEFAULT_WAGON_HEALTH)
	assert_eq(state.current_speed, RunStateType.DEFAULT_FORWARD_SPEED)
	assert_false(state.has_temporary_control_instability())


func test_perfect_recovery_when_sequence_is_clean_then_bonus_score_and_callout_are_awarded() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	_start_seeded_recovery_sequence(scene, state, 10)

	for action_name in state.recovery_sequence:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	var bonus_callout_panel: Control = scene.get_node("%BonusCalloutPanel")
	var bonus_callout_label: Label = scene.get_node("%BonusCalloutLabel")
	assert_eq(state.bonus_score, RunStateType.PERFECT_RECOVERY_BONUS_SCORE)
	assert_eq(state.perfect_recoveries, 1)
	assert_eq(state.recovery_failures, 0)
	assert_true(bonus_callout_panel.visible)
	assert_eq(bonus_callout_label.text, "PERFECT RECOVERY +100")


func test_perfect_recovery_bonus_is_not_awarded_after_wrong_input_then_clean_finish() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	var recovery_sequence := _start_seeded_recovery_sequence(scene, state, 10)

	var wrong_event := InputEventAction.new()
	wrong_event.action = &"steer_right" if recovery_sequence[0] == &"steer_left" else &"steer_left"
	wrong_event.pressed = true
	scene._input(wrong_event)

	for action_name in state.recovery_sequence:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = true
		scene._input(event)

	var bonus_callout_panel: Control = scene.get_node("%BonusCalloutPanel")
	assert_eq(state.last_recovery_outcome, &"success")
	assert_eq(state.bonus_score, 0)
	assert_eq(state.perfect_recoveries, 0)
	assert_eq(state.recovery_failures, 0)
	assert_false(bonus_callout_panel.visible)


func test_perfect_recovery_bonus_is_not_awarded_after_timeout() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)

	scene._advance_failure_triggers(0.0)
	scene._advance_failure_triggers(scene.WHEEL_LOOSE_RECOVERY_DURATION)

	var bonus_callout_panel: Control = scene.get_node("%BonusCalloutPanel")
	assert_eq(state.last_recovery_outcome, &"failure")
	assert_eq(state.bonus_score, 0)
	assert_eq(state.perfect_recoveries, 0)
	assert_eq(state.recovery_failures, 1)
	assert_false(bonus_callout_panel.visible)


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


func test_hud_panel_uses_compact_health_distance_and_cargo_layout() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var hud_panel: PanelContainer = scene.get_node("HUDLayer/HUDPanel")
	var health_tag: Label = scene.get_node("HUDLayer/HUDPanel/MarginContainer/VBoxContainer/HealthRow/HealthTag")
	var health_bar: ProgressBar = scene.get_node("%HealthBar")
	var distance_bar: ProgressBar = scene.get_node("%DistanceBar")
	var distance_bar_overlay: Control = scene.get_node(
		"HUDLayer/HUDPanel/MarginContainer/VBoxContainer/DistanceRow/DistanceBarMargin/DistanceBarOverlay"
	)
	var distance_band_markers: Control = scene.get_node("%DistanceBandMarkers")
	var health_label: Label = scene.get_node("%HealthLabel")
	var cargo_label: Label = scene.get_node("%CargoLabel")

	assert_eq(hud_panel.size.x, 140.0)
	assert_eq(hud_panel.size.y, 79.0)
	assert_eq(health_tag.text, "HP")
	assert_not_null(health_bar)
	assert_not_null(distance_bar)
	assert_not_null(distance_bar_overlay)
	assert_not_null(distance_band_markers)
	assert_eq(distance_band_markers.get_child_count(), scene.DISTANCE_BAR_BAND_BOUNDARIES.size())
	for marker_index in range(distance_band_markers.get_child_count()):
		var band_marker := distance_band_markers.get_child(marker_index) as ColorRect
		var expected_boundary: float = scene.DISTANCE_BAR_BAND_BOUNDARIES[marker_index]
		assert_not_null(band_marker)
		assert_almost_eq(band_marker.anchor_left, expected_boundary, 0.00001)
		assert_almost_eq(band_marker.anchor_right, expected_boundary, 0.00001)
	assert_not_null(health_label)
	assert_not_null(cargo_label)
	assert_false(scene.has_node("%SpeedLabel"))
	assert_false(scene.has_node("%ProgressLabel"))
	assert_false(scene.has_node("%ProgressBar"))


func test_touch_controls_exist_in_scene_corners_with_mobile_friendly_sizing() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var touch_layer: CanvasLayer = scene.get_node("%TouchLayer")
	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_not_null(touch_layer)
	assert_not_null(touch_left)
	assert_not_null(touch_right)
	assert_not_null(touch_pause)
	assert_false(touch_layer.visible)
	assert_false(touch_left.flat)
	assert_false(touch_right.flat)
	assert_false(touch_pause.flat)
	assert_true(touch_left.custom_minimum_size.x >= 120.0)
	assert_true(touch_left.custom_minimum_size.y >= 100.0)
	assert_true(touch_right.custom_minimum_size.x >= 120.0)
	assert_true(touch_right.custom_minimum_size.y >= 100.0)
	assert_true(touch_pause.custom_minimum_size.x >= 72.0)
	assert_true(touch_pause.custom_minimum_size.y >= 72.0)
	assert_eq(touch_left.position, Vector2(16.0, 240.0))
	assert_eq(touch_right.position, Vector2(504.0, 240.0))
	assert_eq(touch_pause.position, Vector2(552.0, 16.0))
	assert_eq(touch_left.get_theme_font("font"), scene.ARROW_FONT)
	assert_eq(touch_right.get_theme_font("font"), scene.ARROW_FONT)
	assert_eq(touch_pause.get_theme_font("font"), scene.ARROW_FONT)
	assert_eq(touch_left.text, char(0xE020))
	assert_eq(touch_right.text, char(0xE022))
	assert_not_null(touch_left.get_theme_stylebox("normal"))
	assert_not_null(touch_right.get_theme_stylebox("normal"))
	assert_not_null(touch_pause.get_theme_stylebox("normal"))


func test_touch_controls_stay_hidden_and_disabled_on_desktop_runtime() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var touch_layer: CanvasLayer = scene.get_node("%TouchLayer")
	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_false(touch_layer.visible)
	assert_true(touch_left.disabled)
	assert_true(touch_right.disabled)
	assert_true(touch_pause.disabled)


func test_touch_controls_show_immediately_on_native_mobile_runtime() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_enable_touch_controls_for_native_mobile(scene)

	var touch_layer: CanvasLayer = scene.get_node("%TouchLayer")
	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_true(touch_layer.visible)
	assert_false(touch_left.disabled)
	assert_false(touch_right.disabled)
	assert_false(touch_pause.disabled)


func test_touch_controls_show_on_mobile_web_after_touch_capability_detection() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_configure_mobile_web_touch_runtime(scene, false)

	var touch_layer: CanvasLayer = scene.get_node("%TouchLayer")
	assert_false(touch_layer.visible)

	scene._touchscreen_available_override = true
	scene._refresh_touch_controls()

	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_true(touch_layer.visible)
	assert_true(scene._touch_controls_enabled_for_runtime)
	assert_false(touch_left.disabled)
	assert_false(touch_right.disabled)
	assert_false(touch_pause.disabled)


func test_touch_controls_reveal_on_first_mobile_web_touch_when_capability_is_delayed() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_configure_mobile_web_touch_runtime(scene, false)

	var touch_layer: CanvasLayer = scene.get_node("%TouchLayer")
	assert_false(touch_layer.visible)

	var touch_event := InputEventScreenTouch.new()
	touch_event.pressed = true
	touch_event.index = 0
	touch_event.position = Vector2(320.0, 180.0)
	scene._input(touch_event)

	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_true(touch_layer.visible)
	assert_true(scene._touch_controls_enabled_for_runtime)
	assert_false(touch_left.disabled)
	assert_false(touch_right.disabled)
	assert_false(touch_pause.disabled)


func test_touch_steering_buttons_hold_and_release_their_actions() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_enable_touch_controls_for_native_mobile(scene)

	var touch_left: Button = scene.get_node("%TouchLeft")
	touch_left.button_down.emit()
	await wait_process_frames(1)
	scene._process(0.5)
	var lateral_after_hold := state.lateral_position
	touch_left.button_up.emit()
	await wait_process_frames(1)

	assert_true(lateral_after_hold < 0.0)
	assert_false(Input.is_action_pressed("steer_left"))


func test_hidden_touch_controls_do_not_press_steering_actions() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var touch_left: Button = scene.get_node("%TouchLeft")
	touch_left.button_down.emit()
	await wait_process_frames(1)
	scene._process(0.5)

	assert_false(Input.is_action_pressed("steer_left"))
	assert_eq(state.lateral_position, 0.0)


func test_touch_steering_counts_as_recovery_input() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	_enable_touch_controls_for_native_mobile(scene)
	var expected_sequence := _start_seeded_recovery_sequence(scene, state, 10)

	var touch_button: Button = (
		scene.get_node("%TouchLeft")
		if expected_sequence[0] == &"steer_left"
		else scene.get_node("%TouchRight")
	)
	touch_button.button_down.emit()
	await wait_process_frames(1)
	touch_button.button_up.emit()

	assert_eq(state.recovery_prompt_index, 1)


func test_touch_pause_button_opens_pause_and_hides_touch_controls() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_enable_touch_controls_for_native_mobile(scene)

	var touch_layer: CanvasLayer = scene.get_node("%TouchLayer")
	var touch_pause: Button = scene.get_node("%TouchPause")
	assert_true(touch_layer.visible)

	var touch_left: Button = scene.get_node("%TouchLeft")
	touch_left.button_down.emit()
	await wait_process_frames(1)
	assert_true(Input.is_action_pressed("steer_left"))

	touch_pause.pressed.emit()
	await wait_process_frames(1)

	assert_true(scene._pause_menu_open)
	assert_false(touch_layer.visible)
	assert_false(Input.is_action_pressed("steer_left"))


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


## Verifies the result screen lands keyboard focus on restart as soon as it opens.
func test_result_panel_when_opened_then_restart_button_has_default_focus() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.cargo_value = 88
	state.wagon_health = 54
	scene.setup(state)
	scene._refresh_result_screen()
	await wait_process_frames(1)

	var restart_button: Button = scene.get_node("ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton")
	var return_button: Button = scene.get_node("ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultReturnButton")
	assert_true(restart_button.has_focus())
	assert_false(return_button.has_focus())


## Verifies the result buttons move focus predictably with keyboard navigation.
func test_result_panel_when_open_then_keyboard_navigation_moves_between_actions() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_COLLAPSED
	state.distance_remaining = 375.0
	state.cargo_value = 10
	state.wagon_health = 20
	scene.setup(state)
	scene._refresh_result_screen()
	await wait_process_frames(1)

	var restart_button: Button = scene.get_node("ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton")
	var return_button: Button = scene.get_node("ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultReturnButton")
	assert_true(restart_button.has_focus())

	await _send_key_input(KEY_RIGHT)

	assert_false(restart_button.has_focus())
	assert_true(return_button.has_focus())

	await _send_key_input(KEY_LEFT)

	assert_true(restart_button.has_focus())
	assert_false(return_button.has_focus())


## Verifies keyboard confirm activates the focused restart result action.
func test_result_panel_when_confirming_focused_restart_then_restart_requested_emits() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.cargo_value = 88
	state.wagon_health = 54
	scene.setup(state)
	scene._refresh_result_screen()
	await wait_process_frames(1)

	var ui_click_player: AudioStreamPlayer = scene.get_node("%UIClickPlayer")
	ui_click_player.stream = null

	watch_signals(scene)
	await _send_key_input(KEY_ENTER)

	assert_signal_emitted(scene, "restart_requested")


## Verifies keyboard confirm activates the focused return-to-title result action.
func test_result_panel_when_confirming_focused_return_then_return_to_title_requested_emits() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.cargo_value = 88
	state.wagon_health = 54
	scene.setup(state)
	scene._refresh_result_screen()
	await wait_process_frames(1)

	var ui_click_player: AudioStreamPlayer = scene.get_node("%UIClickPlayer")
	ui_click_player.stream = null
	await _send_key_input(KEY_RIGHT)

	watch_signals(scene)
	await _send_key_input(KEY_ENTER)

	assert_signal_emitted(scene, "return_to_title_requested")


## Verifies the success result panel shows score and grade alongside the stat summary.
func test_result_panel_includes_score_grade_and_small_stats_summary_for_success() -> void:
	var scene = RUN_SCENE.instantiate()
	scene._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.cargo_value = 72
	state.wagon_health = 41
	state.current_speed = 0.0
	state.hazards_dodged = 9
	state.near_misses = 3
	state.perfect_recoveries = 2
	state.recovery_failures = 1
	scene.setup(state)
	scene._refresh_result_screen()

	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats: Label = scene.get_node("%ResultStats")
	assert_true(result_summary.visible)
	assert_string_contains(result_summary.text, "New Best Run!")
	assert_string_contains(result_summary.text, "Best Score: 1565")
	assert_string_contains(result_summary.text, "Best Grade: A")
	assert_string_contains(result_stats.text, "Score: 1565")
	assert_string_contains(result_stats.text, "Delivery Grade: A")
	assert_string_contains(result_stats.text, "Health: 41")
	assert_string_contains(result_stats.text, "Cargo: 72")
	assert_string_contains(result_stats.text, "Distance traveled: 500 / 500")
	assert_string_contains(result_stats.text, "Hazards Dodged: 9")
	assert_string_contains(result_stats.text, "Near Misses: 3")
	assert_string_contains(result_stats.text, "Perfect Recoveries: 2")
	assert_string_contains(result_stats.text, "Recovery Failures: 1")
	assert_false(result_stats.text.contains("Speed:"))

	var restart_button: Button = scene.get_node("ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton")
	var return_button: Button = scene.get_node("ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultReturnButton")
	assert_eq(restart_button.text, "Restart")
	assert_eq(return_button.text, "Title")


## Verifies the collapse result panel uses the same score and grade wiring.
func test_result_panel_includes_score_and_grade_for_collapse() -> void:
	var scene = RUN_SCENE.instantiate()
	scene._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_COLLAPSED
	state.distance_remaining = 375.0
	state.cargo_value = 10
	state.wagon_health = 20
	state.hazards_dodged = 2
	state.near_misses = 1
	state.perfect_recoveries = 0
	state.recovery_failures = 3
	scene.setup(state)
	scene._refresh_result_screen()

	var result_title: Label = scene.get_node("%ResultTitle")
	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats: Label = scene.get_node("%ResultStats")
	assert_eq(result_title.text, "Wagon Collapsed")
	assert_true(result_summary.visible)
	assert_string_contains(result_summary.text, "New Best Run!")
	assert_string_contains(result_summary.text, "Best Score: 400")
	assert_string_contains(result_summary.text, "Best Grade: F")
	assert_string_contains(result_stats.text, "Score: 400")
	assert_string_contains(result_stats.text, "Delivery Grade: F")
	assert_string_contains(result_stats.text, "Health: 20")
	assert_string_contains(result_stats.text, "Cargo: 10")
	assert_string_contains(result_stats.text, "Distance traveled: 125 / 500")
	assert_string_contains(result_stats.text, "Hazards Dodged: 2")
	assert_string_contains(result_stats.text, "Near Misses: 1")
	assert_string_contains(result_stats.text, "Perfect Recoveries: 0")
	assert_string_contains(result_stats.text, "Recovery Failures: 3")


## Verifies the completed-run result flow does not overwrite a higher stored best score.
func test_result_flow_when_completed_score_is_lower_then_stored_best_run_is_unchanged() -> void:
	assert_eq(
		RunStateType.save_best_run(RunStateType.BestRunData.new(1700, "A", true), TEST_BEST_RUN_SAVE_PATH),
		OK
	)
	var scene = RUN_SCENE.instantiate()
	scene._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_COLLAPSED
	state.distance_remaining = 375.0
	state.cargo_value = 10
	state.wagon_health = 20
	scene.setup(state)

	var stored_best := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)
	var result_summary: Label = scene.get_node("%ResultSummary")

	assert_false(state.current_run_is_new_best)
	assert_true(result_summary.visible)
	assert_false(result_summary.text.contains("New Best Run!"))
	assert_string_contains(result_summary.text, "Best Score: 1700")
	assert_string_contains(result_summary.text, "Best Grade: A")
	assert_eq(stored_best.score, 1700)
	assert_eq(stored_best.grade, "A")


## Verifies the completed-run result flow persists a strictly higher score as the new best run.
func test_result_flow_when_completed_score_is_higher_then_new_best_run_is_saved() -> void:
	assert_eq(
		RunStateType.save_best_run(RunStateType.BestRunData.new(1200, "B", true), TEST_BEST_RUN_SAVE_PATH),
		OK
	)
	var scene = RUN_SCENE.instantiate()
	scene._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.cargo_value = 88
	state.wagon_health = 54
	scene.setup(state)

	var stored_best := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)
	var result_summary: Label = scene.get_node("%ResultSummary")

	assert_true(state.current_run_is_new_best)
	assert_true(result_summary.visible)
	assert_string_contains(result_summary.text, "New Best Run!")
	assert_eq(stored_best.score, state.get_score())
	assert_eq(stored_best.grade, state.get_delivery_grade())


func test_result_panel_fits_viewport_with_full_mastery_breakdown_for_success() -> void:
	var scene = RUN_SCENE.instantiate()
	scene._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.cargo_value = 88
	state.wagon_health = 54
	state.hazards_dodged = 12
	state.near_misses = 4
	state.perfect_recoveries = 3
	state.recovery_failures = 2
	scene.setup(state)
	scene._refresh_result_screen()
	await wait_process_frames(1)

	var viewport_rect: Rect2 = scene.get_viewport_rect()
	var result_title: Label = scene.get_node("%ResultTitle")
	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats: Label = scene.get_node("%ResultStats")
	var restart_button: Button = scene.get_node(
		"ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton"
	)
	var title_button: Button = scene.get_node(
		"ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultReturnButton"
	)

	assert_true(result_title.get_global_rect().position.y >= viewport_rect.position.y)
	assert_true(result_summary.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(result_stats.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(restart_button.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(title_button.get_global_rect().end.y <= viewport_rect.end.y)


func test_result_panel_fits_viewport_with_full_mastery_breakdown_for_collapse() -> void:
	var scene = RUN_SCENE.instantiate()
	scene._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_COLLAPSED
	state.distance_remaining = 4359.0
	state.route_distance = 10000.0
	state.cargo_value = 48
	state.wagon_health = 0
	state.hazards_dodged = 1
	state.near_misses = 1
	state.perfect_recoveries = 1
	state.recovery_failures = 1
	scene.setup(state)
	scene._refresh_result_screen()
	await wait_process_frames(1)

	var viewport_rect: Rect2 = scene.get_viewport_rect()
	var result_title: Label = scene.get_node("%ResultTitle")
	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats: Label = scene.get_node("%ResultStats")
	var restart_button: Button = scene.get_node(
		"ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton"
	)
	var title_button: Button = scene.get_node(
		"ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultReturnButton"
	)

	assert_true(result_title.get_global_rect().position.y >= viewport_rect.position.y)
	assert_true(result_summary.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(result_stats.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(restart_button.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(title_button.get_global_rect().end.y <= viewport_rect.end.y)


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
	assert_true(resume_button.has_focus())
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

	restart_button.pressed.emit()
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout
	assert_false(scene._pause_menu_open)
	assert_false(get_tree().paused)
	assert_signal_emitted(scene, "restart_requested")

	scene._set_pause_state(true)
	await wait_process_frames(1)
	return_button.pressed.emit()
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
	resume_button.pressed.emit()
	await wait_process_frames(1)

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
		if child is Sprite2D and child.name == "RoadsideSign" and child.texture == scene.SIGN_TEXTURE:
			sign_found = true
			break

	assert_true(sign_found)


func test_step4_environment_art_replaces_route_placeholder_geometry() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var backdrop: Sprite2D = scene.get_node("World/Backdrop")
	var road: Sprite2D = scene.get_node("World/Road")
	assert_eq(backdrop.texture, scene.DESERT_TEXTURE)
	assert_eq(road.texture, scene.ROAD_TEXTURE)
	assert_true(backdrop.region_enabled)
	assert_true(road.region_enabled)
	assert_false(scene.has_node("World/RoadStripeLeft"))
	assert_false(scene.has_node("World/RoadStripeRight"))


func test_step4_environment_art_scrolls_with_route_motion() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var backdrop: Sprite2D = scene.get_node("World/Backdrop")
	var road: Sprite2D = scene.get_node("World/Road")
	var starting_backdrop_offset := backdrop.region_rect.position.y
	var starting_road_offset := road.region_rect.position.y

	scene._process(0.5)

	assert_true(backdrop.region_rect.position.y < starting_backdrop_offset)
	assert_true(road.region_rect.position.y < starting_road_offset)


func test_step3_cohesion_nodes_exist_on_wagon() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_true(scene.has_node("World/Wagon/Shadow"))
	assert_true(scene.has_node("World/Wagon/CarriageSprite"))
	assert_true(scene.has_node("World/Wagon/HorseTeam/HorseLeft"))
	assert_true(scene.has_node("World/Wagon/HorseTeam/HorseRight"))


## Confirms the animated carriage sprite is wired to sheet slices from the exported asset.
func test_step1_carriage_sprite_uses_animated_sheet_frames() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var carriage_sprite := scene.get_node("World/Wagon/CarriageSprite") as AnimatedSprite2D
	assert_not_null(carriage_sprite)
	assert_not_null(carriage_sprite.sprite_frames)
	assert_true(carriage_sprite.sprite_frames.has_animation("default"))
	assert_eq(carriage_sprite.sprite_frames.get_frame_count("default"), 2)
	assert_gt(carriage_sprite.sprite_frames.get_animation_speed("default"), 0.0)
	assert_eq(carriage_sprite.position, Vector2.ZERO)

	var frame_0 := carriage_sprite.sprite_frames.get_frame_texture("default", 0) as AtlasTexture
	var frame_1 := carriage_sprite.sprite_frames.get_frame_texture("default", 1) as AtlasTexture

	assert_not_null(frame_0)
	assert_not_null(frame_1)
	assert_eq(frame_0.atlas, scene.CARRIAGE_SHEET_TEXTURE)
	assert_eq(frame_1.atlas, scene.CARRIAGE_SHEET_TEXTURE)
	assert_eq(frame_0.get_size(), Vector2(32, 64))
	assert_eq(frame_1.get_size(), Vector2(32, 64))
	assert_true(carriage_sprite.is_playing())
	assert_gt(carriage_sprite.get_playing_speed(), 0.0)


## Confirms the wagon rig still applies the existing presentation state while the carriage animates.
func test_step2_vehicle_sprites_replace_placeholder_shapes() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var wagon: Polygon2D = scene.get_node("%Wagon")
	var carriage_sprite := scene.get_node("World/Wagon/CarriageSprite") as AnimatedSprite2D
	var horse_left: Sprite2D = scene.get_node("World/Wagon/HorseTeam/HorseLeft")
	var horse_right: Sprite2D = scene.get_node("World/Wagon/HorseTeam/HorseRight")

	assert_eq(wagon.color.a, 0.0)
	assert_not_null(carriage_sprite)
	assert_true(carriage_sprite.is_playing())
	assert_eq(horse_left.texture, scene.HORSE_TEXTURE)
	assert_eq(horse_right.texture, scene.HORSE_TEXTURE)


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


## Removes the persisted best-run fixture file when the test created one.
func _delete_test_best_run_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_BEST_RUN_SAVE_PATH)
	if FileAccess.file_exists(TEST_BEST_RUN_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
