extends InProgressStateMachineStateBase

## Owns active gameplay while the run remains inside the in-progress branch.


# Imports

const GameplayUiLayerType := preload(ProjectPaths.GAMEPLAY_UI_LAYER_SCRIPT_PATH)
const RunSceneTuningType := preload(ProjectPaths.RUN_SCENE_TUNING_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Constants

const STATE_KEY: InProgressStateMachineKeyType.Key = InProgressStateMachineKeyType.Key.ACTIVE_GAMEPLAY


# Private Fields

var __finish_buffer_scroll_distance := 0.0


# Public Methods

## Returns the child-FSM key owned by this active gameplay substate.
func get_state_key() -> InProgressStateMachineKeyType.Key:
	return STATE_KEY


## Handles transition entry for the active gameplay substate.
func enter(previous_state_key: InProgressStateMachineKeyType.Key) -> void:
	if (
		previous_state_key == InProgressStateMachineKeyType.Key.NONE
		or previous_state_key == InProgressStateMachineKeyType.Key.ONBOARDING
	):
		__finish_buffer_scroll_distance = 0.0

	var context := _get_context()
	if context != null and context.touch_layer != null:
		if not context.touch_layer.pause_requested.is_connected(__on_touch_pause_requested):
			context.touch_layer.pause_requested.connect(__on_touch_pause_requested)



## Handles transition exit for the active gameplay substate.
func exit(_next_state_key: InProgressStateMachineKeyType.Key) -> void:
	var context := _get_context()
	if context != null and context.touch_layer != null:
		if context.touch_layer.pause_requested.is_connected(__on_touch_pause_requested):
			context.touch_layer.pause_requested.disconnect(__on_touch_pause_requested)


## Advances one active gameplay frame through the injected in-progress context.
func advance(delta: float) -> void:
	var context := _get_context()
	if context == null or context.run_state == null or context.run_presentation == null:
		return

	var steer_input := Input.get_axis(
		RunSceneTuningType.STEER_ACTION_NEGATIVE,
		RunSceneTuningType.STEER_ACTION_POSITIVE
	)
	var steer_multiplier := 1.0
	var lateral_drift := 0.0
	match context.run_state.active_failure:
		&"wheel_loose":
			steer_multiplier = RunSceneTuningType.WHEEL_LOOSE_STEER_MULTIPLIER
			lateral_drift = sin(
				context.run_presentation.impact_time * RunSceneTuningType.WHEEL_LOOSE_DRIFT_FREQUENCY
			) * RunSceneTuningType.WHEEL_LOOSE_DRIFT_SPEED
		&"horse_panic":
			steer_multiplier = RunSceneTuningType.HORSE_PANIC_STEER_MULTIPLIER
			lateral_drift = sin(
				context.run_presentation.impact_time * RunSceneTuningType.HORSE_PANIC_DRIFT_FREQUENCY
			) * RunSceneTuningType.HORSE_PANIC_DRIFT_SPEED
		_:
			if context.run_state.has_temporary_control_instability():
				steer_multiplier = RunSceneTuningType.POST_FAILURE_STEER_MULTIPLIER
				lateral_drift = sin(
					context.run_presentation.impact_time * RunSceneTuningType.POST_FAILURE_DRIFT_FREQUENCY
				) * RunSceneTuningType.POST_FAILURE_DRIFT_SPEED

	context.run_state.lateral_position = clamp(
		context.run_state.lateral_position
			+ ((steer_input * RunSceneTuningType.STEER_SPEED * steer_multiplier) + lateral_drift) * delta,
		-RunSceneTuningType.ROAD_HALF_WIDTH,
		RunSceneTuningType.ROAD_HALF_WIDTH
	)

	context.update_wagon_visual()
	context.run_state.recover_speed(delta)
	var distance_remaining_before_travel := context.run_state.distance_remaining
	context.run_state.distance_remaining = max(
		0.0,
		context.run_state.distance_remaining - context.run_state.current_speed * delta
	)

	var scroll_distance := context.run_state.current_speed * delta
	context.run_presentation.advance_scroll(context.run_state.current_speed, delta)
	context.refresh_regular_roadside_sign_spawning()
	context.advance_roadside_scenery(scroll_distance)
	context.sync_route_phase()

	var should_process_runtime_hazards := (
		context.dev_cheats == null or bool(context.dev_cheats.are_runtime_hazards_enabled)
	)
	if should_process_runtime_hazards:
		if context.hazard_spawner != null:
			context.hazard_spawner.advance(
				scroll_distance,
				context.run_state.get_delivery_progress_ratio(),
				context.run_state.distance_remaining,
				context.run_state.route_distance
			)

		if (
			context.run_hazard_resolver != null
			and context.hazard_spawner != null
			and context.run_director != null
		):
			context.handle_run_hazard_update(
				context.run_hazard_resolver.resolve_frame(
					context.hazard_spawner,
					context.run_state,
					context.run_director
				)
			)

	context.advance_failure_triggers(delta)
	__advance_finish_buffer_runoff(context, scroll_distance, distance_remaining_before_travel)
	context.try_spawn_finish_buffer_sign()
	context.try_finalize_finish_success(__finish_buffer_scroll_distance)
	context.sync_completed_run_best_state()
	if context.should_start_success_arrival():
		return

	context.sync_previous_frame_state()
	context.update_impact_feedback(delta)
	context.update_wagon_visual()
	context.update_scroll_visuals()
	context.update_camera_framing()
	context.refresh_in_progress_ui(delta)
	context.refresh_audio_presentation()


## Enables or disables runtime hazards while active gameplay owns the in-progress branch.
func set_hazards_enabled(enabled: bool) -> void:
	var context := _get_context()
	if context == null:
		return
	if context.dev_cheats == null or not context.dev_cheats.are_cheats_available():
		return
	if context.dev_cheats.are_runtime_hazards_enabled == enabled:
		return

	context.dev_cheats.are_runtime_hazards_enabled = enabled
	if not context.dev_cheats.are_runtime_hazards_enabled and context.hazard_spawner != null:
		context.hazard_spawner.clear_runtime_hazards()

	context.show_bonus_callout("HAZARDS ON" if context.dev_cheats.are_runtime_hazards_enabled else "HAZARDS OFF")


## Handles pause and recovery input while active gameplay owns the branch.
func handle_input(event: InputEvent) -> void:
	var context := _get_context()
	if context == null:
		return
	if context.dev_cheats != null and context.dev_cheats.consume_input(event):
		set_hazards_enabled(not context.dev_cheats.are_runtime_hazards_enabled)
		return

	var ui_input_result: Variant = context.route_ui_input(event)
	if ui_input_result == null:
		return

	if ui_input_result.pause_command == GameplayUiLayerType.PAUSE_COMMAND_TOGGLE:
		_request_transition(InProgressStateMachineKeyType.Key.PAUSED)
		return

	context.try_handle_recovery_input(ui_input_result)


# Private Methods

## Requests transition to the paused substate when the mobile pause button is pressed.
func __on_touch_pause_requested() -> void:
	_request_transition(InProgressStateMachineKeyType.Key.PAUSED)


## Tracks the amount of world scroll that has happened after crossing the finish threshold.
func __advance_finish_buffer_runoff(
	context: InProgressContextType,
	scroll_distance: float,
	distance_remaining_before_travel: float
) -> void:
	if context.run_state == null or context.run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	
	if not context.run_state.has_crossed_finish_line:
		return

	var runoff_distance := scroll_distance
	if not context.previous_frame_has_crossed_finish_line:
		runoff_distance = maxf(0.0, scroll_distance - maxf(distance_remaining_before_travel, 0.0))

	if runoff_distance <= 0.0:
		return

	__finish_buffer_scroll_distance += runoff_distance
