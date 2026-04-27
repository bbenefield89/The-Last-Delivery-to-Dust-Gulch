class_name InProgressContext
extends RefCounted

## Owns the injected collaborators and shared helpers for the RunScene in-progress child FSM.


# Imports

const DevCheatsType := preload(ProjectPaths.DEV_CHEATS_SCRIPT_PATH)
const GameplayUiLayerType := preload(ProjectPaths.GAMEPLAY_UI_LAYER_SCRIPT_PATH)
const HazardSpawnerType := preload(ProjectPaths.HAZARD_SPAWNER_SCRIPT_PATH)
const PauseLayerType := preload(ProjectPaths.PAUSE_LAYER_SCRIPT_PATH)
const TouchLayerType := preload(ProjectPaths.TOUCH_LAYER_SCRIPT_PATH)
const RoadsideSceneryType := preload(ProjectPaths.ROADSIDE_SCENERY_SCRIPT_PATH)
const RunAudioPresenterType := preload(ProjectPaths.RUN_AUDIO_PRESENTER_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunHazardResolverType := preload(ProjectPaths.RUN_HAZARD_RESOLVER_SCRIPT_PATH)
const RunPresentationType := preload(ProjectPaths.RUN_PRESENTATION_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Public Fields

var run_state: RunStateType
var ui_presenter: GameplayUiLayerType
var run_presentation: RunPresentationType
var run_director: RunDirectorType
var run_audio_presenter: RunAudioPresenterType
var run_hazard_resolver: RunHazardResolverType
var roadside_scenery: RoadsideSceneryType
var hazard_spawner: HazardSpawnerType
var pause_layer: PauseLayerType
var touch_layer: TouchLayerType
var dev_cheats: DevCheatsType
var wagon: Node2D
var viewport: Viewport
var pause_action: StringName = &"pause_run"
var finish_runoff_distance := 0.0
var previous_frame_result: StringName = RunStateType.RESULT_IN_PROGRESS
var previous_frame_has_crossed_finish_line := false


# Public Methods

## Injects the scene-owned collaborators and transient values needed by the child FSM.
func bind_dependencies(
	run_state_value: RunStateType,
	ui_presenter_value: GameplayUiLayerType,
	run_presentation_value: RunPresentationType,
	run_director_value: RunDirectorType,
	run_audio_presenter_value: RunAudioPresenterType,
	run_hazard_resolver_value: RunHazardResolverType,
	roadside_scenery_value: RoadsideSceneryType,
	hazard_spawner_value: HazardSpawnerType,
	pause_layer_value: PauseLayerType,
	touch_layer_value: TouchLayerType,
	dev_cheats_value: DevCheatsType,
	wagon_value: Node2D,
	viewport_value: Viewport,
	pause_action_value: StringName,
	finish_runoff_distance_value: float,
	previous_frame_result_value: StringName,
	previous_frame_has_crossed_finish_line_value: bool
) -> void:
	run_state = run_state_value
	ui_presenter = ui_presenter_value
	run_presentation = run_presentation_value
	run_director = run_director_value
	run_audio_presenter = run_audio_presenter_value
	run_hazard_resolver = run_hazard_resolver_value
	roadside_scenery = roadside_scenery_value
	hazard_spawner = hazard_spawner_value
	pause_layer = pause_layer_value
	touch_layer = touch_layer_value
	dev_cheats = dev_cheats_value
	wagon = wagon_value
	viewport = viewport_value
	pause_action = pause_action_value
	finish_runoff_distance = finish_runoff_distance_value
	previous_frame_result = previous_frame_result_value
	previous_frame_has_crossed_finish_line = previous_frame_has_crossed_finish_line_value


## Interprets one input event against the active in-progress UI state.
func route_ui_input(event: InputEvent) -> Variant:
	if ui_presenter == null:
		return null
	return ui_presenter.route_input(event, pause_action)


## Applies one recovery input request and returns whether it changed runtime state.
func try_handle_recovery_input(ui_input_result: Variant) -> bool:
	if ui_input_result == null:
		return false
	if run_state == null or run_director == null or run_audio_presenter == null or ui_presenter == null:
		return false
	if ui_input_result.recovery_action == &"":
		return false

	var recovery_result: RefCounted = run_director.handle_recovery_action(ui_input_result.recovery_action)
	if recovery_result.was_wrong_input:
		return false

	if recovery_result.bonus_callout_text != "":
		show_bonus_callout(recovery_result.bonus_callout_text)
	if recovery_result.play_step_sound:
		run_audio_presenter.play_recovery_step()
	if recovery_result.recovery_completed:
		run_audio_presenter.play_recovery_success()

	ui_presenter.refresh_status()
	ui_presenter.refresh_recovery_prompt()
	return true


## Updates pause state and pause-menu focus without routing back through RunScene.
func set_pause_state(paused: bool) -> void:
	if ui_presenter == null:
		return

	var was_paused := bool(ui_presenter.is_pause_menu_open)
	if not ui_presenter.set_pause_state(paused):
		return

	if run_audio_presenter != null:
		run_audio_presenter.play_pause_toggle()
	if bool(ui_presenter.is_pause_menu_open) and not was_paused and pause_layer != null:
		pause_layer.focus_default_button()


## Refreshes the in-progress HUD and overlays after one frame of work.
func refresh_in_progress_ui(delta: float) -> void:
	if ui_presenter == null:
		return

	ui_presenter.advance_callouts(delta, __get_canvas_transform())
	ui_presenter.refresh_status()
	ui_presenter.refresh_pause_menu()
	ui_presenter.refresh_recovery_prompt()
	ui_presenter.refresh_result_screen(build_best_run_summary())
	ui_presenter.refresh_touch_controls()


## Builds the compact best-run summary line for the result panel.
func build_best_run_summary() -> String:
	if run_state == null or not run_state.best_run.has_value:
		return ""

	var prefix := "New Best Run! | " if run_state.current_run_is_new_best else ""
	return "%sBest Score: %d | Best Grade: %s" % [
		prefix,
		run_state.best_run.score,
		run_state.best_run.grade,
	]


## Refreshes dust through the presentation owner and runtime audio through the extracted audio presenter.
func refresh_audio_presentation() -> void:
	if run_state == null:
		return

	if run_presentation != null:
		run_presentation.refresh_dust_presentation(RunStateType.DEFAULT_FORWARD_SPEED)
	if run_audio_presenter != null:
		run_audio_presenter.refresh_audio_presentation()


## Stores transition-sensitive run state so frame-entry checks can fire exactly once.
func sync_previous_frame_state() -> void:
	if run_state == null:
		previous_frame_result = RunStateType.RESULT_IN_PROGRESS
		previous_frame_has_crossed_finish_line = false
		return

	previous_frame_result = run_state.result
	previous_frame_has_crossed_finish_line = run_state.has_crossed_finish_line


# Private Methods

## Returns the current viewport canvas transform or the identity transform when unavailable.
func __get_canvas_transform() -> Transform2D:
	if viewport == null:
		return Transform2D.IDENTITY
	return viewport.get_canvas_transform()


## Refreshes the regular roadside sign cadence for the active progress band.
func refresh_regular_roadside_sign_spawning() -> void:
	if roadside_scenery == null:
		return

	roadside_scenery.set_regular_sign_spawning_enabled(should_allow_regular_roadside_signs())


## Returns whether regular roadside signs should stay active in the current route phase.
func should_allow_regular_roadside_signs() -> bool:
	if run_state == null:
		return true

	var route_phase := RunDirectorType.get_route_phase_for_progress(run_state.get_delivery_progress_ratio())
	return route_phase != RunDirectorType.ROUTE_PHASE_RESET_BEFORE_FINALE \
		and route_phase != RunDirectorType.ROUTE_PHASE_FINAL_STRETCH


## Advances the dedicated roadside scenery owner using travelled distance.
func advance_roadside_scenery(distance_delta: float) -> void:
	if roadside_scenery == null:
		return

	roadside_scenery.advance(distance_delta)


## Updates the wagon position to match the current lateral run-state offset.
func update_wagon_visual() -> void:
	if run_presentation == null:
		return

	run_presentation.update_wagon_visual()


## Keeps the camera centered on the wagon while preserving the below-center framing offset.
func update_camera_framing() -> void:
	if run_presentation == null:
		return

	run_presentation.update_camera_framing()


## Updates the wagon flash, wobble, and shake presentation for the current run state.
func update_impact_feedback(delta: float) -> void:
	if run_presentation == null:
		return

	run_presentation.update_impact_feedback(delta)


## Triggers the authored impact flash, wobble, and shake presentation state.
func trigger_impact_feedback() -> void:
	if run_presentation == null:
		return

	run_presentation.trigger_impact_feedback()


## Updates the looping world segments and tiled environment scroll windows.
func update_scroll_visuals() -> void:
	if run_presentation == null:
		return

	run_presentation.update_scroll_visuals()


## Plays one floating bonus callout anchored to the wagon position.
func show_bonus_callout(text: String) -> void:
	if ui_presenter == null:
		return

	var anchor_world_position := Vector2.ZERO if wagon == null else wagon.global_position
	ui_presenter.show_bonus_callout(text, anchor_world_position, __get_canvas_transform())


## Plays the authored impact cue for one resolved hazard hit.
func play_hazard_impact(hazard_type: StringName) -> void:
	if run_audio_presenter == null:
		return

	run_audio_presenter.play_hazard_impact(hazard_type)


## Applies child-FSM-visible presentation side effects emitted by the run director.
func handle_run_director_update(update: RefCounted) -> void:
	if update == null:
		return

	if ui_presenter != null and update.phase_callout_text != "":
		ui_presenter.show_phase_callout(update.phase_callout_text)
	if run_audio_presenter != null and update.recovery_penalty_applied:
		run_audio_presenter.play_recovery_fail()


## Applies child-FSM-visible impact and bonus presentation emitted by the hazard resolver.
func handle_run_hazard_update(update: RefCounted) -> void:
	if update == null:
		return

	for hazard_type: StringName in update.impact_hazard_types:
		trigger_impact_feedback()
		play_hazard_impact(hazard_type)

	for bonus_callout_text: String in update.bonus_callout_texts:
		show_bonus_callout(bonus_callout_text)


## Advances failure state timers and starts timer-driven bad luck when its scheduled roll matures.
func advance_failure_triggers(delta: float) -> void:
	if run_state == null or run_director == null:
		return

	handle_run_director_update(run_director.advance(delta))


## Synchronizes the route phase against the current run progress and refreshes bad-luck timing when it changes.
func sync_route_phase() -> void:
	if run_state == null or run_director == null:
		return

	handle_run_director_update(run_director.sync_route_phase())


## Spawns the dedicated finish sign exactly once when the run first enters the finish buffer.
func try_spawn_finish_buffer_sign() -> void:
	if run_state == null or roadside_scenery == null:
		return
	if not run_state.has_crossed_finish_line or previous_frame_has_crossed_finish_line:
		return
	if run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return

	roadside_scenery.spawn_forced_finish_sign()


## Converts a crossed finish line into true success only after the last live hazard has cleared.
func try_finalize_finish_success(finish_buffer_scroll_distance: float) -> void:
	if run_state == null or run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	if not run_state.has_crossed_finish_line:
		return
	if finish_buffer_scroll_distance < finish_runoff_distance:
		return
	if hazard_spawner != null and hazard_spawner.has_runtime_hazards():
		return

	run_state.result = RunStateType.RESULT_SUCCESS
	run_state.current_speed = 0.0


## Persists a newly completed run exactly once when it beats the stored best score.
func sync_completed_run_best_state() -> void:
	if run_state == null:
		return

	if run_state.result == RunStateType.RESULT_IN_PROGRESS:
		return

	if run_audio_presenter != null and run_audio_presenter.last_announced_result == run_state.result:
		return

	run_state.record_best_run_if_needed(RunStateType.BEST_RUN_SAVE_PATH)


## Returns whether the scripted success-arrival beat should start on this gameplay frame.
func should_start_success_arrival() -> bool:
	return run_state != null \
		and run_state.result == RunStateType.RESULT_SUCCESS \
		and previous_frame_result == RunStateType.RESULT_IN_PROGRESS
