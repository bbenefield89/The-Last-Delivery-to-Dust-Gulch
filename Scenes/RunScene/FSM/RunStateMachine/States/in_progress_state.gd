extends RunStateMachineStateBase

## Owns the full top-level in-progress branch for RunScene until later tickets split it further.


# Imports

const RunSceneTuningType := preload(ProjectPaths.RUN_SCENE_TUNING_SCRIPT_PATH)
const RunAudioPresenterType := preload(ProjectPaths.RUN_AUDIO_PRESENTER_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunHazardResolverType := preload(ProjectPaths.RUN_HAZARD_RESOLVER_SCRIPT_PATH)
const RunPresentationType := preload(ProjectPaths.RUN_PRESENTATION_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Constants

const STATE_KEY: RunStateMachineKey.Key = RunStateMachineKey.Key.IN_PROGRESS


# Public Methods

## Returns the top-level machine key owned by this derived state.
func get_state_key() -> RunStateMachineKey.Key:
	return STATE_KEY


## Routes one input event while the run remains in progress.
func handle_input(event: InputEvent) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	var run_director := __get_run_director(scene)
	var run_audio_presenter := __get_run_audio_presenter(scene)
	var run_state := __get_run_state(scene)
	if ui_presenter == null or run_director == null or run_audio_presenter == null:
		return

	var ui_input_result: Variant = ui_presenter.route_input(event, scene.PAUSE_ACTION)
	if ui_input_result.pause_command == scene.GameplayUiLayerType.PAUSE_COMMAND_TOGGLE:
		__set_pause_state(scene, not bool(ui_presenter.is_pause_menu_open))
		return
	if ui_input_result.pause_command == scene.GameplayUiLayerType.PAUSE_COMMAND_CLOSE:
		__set_pause_state(scene, false)
		return

	if ui_input_result.did_dismiss_onboarding:
		ui_presenter.dismiss_onboarding()
		if run_director.route_phase_callout_zone == scene.ROUTE_PHASE_WARM_UP:
			ui_presenter.show_phase_callout(
				RunDirectorType.get_route_phase_display_name(run_director.route_phase_callout_zone)
			)
		return

	if run_state == null or ui_input_result.recovery_action == &"":
		return

	var recovery_result: RefCounted = run_director.handle_recovery_action(ui_input_result.recovery_action)
	if recovery_result.was_wrong_input:
		return

	if recovery_result.bonus_callout_text != "":
		__show_bonus_callout(scene, recovery_result.bonus_callout_text)
	if recovery_result.play_step_sound:
		run_audio_presenter.play_recovery_step()
	if recovery_result.recovery_completed:
		run_audio_presenter.play_recovery_success()

	ui_presenter.refresh_status()
	ui_presenter.refresh_recovery_prompt()


## Advances one frame for the in-progress branch, preserving onboarding and pause branching inside this state.
func advance(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if ui_presenter != null and bool(ui_presenter.is_pause_menu_open):
		__advance_paused_frame(delta)
		return

	if ui_presenter != null and bool(ui_presenter.is_onboarding_active):
		__advance_onboarding_frame(delta)
		return

	__advance_active_drive_frame(delta)


# Private Methods

## Returns the currently bound run presentation owner.
func __get_run_presentation(scene: Node) -> RunPresentationType:
	return scene.get(&"_run_presentation") as RunPresentationType


## Returns the currently bound run state.
func __get_run_state(scene: Node) -> RunStateType:
	return scene.get(&"_run_state") as RunStateType


## Returns the currently bound run audio presenter.
func __get_run_audio_presenter(scene: Node) -> RunAudioPresenterType:
	return scene.get(&"_run_audio_presenter") as RunAudioPresenterType


## Returns the currently bound run director.
func __get_run_director(scene: Node) -> RunDirectorType:
	return scene.get(&"_run_director") as RunDirectorType


## Returns the currently bound hazard resolver.
func __get_run_hazard_resolver(scene: Node) -> RunHazardResolverType:
	return scene.get(&"_run_hazard_resolver") as RunHazardResolverType


## Builds the current best-run summary line for the result panel.
func __build_best_run_summary(run_state: RunStateType) -> String:
	if run_state == null or not run_state.best_run.has_value:
		return ""

	var prefix := "New Best Run! | " if run_state.current_run_is_new_best else ""
	return "%sBest Score: %d | Best Grade: %s" % [
		prefix,
		run_state.best_run.score,
		run_state.best_run.grade,
	]


## Updates the pause state without routing back through the scene script.
func __set_pause_state(scene: Node, paused: bool) -> void:
	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	var run_audio_presenter := __get_run_audio_presenter(scene)
	if ui_presenter == null or run_audio_presenter == null:
		return

	var was_paused := bool(ui_presenter.is_pause_menu_open)
	if not ui_presenter.set_pause_state(paused):
		return

	run_audio_presenter.play_pause_toggle()
	var pause_layer: Variant = scene.get(&"_pause_layer")
	if bool(ui_presenter.is_pause_menu_open) and not was_paused and pause_layer != null:
		pause_layer.focus_default_button()


## Persists a newly completed run exactly once when it beats the stored best score.
func __sync_completed_run_best_state(scene: Node, run_state: RunStateType) -> void:
	if run_state == null:
		return
	if run_state.result == RunStateType.RESULT_IN_PROGRESS:
		return

	var run_audio_presenter := __get_run_audio_presenter(scene)
	if run_audio_presenter != null and run_audio_presenter.last_announced_result == run_state.result:
		return

	var best_run_save_path: Variant = scene.get(&"_best_run_save_path")
	run_state.record_best_run_if_needed(best_run_save_path)


## Stores transition-sensitive run state so frame-entry checks can fire exactly once.
func __sync_previous_frame_state(scene: Node, run_state: RunStateType) -> void:
	if run_state == null:
		scene.set(&"_previous_frame_result", RunStateType.RESULT_IN_PROGRESS)
		scene.set(&"_previous_frame_has_crossed_finish_line", false)
		return

	scene.set(&"_previous_frame_result", run_state.result)
	scene.set(&"_previous_frame_has_crossed_finish_line", run_state.has_crossed_finish_line)


## Refreshes the regular roadside sign cadence for the active progress band.
func __refresh_regular_roadside_sign_spawning(scene: Node, run_state: RunStateType) -> void:
	var roadside_scenery: Variant = scene.get(&"_roadside_scenery")
	if roadside_scenery == null:
		return

	roadside_scenery.set_regular_sign_spawning_enabled(__should_allow_regular_roadside_signs(run_state))


## Returns whether regular roadside signs should stay active in the current route phase.
func __should_allow_regular_roadside_signs(run_state: RunStateType) -> bool:
	if run_state == null:
		return true

	var route_phase := RunDirectorType.get_route_phase_for_progress(run_state.get_delivery_progress_ratio())
	return route_phase != RunDirectorType.ROUTE_PHASE_RESET_BEFORE_FINALE \
		and route_phase != RunDirectorType.ROUTE_PHASE_FINAL_STRETCH


## Advances the dedicated roadside scenery owner using travelled distance.
func __advance_roadside_scenery(scene: Node, distance_delta: float) -> void:
	var roadside_scenery: Variant = scene.get(&"_roadside_scenery")
	if roadside_scenery == null:
		return

	roadside_scenery.advance(distance_delta)


## Updates the wagon position to match the current lateral run-state offset.
func __update_wagon_visual(scene: Node) -> void:
	var run_presentation := __get_run_presentation(scene)
	if run_presentation == null:
		return

	run_presentation.update_wagon_visual()


## Keeps the camera centered on the wagon while preserving the below-center framing offset.
func __update_camera_framing(scene: Node) -> void:
	var run_presentation := __get_run_presentation(scene)
	if run_presentation == null:
		return

	run_presentation.update_camera_framing()


## Updates the wagon flash, wobble, and shake presentation for the current run state.
func __update_impact_feedback(scene: Node, delta: float) -> void:
	var run_presentation := __get_run_presentation(scene)
	if run_presentation == null:
		return

	run_presentation.update_impact_feedback(delta)


## Triggers the authored impact flash, wobble, and shake presentation state.
func __trigger_impact_feedback(scene: Node) -> void:
	var run_presentation := __get_run_presentation(scene)
	if run_presentation == null:
		return

	run_presentation.trigger_impact_feedback()


## Updates the looping world segments and tiled environment scroll windows.
func __update_scroll_visuals(scene: Node) -> void:
	var run_presentation := __get_run_presentation(scene)
	if run_presentation == null:
		return

	run_presentation.update_scroll_visuals()


## Refreshes dust through the presentation owner and runtime audio through the extracted audio presenter.
func __refresh_audio_presentation(scene: Node, run_state: RunStateType) -> void:
	if run_state == null:
		return

	var run_presentation := __get_run_presentation(scene)
	if run_presentation != null:
		run_presentation.refresh_dust_presentation(RunStateType.DEFAULT_FORWARD_SPEED)

	var run_audio_presenter := __get_run_audio_presenter(scene)
	if run_audio_presenter != null:
		run_audio_presenter.refresh_audio_presentation()


## Plays one floating bonus callout anchored to the wagon position.
func __show_bonus_callout(scene: Node, text: String) -> void:
	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if ui_presenter == null:
		return

	var wagon := scene.get(&"_wagon") as Node2D
	var anchor_world_position := Vector2.ZERO if wagon == null else wagon.global_position
	ui_presenter.show_bonus_callout(
		text,
		anchor_world_position,
		scene.get_viewport().get_canvas_transform()
	)


## Plays the authored impact cue for one resolved hazard hit.
func __play_hazard_impact(scene: Node, hazard_type: StringName) -> void:
	var run_audio_presenter := __get_run_audio_presenter(scene)
	if run_audio_presenter == null:
		return

	run_audio_presenter.play_hazard_impact(hazard_type)


## Applies scene-local presentation side effects emitted by the run director.
func __handle_run_director_update(scene: Node, update: RefCounted) -> void:
	if update == null:
		return

	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	var run_audio_presenter := __get_run_audio_presenter(scene)
	if ui_presenter != null and update.phase_callout_text != "":
		ui_presenter.show_phase_callout(update.phase_callout_text)
	if run_audio_presenter != null and update.recovery_penalty_applied:
		run_audio_presenter.play_recovery_fail()


## Applies scene-local impact and bonus presentation emitted by the hazard resolver.
func __handle_run_hazard_update(scene: Node, update: RefCounted) -> void:
	if update == null:
		return

	for hazard_type in update.impact_hazard_types:
		__trigger_impact_feedback(scene)
		__play_hazard_impact(scene, hazard_type)

	for bonus_callout_text in update.bonus_callout_texts:
		__show_bonus_callout(scene, bonus_callout_text)


## Advances failure state timers and starts timer-driven bad luck when its scheduled roll matures.
func __advance_failure_triggers(scene: Node, run_state: RunStateType, delta: float) -> void:
	if run_state == null:
		return

	var run_director := __get_run_director(scene)
	if run_director == null:
		return

	__handle_run_director_update(scene, run_director.advance(delta))


## Synchronizes the route phase against the current run progress and refreshes bad-luck timing when it changes.
func __sync_route_phase(scene: Node, run_state: RunStateType) -> void:
	if run_state == null:
		return

	var run_director := __get_run_director(scene)
	if run_director == null:
		return

	__handle_run_director_update(scene, run_director.sync_route_phase())


## Spawns the dedicated finish sign exactly once when the run first enters the finish buffer.
func __try_spawn_finish_buffer_sign(scene: Node, run_state: RunStateType) -> void:
	var roadside_scenery: Variant = scene.get(&"_roadside_scenery")
	if run_state == null or roadside_scenery == null:
		return
	if not run_state.has_crossed_finish_line or bool(scene.get(&"_previous_frame_has_crossed_finish_line")):
		return
	if run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return

	roadside_scenery.spawn_forced_finish_sign()


## Tracks the amount of world scroll that has happened after crossing the finish threshold.
func __advance_finish_buffer_runoff(
	scene: Node,
	run_state: RunStateType,
	scroll_distance: float,
	distance_remaining_before_travel: float
) -> void:
	if run_state == null or run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	if not run_state.has_crossed_finish_line:
		return

	var runoff_distance := scroll_distance
	if not bool(scene.get(&"_previous_frame_has_crossed_finish_line")):
		runoff_distance = maxf(0.0, scroll_distance - maxf(distance_remaining_before_travel, 0.0))

	if runoff_distance <= 0.0:
		return

	var finish_buffer_scroll_distance := float(scene.get(&"_finish_buffer_scroll_distance"))
	scene.set(&"_finish_buffer_scroll_distance", finish_buffer_scroll_distance + runoff_distance)


## Converts a crossed finish line into true success only after the last live hazard has cleared.
func __try_finalize_finish_success(scene: Node, run_state: RunStateType) -> void:
	if run_state == null or run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	if not run_state.has_crossed_finish_line:
		return
	if float(scene.get(&"_finish_buffer_scroll_distance")) < scene.FINISH_RUNOFF_DISTANCE:
		return

	var hazard_spawner: Variant = scene.get(&"_hazard_spawner")
	if hazard_spawner != null and hazard_spawner.has_runtime_hazards():
		return

	run_state.result = RunStateType.RESULT_SUCCESS
	run_state.current_speed = 0.0


## Refreshes the in-progress HUD and overlays after one frame of work.
func __refresh_in_progress_ui(scene: Node, run_state: RunStateType, delta: float) -> void:
	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if ui_presenter == null:
		return

	ui_presenter.advance_callouts(delta, scene.get_viewport().get_canvas_transform())
	ui_presenter.refresh_status()
	ui_presenter.refresh_onboarding_prompt()
	ui_presenter.refresh_pause_menu()
	ui_presenter.refresh_recovery_prompt()
	ui_presenter.refresh_result_screen(__build_best_run_summary(run_state))
	ui_presenter.refresh_touch_controls()


## Advances one paused frame while the pause menu is open.
func __advance_paused_frame(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var run_state := __get_run_state(scene)
	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if ui_presenter == null:
		return

	__sync_previous_frame_state(scene, run_state)
	ui_presenter.refresh_onboarding_prompt()
	ui_presenter.advance_callouts(delta, scene.get_viewport().get_canvas_transform())
	ui_presenter.refresh_pause_menu()
	ui_presenter.refresh_result_screen(__build_best_run_summary(run_state))
	ui_presenter.refresh_touch_controls()
	__refresh_audio_presentation(scene, run_state)


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

	var run_state := __get_run_state(scene)
	var run_presentation := __get_run_presentation(scene)
	var ui_presenter: Variant = scene.get(&"_run_ui_presenter")
	if run_state == null or run_presentation == null or ui_presenter == null:
		return

	__sync_previous_frame_state(scene, run_state)
	run_presentation.advance_scroll(run_state.current_speed, delta)
	__refresh_regular_roadside_sign_spawning(scene, run_state)
	__advance_roadside_scenery(scene, run_state.current_speed * delta)
	__update_impact_feedback(scene, delta)
	__update_wagon_visual(scene)
	__update_scroll_visuals(scene)
	__update_camera_framing(scene)
	__refresh_in_progress_ui(scene, run_state, delta)
	__refresh_audio_presentation(scene, run_state)


## Advances one active gameplay frame while the run is in progress.
func __advance_active_drive_frame(delta: float) -> void:
	var scene := _get_scene()
	if scene == null:
		return

	var run_state := __get_run_state(scene)
	if run_state == null:
		return

	var run_presentation := __get_run_presentation(scene)
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

	__update_wagon_visual(scene)
	run_state.recover_speed(delta)
	var distance_remaining_before_travel: float = run_state.distance_remaining
	run_state.distance_remaining = max(
		0.0,
		run_state.distance_remaining - run_state.current_speed * delta,
	)

	var scroll_distance: float = run_state.current_speed * delta
	run_presentation.advance_scroll(run_state.current_speed, delta)
	__refresh_regular_roadside_sign_spawning(scene, run_state)
	__advance_roadside_scenery(scene, scroll_distance)
	__sync_route_phase(scene, run_state)

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

		var run_hazard_resolver := __get_run_hazard_resolver(scene)
		var run_director := __get_run_director(scene)
		if run_hazard_resolver != null and hazard_spawner != null and run_director != null:
			__handle_run_hazard_update(
				scene,
				run_hazard_resolver.resolve_frame(hazard_spawner, run_state, run_director)
			)

	__advance_failure_triggers(scene, run_state, delta)
	__advance_finish_buffer_runoff(scene, run_state, scroll_distance, distance_remaining_before_travel)
	__try_spawn_finish_buffer_sign(scene, run_state)
	__try_finalize_finish_success(scene, run_state)
	__sync_completed_run_best_state(scene, run_state)
	if __should_start_success_arrival(scene, run_state):
		return

	__sync_previous_frame_state(scene, run_state)
	__update_impact_feedback(scene, delta)
	__update_wagon_visual(scene)
	__update_scroll_visuals(scene)
	__update_camera_framing(scene)
	__refresh_in_progress_ui(scene, run_state, delta)
	__refresh_audio_presentation(scene, run_state)
