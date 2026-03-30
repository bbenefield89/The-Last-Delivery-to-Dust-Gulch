extends GutTest

# Constants
const HazardInstanceType := preload(ProjectPaths.HAZARD_INSTANCE_SCRIPT_PATH)
const HazardSpawnerType := preload(ProjectPaths.HAZARD_SPAWNER_SCRIPT_PATH)
const RecoverySequenceGeneratorType := preload(ProjectPaths.RECOVERY_SEQUENCE_GENERATOR_SCRIPT_PATH)
const RunAudioPresenterType := preload(ProjectPaths.RUN_AUDIO_PRESENTER_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunHazardResolverType := preload(ProjectPaths.RUN_HAZARD_RESOLVER_SCRIPT_PATH)
const RunPresentationType := preload(ProjectPaths.RUN_PRESENTATION_SCRIPT_PATH)
const ResultPanelUiType := preload(ProjectPaths.RESULT_PANEL_UI_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const GameplayUiLayerType := preload(ProjectPaths.GAMEPLAY_UI_LAYER_SCRIPT_PATH)
const RunUiPresenterType := GameplayUiLayerType


const RUN_SCENE := preload(ProjectPaths.RUN_SCENE_PATH)
const LIVESTOCK_TEXTURE := preload(AssetPaths.LIVESTOCK_TEXTURE_PATH)
const TEST_BEST_RUN_SAVE_PATH := SavePaths.TEST_RUN_SCENE_BEST_RUN_SAVE_PATH
# Public Methods



## Clears the scene-level best-run fixture before each test uses the override save path.
func before_each() -> void:
	_delete_test_best_run_file()


## Clears the scene-level best-run fixture after each test completes.
func after_each() -> void:
	_delete_test_best_run_file()
# Private Methods



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


## Dismisses onboarding through the same steer-input path a player uses.
func _dismiss_onboarding(scene: Node) -> void:
	var dismiss_event := InputEventAction.new()
	dismiss_event.action = &"steer_left"
	dismiss_event.pressed = true
	scene._input(dismiss_event)


## Binds a run state and dismisses onboarding so the scene enters active gameplay.
func _setup_active_run(scene: Node, state: RunStateType) -> void:
	scene.setup(state)
	_dismiss_onboarding(scene)


## Starts a run at a specific delivery progress ratio before dismissing onboarding.
func _setup_active_run_at_progress(scene: Node, state: RunStateType, progress_ratio: float) -> void:
	state.distance_remaining = state.route_distance * (1.0 - progress_ratio)
	scene.setup(state)
	_dismiss_onboarding(scene)


## Returns the extracted run director bound to the active test scene.
func _get_run_director(scene: Node) -> RunDirectorType:
	return scene._run_director as RunDirectorType


## Returns the extracted hazard resolver bound to the active test scene.
func _get_run_hazard_resolver(scene: Node) -> RunHazardResolverType:
	return scene._run_hazard_resolver as RunHazardResolverType


## Returns the extracted presentation owner bound to the active test scene.
func _get_run_presentation(scene: Node) -> RunPresentationType:
	return scene._run_presentation as RunPresentationType


## Returns the extracted audio presenter bound to the active test scene.
func _get_run_audio_presenter(scene: Node) -> RunAudioPresenterType:
	return scene._run_audio_presenter as RunAudioPresenterType


## Returns the extracted UI presenter bound to the active test scene.
func _get_run_ui_presenter(scene: Node) -> RunUiPresenterType:
	return scene._run_ui_presenter as RunUiPresenterType


## Returns the node-backed gameplay UI owner attached to the run scene canvas layer.
func _get_gameplay_ui_layer(scene: Node) -> GameplayUiLayerType:
	return scene.get_node("%GameplayUiLayer") as GameplayUiLayerType


## Returns the visible stats-row container from the structured result panel.
func _get_result_stats_rows(scene: Node) -> VBoxContainer:
	return scene.get_node("%ResultStatsRows") as VBoxContainer


## Returns the bounded scroll container that owns the visible result-stat rows.
func _get_result_stats_scroll(scene: Node) -> ScrollContainer:
	return scene.get_node("%ResultStatsScroll") as ScrollContainer


## Returns the rendered value for one named result-stat row, or an empty string when absent.
func _get_result_stat_value(scene: Node, stat_name: String) -> String:
	var result_stats_rows := _get_result_stats_rows(scene)
	for child in result_stats_rows.get_children():
		var stat_row := child as HBoxContainer
		if stat_row == null:
			continue

		var stat_name_label := stat_row.get_node("StatNameLabel") as Label
		var stat_value_label := stat_row.get_node("StatValueLabel") as Label
		if stat_name_label != null and stat_name_label.text == stat_name and stat_value_label != null:
			return stat_value_label.text

	return ""


## Returns the ordered gameplay UI wrapper controls under the unified canvas layer.
func _get_gameplay_ui_wrappers(scene: Node) -> Array[Control]:
	var gameplay_ui_layer := scene.get_node("%GameplayUiLayer") as CanvasLayer
	var wrappers: Array[Control] = []
	for child in gameplay_ui_layer.get_children():
		if child is Control:
			wrappers.append(child as Control)
	return wrappers


## Asserts one gameplay UI wrapper keeps the expected visibility and mouse policy.
func _assert_gameplay_ui_wrapper_state(
	scene: Node,
	layer_name: String,
	expected_visible: bool,
	expected_mouse_filter: Control.MouseFilter
) -> void:
	var layer := scene.get_node("GameplayUiLayer/%s" % layer_name) as Control
	assert_not_null(layer)
	assert_eq(layer.visible, expected_visible)
	assert_eq(layer.mouse_filter, expected_mouse_filter)
# Public Methods



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


## Verifies route phase when transitioning from warm up then first trouble callout appears.

func test_route_phase_when_transitioning_from_warm_up_then_first_trouble_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.19, 0.05, "First Trouble")


## Verifies route phase when transitioning from first trouble then crossing beats callout appears.

func test_route_phase_when_transitioning_from_first_trouble_then_crossing_beats_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.44, 0.05, "Crossing Beat")


## Verifies route phase when transitioning from crossing then clutter callout appears.

func test_route_phase_when_transitioning_from_crossing_then_clutter_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.59, 0.05, "Clutter Beat")


## Verifies route phase when transitioning from clutter then reset callout appears.

func test_route_phase_when_transitioning_from_clutter_then_reset_callout_appears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_assert_phase_callout_for_transition(scene, state, 0.79, 0.05, "Reset Before Finale")


## Verifies route phase when transitioning from reset then final stretch callout appears.

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
	var run_director := _get_run_director(scene)
	run_director.bad_luck_rng.seed = 7
	_setup_active_run_at_progress(scene, state, 0.879)

	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_true(run_director.is_timer_bad_luck_enabled())
	assert_true(run_director.scheduled_bad_luck_interval > 0.0)

	state.distance_remaining = state.route_distance * 0.12
	scene._process(0.0)

	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_FINAL_STRETCH)
	assert_false(run_director.is_timer_bad_luck_enabled())
	assert_eq(run_director.scheduled_bad_luck_interval, 0.0)
	assert_eq(run_director.bad_luck_elapsed, 0.0)
	assert_false(run_director.pending_bad_luck_trigger)

	scene._advance_failure_triggers(999.0)

	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_FINAL_STRETCH)
	assert_eq(state.active_failure, &"")
	assert_eq(run_director.scheduled_bad_luck_interval, 0.0)
	assert_eq(run_director.bad_luck_elapsed, 0.0)
	assert_false(run_director.pending_bad_luck_trigger)


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

	_get_run_director(scene).bad_luck_rng.seed = 23
	scene._hazard_spawner._rng.seed = 23
	scene._process(0.0)

	assert_eq(_get_run_director(scene).route_phase, scene.ROUTE_PHASE_FINAL_STRETCH)
	assert_not_null(scene._hazard_spawner._next_spawn_plan)

	var planned_spacing: float = scene._hazard_spawner._next_spawn_plan.spacing
	scene._process(planned_spacing / state.current_speed)

	assert_true(scene._hazard_spawner.get_child_count() > 0)

	var runway_delta: float = (
		state.distance_remaining - scene._hazard_spawner.FINAL_STRETCH_CLEAR_RUNWAY_DISTANCE
	) / state.current_speed
	scene._process(runway_delta)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await wait_process_frames(1)
	for _step in range(8):
		if scene._hazard_spawner.get_child_count() == 0:
			break
		scene._process(0.5)
		await get_tree().physics_frame
		await wait_process_frames(1)

	assert_true(state.distance_remaining <= scene._hazard_spawner.FINAL_STRETCH_CLEAR_RUNWAY_DISTANCE)
	assert_eq(scene._hazard_spawner.get_child_count(), 0)
	assert_eq(scene._hazard_spawner._next_spawn_plan, null)
	assert_eq(scene._hazard_spawner._distance_until_next_spawn, 0.0)
	assert_eq(scene._hazard_spawner._get_route_phase(0.98), scene._hazard_spawner.ROUTE_PHASE_FINAL_STRETCH)


## Verifies dismissing onboarding when run starts then warm up callout appears.

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
	_get_run_ui_presenter(scene).has_native_mobile_runtime_override = true
	_get_run_ui_presenter(scene).native_mobile_runtime_override = true
	scene._refresh_touch_controls()


## Configures the test scene to behave like a mobile web runtime with controllable touch capability.
func _configure_mobile_web_touch_runtime(scene: Node, touchscreen_available: bool) -> void:
	_get_run_ui_presenter(scene).has_mobile_web_runtime_override = true
	_get_run_ui_presenter(scene).mobile_web_runtime_override = true
	_get_run_ui_presenter(scene).has_touchscreen_available_override = true
	_get_run_ui_presenter(scene).touchscreen_available_override = touchscreen_available
	scene._refresh_touch_controls()


## Confirms RunScene binds the extracted rule owners without keeping duplicate route-state fields.

func test_setup_binds_run_rule_systems_without_scene_route_state_mirrors() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.distance_remaining = state.route_distance * 0.70
	scene.setup(state)

	var property_names := scene.get_property_list().map(
		func(property_data: Dictionary) -> String:
			return property_data.get("name", "")
	)

	assert_not_null(_get_run_director(scene))
	assert_not_null(_get_run_hazard_resolver(scene))
	assert_false(property_names.has("_route_phase"))
	assert_false(property_names.has("_route_phase_callout_zone"))
	assert_false(property_names.has("_scheduled_bad_luck_interval"))
	assert_false(property_names.has("_pending_bad_luck_trigger"))
	assert_false(property_names.has("_bad_luck_elapsed"))
	assert_false(property_names.has("_bad_luck_rng"))


## Confirms the run scene delegates scroll and impact presentation state to the extracted presentation owner.

func test_setup_binds_run_presentation_without_scene_scroll_or_impact_mirrors() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var property_names := scene.get_property_list().map(
		func(property_data: Dictionary) -> String:
			return property_data.get("name", "")
	)
	var run_presentation := _get_run_presentation(scene)

	assert_not_null(run_presentation)
	assert_eq(run_presentation.scroll_offset, 0.0)
	assert_eq(run_presentation.impact_time, 0.0)
	assert_false(property_names.has("_scroll_offset"))
	assert_false(property_names.has("_impact_flash_remaining"))
	assert_false(property_names.has("_impact_wobble_remaining"))
	assert_false(property_names.has("_impact_shake_remaining"))
	assert_false(property_names.has("_impact_time"))


## Confirms the run scene delegates transient UI state to the extracted UI presenter.

func test_setup_binds_run_ui_presenter_without_scene_ui_state_mirrors() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var property_names := scene.get_property_list().map(
		func(property_data: Dictionary) -> String:
			return property_data.get("name", "")
	)
	var run_ui_presenter := _get_run_ui_presenter(scene)

	assert_not_null(run_ui_presenter)
	assert_true(run_ui_presenter.onboarding_active)
	assert_false(run_ui_presenter.pause_menu_open)
	assert_false(run_ui_presenter.touch_controls_enabled_for_runtime)
	assert_false(property_names.has("_onboarding_active"))
	assert_false(property_names.has("_pause_menu_open"))
	assert_false(property_names.has("_touch_controls_enabled_for_runtime"))
	assert_false(property_names.has("_has_native_mobile_runtime_override"))
	assert_false(property_names.has("_native_mobile_runtime_override"))
	assert_false(property_names.has("_has_mobile_web_runtime_override"))
	assert_false(property_names.has("_mobile_web_runtime_override"))
	assert_false(property_names.has("_has_touchscreen_available_override"))
	assert_false(property_names.has("_touchscreen_available_override"))


## Confirms the gameplay UI owner is attached to the canvas layer and the scene no longer mirrors UI subtree nodes.
func test_setup_uses_node_backed_gameplay_ui_layer_without_scene_ui_node_refs() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var property_names := scene.get_property_list().map(
		func(property_data: Dictionary) -> String:
			return property_data.get("name", "")
	)
	var gameplay_ui_layer := _get_gameplay_ui_layer(scene)

	assert_not_null(gameplay_ui_layer)
	assert_eq(_get_run_ui_presenter(scene), gameplay_ui_layer)
	assert_eq(gameplay_ui_layer.get_script().resource_path, ProjectPaths.GAMEPLAY_UI_LAYER_SCRIPT_PATH)
	assert_false(property_names.has("_gameplay_ui_layer"))
	assert_false(property_names.has("_hud_layer"))
	assert_false(property_names.has("_touch_left_button"))
	assert_false(property_names.has("_pause_overlay"))
	assert_false(property_names.has("_result_panel"))


## Confirms the run scene delegates audio transition state to the extracted audio presenter.

func test_setup_binds_run_audio_presenter_without_scene_audio_state_mirrors() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	var run_audio_presenter := _get_run_audio_presenter(scene)

	var property_names := scene.get_property_list().map(
		func(property_data: Dictionary) -> String:
			return property_data.get("name", "")
	)

	assert_not_null(run_audio_presenter)
	assert_eq(run_audio_presenter.last_announced_failure, state.active_failure)
	assert_eq(run_audio_presenter.last_announced_result, state.result)
	assert_eq(run_audio_presenter.tumbleweed_impact_serial, 0)
	assert_false(property_names.has("_last_announced_failure"))
	assert_false(property_names.has("_last_announced_result"))
	assert_false(property_names.has("_tumbleweed_impact_serial"))


## Rebuilds the expected seeded recovery sequence for the current progress band.
func _build_expected_recovery_sequence(scene: Node, progress: float, seed: int) -> Array[StringName]:
	var generator := RecoverySequenceGeneratorType.new()
	generator.set_seed(seed)
	return generator.generate_sequence(progress, scene.RECOVERY_PROMPT_POOL)


## Triggers a seeded failure flow and returns the expected authored recovery sequence.
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


## Clicks a control through the same mouse-event path used by the runtime UI.
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


## Verifies setup populates hud labels with run state values.

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

	var health_tag: Label = scene.get_node("GameplayUiLayer/HUDLayer/HUDPanel/MarginContainer/VBoxContainer/HealthRow/HealthTag")
	var health_bar_margin: MarginContainer = scene.get_node("GameplayUiLayer/HUDLayer/HUDPanel/MarginContainer/VBoxContainer/HealthRow/HealthBarMargin")
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


## Verifies setup shows onboarding panel at run start.

func test_setup_shows_onboarding_panel_at_run_start() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	var onboarding_panel: PanelContainer = scene.get_node("%OnboardingPanel")
	var onboarding_title: Label = scene.get_node("%OnboardingTitle")
	assert_true(_get_run_ui_presenter(scene).onboarding_active)
	assert_true(onboarding_panel.visible)
	assert_eq(onboarding_title.text, scene.ONBOARDING_TITLE)


## Verifies onboarding freezes distance and hazard spawning while road scrolls.

func test_onboarding_freezes_distance_and_hazard_spawning_while_road_scrolls() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	var starting_distance := state.distance_remaining
	var starting_scroll: float = _get_run_presentation(scene).scroll_offset

	scene._process(0.5)

	var spawner = scene.get_node("%HazardSpawner")
	assert_eq(state.distance_remaining, starting_distance)
	assert_eq(spawner.get_child_count(), 0)
	assert_true(_get_run_presentation(scene).scroll_offset > starting_scroll)


## Verifies dismissing onboarding with steer input starts normal gameplay.

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
	assert_false(_get_run_ui_presenter(scene).onboarding_active)
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
	assert_false(_get_run_ui_presenter(scene).onboarding_active)
	assert_false(onboarding_panel.visible)
	assert_true(state.distance_remaining < distance_before_process)
	assert_true(spawner.get_child_count() > 0)


## Verifies ready registers steering input actions.

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
	assert_true(_get_run_ui_presenter(scene).pause_menu_open)
	assert_true(pause_overlay.visible)
	assert_true(pause_panel.visible)
	assert_true(resume_button.has_focus())


## Verifies the UI presenter owns pause-menu click routing once the modal is open.

func test_ui_presenter_when_pause_resume_button_is_clicked_then_route_input_returns_resume_action() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	scene._set_pause_state(true)

	var resume_button: Button = scene.get_node("%PauseResumeButton")
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = resume_button.get_global_rect().get_center()

	var ui_input_result := _get_run_ui_presenter(scene).route_input(click_event, scene.PAUSE_ACTION)

	assert_true(ui_input_result.consumed)
	assert_eq(ui_input_result.navigation_action, RunUiPresenterType.PAUSE_MENU_ACTION_RESUME)


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
	assert_false(_get_run_ui_presenter(scene).pause_menu_open)


## Verifies the existing cancel input closes the pause menu without needing a mouse click.

func test_pause_menu_when_open_then_escape_closes_it() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	await _send_key_input(KEY_ENTER)
	await _send_key_input(KEY_ESCAPE)
	assert_true(_get_run_ui_presenter(scene).pause_menu_open)

	await _send_key_input(KEY_ESCAPE)

	var pause_overlay: Control = scene.get_node("%PauseOverlay")
	var pause_panel: PanelContainer = scene.get_node("%PausePanel")
	assert_false(_get_run_ui_presenter(scene).pause_menu_open)
	assert_false(pause_overlay.visible)
	assert_false(pause_panel.visible)


## Verifies process moves right and reduces distance.

func test_process_moves_right_and_reduces_distance() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	var horse_team: Node2D = scene.get_node("World/Wagon/HorseTeam")
	var horse_left := scene.get_node("World/Wagon/HorseTeam/HorseLeft") as AnimatedSprite2D
	var horse_right := scene.get_node("World/Wagon/HorseTeam/HorseRight") as AnimatedSprite2D

	Input.action_press("steer_right")
	scene._process(0.5)
	Input.action_release("steer_right")

	assert_almost_eq(state.lateral_position, 90.0, 0.01)
	assert_almost_eq(
		state.distance_remaining,
		RunStateType.DEFAULT_DISTANCE_REMAINING - (RunStateType.DEFAULT_FORWARD_SPEED * 0.5),
		0.01
	)
	assert_eq(horse_team.position, Vector2(0.0, -38.0))
	assert_eq(horse_left.position, Vector2(-8.0, 0.0))
	assert_eq(horse_right.position, Vector2(8.0, 0.0))


## Verifies process clamps lateral position to road bounds.

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


## Verifies hazard collision reduces health and records last hit type.

func test_hazard_collision_reduces_health_and_records_last_hit_type() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"pothole")
	await get_tree().physics_frame
	await get_tree().physics_frame
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


## Verifies rock collision when it hits then it causes the heavier wheel loose punishment.

func test_rock_collision_when_it_hits_then_it_causes_the_heavier_wheel_loose_punishment() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"rock")
	await get_tree().physics_frame
	await get_tree().physics_frame
	scene._process(0.0)
	await wait_process_frames(1)

	assert_eq(state.wagon_health, 82)
	assert_eq(state.cargo_value, 91)
	assert_eq(state.last_hit_hazard, &"rock")
	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")


## Verifies near miss when hazard passes close without collision then bonus and callout are awarded once.

func test_near_miss_when_hazard_passes_close_without_collision_then_bonus_and_callout_are_awarded_once() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"pothole").position = Vector2(0.0, -120.0)
	state.lateral_position = 40.0
	scene._update_wagon_visual()
	var near_miss_awarded := false
	var dodge_recorded := false
	for _step in range(60):
		scene._process(0.1)
		await get_tree().physics_frame
		scene._process(0.0)
		if state.near_misses == 1:
			near_miss_awarded = true
		if state.hazards_dodged == 1:
			dodge_recorded = true
		if near_miss_awarded and dodge_recorded:
			break

	var bonus_callout_panel: Control = scene.get_node("%BonusCalloutPanel")
	var bonus_callout_label: Label = scene.get_node("%BonusCalloutLabel")
	var wagon: Node2D = scene.get_node("%Wagon")
	var wagon_canvas_position: Vector2 = scene.get_viewport().get_canvas_transform() * wagon.global_position
	var bonus_callout_center: Vector2 = bonus_callout_panel.get_global_rect().get_center()

	assert_true(near_miss_awarded)
	assert_true(dodge_recorded)
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


## Verifies clean dodge when hazard passes safely then only hazards dodged increments.

func test_clean_dodge_when_hazard_passes_safely_then_only_hazards_dodged_increments() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"pothole").position = Vector2(72.0, -120.0)
	for _step in range(60):
		scene._process(0.1)
		await get_tree().physics_frame
	scene._process(0.0)

	assert_eq(state.hazards_dodged, 1)
	assert_eq(state.near_misses, 0)
	assert_eq(state.bonus_score, 0)


## Verifies near miss bonus is not awarded for a real collision.

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


## Verifies near miss bonus is not awarded for side pass then late swerve toward hazard.

func test_near_miss_bonus_is_not_awarded_for_side_pass_then_late_swerve_toward_hazard() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var hazard: Node2D = _spawn_test_hazard(scene, &"pothole")
	hazard.position = Vector2(72.0, -120.0)
	var late_swerve_delta: float = 140.0 / state.current_speed
	scene._process(late_swerve_delta)
	await get_tree().physics_frame
	await wait_process_frames(1)
	state.lateral_position = 44.0
	scene._update_wagon_visual()
	var cleanup_delta: float = maxf(0.0, (284.0 - hazard.position.y) / state.current_speed)
	scene._process(cleanup_delta)
	await get_tree().physics_frame
	await wait_process_frames(1)
	scene._process(0.0)

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
	await get_tree().physics_frame
	await get_tree().physics_frame
	scene._process(0.0)
	await wait_process_frames(1)

	assert_eq(state.wagon_health, 88)
	assert_eq(state.cargo_value, 95)
	assert_eq(state.last_hit_hazard, &"livestock")
	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"livestock")


## Verifies hazard collision triggers hit flash wobble and camera shake.

func test_hazard_collision_triggers_hit_flash_wobble_and_camera_shake() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	_spawn_test_hazard(scene, &"pothole")
	await get_tree().physics_frame
	await get_tree().physics_frame
	scene._process(0.05)

	var wagon: Node2D = scene.get_node("%Wagon")
	var horse_team: Node2D = scene.get_node("World/Wagon/HorseTeam")
	var carriage_sprite := scene.get_node("World/Wagon/CarriageSprite") as AnimatedSprite2D
	var horse_left := scene.get_node("World/Wagon/HorseTeam/HorseLeft") as AnimatedSprite2D
	var horse_right := scene.get_node("World/Wagon/HorseTeam/HorseRight") as AnimatedSprite2D
	var camera: Camera2D = scene.get_node("%Camera")

	assert_eq(wagon.modulate, scene.WAGON_HIT_COLOR)
	assert_eq(horse_team.position, Vector2(0.0, -38.0))
	assert_not_null(carriage_sprite)
	assert_eq(carriage_sprite.modulate, scene.WAGON_HIT_COLOR)
	assert_not_null(horse_left)
	assert_not_null(horse_right)
	assert_eq(horse_left.modulate, scene.WAGON_HIT_COLOR)
	assert_eq(horse_right.modulate, scene.WAGON_HIT_COLOR)
	assert_ne(wagon.rotation, 0.0)
	assert_eq(carriage_sprite.global_rotation, wagon.global_rotation)
	assert_eq(horse_left.global_rotation, wagon.global_rotation)
	assert_eq(horse_right.global_rotation, wagon.global_rotation)
	assert_ne(camera.position, Vector2(320.0, 180.0))


## Verifies impact feedback recovers after timers expire.

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

	var wagon: Node2D = scene.get_node("%Wagon")
	var horse_team: Node2D = scene.get_node("World/Wagon/HorseTeam")
	var carriage_sprite := scene.get_node("World/Wagon/CarriageSprite") as AnimatedSprite2D
	var horse_left := scene.get_node("World/Wagon/HorseTeam/HorseLeft") as AnimatedSprite2D
	var horse_right := scene.get_node("World/Wagon/HorseTeam/HorseRight") as AnimatedSprite2D
	var camera: Camera2D = scene.get_node("%Camera")

	assert_eq(wagon.modulate, scene.WAGON_BASE_COLOR)
	assert_eq(horse_team.position, Vector2(0.0, -38.0))
	assert_not_null(carriage_sprite)
	assert_eq(carriage_sprite.modulate, scene.WAGON_BASE_COLOR)
	assert_not_null(horse_left)
	assert_not_null(horse_right)
	assert_eq(horse_left.modulate, scene.WAGON_BASE_COLOR)
	assert_eq(horse_right.modulate, scene.WAGON_BASE_COLOR)
	assert_eq(wagon.rotation, 0.0)
	assert_eq(carriage_sprite.global_rotation, wagon.global_rotation)
	assert_eq(horse_left.global_rotation, wagon.global_rotation)
	assert_eq(horse_right.global_rotation, wagon.global_rotation)
	assert_eq(camera.position, Vector2(320.0, 180.0))


## Verifies camera tracks wagon with below center offset.

func test_camera_tracks_wagon_with_below_center_offset() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.lateral_position = -80.0
	scene.setup(state)
	scene._process(0.0)

	var wagon: Node2D = scene.get_node("%Wagon")
	var camera: Camera2D = scene.get_node("%Camera")

	assert_eq(wagon.position, Vector2(240.0, 300.0))
	assert_eq(camera.position, Vector2(320.0, 180.0))


## Verifies forward motion scrolls the environment.

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


## Verifies scroll environment wraps for continuous travel.

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


## Verifies scroll segment populates enough roadside scrub to cover loop end.

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
	assert_eq(_get_run_director(crossing_scene).route_phase, crossing_scene.ROUTE_PHASE_CROSSING_BEAT)
	assert_true(crossing_spawner._get_active_band().allows_pressure_pair)

	var reset_scene = RUN_SCENE.instantiate()
	add_child_autofree(reset_scene)
	await wait_process_frames(1)

	var reset_state := RunStateType.new()
	reset_state.distance_remaining = RunStateType.DEFAULT_ROUTE_DISTANCE * 0.2
	_setup_active_run(reset_scene, reset_state)
	var reset_spawner = reset_scene.get_node("%HazardSpawner")
	reset_scene._process(0.0)
	assert_eq(_get_run_director(reset_scene).route_phase, reset_scene.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_false(reset_spawner._get_active_band().allows_pressure_pair)


## Verifies reaching dust gulch triggers success and stops forward motion.

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


## Verifies success state freezes progress on later frames.

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


## Verifies zero health triggers collapse and stops forward motion.

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


## Verifies rock collision triggers wheel loose failure.

func test_rock_collision_triggers_wheel_loose_failure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	_get_run_hazard_resolver(scene).attempt_failure_trigger_from_collision(_get_run_director(scene), &"rock")

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")


## Verifies tumbleweed collision triggers horse panic failure.

func test_tumbleweed_collision_triggers_horse_panic_failure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	_get_run_hazard_resolver(scene).attempt_failure_trigger_from_collision(_get_run_director(scene), &"tumbleweed")

	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"tumbleweed")


## Verifies timer bad luck still fires in the reset-before-finale phase.

func test_bad_luck_timer_triggers_failure_when_no_active_failure_exists() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	var run_director := _get_run_director(scene)
	run_director.bad_luck_rng.seed = 7
	_setup_active_run_at_progress(scene, state, 0.8)

	scene._advance_failure_triggers(run_director.scheduled_bad_luck_interval)

	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"bad_luck")
	assert_eq(run_director.bad_luck_elapsed, 0.0)
	assert_false(run_director.pending_bad_luck_trigger)
	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_true(
		run_director.scheduled_bad_luck_interval >= scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN
	)
	assert_true(
		run_director.scheduled_bad_luck_interval <= scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX
	)


## Verifies the timer bad-luck ranges line up with the authored phase windows.

func test_bad_luck_interval_range_uses_route_phase_windows() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)
	var run_director := _get_run_director(scene)

	assert_eq(
		run_director.get_bad_luck_interval_range(0.1),
		Vector2.ZERO
	)
	assert_eq(
		run_director.get_bad_luck_interval_range(0.2),
		Vector2(
			scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN,
			scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX
		)
	)
	assert_eq(
		run_director.get_bad_luck_interval_range(0.45),
		Vector2(
			scene.BAD_LUCK_INTERVAL_CROSSING_BEAT_MIN,
			scene.BAD_LUCK_INTERVAL_CROSSING_BEAT_MAX
		)
	)
	assert_eq(
		run_director.get_bad_luck_interval_range(0.6),
		Vector2(
			scene.BAD_LUCK_INTERVAL_CLUTTER_BEAT_MIN,
			scene.BAD_LUCK_INTERVAL_CLUTTER_BEAT_MAX
		)
	)
	assert_eq(
		run_director.get_bad_luck_interval_range(0.85),
		Vector2(
			scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN,
			scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX
		)
	)
	assert_eq(scene._get_route_phase(0.88), scene.ROUTE_PHASE_FINAL_STRETCH)
	assert_eq(run_director.get_bad_luck_interval_range(0.88), Vector2.ZERO)


## Verifies warm-up suppresses timer bad luck until the first trouble phase starts.

func test_bad_luck_timer_when_run_starts_in_warm_up_then_it_stays_disabled() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	var run_director := _get_run_director(scene)

	scene._advance_failure_triggers(10.0)

	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_WARM_UP)
	assert_eq(run_director.scheduled_bad_luck_interval, 0.0)
	assert_eq(run_director.bad_luck_elapsed, 0.0)
	assert_eq(state.active_failure, &"")


## Verifies setup disables timer bad luck in warm-up and schedules it once phases activate.

func test_setup_rolls_first_bad_luck_interval_from_current_progress_band() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)
	var run_director := _get_run_director(scene)

	run_director.bad_luck_rng.seed = 19

	var warm_up_state := RunStateType.new()
	scene.setup(warm_up_state)
	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_WARM_UP)
	assert_eq(run_director.scheduled_bad_luck_interval, 0.0)

	var first_trouble_state := RunStateType.new()
	_setup_active_run_at_progress(scene, first_trouble_state, 0.2)
	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_FIRST_TROUBLE)
	assert_true(
		run_director.scheduled_bad_luck_interval >= scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN
	)
	assert_true(
		run_director.scheduled_bad_luck_interval <= scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX
	)

	var reset_state := RunStateType.new()
	_setup_active_run_at_progress(scene, reset_state, 0.85)
	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_RESET_BEFORE_FINALE)
	assert_true(
		run_director.scheduled_bad_luck_interval >= scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN
	)
	assert_true(
		run_director.scheduled_bad_luck_interval <= scene.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX
	)


## Verifies bad luck timer does not replace existing failure.

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
	var run_director := _get_run_director(scene)
	run_director.bad_luck_rng.seed = 31
	_setup_active_run_at_progress(scene, state, 0.3)
	run_director.scheduled_bad_luck_interval = 99.0
	run_director.bad_luck_elapsed = 5.0
	run_director.pending_bad_luck_trigger = true

	_get_run_hazard_resolver(scene).attempt_failure_trigger_from_collision(run_director, &"rock")

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")
	assert_eq(run_director.bad_luck_elapsed, 0.0)
	assert_false(run_director.pending_bad_luck_trigger)
	assert_eq(run_director.route_phase, scene.ROUTE_PHASE_FIRST_TROUBLE)
	assert_true(
		run_director.scheduled_bad_luck_interval >= scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN
	)
	assert_true(
		run_director.scheduled_bad_luck_interval <= scene.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX
	)


## Verifies bad luck timer arms one pending trigger during recovery cooldown.

func test_bad_luck_timer_arms_one_pending_trigger_during_recovery_cooldown() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run_at_progress(scene, state, 0.3)
	state.recovery_cooldown_remaining = 0.5
	var run_director := _get_run_director(scene)
	run_director.scheduled_bad_luck_interval = 0.2
	run_director.bad_luck_elapsed = 0.0

	scene._advance_failure_triggers(0.2)

	assert_eq(state.active_failure, &"")
	assert_true(run_director.pending_bad_luck_trigger)
	assert_eq(run_director.bad_luck_elapsed, 0.0)

	scene._advance_failure_triggers(0.1)

	assert_eq(state.active_failure, &"")
	assert_true(run_director.pending_bad_luck_trigger)
	assert_eq(run_director.bad_luck_elapsed, 0.0)


## Verifies bad luck timer arms one pending trigger during active failure.

func test_bad_luck_timer_arms_one_pending_trigger_during_active_failure() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run_at_progress(scene, state, 0.3)
	state.start_failure(&"wheel_loose", &"rock")
	var run_director := _get_run_director(scene)
	run_director.scheduled_bad_luck_interval = 0.2
	run_director.bad_luck_elapsed = 0.0

	scene._advance_failure_triggers(0.2)

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")
	assert_true(run_director.pending_bad_luck_trigger)
	assert_eq(run_director.bad_luck_elapsed, 0.0)


## Verifies pending bad luck fires on first frame after cooldown clears.

func test_pending_bad_luck_fires_on_first_frame_after_cooldown_clears() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	var run_director := _get_run_director(scene)
	run_director.bad_luck_rng.seed = 47
	_setup_active_run_at_progress(scene, state, 0.3)
	state.recovery_cooldown_remaining = 0.1
	run_director.scheduled_bad_luck_interval = 0.05

	scene._advance_failure_triggers(0.05)
	scene._advance_failure_triggers(0.05)

	assert_eq(state.active_failure, &"horse_panic")
	assert_eq(state.current_failure.source_hazard, &"bad_luck")
	assert_false(run_director.pending_bad_luck_trigger)
	assert_eq(run_director.bad_luck_elapsed, 0.0)


## Verifies pending bad luck does not stack or reroll while blocked.

func test_pending_bad_luck_does_not_stack_or_reroll_while_blocked() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run_at_progress(scene, state, 0.3)
	state.recovery_cooldown_remaining = 0.6
	var run_director := _get_run_director(scene)
	run_director.scheduled_bad_luck_interval = 0.2
	run_director.bad_luck_elapsed = 0.0

	scene._advance_failure_triggers(0.2)
	var scheduled_interval_after_pending: float = run_director.scheduled_bad_luck_interval

	scene._advance_failure_triggers(0.2)
	scene._advance_failure_triggers(0.1)

	assert_true(run_director.pending_bad_luck_trigger)
	assert_eq(run_director.bad_luck_elapsed, 0.0)
	assert_eq(run_director.scheduled_bad_luck_interval, scheduled_interval_after_pending)
	assert_eq(state.active_failure, &"")


## Verifies wheel loose reduces steering authority without one side lock.

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


## Verifies wheel loose drift oscillates instead of always pulling right.

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


## Verifies wheel loose adds persistent wobble to wagon visual.

func test_wheel_loose_adds_persistent_wobble_to_wagon_visual() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)

	scene._process(0.2)

	var wagon: Node2D = scene.get_node("%Wagon")
	assert_ne(wagon.rotation, 0.0)


## Verifies horse panic adds stronger side to side instability.

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


## Verifies horse panic adds distinct wobble to wagon visual.

func test_horse_panic_adds_distinct_wobble_to_wagon_visual() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"horse_panic", &"tumbleweed")
	scene.setup(state)

	scene._process(0.2)

	var wagon: Node2D = scene.get_node("%Wagon")
	assert_ne(wagon.rotation, 0.0)


## Verifies collision trigger does not replace existing failure type.

func test_collision_trigger_does_not_replace_existing_failure_type() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	scene.setup(state)

	_get_run_hazard_resolver(scene).attempt_failure_trigger_from_collision(_get_run_director(scene), &"tumbleweed")

	assert_eq(state.active_failure, &"wheel_loose")
	assert_eq(state.current_failure.source_hazard, &"rock")


## Verifies wheel loose starts recovery sequence prompt.

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


## Verifies recovery prompt steps use embedded arrow font.

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


## Verifies long recovery sequence uses same row width with smaller prompt chips.

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


## Verifies recovery panel stays inside viewport during touch recovery.

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


## Verifies recovery panel does not overlap touch steering buttons.

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


## Verifies wheel loose recovery sequence clears failure on success.

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


## Verifies recovery prompt advances highlight with direct input actions.

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


## Verifies the UI presenter owns recovery-input extraction while a recovery sequence is active.

func test_ui_presenter_when_recovery_sequence_is_active_then_route_input_returns_matching_recovery_action() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.start_failure(&"wheel_loose", &"rock")
	_setup_active_run(scene, state)
	var expected_sequence := _start_seeded_recovery_sequence(scene, state, 10)

	var recovery_event := InputEventAction.new()
	recovery_event.action = expected_sequence[0]
	recovery_event.pressed = true

	var ui_input_result := _get_run_ui_presenter(scene).route_input(recovery_event, scene.PAUSE_ACTION)

	assert_true(ui_input_result.consumed)
	assert_eq(ui_input_result.recovery_action, expected_sequence[0])


## Verifies recovery step audio plays on non final correct input.

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


## Verifies horse panic starts distinct recovery sequence prompt.

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


## Verifies horse panic recovery sequence clears failure on success.

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


## Verifies perfect recovery counter when recovery finishes clean then result stat increments.

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


## Verifies wheel loose recovery timeout applies health and speed penalty.

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


## Verifies horse panic recovery timeout applies cargo and speed penalty.

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


## Verifies successful recovery sets success outcome without resource penalty.

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


## Verifies perfect recovery when sequence is clean then bonus score and callout are awarded.

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


## Verifies perfect recovery bonus is not awarded after wrong input then clean finish.

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


## Verifies perfect recovery bonus is not awarded after timeout.

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


## Verifies failed recovery causes temporary control instability after failure clears.

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


## Verifies speed penalty recovers toward default speed over time.

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


## Verifies recovery outcome message and cooldown clear after post failure window.

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


## Verifies hud panel uses compact health distance and cargo layout.

func test_hud_panel_uses_compact_health_distance_and_cargo_layout() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var hud_panel: PanelContainer = scene.get_node("GameplayUiLayer/HUDLayer/HUDPanel")
	var health_tag: Label = scene.get_node("GameplayUiLayer/HUDLayer/HUDPanel/MarginContainer/VBoxContainer/HealthRow/HealthTag")
	var health_bar: ProgressBar = scene.get_node("%HealthBar")
	var distance_bar: ProgressBar = scene.get_node("%DistanceBar")
	var distance_bar_overlay: Control = scene.get_node(
		"GameplayUiLayer/HUDLayer/HUDPanel/MarginContainer/VBoxContainer/DistanceRow/DistanceBarMargin/DistanceBarOverlay"
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


## Verifies gameplay UI groups live under one unified canvas layer root.

func test_gameplay_ui_groups_live_under_single_canvas_layer_root() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var gameplay_ui_layer := scene.get_node("%GameplayUiLayer") as CanvasLayer
	var top_level_canvas_layers: Array[CanvasLayer] = []
	for child in scene.get_children():
		if child is CanvasLayer:
			top_level_canvas_layers.append(child as CanvasLayer)

	assert_not_null(gameplay_ui_layer)
	assert_eq(top_level_canvas_layers.size(), 1)
	assert_eq(top_level_canvas_layers[0], gameplay_ui_layer)
	assert_true(scene.has_node("GameplayUiLayer/HUDLayer"))
	assert_true(scene.has_node("GameplayUiLayer/BonusCalloutLayer"))
	assert_true(scene.has_node("GameplayUiLayer/PhaseCalloutLayer"))
	assert_true(scene.has_node("GameplayUiLayer/TouchLayer"))
	assert_true(scene.has_node("GameplayUiLayer/OnboardingLayer"))
	assert_true(scene.has_node("GameplayUiLayer/RecoveryLayer"))
	assert_true(scene.has_node("GameplayUiLayer/PauseLayer"))
	assert_true(scene.has_node("GameplayUiLayer/ResultLayer"))
	assert_false(scene.has_node("HUDLayer"))
	assert_false(scene.has_node("BonusCalloutLayer"))
	assert_false(scene.has_node("PhaseCalloutLayer"))
	assert_false(scene.has_node("TouchLayer"))
	assert_false(scene.has_node("OnboardingLayer"))
	assert_false(scene.has_node("RecoveryLayer"))
	assert_false(scene.has_node("PauseLayer"))
	assert_false(scene.has_node("ResultLayer"))


## Verifies the unified gameplay UI uses explicit wrapper order and stacking indexes.
func test_gameplay_ui_wrappers_use_explicit_overlay_order_and_stacking() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var wrappers := _get_gameplay_ui_wrappers(scene)
	var actual_names := wrappers.map(
		func(layer: Control) -> String:
			return layer.name
	)
	var expected_names := [
		"HUDLayer",
		"BonusCalloutLayer",
		"PhaseCalloutLayer",
		"TouchLayer",
		"OnboardingLayer",
		"RecoveryLayer",
		"PauseLayer",
		"ResultLayer",
	]

	assert_eq(actual_names, expected_names)
	for layer_index in range(wrappers.size()):
		assert_eq(wrappers[layer_index].z_index, layer_index)
		assert_false(wrappers[layer_index].z_as_relative)


## Verifies onboarding starts as the only modal gameplay overlay while inactive wrappers stay non-blocking.
func test_setup_when_run_starts_then_gameplay_ui_wrapper_visibility_and_mouse_filters_match_overlay_state() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)

	_assert_gameplay_ui_wrapper_state(scene, "HUDLayer", true, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "BonusCalloutLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "PhaseCalloutLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "TouchLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "OnboardingLayer", true, Control.MOUSE_FILTER_STOP)
	_assert_gameplay_ui_wrapper_state(scene, "RecoveryLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "PauseLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "ResultLayer", false, Control.MOUSE_FILTER_IGNORE)


## Verifies recovery, touch, and transient callouts can coexist without modal wrappers blocking the controls.
func test_active_run_when_touch_recovery_and_callouts_are_visible_then_gameplay_ui_wrappers_keep_expected_stacking() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_enable_touch_controls_for_native_mobile(scene)
	state.start_failure(&"wheel_loose", &"rock")
	_start_seeded_recovery_sequence(scene, state, 10)
	scene._show_bonus_callout("NEAR MISS +50")
	scene._show_phase_callout("First Trouble")
	scene._refresh_recovery_prompt()

	_assert_gameplay_ui_wrapper_state(scene, "TouchLayer", true, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "RecoveryLayer", true, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "BonusCalloutLayer", true, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "PhaseCalloutLayer", true, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "OnboardingLayer", false, Control.MOUSE_FILTER_IGNORE)
	assert_true((scene.get_node("%TouchLeft") as Button).visible)
	assert_true((scene.get_node("%RecoveryPanel") as PanelContainer).visible)
	assert_true((scene.get_node("%BonusCalloutPanel") as Control).visible)
	assert_true((scene.get_node("%PhaseCalloutPanel") as PanelContainer).visible)


## Verifies the pause overlay becomes the only modal gameplay wrapper and hides touch and recovery wrappers.
func test_pause_overlay_when_opened_then_wrapper_visibility_and_mouse_filters_become_modal() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_enable_touch_controls_for_native_mobile(scene)
	state.start_failure(&"wheel_loose", &"rock")
	_start_seeded_recovery_sequence(scene, state, 10)
	scene._refresh_recovery_prompt()
	scene._set_pause_state(true)

	_assert_gameplay_ui_wrapper_state(scene, "TouchLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "RecoveryLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "PauseLayer", true, Control.MOUSE_FILTER_STOP)
	assert_true((scene.get_node("%PauseOverlay") as Control).visible)
	assert_true((scene.get_node("%PausePanel") as PanelContainer).visible)


## Verifies onboarding starts modal on touch runtimes and yields cleanly back to the touch wrapper after dismissal.
func test_touch_runtime_when_onboarding_is_dismissed_then_modal_wrapper_yields_to_touch_controls() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	_enable_touch_controls_for_native_mobile(scene)

	_assert_gameplay_ui_wrapper_state(scene, "TouchLayer", true, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "OnboardingLayer", true, Control.MOUSE_FILTER_STOP)

	_dismiss_onboarding(scene)

	_assert_gameplay_ui_wrapper_state(scene, "TouchLayer", true, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "OnboardingLayer", false, Control.MOUSE_FILTER_IGNORE)


## Verifies the result screen becomes the topmost modal wrapper and suppresses gameplay overlays.
func test_result_screen_when_run_is_over_then_only_result_wrapper_stays_modal() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	scene.setup(state)

	_assert_gameplay_ui_wrapper_state(scene, "TouchLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "OnboardingLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "RecoveryLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "PauseLayer", false, Control.MOUSE_FILTER_IGNORE)
	_assert_gameplay_ui_wrapper_state(scene, "ResultLayer", true, Control.MOUSE_FILTER_STOP)
	assert_true((scene.get_node("%ResultPanel") as PanelContainer).visible)


## Verifies touch controls exist in scene corners with mobile friendly sizing.

func test_touch_controls_exist_in_scene_corners_with_mobile_friendly_sizing() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var touch_layer: Control = scene.get_node("%TouchLayer")
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


## Verifies touch controls stay hidden and disabled on desktop runtime.

func test_touch_controls_stay_hidden_and_disabled_on_desktop_runtime() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)

	var touch_layer: Control = scene.get_node("%TouchLayer")
	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_false(touch_layer.visible)
	assert_true(touch_left.disabled)
	assert_true(touch_right.disabled)
	assert_true(touch_pause.disabled)


## Verifies touch controls show immediately on native mobile runtime.

func test_touch_controls_show_immediately_on_native_mobile_runtime() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_enable_touch_controls_for_native_mobile(scene)

	var touch_layer: Control = scene.get_node("%TouchLayer")
	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_true(touch_layer.visible)
	assert_false(touch_left.disabled)
	assert_false(touch_right.disabled)
	assert_false(touch_pause.disabled)


## Verifies touch controls show on mobile web after touch capability detection.

func test_touch_controls_show_on_mobile_web_after_touch_capability_detection() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_configure_mobile_web_touch_runtime(scene, false)

	var touch_layer: Control = scene.get_node("%TouchLayer")
	assert_false(touch_layer.visible)

	_get_run_ui_presenter(scene).touchscreen_available_override = true
	scene._refresh_touch_controls()

	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_true(touch_layer.visible)
	assert_true(_get_run_ui_presenter(scene).touch_controls_enabled_for_runtime)
	assert_false(touch_left.disabled)
	assert_false(touch_right.disabled)
	assert_false(touch_pause.disabled)


## Verifies touch controls reveal on first mobile web touch when capability is delayed.

func test_touch_controls_reveal_on_first_mobile_web_touch_when_capability_is_delayed() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_configure_mobile_web_touch_runtime(scene, false)

	var touch_layer: Control = scene.get_node("%TouchLayer")
	assert_false(touch_layer.visible)
	_assert_gameplay_ui_wrapper_state(scene, "TouchLayer", false, Control.MOUSE_FILTER_IGNORE)

	var touch_event := InputEventScreenTouch.new()
	touch_event.pressed = true
	touch_event.index = 0
	touch_event.position = Vector2(320.0, 180.0)
	scene._input(touch_event)

	var touch_left: Button = scene.get_node("%TouchLeft")
	var touch_right: Button = scene.get_node("%TouchRight")
	var touch_pause: Button = scene.get_node("%TouchPause")

	assert_true(touch_layer.visible)
	assert_true(_get_run_ui_presenter(scene).touch_controls_enabled_for_runtime)
	assert_false(touch_left.disabled)
	assert_false(touch_right.disabled)
	assert_false(touch_pause.disabled)
	_assert_gameplay_ui_wrapper_state(scene, "TouchLayer", true, Control.MOUSE_FILTER_IGNORE)


## Verifies touch steering buttons hold and release their actions.

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


## Verifies hidden touch controls do not press steering actions.

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


## Verifies touch steering counts as recovery input.

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


## Verifies touch pause button opens pause and hides touch controls.

func test_touch_pause_button_opens_pause_and_hides_touch_controls() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	_enable_touch_controls_for_native_mobile(scene)

	var touch_layer: Control = scene.get_node("%TouchLayer")
	var touch_pause: Button = scene.get_node("%TouchPause")
	assert_true(touch_layer.visible)

	var touch_left: Button = scene.get_node("%TouchLeft")
	touch_left.button_down.emit()
	await wait_process_frames(1)
	assert_true(Input.is_action_pressed("steer_left"))

	touch_pause.pressed.emit()
	await wait_process_frames(1)

	assert_true(_get_run_ui_presenter(scene).pause_menu_open)
	assert_false(touch_layer.visible)
	assert_false(Input.is_action_pressed("steer_left"))


## Verifies the node-backed gameplay UI layer emits touch pause only when touch controls are currently active.
func test_gameplay_ui_layer_when_touch_pause_is_pressed_then_it_emits_only_for_active_touch_runtime() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	_setup_active_run(scene, state)
	var gameplay_ui_layer := _get_gameplay_ui_layer(scene)
	var touch_pause: Button = scene.get_node("%TouchPause")

	touch_pause.pressed.emit()
	await wait_process_frames(1)
	assert_false(gameplay_ui_layer.pause_menu_open)

	_enable_touch_controls_for_native_mobile(scene)
	watch_signals(gameplay_ui_layer)
	touch_pause.pressed.emit()
	await wait_process_frames(1)

	assert_signal_emitted(gameplay_ui_layer, "touch_pause_requested")
	assert_true(gameplay_ui_layer.pause_menu_open)


## Verifies temporary instability resolves back to normal driving.

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
	var wagon: Node2D = scene.get_node("%Wagon")

	assert_eq(state.temporary_control_instability_remaining, 0.0)
	assert_almost_eq(lateral_after - lateral_before, 0.0, 0.01)
	assert_eq(wagon.rotation, 0.0)


## Verifies recovery panel title shows active failure warning.

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


## Verifies no persistent failure banner exists in scene.

func test_no_persistent_failure_banner_exists_in_scene() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_false(scene.has_node("%FailureBanner"))


## Verifies recovery hint matches active failure type.

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


## Verifies result panel stays hidden during active run.

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

	var restart_button: Button = scene.get_node("%ResultRestartButton")
	var return_button: Button = scene.get_node("%ResultReturnButton")
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

	var restart_button: Button = scene.get_node("%ResultRestartButton")
	var return_button: Button = scene.get_node("%ResultReturnButton")
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
	var result_stats_rows := _get_result_stats_rows(scene)
	assert_true(result_summary.visible)
	assert_string_contains(result_summary.text, "New Best Run!")
	assert_string_contains(result_summary.text, "Best Score: 1565")
	assert_string_contains(result_summary.text, "Best Grade: A")
	assert_eq(result_stats_rows.get_child_count(), 9)
	assert_eq(_get_result_stat_value(scene, "Score"), "1565")
	assert_eq(_get_result_stat_value(scene, "Delivery Grade"), "A")
	assert_eq(_get_result_stat_value(scene, "Health"), "41")
	assert_eq(_get_result_stat_value(scene, "Cargo"), "72")
	assert_eq(_get_result_stat_value(scene, "Distance traveled"), "500 / 500")
	assert_eq(_get_result_stat_value(scene, "Hazards Dodged"), "9")
	assert_eq(_get_result_stat_value(scene, "Near Misses"), "3")
	assert_eq(_get_result_stat_value(scene, "Perfect Recoveries"), "2")
	assert_eq(_get_result_stat_value(scene, "Recovery Failures"), "1")
	assert_eq(_get_result_stat_value(scene, "Speed"), "")

	var restart_button: Button = scene.get_node("%ResultRestartButton")
	var return_button: Button = scene.get_node("%ResultReturnButton")
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
	var result_stats_rows := _get_result_stats_rows(scene)
	assert_eq(result_title.text, "Wagon Collapsed")
	assert_true(result_summary.visible)
	assert_string_contains(result_summary.text, "New Best Run!")
	assert_string_contains(result_summary.text, "Best Score: 400")
	assert_string_contains(result_summary.text, "Best Grade: F")
	assert_eq(result_stats_rows.get_child_count(), 9)
	assert_eq(_get_result_stat_value(scene, "Score"), "400")
	assert_eq(_get_result_stat_value(scene, "Delivery Grade"), "F")
	assert_eq(_get_result_stat_value(scene, "Health"), "20")
	assert_eq(_get_result_stat_value(scene, "Cargo"), "10")
	assert_eq(_get_result_stat_value(scene, "Distance traveled"), "125 / 500")
	assert_eq(_get_result_stat_value(scene, "Hazards Dodged"), "2")
	assert_eq(_get_result_stat_value(scene, "Near Misses"), "1")
	assert_eq(_get_result_stat_value(scene, "Perfect Recoveries"), "0")
	assert_eq(_get_result_stat_value(scene, "Recovery Failures"), "3")


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


## Verifies result panel fits viewport with full mastery breakdown for success.

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
	var result_stats_rows := _get_result_stats_rows(scene)
	var restart_button: Button = scene.get_node(
		"%ResultRestartButton"
	)
	var title_button: Button = scene.get_node(
		"%ResultReturnButton"
	)

	assert_true(result_title.get_global_rect().position.y >= viewport_rect.position.y)
	assert_true(result_summary.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(result_stats_rows.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(restart_button.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(title_button.get_global_rect().end.y <= viewport_rect.end.y)


## Verifies result panel fits viewport with full mastery breakdown for collapse.

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
	var result_stats_rows := _get_result_stats_rows(scene)
	var restart_button: Button = scene.get_node(
		"%ResultRestartButton"
	)
	var title_button: Button = scene.get_node(
		"%ResultReturnButton"
	)

	assert_true(result_title.get_global_rect().position.y >= viewport_rect.position.y)
	assert_true(result_summary.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(result_stats_rows.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(restart_button.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(title_button.get_global_rect().end.y <= viewport_rect.end.y)


## Verifies longer summaries and denser stat lists stay bounded without pushing result buttons off-screen.
func test_result_panel_when_content_is_dense_then_stats_scroll_and_buttons_remain_usable() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var result_panel := scene.get_node("%ResultPanel")
	var dense_rows: Array = []
	dense_rows.append(
		ResultPanelUiType.ResultStatRowData.new(
			"Longest frontier dispatch heading used for score breakdown",
			"1565 points after a very long route report value that needs to wrap cleanly"
		)
	)
	dense_rows.append(
		ResultPanelUiType.ResultStatRowData.new(
			"Best dispatch note",
			"New Best Run! Best Score 1565 Best Grade A with extra dusty detail for wrapping"
		)
	)
	for i in range(12):
		dense_rows.append(
			ResultPanelUiType.ResultStatRowData.new(
				"Supplemental result stat %d with a longer label" % i,
				"Value %d that remains readable even when the summary grows wider than usual" % i
			)
		)

	result_panel.visible = true
	result_panel.set_result_data(
		"Delivered to Dust Gulch",
		"New Best Run! | Best Score: 1565 | Best Grade: A | Long trail report with extra dispatch detail",
		dense_rows
	)
	await wait_process_frames(2)

	var viewport_rect: Rect2 = scene.get_viewport_rect()
	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats_scroll := _get_result_stats_scroll(scene)
	var result_stats_rows := _get_result_stats_rows(scene)
	var restart_button: Button = scene.get_node(
		"%ResultRestartButton"
	)
	var title_button: Button = scene.get_node(
		"%ResultReturnButton"
	)
	var first_row := result_stats_rows.get_child(0) as HBoxContainer
	var first_row_name_label := first_row.get_node("StatNameLabel") as Label
	var first_row_value_label := first_row.get_node("StatValueLabel") as Label

	assert_true(result_summary.get_line_count() > 1)
	assert_true(first_row_name_label.get_line_count() > 1)
	assert_true(first_row_value_label.get_line_count() > 1)
	assert_true(result_stats_scroll.get_global_rect().position.y >= result_summary.get_global_rect().end.y)
	assert_true(result_stats_scroll.get_global_rect().end.y <= restart_button.get_global_rect().position.y)
	assert_true(restart_button.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(title_button.get_global_rect().end.y <= viewport_rect.end.y)
	assert_true(result_stats_rows.size.y > result_stats_scroll.size.y)


## Verifies the structured result panel preview helper populates title, summary, and stat rows.
func test_result_panel_preview_helper_populates_structured_dummy_data() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var result_panel := scene.get_node("%ResultPanel")
	result_panel.show_editor_preview()

	var result_title: Label = scene.get_node("%ResultTitle")
	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats_rows := _get_result_stats_rows(scene)

	assert_eq(result_title.text, "Delivered to Dust Gulch")
	assert_eq(result_summary.text, "New Best Run! | Best Score: 1565 | Best Grade: A")
	assert_eq(result_stats_rows.get_child_count(), 9)
	assert_eq(_get_result_stat_value(scene, "Score"), "1565")
	assert_eq(_get_result_stat_value(scene, "Distance traveled"), "500 / 500")
	assert_eq(_get_result_stat_value(scene, "Hazards Dodged"), "12")
	assert_eq(_get_result_stat_value(scene, "Near Misses"), "4")
	assert_eq(_get_result_stat_value(scene, "Perfect Recoveries"), "3")
	assert_eq(_get_result_stat_value(scene, "Recovery Failures"), "2")


## Verifies the editor preview helper fills the result screen with representative dummy data.
func test_apply_editor_result_preview_populates_result_screen_with_dummy_data() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	scene._apply_editor_result_preview()

	var result_panel: PanelContainer = scene.get_node("%ResultPanel")
	var result_title: Label = scene.get_node("%ResultTitle")
	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats_rows := _get_result_stats_rows(scene)

	assert_eq(result_panel.visible, Engine.is_editor_hint())
	if not Engine.is_editor_hint():
		return

	assert_eq(result_title.text, "Delivered to Dust Gulch")
	assert_eq(result_summary.text, "New Best Run! | Best Score: 1565 | Best Grade: A")
	assert_eq(result_stats_rows.get_child_count(), 9)
	assert_eq(_get_result_stat_value(scene, "Score"), "1565")
	assert_eq(_get_result_stat_value(scene, "Hazards Dodged"), "12")
	assert_eq(_get_result_stat_value(scene, "Near Misses"), "4")
	assert_eq(_get_result_stat_value(scene, "Perfect Recoveries"), "3")
	assert_eq(_get_result_stat_value(scene, "Recovery Failures"), "2")


## Verifies result panel buttons emit restart and return signals.

func test_result_panel_buttons_emit_restart_and_return_signals() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	watch_signals(scene)
	var ui_click_player: AudioStreamPlayer = scene.get_node("%UIClickPlayer")
	var restart_button: Button = scene.get_node(
		"%ResultRestartButton"
	)
	var return_button: Button = scene.get_node(
		"%ResultReturnButton"
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


## Verifies the node-backed gameplay UI layer emits pause menu button intents from its own button handlers.
func test_gameplay_ui_layer_pause_buttons_emit_owner_intent_signals() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var gameplay_ui_layer := _get_gameplay_ui_layer(scene)
	watch_signals(gameplay_ui_layer)

	var resume_button: Button = scene.get_node("%PauseResumeButton")
	var restart_button: Button = scene.get_node("%PauseRestartButton")
	var return_button: Button = scene.get_node("%PauseReturnButton")
	resume_button.pressed.emit()
	restart_button.pressed.emit()
	return_button.pressed.emit()

	assert_signal_emitted(gameplay_ui_layer, "pause_resume_requested")
	assert_signal_emitted(gameplay_ui_layer, "pause_restart_requested")
	assert_signal_emitted(gameplay_ui_layer, "pause_return_to_title_requested")


## Verifies the node-backed gameplay UI layer emits result button intents from its own button handlers.
func test_gameplay_ui_layer_result_buttons_emit_owner_intent_signals() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var gameplay_ui_layer := _get_gameplay_ui_layer(scene)
	watch_signals(gameplay_ui_layer)

	var restart_button: Button = scene.get_node("%ResultRestartButton")
	var return_button: Button = scene.get_node("%ResultReturnButton")
	restart_button.pressed.emit()
	return_button.pressed.emit()

	assert_signal_emitted(gameplay_ui_layer, "result_restart_requested")
	assert_signal_emitted(gameplay_ui_layer, "result_return_to_title_requested")


## Verifies pause menu toggles tree pause and visibility.

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
	assert_true(_get_run_ui_presenter(scene).pause_menu_open)
	assert_false(get_tree().paused)
	assert_true(pause_overlay.visible)
	assert_true(pause_panel.visible)
	assert_eq(pause_overlay.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_true(resume_button.has_focus())
	assert_true(pause_toggle_player.playing)
	assert_eq(pause_toggle_player.stream, scene.PAUSE_TOGGLE_SOUND)

	pause_toggle_player.stop()
	scene._set_pause_state(false)
	assert_false(_get_run_ui_presenter(scene).pause_menu_open)
	assert_false(get_tree().paused)
	assert_false(pause_overlay.visible)
	assert_false(pause_panel.visible)
	assert_eq(pause_panel.process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_true(pause_toggle_player.playing)


## Verifies pause menu buttons emit restart and return after unpausing.

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
	assert_false(_get_run_ui_presenter(scene).pause_menu_open)
	assert_false(get_tree().paused)
	assert_signal_emitted(scene, "restart_requested")

	scene._set_pause_state(true)
	await wait_process_frames(1)
	return_button.pressed.emit()
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout
	assert_false(_get_run_ui_presenter(scene).pause_menu_open)
	assert_false(get_tree().paused)
	assert_signal_emitted(scene, "return_to_title_requested")


## Verifies pause resume button unpauses through button signal.

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

	assert_false(_get_run_ui_presenter(scene).pause_menu_open)
	assert_false(get_tree().paused)
	var pause_panel: PanelContainer = scene.get_node("%PausePanel")
	assert_false(pause_panel.visible)


## Verifies pause menu and result buttons share ui click sound.

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
		"%ResultRestartButton"
	)
	restart_button.pressed.emit()
	assert_true(ui_click_player.playing)
	assert_eq(ui_click_player.stream, scene.UI_CLICK_SOUND)
	await get_tree().create_timer(scene.UI_CLICK_SOUND.get_length(), false).timeout


## Verifies pause menu does not show after run is over.

func test_pause_menu_does_not_show_after_run_is_over() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	scene.setup(state)

	scene._set_pause_state(true)
	var pause_panel: PanelContainer = scene.get_node("%PausePanel")
	assert_false(_get_run_ui_presenter(scene).pause_menu_open)
	assert_false(get_tree().paused)
	assert_false(pause_panel.visible)


## Verifies recovery panel hides when run is over.

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


## Verifies result panel is darkened without full screen backdrop.

func test_result_panel_is_darkened_without_full_screen_backdrop() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	state.result = RunStateType.RESULT_SUCCESS
	scene.setup(state)
	scene._refresh_result_screen()

	assert_false(scene.has_node("%ResultBackdrop"))

	var result_panel: PanelContainer = scene.get_node("%ResultPanel")
	var panel_style := result_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(panel_style)
	assert_eq(panel_style.bg_color, Color(0.156863, 0.101961, 0.0666667, 0.94))
	assert_eq(panel_style.border_color, Color(0.745098, 0.592157, 0.305882, 0.95))

	var result_title: Label = scene.get_node("%ResultTitle")
	var result_summary: Label = scene.get_node("%ResultSummary")
	var result_stats_rows := _get_result_stats_rows(scene)
	var sample_stat_row := result_stats_rows.get_child(0) as HBoxContainer
	assert_not_null(sample_stat_row)
	var stat_name_label := sample_stat_row.get_node("StatNameLabel") as Label
	var stat_value_label := sample_stat_row.get_node("StatValueLabel") as Label
	assert_eq(result_title.get_theme_color("font_color"), Color(1, 1, 1, 1))
	assert_eq(result_summary.get_theme_color("font_color"), Color(1, 1, 1, 1))
	assert_eq(stat_name_label.get_theme_color("font_color"), Color(1, 1, 1, 1))
	assert_eq(stat_value_label.get_theme_color("font_color"), Color(0.980392, 0.929412, 0.803922, 1))


## Verifies step4 presentation nodes exist for dust and audio.

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


## Verifies ready starts music and dust presentation.

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


## Verifies hazard impact audio dispatches to specific players and fallback.

func test_hazard_impact_audio_dispatches_to_specific_players_and_fallback() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var run_audio_presenter := _get_run_audio_presenter(scene)
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
	assert_eq(run_audio_presenter.tumbleweed_impact_serial, 1)
	assert_true(tumbleweed_impact_player.playing)
	assert_eq(tumbleweed_impact_player.stream, scene.TUMBLEWEED_IMPACT_SOUND)
	await get_tree().create_timer(scene.IMPACT_SOUND.get_length() + 0.05, false).timeout
	assert_false(tumbleweed_impact_player.playing)

	tumbleweed_impact_player.stop()
	scene._play_hazard_impact(&"unknown")
	assert_true(impact_player.playing)
	assert_eq(impact_player.stream, scene.IMPACT_SOUND)
	assert_eq(impact_player.volume_db, -4.5)


## Verifies tumbleweed timeout when newer impact replaces older then stale stop is ignored.

func test_tumbleweed_timeout_when_newer_impact_replaces_older_then_stale_stop_is_ignored() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var run_audio_presenter := _get_run_audio_presenter(scene)
	var tumbleweed_impact_player: AudioStreamPlayer = scene.get_node("%TumbleweedImpactPlayer")

	scene._play_hazard_impact(&"tumbleweed")
	var first_serial := run_audio_presenter.tumbleweed_impact_serial
	scene._play_hazard_impact(&"tumbleweed")
	var second_serial := run_audio_presenter.tumbleweed_impact_serial

	assert_true(tumbleweed_impact_player.playing)
	assert_true(second_serial > first_serial)

	scene._on_tumbleweed_impact_timeout(first_serial)
	assert_true(tumbleweed_impact_player.playing)

	scene._on_tumbleweed_impact_timeout(second_serial)
	assert_false(tumbleweed_impact_player.playing)


## Verifies new failure plays failure audio cue.

func test_new_failure_plays_failure_audio_cue() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	state.start_failure(&"wheel_loose", &"rock")
	scene._refresh_audio_presentation()

	var run_audio_presenter := _get_run_audio_presenter(scene)
	var failure_player: AudioStreamPlayer = scene.get_node("%FailurePlayer")
	assert_true(failure_player.playing)
	assert_eq(failure_player.stream, scene.HORSE_SPOOK_SOUND)
	assert_eq(run_audio_presenter.last_announced_failure, state.active_failure)

	failure_player.stop()
	scene._refresh_audio_presentation()
	assert_false(failure_player.playing)


## Verifies failure ambient audio tracks active failure and run end.

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


## Verifies success result stops dust and plays result cue.

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
	assert_eq(_get_run_audio_presenter(scene).last_announced_result, RunStateType.RESULT_SUCCESS)


## Verifies collapse result plays collapse stinger.

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
	assert_eq(_get_run_audio_presenter(scene).last_announced_result, RunStateType.RESULT_COLLAPSED)


## Verifies completed-run best-state sync uses the extracted audio transition tracker to gate persistence.

func test_sync_completed_run_best_state_uses_audio_presenter_result_tracking() -> void:
	assert_eq(
		RunStateType.save_best_run(RunStateType.BestRunData.new(1200, "B", true), TEST_BEST_RUN_SAVE_PATH),
		OK
	)
	var scene = RUN_SCENE.instantiate()
	scene._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(scene)
	await wait_process_frames(1)

	var state := RunStateType.new()
	scene.setup(state)
	state.result = RunStateType.RESULT_SUCCESS
	state.distance_remaining = 0.0
	state.cargo_value = 95
	state.wagon_health = 90

	var run_audio_presenter := _get_run_audio_presenter(scene)
	run_audio_presenter.last_announced_result = RunStateType.RESULT_IN_PROGRESS
	scene._sync_completed_run_best_state()

	var stored_best := RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)
	assert_eq(stored_best.score, state.get_score())

	RunStateType.save_best_run(RunStateType.BestRunData.new(1200, "B", true), TEST_BEST_RUN_SAVE_PATH)
	run_audio_presenter.last_announced_result = state.result
	scene._sync_completed_run_best_state()

	stored_best = RunStateType.load_best_run(TEST_BEST_RUN_SAVE_PATH)
	assert_eq(stored_best.score, 1200)


## Verifies wagon loop audio wraps back to five second mark.

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


## Verifies scroll segment includes roadside dust gulch sign.

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


## Verifies step4 environment art replaces route placeholder geometry.

func test_step4_environment_art_replaces_route_placeholder_geometry() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var backdrop: Sprite2D = scene.get_node("World/Backdrop")
	var road: Sprite2D = scene.get_node("World/Road")
	assert_eq(backdrop.texture, scene.DESERT_TEXTURE)
	assert_eq(road.texture, scene.ROAD_TEXTURE)
	assert_true(backdrop.visible)
	assert_true(road.visible)
	assert_true(backdrop.region_enabled)
	assert_true(road.region_enabled)
	assert_false(scene.has_node("World/RoadStripeLeft"))
	assert_false(scene.has_node("World/RoadStripeRight"))


## Verifies step4 environment art scrolls with route motion.

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


## Verifies step3 cohesion nodes exist on wagon.

func test_step3_cohesion_nodes_exist_on_wagon() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	assert_true(scene.has_node("World/Wagon/WagonCollisionArea"))
	assert_true(scene.has_node("World/Wagon/WagonCollisionArea/WagonCollisionShape"))
	assert_true(scene.has_node("World/Wagon/WagonNearMissArea"))
	assert_true(scene.has_node("World/Wagon/WagonNearMissArea/WagonNearMissShape"))
	assert_true(scene.has_node("World/HazardCleanupBottomArea"))
	assert_true(scene.has_node("World/HazardCleanupBottomArea/HazardCleanupBottomShape"))
	assert_true(scene.has_node("World/HazardCleanupLeftArea"))
	assert_true(scene.has_node("World/HazardCleanupLeftArea/HazardCleanupLeftShape"))
	assert_true(scene.has_node("World/HazardCleanupRightArea"))
	assert_true(scene.has_node("World/HazardCleanupRightArea/HazardCleanupRightShape"))
	assert_true(scene.has_node("World/Wagon/Shadow"))
	assert_true(scene.has_node("World/Wagon/CarriageSprite"))
	assert_true(scene.has_node("World/Wagon/HorseTeam/HorseLeft"))
	assert_true(scene.has_node("World/Wagon/HorseTeam/HorseRight"))


## Verifies the wagon scene owns an authored collision box that covers the visible rig footprint.
func test_wagon_collision_box_exists_with_authored_size_and_offset() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var collision_area := scene.get_node("World/Wagon/WagonCollisionArea") as Area2D
	var collision_shape := scene.get_node("World/Wagon/WagonCollisionArea/WagonCollisionShape") as CollisionShape2D
	var rectangle_shape := collision_shape.shape as RectangleShape2D
	var near_miss_area := scene.get_node("World/Wagon/WagonNearMissArea") as Area2D
	var near_miss_shape := scene.get_node("World/Wagon/WagonNearMissArea/WagonNearMissShape") as CollisionShape2D
	var near_miss_rectangle := near_miss_shape.shape as RectangleShape2D
	var cleanup_bottom_area := scene.get_node("World/HazardCleanupBottomArea") as Area2D
	var cleanup_bottom_shape := scene.get_node("World/HazardCleanupBottomArea/HazardCleanupBottomShape") as CollisionShape2D
	var cleanup_bottom_rectangle := cleanup_bottom_shape.shape as RectangleShape2D
	var cleanup_left_area := scene.get_node("World/HazardCleanupLeftArea") as Area2D
	var cleanup_left_shape := scene.get_node("World/HazardCleanupLeftArea/HazardCleanupLeftShape") as CollisionShape2D
	var cleanup_left_rectangle := cleanup_left_shape.shape as RectangleShape2D
	var cleanup_right_area := scene.get_node("World/HazardCleanupRightArea") as Area2D
	var cleanup_right_shape := scene.get_node("World/HazardCleanupRightArea/HazardCleanupRightShape") as CollisionShape2D
	var cleanup_right_rectangle := cleanup_right_shape.shape as RectangleShape2D

	assert_not_null(collision_area)
	assert_not_null(collision_shape)
	assert_not_null(rectangle_shape)
	assert_not_null(near_miss_area)
	assert_not_null(near_miss_shape)
	assert_not_null(near_miss_rectangle)
	assert_not_null(cleanup_bottom_area)
	assert_not_null(cleanup_bottom_shape)
	assert_not_null(cleanup_bottom_rectangle)
	assert_not_null(cleanup_left_area)
	assert_not_null(cleanup_left_shape)
	assert_not_null(cleanup_left_rectangle)
	assert_not_null(cleanup_right_area)
	assert_not_null(cleanup_right_shape)
	assert_not_null(cleanup_right_rectangle)
	assert_true(collision_area.monitoring)
	assert_true(collision_area.monitorable)
	assert_eq(collision_area.collision_layer, 2)
	assert_eq(collision_area.collision_mask, 1)
	assert_true(near_miss_area.monitoring)
	assert_true(near_miss_area.monitorable)
	assert_eq(near_miss_area.collision_layer, 2)
	assert_eq(near_miss_area.collision_mask, 1)
	assert_true(cleanup_bottom_area.monitoring)
	assert_true(cleanup_bottom_area.monitorable)
	assert_eq(cleanup_bottom_area.collision_layer, 4)
	assert_eq(cleanup_bottom_area.collision_mask, 1)
	assert_true(cleanup_left_area.monitoring)
	assert_true(cleanup_left_area.monitorable)
	assert_eq(cleanup_left_area.collision_layer, 4)
	assert_eq(cleanup_left_area.collision_mask, 1)
	assert_true(cleanup_right_area.monitoring)
	assert_true(cleanup_right_area.monitorable)
	assert_eq(cleanup_right_area.collision_layer, 4)
	assert_eq(cleanup_right_area.collision_mask, 1)
	assert_eq(collision_shape.position, Vector2(0.0, -10.5))
	assert_eq(rectangle_shape.size, Vector2(30.0, 79.0))
	assert_eq(near_miss_shape.position, Vector2(0.0, -10.5))
	assert_eq(near_miss_rectangle.size, Vector2(54.0, 103.0))
	assert_eq(cleanup_bottom_area.position, Vector2(320.0, 720.0))
	assert_eq(cleanup_bottom_rectangle.size, Vector2(900.0, 320.0))
	assert_eq(cleanup_left_area.position, Vector2(-100.0, 300.0))
	assert_eq(cleanup_left_rectangle.size, Vector2(120.0, 900.0))
	assert_eq(cleanup_right_area.position, Vector2(740.0, 300.0))
	assert_eq(cleanup_right_rectangle.size, Vector2(120.0, 900.0))


## Confirms the horse team sits closer to the wagon without the drawn-on harness lines.

func test_step1_horse_team_is_pulled_closer_to_wagon() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var wagon: Node2D = scene.get_node("%Wagon")
	var horse_team: Node2D = scene.get_node("World/Wagon/HorseTeam")
	var horse_left := scene.get_node("World/Wagon/HorseTeam/HorseLeft") as AnimatedSprite2D
	var horse_right := scene.get_node("World/Wagon/HorseTeam/HorseRight") as AnimatedSprite2D

	assert_not_null(wagon)
	assert_not_null(horse_team)
	assert_not_null(horse_left)
	assert_not_null(horse_right)
	assert_false(scene.has_node("World/Wagon/HorseTeam/HarnessLeft"))
	assert_false(scene.has_node("World/Wagon/HorseTeam/HarnessRight"))
	assert_eq(horse_team.position, Vector2(0.0, -38.0))
	assert_eq(horse_left.position, Vector2(-8.0, 0.0))
	assert_eq(horse_right.position, Vector2(8.0, 0.0))
	assert_eq(horse_left.global_position - wagon.global_position, Vector2(-8.0, -38.0))
	assert_eq(horse_right.global_position - wagon.global_position, Vector2(8.0, -38.0))
	assert_eq(horse_left.global_position.y - wagon.global_position.y, -38.0)
	assert_eq(horse_right.global_position.y - wagon.global_position.y, -38.0)


## Confirms the animated horse sprites are wired to the exported sheet slices.

func test_step1_horse_sprites_use_animated_sheet_frames() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var horse_left := scene.get_node("World/Wagon/HorseTeam/HorseLeft") as AnimatedSprite2D
	var horse_right := scene.get_node("World/Wagon/HorseTeam/HorseRight") as AnimatedSprite2D

	assert_not_null(horse_left)
	assert_not_null(horse_right)
	assert_not_null(horse_left.sprite_frames)
	assert_not_null(horse_right.sprite_frames)
	assert_true(horse_left.sprite_frames.has_animation("default"))
	assert_true(horse_right.sprite_frames.has_animation("default"))
	assert_eq(horse_left.sprite_frames.get_frame_count("default"), 4)
	assert_eq(horse_right.sprite_frames.get_frame_count("default"), 4)
	assert_eq(horse_left.sprite_frames.get_animation_speed("default"), scene.HORSE_ANIMATION_FPS)
	assert_eq(horse_right.sprite_frames.get_animation_speed("default"), scene.HORSE_ANIMATION_FPS)
	assert_eq(horse_left.sprite_frames.get_animation_loop("default"), true)
	assert_eq(horse_right.sprite_frames.get_animation_loop("default"), true)
	assert_eq(horse_left.speed_scale, 1.0)
	assert_eq(horse_right.speed_scale, 1.0)

	var left_frame_0 := horse_left.sprite_frames.get_frame_texture("default", 0) as AtlasTexture
	var left_frame_3 := horse_left.sprite_frames.get_frame_texture("default", 3) as AtlasTexture
	var right_frame_0 := horse_right.sprite_frames.get_frame_texture("default", 0) as AtlasTexture
	var right_frame_3 := horse_right.sprite_frames.get_frame_texture("default", 3) as AtlasTexture

	assert_not_null(left_frame_0)
	assert_not_null(left_frame_3)
	assert_not_null(right_frame_0)
	assert_not_null(right_frame_3)
	assert_eq(left_frame_0.atlas, scene.HORSE_SHEET_TEXTURE)
	assert_eq(left_frame_3.atlas, scene.HORSE_SHEET_TEXTURE)
	assert_eq(right_frame_0.atlas, scene.HORSE_SHEET_TEXTURE)
	assert_eq(right_frame_3.atlas, scene.HORSE_SHEET_TEXTURE)
	assert_eq(left_frame_0.get_size(), Vector2(16, 48))
	assert_eq(left_frame_3.get_size(), Vector2(16, 48))
	assert_eq(right_frame_0.get_size(), Vector2(16, 48))
	assert_eq(right_frame_3.get_size(), Vector2(16, 48))
	assert_true(horse_left.is_playing())
	assert_true(horse_right.is_playing())
	assert_eq(horse_left.position, Vector2(-8.0, 0.0))
	assert_eq(horse_right.position, Vector2(8.0, 0.0))


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
	assert_eq(carriage_sprite.sprite_frames.get_animation_speed("default"), scene.CARRIAGE_ANIMATION_FPS)
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
	assert_eq(carriage_sprite.speed_scale, 1.0)


## Confirms the run scene wires the jackalope hazard to the exported 48x32 sheet resource.

func test_step1_hazard_spawner_uses_animated_jackalope_sheet_resource() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var spawner := scene.get_node("%HazardSpawner") as HazardSpawnerType
	assert_not_null(spawner)
	assert_eq(spawner.livestock_definition.texture, LIVESTOCK_TEXTURE)
	assert_eq(spawner.livestock_definition.hazard_type, &"livestock")


## Confirms spawned jackalopes keep the final readable playback cadence in the shipped run scene.

func test_step3_livestock_hazards_play_at_the_final_readable_speed_in_scene() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var spawner := scene.get_node("%HazardSpawner") as HazardSpawnerType
	assert_not_null(spawner)

	for lane_index in [1, 3, 5]:
		spawner._spawn_hazard(&"livestock", lane_index)

	for child in spawner.get_children():
		var livestock := child as HazardInstanceType
		var livestock_visual := livestock.get_visual()
		assert_not_null(livestock)
		assert_not_null(livestock_visual.sprite_frames)
		assert_true(livestock_visual.sprite_frames.has_animation("default"))
		assert_eq(livestock_visual.sprite_frames.get_frame_count("default"), 4)
		assert_eq(
			livestock_visual.sprite_frames.get_animation_speed("default"),
			spawner.livestock_definition.animation_fps
		)
		assert_eq(livestock_visual.sprite_frames.get_animation_loop("default"), true)
		assert_eq(livestock_visual.speed_scale, 1.0)
		assert_true(livestock_visual.is_playing())


## Confirms the wagon rig still applies the existing presentation state while the carriage animates.

func test_step2_vehicle_sprites_replace_placeholder_shapes() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var wagon: Node2D = scene.get_node("%Wagon")
	var shadow := scene.get_node("World/Wagon/Shadow") as AnimatedSprite2D
	var carriage_sprite := scene.get_node("World/Wagon/CarriageSprite") as AnimatedSprite2D
	var horse_left := scene.get_node("World/Wagon/HorseTeam/HorseLeft") as AnimatedSprite2D
	var horse_right := scene.get_node("World/Wagon/HorseTeam/HorseRight") as AnimatedSprite2D

	assert_true(wagon.visible)
	assert_not_null(shadow)
	assert_not_null(carriage_sprite)
	assert_not_null(shadow.sprite_frames)
	assert_true(shadow.sprite_frames.has_animation("default"))
	assert_not_null(carriage_sprite.sprite_frames)
	assert_eq(shadow.sprite_frames.get_animation_speed("default"), scene.CARRIAGE_ANIMATION_FPS)
	assert_eq(
		carriage_sprite.sprite_frames.get_animation_speed("default"),
		scene.CARRIAGE_ANIMATION_FPS
	)
	assert_eq(
		shadow.sprite_frames.get_frame_count("default"),
		carriage_sprite.sprite_frames.get_frame_count("default")
	)
	assert_eq(shadow.modulate, Color(0.0, 0.0, 0.0, 0.2))
	assert_eq(shadow.position, Vector2(0.0, 5.0))
	assert_true(shadow.is_playing())
	assert_eq(shadow.speed_scale, 1.0)
	assert_true(carriage_sprite.is_playing())
	assert_eq(carriage_sprite.speed_scale, 1.0)
	assert_not_null(horse_left.sprite_frames)
	assert_not_null(horse_right.sprite_frames)
	assert_true(horse_left.sprite_frames.has_animation("default"))
	assert_true(horse_right.sprite_frames.has_animation("default"))
	assert_eq(horse_left.sprite_frames.get_frame_count("default"), 4)
	assert_eq(horse_right.sprite_frames.get_frame_count("default"), 4)
	assert_eq(horse_left.sprite_frames.get_animation_speed("default"), scene.HORSE_ANIMATION_FPS)
	assert_eq(horse_right.sprite_frames.get_animation_speed("default"), scene.HORSE_ANIMATION_FPS)
	assert_eq(horse_left.sprite_frames.get_animation_loop("default"), true)
	assert_eq(horse_right.sprite_frames.get_animation_loop("default"), true)
	assert_true(horse_left.is_playing())
	assert_true(horse_right.is_playing())
	assert_eq(horse_left.speed_scale, 1.0)
	assert_eq(horse_right.speed_scale, 1.0)


## Verifies step3 panel styles use western palette.

func test_step3_panel_styles_use_western_palette() -> void:
	var scene = RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var hud_panel: PanelContainer = scene.get_node("GameplayUiLayer/HUDLayer/HUDPanel")
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
