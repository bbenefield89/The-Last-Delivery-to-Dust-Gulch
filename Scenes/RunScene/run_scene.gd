extends Node2D

## Owns the run scene composition and coordinates the extracted runtime systems.


# Signals

signal restart_requested
signal return_to_title_requested


# Constants
const DevCheatsType := preload(ProjectPaths.DEV_CHEATS_SCRIPT_PATH)
const HazardSpawnerType := preload(ProjectPaths.HAZARD_SPAWNER_SCRIPT_PATH)
const RecoverySequenceGeneratorType := preload(ProjectPaths.RECOVERY_SEQUENCE_GENERATOR_SCRIPT_PATH)
const RoadsideSceneryType := preload(ProjectPaths.ROADSIDE_SCENERY_SCRIPT_PATH)
const RunAudioPresenterType := preload(ProjectPaths.RUN_AUDIO_PRESENTER_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunHazardResolverType := preload(ProjectPaths.RUN_HAZARD_RESOLVER_SCRIPT_PATH)
const RunPresentationType := preload(ProjectPaths.RUN_PRESENTATION_SCRIPT_PATH)
const RunStateMachineType := preload(ProjectPaths.RUN_STATE_MACHINE_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
const RunSceneTuningType := preload(ProjectPaths.RUN_SCENE_TUNING_SCRIPT_PATH)
const PhaseCalloutLayerType := preload(ProjectPaths.PHASE_CALLOUT_LAYER_SCRIPT_PATH)
const GameplayUiLayerType := preload(ProjectPaths.GAMEPLAY_UI_LAYER_SCRIPT_PATH)
const PauseLayerType := preload(ProjectPaths.PAUSE_LAYER_SCRIPT_PATH)
const ResultLayerType := preload(ProjectPaths.RESULT_LAYER_SCRIPT_PATH)
const TouchLayerType := preload(ProjectPaths.TOUCH_LAYER_SCRIPT_PATH)


const BACKGROUND_MUSIC := preload(AssetPaths.RUN_BACKGROUND_MUSIC_AUDIO_PATH)
const CARRIAGE_SHEET_TEXTURE := preload(AssetPaths.CARRIAGE_SHEET_TEXTURE_PATH)
const CARRIAGE_SHEET_FRAMES: Array[Rect2i] = [
	Rect2i(0, 0, 32, 64),
	Rect2i(32, 0, 32, 64),
]
const CARRIAGE_ANIMATION_FPS := 4.0
const HORSE_SHEET_TEXTURE := preload(AssetPaths.HORSE_SHEET_TEXTURE_PATH)
const HORSE_SHEET_FRAMES: Array[Rect2i] = [
	Rect2i(0, 0, 16, 48),
	Rect2i(16, 0, 16, 48),
	Rect2i(32, 0, 16, 48),
	Rect2i(48, 0, 16, 48),
]
const HORSE_ANIMATION_FPS := 4.0
const DESERT_TEXTURE := preload(AssetPaths.DESERT_TEXTURE_PATH)
const ROAD_TEXTURE := preload(AssetPaths.ROAD_TEXTURE_PATH)
const SHRUB_TEXTURES: Array[Texture2D] = [
	preload(AssetPaths.SHRUB_1_TEXTURE_PATH),
	preload(AssetPaths.SHRUB_2_TEXTURE_PATH),
	preload(AssetPaths.SHRUB_3_TEXTURE_PATH),
	preload(AssetPaths.SHRUB_4_TEXTURE_PATH),
]
const SIGN_TEXTURE := preload(AssetPaths.SIGN_TEXTURE_PATH)
const WAGON_LOOP_SOUND := preload(AssetPaths.WAGON_LOOP_SOUND_PATH)
const IMPACT_SOUND := preload(AssetPaths.IMPACT_SOUND_PATH)
const POTHOLE_IMPACT_SOUND := preload(AssetPaths.IMPACT_SOUND_PATH)
const ROCK_IMPACT_SOUND := preload(AssetPaths.IMPACT_SOUND_PATH)
const TUMBLEWEED_IMPACT_SOUND := preload(AssetPaths.TUMBLEWEED_IMPACT_SOUND_PATH)
const WHEEL_LOOSE_AMBIENT_SOUND := preload(AssetPaths.WHEEL_LOOSE_AMBIENT_SOUND_PATH)
const HORSE_PANIC_AMBIENT_SOUND := preload(AssetPaths.HORSE_PANIC_AMBIENT_SOUND_PATH)
const RECOVERY_STEP_SOUND := preload(AssetPaths.UI_CLICK_SOUND_PATH)
const RECOVERY_SUCCESS_SOUND := preload(AssetPaths.RECOVERY_SUCCESS_SOUND_PATH)
const RECOVERY_FAIL_SOUND := preload(AssetPaths.RECOVERY_FAIL_SOUND_PATH)
const ARROW_FONT := preload(AssetPaths.ARROW_FONT_PATH)
const PAUSE_TOGGLE_SOUND := preload(AssetPaths.PAUSE_TOGGLE_SOUND_PATH)
const WIN_STINGER := preload(AssetPaths.WIN_STINGER_SOUND_PATH)
const COLLAPSE_STINGER := preload(AssetPaths.COLLAPSE_STINGER_SOUND_PATH)
const HORSE_SPOOK_SOUND := preload(AssetPaths.HORSE_PANIC_AMBIENT_SOUND_PATH)
const UI_CLICK_SOUND := preload(AssetPaths.UI_CLICK_SOUND_PATH)
const PAUSE_ACTION: StringName = &"pause_run"
const HAZARD_COLLISION_LAYER := 1
const WAGON_COLLISION_LAYER := 2
const HAZARD_CLEANUP_COLLISION_LAYER := 4
const WAGON_BASE_COLOR := RunPresentationType.WAGON_BASE_COLOR
const WAGON_HIT_COLOR := RunPresentationType.WAGON_HIT_COLOR
const CAMERA_VERTICAL_OFFSET := RunPresentationType.CAMERA_VERTICAL_OFFSET
const IMPACT_FLASH_DURATION := RunPresentationType.IMPACT_FLASH_DURATION
const IMPACT_WOBBLE_DURATION := RunPresentationType.IMPACT_WOBBLE_DURATION
const IMPACT_SHAKE_DURATION := RunPresentationType.IMPACT_SHAKE_DURATION
const IMPACT_WOBBLE_DEGREES := RunPresentationType.IMPACT_WOBBLE_DEGREES
const IMPACT_WOBBLE_FREQUENCY := RunPresentationType.IMPACT_WOBBLE_FREQUENCY
const IMPACT_SHAKE_AMPLITUDE := RunPresentationType.IMPACT_SHAKE_AMPLITUDE
const WHEEL_LOOSE_WOBBLE_DEGREES := RunPresentationType.WHEEL_LOOSE_WOBBLE_DEGREES
const WHEEL_LOOSE_WOBBLE_FREQUENCY := RunPresentationType.WHEEL_LOOSE_WOBBLE_FREQUENCY
const HORSE_PANIC_WOBBLE_DEGREES := RunPresentationType.HORSE_PANIC_WOBBLE_DEGREES
const HORSE_PANIC_WOBBLE_FREQUENCY := RunPresentationType.HORSE_PANIC_WOBBLE_FREQUENCY
const ROUTE_PHASE_WARM_UP := RunDirectorType.ROUTE_PHASE_WARM_UP
const ROUTE_PHASE_FIRST_TROUBLE := RunDirectorType.ROUTE_PHASE_FIRST_TROUBLE
const ROUTE_PHASE_CROSSING_BEAT := RunDirectorType.ROUTE_PHASE_CROSSING_BEAT
const ROUTE_PHASE_CLUTTER_BEAT := RunDirectorType.ROUTE_PHASE_CLUTTER_BEAT
const ROUTE_PHASE_RESET_BEFORE_FINALE := RunDirectorType.ROUTE_PHASE_RESET_BEFORE_FINALE
const ROUTE_PHASE_FINAL_STRETCH := RunDirectorType.ROUTE_PHASE_FINAL_STRETCH
const ROUTE_PHASE_WARM_UP_END := RunDirectorType.ROUTE_PHASE_WARM_UP_END
const ROUTE_PHASE_FIRST_TROUBLE_END := RunDirectorType.ROUTE_PHASE_FIRST_TROUBLE_END
const ROUTE_PHASE_CROSSING_BEAT_END := RunDirectorType.ROUTE_PHASE_CROSSING_BEAT_END
const ROUTE_PHASE_CLUTTER_BEAT_END := RunDirectorType.ROUTE_PHASE_CLUTTER_BEAT_END
const ROUTE_PHASE_RESET_BEFORE_FINALE_END := RunDirectorType.ROUTE_PHASE_RESET_BEFORE_FINALE_END
const DISTANCE_BAR_BAND_BOUNDARIES := [
	ROUTE_PHASE_WARM_UP_END,
	ROUTE_PHASE_FIRST_TROUBLE_END,
	ROUTE_PHASE_CROSSING_BEAT_END,
	ROUTE_PHASE_CLUTTER_BEAT_END,
	ROUTE_PHASE_RESET_BEFORE_FINALE_END,
]
const DISTANCE_BAR_MARKER_COLOR := Color(0.945098, 0.882353, 0.709804, 0.9)
const DISTANCE_BAR_MARKER_HALF_WIDTH := 1.0
const PHASE_CALLOUT_DURATION := PhaseCalloutLayerType.CALLOUT_DURATION
const BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN := RunDirectorType.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MIN
const BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX := RunDirectorType.BAD_LUCK_INTERVAL_FIRST_TROUBLE_MAX
const BAD_LUCK_INTERVAL_CROSSING_BEAT_MIN := RunDirectorType.BAD_LUCK_INTERVAL_CROSSING_BEAT_MIN
const BAD_LUCK_INTERVAL_CROSSING_BEAT_MAX := RunDirectorType.BAD_LUCK_INTERVAL_CROSSING_BEAT_MAX
const BAD_LUCK_INTERVAL_CLUTTER_BEAT_MIN := RunDirectorType.BAD_LUCK_INTERVAL_CLUTTER_BEAT_MIN
const BAD_LUCK_INTERVAL_CLUTTER_BEAT_MAX := RunDirectorType.BAD_LUCK_INTERVAL_CLUTTER_BEAT_MAX
const BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN := RunDirectorType.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MIN
const BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX := RunDirectorType.BAD_LUCK_INTERVAL_RESET_BEFORE_FINALE_MAX
const RECOVERY_PROMPT_POOL: Array[StringName] = RunDirectorType.RECOVERY_PROMPT_POOL
const WHEEL_LOOSE_RECOVERY_DURATION := RunDirectorType.WHEEL_LOOSE_RECOVERY_DURATION
const HORSE_PANIC_RECOVERY_DURATION := RunDirectorType.HORSE_PANIC_RECOVERY_DURATION
const WHEEL_LOOSE_FAILURE_HEALTH_LOSS := RunDirectorType.WHEEL_LOOSE_FAILURE_HEALTH_LOSS
const WHEEL_LOOSE_FAILURE_CARGO_LOSS := RunDirectorType.WHEEL_LOOSE_FAILURE_CARGO_LOSS
const WHEEL_LOOSE_FAILURE_SPEED_LOSS := RunDirectorType.WHEEL_LOOSE_FAILURE_SPEED_LOSS
const WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION := RunDirectorType.WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION
const HORSE_PANIC_FAILURE_CARGO_LOSS := RunDirectorType.HORSE_PANIC_FAILURE_CARGO_LOSS
const HORSE_PANIC_FAILURE_SPEED_LOSS := RunDirectorType.HORSE_PANIC_FAILURE_SPEED_LOSS
const HORSE_PANIC_FAILURE_INSTABILITY_DURATION := RunDirectorType.HORSE_PANIC_FAILURE_INSTABILITY_DURATION
const SCROLL_LOOP_HEIGHT := RunPresentationType.SCROLL_LOOP_HEIGHT
const SUCCESS_EXIT_BEAT_DURATION := RunPresentationType.SUCCESS_ARRIVAL_DURATION
const SCRUB_COLOR := Color(0.47451, 0.443137, 0.219608, 0.95)
const DUST_BASE_AMOUNT_RATIO := RunPresentationType.DUST_BASE_AMOUNT_RATIO
const FINISH_RUNOFF_DISTANCE := 250.0
const WAGON_LOOP_START_SECONDS := 5.0
const WAGON_LOOP_END_SECONDS := 10.0


# Private Fields

var _run_state: RunStateType
var _run_presentation: RunPresentationType = RunPresentationType.new()
var _run_audio_presenter: RunAudioPresenterType = RunAudioPresenterType.new()
var _run_director: RunDirectorType = RunDirectorType.new()
var _run_hazard_resolver: RunHazardResolverType = RunHazardResolverType.new()
var _run_state_machine: RunStateMachine
var _navigation_click_in_progress := false
var _recovery_sequence_generator: RecoverySequenceGeneratorType = RecoverySequenceGeneratorType.new()
var _dev_cheats: DevCheatsType
var _previous_frame_result: StringName = RunStateType.RESULT_IN_PROGRESS
var _previous_frame_has_crossed_finish_line := false
var _is_success_exit_beat_active := false
var _has_finished_success_exit_beat := false


# Private Fields: OnReady

@onready
var _backdrop: Sprite2D = $World/Backdrop

@onready
var _road: Sprite2D = $World/Road

@onready
var _camera: Camera2D = %Camera

@onready
var _hazard_spawner: HazardSpawnerType = %HazardSpawner

@onready
var _roadside_scenery: RoadsideSceneryType = %RoadsideScenery

@onready
var _scroll_root: Node2D = %ScrollRoot

@onready
var _scroll_segment_a: Node2D = %ScrollSegmentA

@onready
var _scroll_segment_b: Node2D = %ScrollSegmentB

@onready
var _wagon: Node2D = %Wagon

@onready
var _wagon_collision_area: Area2D = %WagonCollisionArea

@onready
var _wagon_collision_shape: CollisionShape2D = %WagonCollisionShape

@onready
var _wagon_near_miss_area: Area2D = %WagonNearMissArea

@onready
var _wagon_near_miss_shape: CollisionShape2D = %WagonNearMissShape

@onready
var _hazard_cleanup_bottom_area: Area2D = %HazardCleanupBottomArea

@onready
var _hazard_cleanup_left_area: Area2D = %HazardCleanupLeftArea

@onready
var _hazard_cleanup_right_area: Area2D = %HazardCleanupRightArea

@onready
var _wagon_shadow: AnimatedSprite2D = $World/Wagon/Shadow

@onready
var _wagon_sprite: AnimatedSprite2D = $World/Wagon/CarriageSprite

@onready
var _horse_left_sprite: AnimatedSprite2D = $World/Wagon/HorseTeam/HorseLeft

@onready
var _horse_right_sprite: AnimatedSprite2D = $World/Wagon/HorseTeam/HorseRight

@onready
var _dust_trail: CPUParticles2D = %DustTrail

@onready
var _run_ui_presenter: GameplayUiLayerType = %GameplayUiLayer

@onready
var _touch_layer: TouchLayerType = %TouchLayer

@onready
var _pause_layer: PauseLayerType = %PauseLayer

@onready
var _result_layer: ResultLayerType = %ResultLayer

@onready
var _music_player: AudioStreamPlayer = %MusicPlayer

@onready
var _wagon_loop_player: AudioStreamPlayer = %WagonLoopPlayer

@onready
var _impact_player: AudioStreamPlayer = %ImpactPlayer

@onready
var _pothole_impact_player: AudioStreamPlayer = %PotholeImpactPlayer

@onready
var _rock_impact_player: AudioStreamPlayer = %RockImpactPlayer

@onready
var _tumbleweed_impact_player: AudioStreamPlayer = %TumbleweedImpactPlayer

@onready
var _wheel_loose_ambient_player: AudioStreamPlayer = %WheelLooseAmbientPlayer

@onready
var _horse_panic_ambient_player: AudioStreamPlayer = %HorsePanicAmbientPlayer

@onready
var _recovery_step_player: AudioStreamPlayer = %RecoveryStepPlayer

@onready
var _recovery_success_player: AudioStreamPlayer = %RecoverySuccessPlayer

@onready
var _recovery_fail_player: AudioStreamPlayer = %RecoveryFailPlayer

@onready
var _pause_toggle_player: AudioStreamPlayer = %PauseTogglePlayer

@onready
var _failure_player: AudioStreamPlayer = %FailurePlayer

@onready
var _result_player: AudioStreamPlayer = %ResultPlayer

@onready
var _ui_click_player: AudioStreamPlayer = %UIClickPlayer


# Public Methods

## Returns the currently bound run state or null when the scene has not been set up yet.
func get_run_state() -> RunStateType:
	return _run_state


## Binds a fresh run state and the shared build-owned dev cheats service for one run scene.
func setup(
	run_state: RunStateType,
	dev_cheats: DevCheatsType = null
) -> void:
	_run_state = run_state

	if dev_cheats != null:
		_dev_cheats = dev_cheats
	elif _dev_cheats == null:
		_dev_cheats = DevCheatsType.new()

	_dev_cheats.register_input_actions()
	_run_state.load_persisted_best_run(RunStateType.BEST_RUN_SAVE_PATH)

	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		_run_state.record_best_run_if_needed(RunStateType.BEST_RUN_SAVE_PATH)
		
	_previous_frame_result = _run_state.result
	_previous_frame_has_crossed_finish_line = _run_state.has_crossed_finish_line

	_is_success_exit_beat_active = false

	_has_finished_success_exit_beat = false

	_run_audio_presenter.bind_run_state(_run_state)
	_run_ui_presenter.bind_run_state(_run_state)
	_run_ui_presenter.reset_for_new_run()
	_run_director.bind_run_state(_run_state, _recovery_sequence_generator)
	_run_presentation.bind_run_state(_run_state)
	_run_presentation.reset_success_arrival()
	_run_state_machine = RunStateMachineType.new()
	_run_state_machine.bind(self)
	_run_ui_presenter.refresh_status()
	_run_ui_presenter.refresh_bonus_callout(get_viewport().get_canvas_transform())
	_run_ui_presenter.refresh_phase_callout()
	_run_ui_presenter.refresh_recovery_prompt()
	_run_ui_presenter.refresh_pause_menu()
	_run_ui_presenter.refresh_result_screen(_build_best_run_summary())
	_run_ui_presenter.refresh_touch_controls()
	
	_refresh_audio_presentation()


# Lifecycle Methods

## Wires scene-local input, UI, visuals, and audio dependencies.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run_director.bad_luck_rng.randomize()
	_ensure_input_actions()
	_run_presentation.configure_scene_nodes(
		_run_state,
		_backdrop,
		_road,
		_camera,
		_scroll_root,
		_scroll_segment_a,
		_scroll_segment_b,
		_wagon,
		_wagon_sprite,
		_horse_left_sprite,
		_horse_right_sprite,
		_dust_trail
	)
	_run_audio_presenter.configure_scene_nodes(
		_run_state,
		self,
		_music_player,
		_wagon_loop_player,
		_impact_player,
		_pothole_impact_player,
		_rock_impact_player,
		_tumbleweed_impact_player,
		_wheel_loose_ambient_player,
		_horse_panic_ambient_player,
		_recovery_step_player,
		_recovery_success_player,
		_recovery_fail_player,
		_pause_toggle_player,
		_failure_player,
		_result_player,
		_ui_click_player
	)
	_configure_environment_art()
	_configure_roadside_scenery()
	_configure_vehicle_sprites()
	_configure_wagon_collision_areas()
	_configure_hazard_cleanup_areas()
	_configure_distance_bar_band_markers()
	_run_ui_presenter.refresh_phase_callout()
	_configure_dust_trail()
	_configure_audio_players()

	if _result_layer != null and not _result_layer.restart_requested.is_connected(_on_result_restart_pressed):
		_result_layer.restart_requested.connect(_on_result_restart_pressed)

	if (
		_result_layer != null
		and not _result_layer.return_to_title_requested.is_connected(_on_result_return_to_title_pressed)
	):
		_result_layer.return_to_title_requested.connect(_on_result_return_to_title_pressed)
	_update_wagon_visual()
	_update_camera_framing()
	_run_ui_presenter.refresh_status()
	_run_ui_presenter.refresh_bonus_callout(get_viewport().get_canvas_transform())
	_run_ui_presenter.refresh_pause_menu()
	_run_ui_presenter.refresh_recovery_prompt()
	_run_ui_presenter.refresh_result_screen(_build_best_run_summary())
	_run_ui_presenter.refresh_touch_controls()
	_refresh_audio_presentation()


## Applies the imported carriage, shadow, and horse art to the existing wagon rig nodes.
func _configure_vehicle_sprites() -> void:
	if _wagon != null:
		_wagon.visible = true
		_wagon.modulate = WAGON_BASE_COLOR
	var carriage_sprite_frames := _build_carriage_sprite_frames()
	var horse_sprite_frames := _build_horse_sprite_frames()
	if _wagon_shadow != null:
		_wagon_shadow.sprite_frames = carriage_sprite_frames
		_wagon_shadow.animation = &"default"
		_wagon_shadow.frame = 0
		_wagon_shadow.play()
	if _wagon_sprite != null:
		_wagon_sprite.sprite_frames = carriage_sprite_frames
		_wagon_sprite.animation = &"default"
		_wagon_sprite.frame = 0
		_wagon_sprite.play()
	if _horse_left_sprite != null:
		_horse_left_sprite.sprite_frames = horse_sprite_frames
		_horse_left_sprite.animation = &"default"
		_horse_left_sprite.frame = 0
		_horse_left_sprite.play()
	if _horse_right_sprite != null:
		_horse_right_sprite.sprite_frames = horse_sprite_frames
		_horse_right_sprite.animation = &"default"
		_horse_right_sprite.frame = 0
		_horse_right_sprite.play()


## Wires the wagon hit and near-miss areas into the active hazard-overlap layers.
func _configure_wagon_collision_areas() -> void:
	if _wagon_collision_area == null:
		return

	_wagon_collision_area.monitoring = true
	_wagon_collision_area.monitorable = true
	_wagon_collision_area.collision_layer = WAGON_COLLISION_LAYER
	_wagon_collision_area.collision_mask = HAZARD_COLLISION_LAYER
	if _wagon_near_miss_area != null:
		_wagon_near_miss_area.monitoring = true
		_wagon_near_miss_area.monitorable = true
		_wagon_near_miss_area.collision_layer = WAGON_COLLISION_LAYER
		_wagon_near_miss_area.collision_mask = HAZARD_COLLISION_LAYER
	_hazard_spawner.bind_wagon_collision_area(_wagon_collision_area)
	_hazard_spawner.bind_wagon_near_miss_area(_wagon_near_miss_area)


## Wires the hazard cleanup boundaries into the event-based pass and despawn flow.
func _configure_hazard_cleanup_areas() -> void:
	var cleanup_areas: Array[Area2D] = []
	for cleanup_area in [
		_hazard_cleanup_bottom_area,
		_hazard_cleanup_left_area,
		_hazard_cleanup_right_area,
	]:
		if cleanup_area == null:
			continue

		cleanup_area.monitoring = true
		cleanup_area.monitorable = true
		cleanup_area.collision_layer = HAZARD_CLEANUP_COLLISION_LAYER
		cleanup_area.collision_mask = HAZARD_COLLISION_LAYER
		cleanup_areas.append(cleanup_area)

	_hazard_spawner.bind_hazard_cleanup_areas(cleanup_areas)
	if _roadside_scenery != null:
		_roadside_scenery.bind_cleanup_areas(cleanup_areas)


## Builds the animated carriage frame set from the exported sheet texture.
func _build_carriage_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.set_animation_loop(&"default", true)
	sprite_frames.set_animation_speed(&"default", CARRIAGE_ANIMATION_FPS)

	for frame_region in CARRIAGE_SHEET_FRAMES:
		sprite_frames.add_frame(&"default", _make_carriage_sheet_frame(frame_region))

	return sprite_frames


## Creates a single atlas frame that slices the carriage sheet to one animation cell.
func _make_carriage_sheet_frame(region: Rect2i) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = CARRIAGE_SHEET_TEXTURE
	atlas_texture.region = region
	return atlas_texture


## Builds the animated horse frame set from the exported sheet texture.
func _build_horse_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.set_animation_loop(&"default", true)
	sprite_frames.set_animation_speed(&"default", HORSE_ANIMATION_FPS)

	for frame_region in HORSE_SHEET_FRAMES:
		sprite_frames.add_frame(&"default", _make_horse_sheet_frame(frame_region))

	return sprite_frames


## Creates a single atlas frame that slices the horse sheet to one animation cell.
func _make_horse_sheet_frame(region: Rect2i) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = HORSE_SHEET_TEXTURE
	atlas_texture.region = region
	return atlas_texture


## Applies the tiled road and desert art to the world background nodes.
func _configure_environment_art() -> void:
	if _backdrop != null:
		_backdrop.visible = true
	if _road != null:
		_road.visible = true
	_run_presentation.configure_environment_art(DESERT_TEXTURE, ROAD_TEXTURE)


## Applies the authored roadside art to the dedicated roadside scenery owner.
func _configure_roadside_scenery() -> void:
	if _roadside_scenery == null:
		return

	_roadside_scenery.configure_scenery_art(SHRUB_TEXTURES, SIGN_TEXTURE)
	var regular_signs_enabled := true
	if _run_state != null:
		var route_phase := RunDirectorType.get_route_phase_for_progress(_run_state.get_delivery_progress_ratio())
		regular_signs_enabled = route_phase != ROUTE_PHASE_RESET_BEFORE_FINALE \
			and route_phase != ROUTE_PHASE_FINAL_STRETCH
	_roadside_scenery.set_regular_sign_spawning_enabled(regular_signs_enabled)


## Rebuilds the distance bar markers from the authored route-band thresholds.
func _configure_distance_bar_band_markers() -> void:
	_run_ui_presenter.configure_distance_bar_band_markers(
		DISTANCE_BAR_BAND_BOUNDARIES,
		DISTANCE_BAR_MARKER_COLOR,
		DISTANCE_BAR_MARKER_HALF_WIDTH
	)


## Stops transient input/audio state when the run scene leaves the tree.
func _exit_tree() -> void:
	_run_ui_presenter.release_touch_steer_actions()
	for player in [
		_music_player,
		_wagon_loop_player,
		_impact_player,
		_pothole_impact_player,
		_rock_impact_player,
		_tumbleweed_impact_player,
		_wheel_loose_ambient_player,
		_horse_panic_ambient_player,
		_recovery_step_player,
		_recovery_success_player,
		_recovery_fail_player,
		_pause_toggle_player,
		_failure_player,
		_result_player,
		_ui_click_player
	]:
		if player == null:
			continue
		player.stop()
		player.stream = null


## Advances runtime presentation and gameplay according to the current run phase.
func _process(delta: float) -> void:
	if _run_state == null:
		_run_ui_presenter.advance_callouts(delta, get_viewport().get_canvas_transform())
		return

	if _run_state_machine == null:
		_run_state_machine = RunStateMachineType.new()
		_run_state_machine.bind(self)

	_run_state_machine.advance(delta)


## Persists a newly completed run exactly once when it beats the stored best score.
func _sync_completed_run_best_state() -> void:
	if _run_state == null:
		return

	if _run_state.result == RunStateType.RESULT_IN_PROGRESS:
		return

	if _run_audio_presenter.last_announced_result == _run_state.result:
		return

	_run_state.record_best_run_if_needed(RunStateType.BEST_RUN_SAVE_PATH)


## Builds the compact best-run summary line set for the completed-run result panel.
func _build_best_run_summary() -> String:
	if _run_state == null:
		return ""
	if not _run_state.best_run.has_value:
		return ""

	var prefix := "New Best Run! | " if _run_state.current_run_is_new_best else ""
	return "%sBest Score: %d | Best Grade: %s" % [
		prefix,
		_run_state.best_run.score,
		_run_state.best_run.grade,
	]

# Event Handlers

## Routes pause, onboarding, and recovery input for the run scene.
func _input(event: InputEvent) -> void:
	if _run_state_machine == null:
		_run_state_machine = RunStateMachineType.new()
		_run_state_machine.bind(self)

	_run_state_machine.handle_input(event)


## Updates the wagon position to match the current lateral run-state offset.
func _update_wagon_visual() -> void:
	_run_presentation.update_wagon_visual()


## Keeps the camera centered on the wagon while preserving the below-center framing offset.
func _update_camera_framing() -> void:
	_run_presentation.update_camera_framing()


## Stores transition-sensitive run state so frame-entry checks can fire exactly once.
func _sync_previous_frame_state() -> void:
	if _run_state == null:
		_previous_frame_result = RunStateType.RESULT_IN_PROGRESS
		_previous_frame_has_crossed_finish_line = false
		return

	_previous_frame_result = _run_state.result
	_previous_frame_has_crossed_finish_line = _run_state.has_crossed_finish_line


## Updates the wagon flash, wobble, and shake presentation for the current run state.
func _update_impact_feedback(delta: float) -> void:
	_run_presentation.update_impact_feedback(delta)


## Applies the authored dust particle configuration through the presentation owner.
func _configure_dust_trail() -> void:
	_run_presentation.configure_dust_trail()


## Applies the authored streams, mix levels, and loop points through the extracted audio presenter.
func _configure_audio_players() -> void:
	_run_audio_presenter.configure_audio_players(
		BACKGROUND_MUSIC,
		WAGON_LOOP_SOUND,
		IMPACT_SOUND,
		POTHOLE_IMPACT_SOUND,
		ROCK_IMPACT_SOUND,
		TUMBLEWEED_IMPACT_SOUND,
		WHEEL_LOOSE_AMBIENT_SOUND,
		HORSE_PANIC_AMBIENT_SOUND,
		RECOVERY_STEP_SOUND,
		RECOVERY_SUCCESS_SOUND,
		RECOVERY_FAIL_SOUND,
		PAUSE_TOGGLE_SOUND,
		HORSE_SPOOK_SOUND,
		WIN_STINGER,
		COLLAPSE_STINGER,
		UI_CLICK_SOUND,
		WAGON_LOOP_START_SECONDS,
		WAGON_LOOP_END_SECONDS
	)


## Refreshes dust through the presentation owner and runtime audio through the extracted audio presenter.
func _refresh_audio_presentation() -> void:
	if _run_state == null:
		return

	_run_presentation.refresh_dust_presentation(RunStateType.DEFAULT_FORWARD_SPEED)
	_run_audio_presenter.refresh_audio_presentation()


## Helper for ensure input actions.
func _ensure_input_actions() -> void:
	_register_action(RunSceneTuningType.STEER_ACTION_NEGATIVE, [KEY_A, KEY_LEFT])
	_register_action(RunSceneTuningType.STEER_ACTION_POSITIVE, [KEY_D, KEY_RIGHT])
	_register_action(PAUSE_ACTION, [KEY_ESCAPE])


## Helper for register action.
func _register_action(action_name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


## Plays the shared menu click cue for pause and result buttons.
func _play_ui_click() -> void:
	_run_audio_presenter.play_ui_click()


## Plays the shared menu click cue and waits long enough for scene transitions to preserve it.
func _play_ui_click_and_wait() -> void:
	await _run_audio_presenter.play_ui_click_and_wait()


## Emits restart after playing the result-screen click cue.
func _on_result_restart_pressed() -> void:
	if _navigation_click_in_progress:
		return
	_navigation_click_in_progress = true
	await _play_ui_click_and_wait()
	_navigation_click_in_progress = false
	restart_requested.emit()


## Emits return-to-title after playing the result-screen click cue.
func _on_result_return_to_title_pressed() -> void:
	if _navigation_click_in_progress:
		return
	_navigation_click_in_progress = true
	await _play_ui_click_and_wait()
	_navigation_click_in_progress = false
	return_to_title_requested.emit()


