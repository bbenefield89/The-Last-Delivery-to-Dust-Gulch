extends RunStateMachineStateBase

## Placeholder top-level in-progress state for the RunStateMachine.

# Constants

const RunSceneTuningType := preload(ProjectPaths.RUN_SCENE_TUNING_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const STATE_KEY: RunStateMachineKey.Key = RunStateMachineKey.Key.IN_PROGRESS


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> RunStateMachineKey.Key:
	return STATE_KEY


## Advances one frame for the in-progress branch, preserving onboarding and pause branching inside this state.
func advance(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if ui_presenter != null and bool(ui_presenter.is_pause_menu_open):
		_advance_paused_frame(delta)
		return

	if ui_presenter != null and bool(ui_presenter.is_onboarding_active):
		__advance_onboarding_frame(delta)
		return

	__advance_active_drive_frame(delta)


# Private Methods

## Returns whether the scripted success-arrival beat should start on this gameplay frame.
func __should_start_success_arrival(scene: Node, run_state: RunStateType) -> bool:
	return (
		run_state != null
		and run_state.result == RunStateType.RESULT_SUCCESS
		and scene.get(&"_previous_frame_result") == RunStateType.RESULT_IN_PROGRESS
		and not bool(scene.get(&"_is_success_exit_beat_active"))
		and not bool(scene.get(&"_has_finished_success_exit_beat"))
	)


## Advances one onboarding frame while the onboarding overlay is active.
func __advance_onboarding_frame(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var run_state := scene.call(&"get_run_state") as RunStateType
	var run_presentation: Variant = scene.get(&"_run_presentation")
	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if run_state == null or run_presentation == null or ui_presenter == null:
		return

	scene.call(&"_sync_previous_frame_state")
	ui_presenter.advance_callouts(delta, scene.get_viewport().get_canvas_transform())
	run_presentation.advance_scroll(run_state.current_speed, delta)
	scene.call(&"_refresh_regular_roadside_sign_spawning")
	scene.call(&"_advance_roadside_scenery", run_state.current_speed * delta)
	scene.call(&"_update_impact_feedback", delta)
	scene.call(&"_update_wagon_visual")
	scene.call(&"_update_scroll_visuals")
	scene.call(&"_update_camera_framing")
	ui_presenter.refresh_status()
	ui_presenter.refresh_onboarding_prompt()
	ui_presenter.refresh_pause_menu()
	ui_presenter.refresh_recovery_prompt()
	ui_presenter.refresh_result_screen(scene.call(&"_build_best_run_summary"))
	ui_presenter.refresh_touch_controls()
	scene.call(&"_refresh_audio_presentation")


## Advances one active gameplay frame while the run is in progress.
func __advance_active_drive_frame(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var run_state := scene.call(&"get_run_state") as RunStateType
	if run_state == null:
		return

	var run_presentation: Variant = scene.get(&"_run_presentation")
	if run_presentation == null:
		return

	var steer_input := Input.get_axis(
		RunSceneTuningType.STEER_ACTION_NEGATIVE,
		RunSceneTuningType.STEER_ACTION_POSITIVE
	)
	var steer_multiplier := 1.0
	var lateral_drift := 0.0
	match run_state.active_failure:
		&"wheel_loose":
			steer_multiplier = RunSceneTuningType.WHEEL_LOOSE_STEER_MULTIPLIER
			lateral_drift = sin(run_presentation.impact_time * RunSceneTuningType.WHEEL_LOOSE_DRIFT_FREQUENCY) * (
				RunSceneTuningType.WHEEL_LOOSE_DRIFT_SPEED
			)
		&"horse_panic":
			steer_multiplier = RunSceneTuningType.HORSE_PANIC_STEER_MULTIPLIER
			lateral_drift = sin(run_presentation.impact_time * RunSceneTuningType.HORSE_PANIC_DRIFT_FREQUENCY) * (
				RunSceneTuningType.HORSE_PANIC_DRIFT_SPEED
			)
		_:
			if run_state.has_temporary_control_instability():
				steer_multiplier = RunSceneTuningType.POST_FAILURE_STEER_MULTIPLIER
				lateral_drift = sin(run_presentation.impact_time * RunSceneTuningType.POST_FAILURE_DRIFT_FREQUENCY) * (
					RunSceneTuningType.POST_FAILURE_DRIFT_SPEED
				)

	run_state.lateral_position = clamp(
		run_state.lateral_position
			+ ((steer_input * RunSceneTuningType.STEER_SPEED * steer_multiplier) + lateral_drift) * delta,
		-RunSceneTuningType.ROAD_HALF_WIDTH,
		RunSceneTuningType.ROAD_HALF_WIDTH,
	)

	scene.call(&"_update_wagon_visual")
	run_state.recover_speed(delta)
	var distance_remaining_before_travel := run_state.distance_remaining
	run_state.distance_remaining = max(
		0.0,
		run_state.distance_remaining - run_state.current_speed * delta,
	)

	var scroll_distance := run_state.current_speed * delta
	run_presentation.advance_scroll(run_state.current_speed, delta)
	scene.call(&"_refresh_regular_roadside_sign_spawning")
	scene.call(&"_advance_roadside_scenery", scroll_distance)
	scene.call(&"_sync_route_phase")

	var dev_cheats: Variant = scene.get(&"_dev_cheats")
	var should_process_runtime_hazards := dev_cheats == null or bool(dev_cheats.are_runtime_hazards_enabled)
	if should_process_runtime_hazards:
		var hazard_spawner: Variant = scene.get(&"_hazard_spawner")
		if hazard_spawner != null:
			hazard_spawner.advance(
				scroll_distance,
				run_state.get_delivery_progress_ratio(),
				run_state.distance_remaining,
				run_state.route_distance
			)

		var run_hazard_resolver: Variant = scene.get(&"_run_hazard_resolver")
		var run_director: Variant = scene.get(&"_run_director")
		if run_hazard_resolver != null and hazard_spawner != null and run_director != null:
			scene.call(
				&"_handle_run_hazard_update",
				run_hazard_resolver.resolve_frame(
					hazard_spawner,
					run_state,
					run_director
				)
			)

	scene.call(&"_advance_failure_triggers", delta)
	scene.call(&"_advance_finish_buffer_runoff", scroll_distance, distance_remaining_before_travel)
	scene.call(&"_try_spawn_finish_buffer_sign")
	scene.call(&"_try_finalize_finish_success")
	scene.call(&"_sync_completed_run_best_state")
	if __should_start_success_arrival(scene, run_state):
		return

	scene.call(&"_sync_previous_frame_state")

	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if ui_presenter == null:
		return

	ui_presenter.advance_callouts(delta, scene.get_viewport().get_canvas_transform())
	scene.call(&"_update_impact_feedback", delta)
	scene.call(&"_update_wagon_visual")
	scene.call(&"_update_scroll_visuals")
	scene.call(&"_update_camera_framing")
	ui_presenter.refresh_status()
	ui_presenter.refresh_onboarding_prompt()
	ui_presenter.refresh_pause_menu()
	ui_presenter.refresh_recovery_prompt()
	ui_presenter.refresh_result_screen(scene.call(&"_build_best_run_summary"))
	ui_presenter.refresh_touch_controls()
	scene.call(&"_refresh_audio_presentation")
