extends Node2D

## Owns the run scene composition and coordinates the extracted runtime systems.


# Signals

signal restart_requested
signal return_to_title_requested


# Constants
const HazardSpawnerType := preload(ProjectPaths.HAZARD_SPAWNER_SCRIPT_PATH)
const RecoverySequenceGeneratorType := preload(ProjectPaths.RECOVERY_SEQUENCE_GENERATOR_SCRIPT_PATH)
const RunAudioPresenterType := preload(ProjectPaths.RUN_AUDIO_PRESENTER_SCRIPT_PATH)
const RunDirectorType := preload(ProjectPaths.RUN_DIRECTOR_SCRIPT_PATH)
const RunHazardResolverType := preload(ProjectPaths.RUN_HAZARD_RESOLVER_SCRIPT_PATH)
const RunPresentationType := preload(ProjectPaths.RUN_PRESENTATION_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)
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
const STEER_ACTION_NEGATIVE := "steer_left"
const STEER_ACTION_POSITIVE := "steer_right"
const PAUSE_ACTION := "pause_run"
const STEER_SPEED := 180.0
const ROAD_HALF_WIDTH := 104.0
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
const WHEEL_LOOSE_STEER_MULTIPLIER := 0.6
const WHEEL_LOOSE_DRIFT_SPEED := 32.0
const WHEEL_LOOSE_DRIFT_FREQUENCY := 8.0
const WHEEL_LOOSE_WOBBLE_DEGREES := RunPresentationType.WHEEL_LOOSE_WOBBLE_DEGREES
const WHEEL_LOOSE_WOBBLE_FREQUENCY := RunPresentationType.WHEEL_LOOSE_WOBBLE_FREQUENCY
const HORSE_PANIC_STEER_MULTIPLIER := 0.3
const HORSE_PANIC_DRIFT_SPEED := 150.0
const HORSE_PANIC_DRIFT_FREQUENCY := 5.0
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
const POST_FAILURE_STEER_MULTIPLIER := 0.75
const POST_FAILURE_DRIFT_SPEED := 55.0
const POST_FAILURE_DRIFT_FREQUENCY := 6.0
const WHEEL_LOOSE_FAILURE_HEALTH_LOSS := RunDirectorType.WHEEL_LOOSE_FAILURE_HEALTH_LOSS
const WHEEL_LOOSE_FAILURE_CARGO_LOSS := RunDirectorType.WHEEL_LOOSE_FAILURE_CARGO_LOSS
const WHEEL_LOOSE_FAILURE_SPEED_LOSS := RunDirectorType.WHEEL_LOOSE_FAILURE_SPEED_LOSS
const WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION := RunDirectorType.WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION
const HORSE_PANIC_FAILURE_CARGO_LOSS := RunDirectorType.HORSE_PANIC_FAILURE_CARGO_LOSS
const HORSE_PANIC_FAILURE_SPEED_LOSS := RunDirectorType.HORSE_PANIC_FAILURE_SPEED_LOSS
const HORSE_PANIC_FAILURE_INSTABILITY_DURATION := RunDirectorType.HORSE_PANIC_FAILURE_INSTABILITY_DURATION
const SCROLL_LOOP_HEIGHT := RunPresentationType.SCROLL_LOOP_HEIGHT
const ROADSIDE_DECOR_SPACING := RunPresentationType.ROADSIDE_DECOR_SPACING
const ROADSIDE_DECOR_COUNT := RunPresentationType.ROADSIDE_DECOR_COUNT
const SCRUB_COLOR := Color(0.47451, 0.443137, 0.219608, 0.95)
const SIGN_WOOD_COLOR := Color(0.415686, 0.266667, 0.121569, 1.0)
const SIGN_TEXT_COLOR := Color(0.956863, 0.913725, 0.760784, 1.0)
const DUST_BASE_AMOUNT_RATIO := RunPresentationType.DUST_BASE_AMOUNT_RATIO
const ONBOARDING_TITLE := "Last Delivery to Dust Gulch"
const ONBOARDING_BODY := (
	"Steer with A/D or Left/Right. Dodge the hazards, protect your cargo, "
	+ "and hold the wagon together until you reach Dust Gulch."
)
const ONBOARDING_HINT := "Press Left, Right, Enter, or click to begin the run."
const WAGON_LOOP_START_SECONDS := 5.0
const WAGON_LOOP_END_SECONDS := 10.0


# Private Fields

var _run_state: RunStateType
var _run_presentation: RunPresentationType = RunPresentationType.new()
var _run_audio_presenter: RunAudioPresenterType = RunAudioPresenterType.new()
var _run_director: RefCounted = RunDirectorType.new()
var _run_hazard_resolver: RefCounted = RunHazardResolverType.new()
var _navigation_click_in_progress := false
var _best_run_save_path := RunStateType.BEST_RUN_SAVE_PATH
var _recovery_sequence_generator: RecoverySequenceGeneratorType = RecoverySequenceGeneratorType.new()


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

## Binds a fresh run state and resets transient scene-only UI flow.
func setup(run_state: RunStateType) -> void:
	_run_state = run_state
	_run_state.load_persisted_best_run(_best_run_save_path)
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		_run_state.record_best_run_if_needed(_best_run_save_path)
	_run_audio_presenter.bind_run_state(_run_state)
	_run_ui_presenter.bind_run_state(_run_state)
	_run_ui_presenter.reset_for_new_run()
	_run_director.bind_run_state(_run_state, _recovery_sequence_generator)
	_run_presentation.bind_run_state(_run_state)
	_run_ui_presenter.refresh_status()
	_run_ui_presenter.refresh_onboarding_prompt()
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
		_dust_trail,
		SHRUB_TEXTURES,
		SIGN_TEXTURE
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
	_ensure_scroll_visuals()
	_configure_vehicle_sprites()
	_configure_wagon_collision_areas()
	_configure_hazard_cleanup_areas()
	_configure_distance_bar_band_markers()
	_run_ui_presenter.refresh_phase_callout()
	_configure_dust_trail()
	_configure_audio_players()

	if _touch_layer != null and not _touch_layer.pause_requested.is_connected(_on_touch_pause_button_pressed):
		_touch_layer.pause_requested.connect(_on_touch_pause_button_pressed)

	if _pause_layer != null and not _pause_layer.resume_requested.is_connected(_on_pause_resume_pressed):
		_pause_layer.resume_requested.connect(_on_pause_resume_pressed)

	if _pause_layer != null and not _pause_layer.restart_requested.is_connected(_on_pause_restart_pressed):
		_pause_layer.restart_requested.connect(_on_pause_restart_pressed)

	if (
		_pause_layer != null
		and not _pause_layer.return_to_title_requested.is_connected(_on_pause_return_to_title_pressed)
	):
		_pause_layer.return_to_title_requested.connect(_on_pause_return_to_title_pressed)

	if _result_layer != null and not _result_layer.restart_requested.is_connected(_on_result_restart_pressed):
		_result_layer.restart_requested.connect(_on_result_restart_pressed)

	if (
		_result_layer != null
		and not _result_layer.return_to_title_requested.is_connected(_on_result_return_to_title_pressed)
	):
		_result_layer.return_to_title_requested.connect(_on_result_return_to_title_pressed)
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_run_ui_presenter.refresh_status()
	_run_ui_presenter.refresh_onboarding_prompt()
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
	if _run_ui_presenter.is_pause_menu_open:
		_run_ui_presenter.refresh_onboarding_prompt()
		_run_ui_presenter.advance_callouts(delta, get_viewport().get_canvas_transform())
		_run_ui_presenter.refresh_pause_menu()
		_run_ui_presenter.refresh_result_screen(_build_best_run_summary())
		_run_ui_presenter.refresh_touch_controls()
		_refresh_audio_presentation()
		return
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		_run_ui_presenter.advance_callouts(delta, get_viewport().get_canvas_transform())
		_update_impact_feedback(delta)
		_update_wagon_visual()
		_update_camera_framing()
		_run_ui_presenter.refresh_status()
		_run_ui_presenter.refresh_onboarding_prompt()
		_run_ui_presenter.refresh_pause_menu()
		_run_ui_presenter.refresh_recovery_prompt()
		_run_ui_presenter.refresh_result_screen(_build_best_run_summary())
		_run_ui_presenter.refresh_touch_controls()
		_refresh_audio_presentation()
		return
	if _run_ui_presenter.is_onboarding_active:
		_run_ui_presenter.advance_callouts(delta, get_viewport().get_canvas_transform())
		_run_presentation.advance_scroll(_run_state.current_speed, delta)
		_update_impact_feedback(delta)
		_update_wagon_visual()
		_update_scroll_visuals()
		_update_camera_framing()
		_run_ui_presenter.refresh_status()
		_run_ui_presenter.refresh_onboarding_prompt()
		_run_ui_presenter.refresh_pause_menu()
		_run_ui_presenter.refresh_recovery_prompt()
		_run_ui_presenter.refresh_result_screen(_build_best_run_summary())
		_run_ui_presenter.refresh_touch_controls()
		_refresh_audio_presentation()
		return

	var steer_input := Input.get_axis(STEER_ACTION_NEGATIVE, STEER_ACTION_POSITIVE)
	var steer_multiplier := 1.0
	var lateral_drift := 0.0
	match _run_state.active_failure:
		&"wheel_loose":
			steer_multiplier = WHEEL_LOOSE_STEER_MULTIPLIER
			lateral_drift = sin(_run_presentation.impact_time * WHEEL_LOOSE_DRIFT_FREQUENCY) * WHEEL_LOOSE_DRIFT_SPEED
		&"horse_panic":
			steer_multiplier = HORSE_PANIC_STEER_MULTIPLIER
			lateral_drift = sin(_run_presentation.impact_time * HORSE_PANIC_DRIFT_FREQUENCY) * HORSE_PANIC_DRIFT_SPEED
		_:
			if _run_state.has_temporary_control_instability():
				steer_multiplier = POST_FAILURE_STEER_MULTIPLIER
				lateral_drift = sin(_run_presentation.impact_time * POST_FAILURE_DRIFT_FREQUENCY) * POST_FAILURE_DRIFT_SPEED

	_run_state.lateral_position = clamp(
		_run_state.lateral_position + ((steer_input * STEER_SPEED * steer_multiplier) + lateral_drift) * delta,
		-ROAD_HALF_WIDTH,
		ROAD_HALF_WIDTH,
	)
	_update_wagon_visual()
	_run_state.recover_speed(delta)
	_run_state.distance_remaining = max(
		0.0,
		_run_state.distance_remaining - _run_state.current_speed * delta,
	)
	_run_presentation.advance_scroll(_run_state.current_speed, delta)
	_sync_route_phase()
	_hazard_spawner.advance(
		_run_state.current_speed * delta,
		_run_state.get_delivery_progress_ratio(),
		_run_state.distance_remaining,
		_run_state.route_distance
	)
	_handle_run_hazard_update(
		_run_hazard_resolver.resolve_frame(
			_hazard_spawner,
			_run_state,
			_run_director
		)
	)
	_advance_failure_triggers(delta)
	_sync_completed_run_best_state()
	_run_ui_presenter.advance_callouts(delta, get_viewport().get_canvas_transform())
	_update_impact_feedback(delta)
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_run_ui_presenter.refresh_status()
	_run_ui_presenter.refresh_onboarding_prompt()
	_run_ui_presenter.refresh_pause_menu()
	_run_ui_presenter.refresh_recovery_prompt()
	_run_ui_presenter.refresh_result_screen(_build_best_run_summary())
	_run_ui_presenter.refresh_touch_controls()
	_refresh_audio_presentation()


## Persists a newly completed run exactly once when it beats the stored best score.
func _sync_completed_run_best_state() -> void:
	if _run_state == null:
		return
	if _run_state.result == RunStateType.RESULT_IN_PROGRESS:
		return
	if _run_audio_presenter.last_announced_result == _run_state.result:
		return

	_run_state.record_best_run_if_needed(_best_run_save_path)


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
	var ui_input_result := _run_ui_presenter.route_input(event, PAUSE_ACTION)
	if ui_input_result.pause_command == GameplayUiLayerType.PAUSE_COMMAND_TOGGLE:
		_set_pause_state(not _run_ui_presenter.is_pause_menu_open)
		return
	if ui_input_result.pause_command == GameplayUiLayerType.PAUSE_COMMAND_CLOSE:
		_set_pause_state(false)
		return

	if ui_input_result.did_dismiss_onboarding:
		_run_ui_presenter.dismiss_onboarding()
		if _run_director.route_phase_callout_zone == ROUTE_PHASE_WARM_UP:
			_show_phase_callout(_get_route_phase_display_name(_run_director.route_phase_callout_zone))
		return

	if _run_state == null or ui_input_result.recovery_action == &"":
		return

	var recovery_result: RefCounted = _run_director.handle_recovery_action(ui_input_result.recovery_action)
	if recovery_result.was_wrong_input:
		return

	if recovery_result.bonus_callout_text != "":
		_show_bonus_callout(recovery_result.bonus_callout_text)
	if recovery_result.play_step_sound:
		_run_audio_presenter.play_recovery_step()
	if recovery_result.recovery_completed:
		_run_audio_presenter.play_recovery_success()

	_run_ui_presenter.refresh_status()
	_run_ui_presenter.refresh_recovery_prompt()


## Updates the wagon position to match the current lateral run-state offset.
func _update_wagon_visual() -> void:
	_run_presentation.update_wagon_visual()


## Keeps the camera centered on the wagon while preserving the below-center framing offset.
func _update_camera_framing() -> void:
	_run_presentation.update_camera_framing()


## Applies scene-owned presentation side effects emitted by the extracted run director.
func _handle_run_director_update(update: RefCounted) -> void:
	if update == null:
		return
	if update.phase_callout_text != "":
		_run_ui_presenter.show_phase_callout(update.phase_callout_text)
	if update.recovery_penalty_applied:
		_run_audio_presenter.play_recovery_fail()


## Applies scene-owned impact and bonus presentation emitted by the hazard resolver.
func _handle_run_hazard_update(update: RefCounted) -> void:
	if update == null:
		return

	for hazard_type in update.impact_hazard_types:
		_trigger_impact_feedback()
		_play_hazard_impact(hazard_type)

	for bonus_callout_text in update.bonus_callout_texts:
		_show_bonus_callout(bonus_callout_text)


## Advances failure state timers and starts timer-driven bad luck when its scheduled roll matures.
func _advance_failure_triggers(delta: float) -> void:
	if _run_state == null:
		return

	_handle_run_director_update(_run_director.advance(delta))


## Synchronizes the route phase against the current run progress and refreshes bad-luck timing when it changes.
func _sync_route_phase() -> void:
	if _run_state == null:
		return

	_handle_run_director_update(_run_director.sync_route_phase())


## Returns the current authored phase for one route-progress ratio.
func _get_route_phase(progress_ratio: float) -> StringName:
	return RunDirectorType.get_route_phase_for_progress(progress_ratio)


## Returns the current cue region for one route-progress ratio.
func _get_route_phase_callout_zone(progress_ratio: float) -> StringName:
	return RunDirectorType.get_route_phase_callout_zone_for_progress(progress_ratio)


## Returns a readable label for the current authored route phase.
func _get_route_phase_display_name(route_phase: StringName) -> String:
	return RunDirectorType.get_route_phase_display_name(route_phase)


## Updates the wagon flash, wobble, and shake presentation for the current run state.
func _update_impact_feedback(delta: float) -> void:
	_run_presentation.update_impact_feedback(delta)


## Triggers the authored impact flash, wobble, and shake presentation state.
func _trigger_impact_feedback() -> void:
	_run_presentation.trigger_impact_feedback()


## Routes a hazard collision to its dedicated impact player and falls back to the generic impact cue.
func _play_hazard_impact(hazard_type: StringName) -> void:
	_run_audio_presenter.play_hazard_impact(hazard_type)


## Stops the tumbleweed cue after the same playback window used by the crash impact cue.
func _schedule_tumbleweed_impact_stop(serial: int) -> void:
	_run_audio_presenter.schedule_tumbleweed_impact_stop(serial)


## Stops the active tumbleweed cue only if a newer tumbleweed playback has not replaced it.
func _on_tumbleweed_impact_timeout(serial: int) -> void:
	_run_audio_presenter.on_tumbleweed_impact_timeout(serial)


## Ensures the looping roadside segments are populated through the presentation owner.
func _ensure_scroll_visuals() -> void:
	_run_presentation.ensure_scroll_visuals()


## Updates the looping world segments and tiled environment scroll windows.
func _update_scroll_visuals() -> void:
	_run_presentation.update_scroll_visuals()


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


## Starts and stops sustained failure ambients according to the active failure and run state.
func _refresh_failure_ambient_audio() -> void:
	_run_audio_presenter.refresh_failure_ambient_audio()


## Helper for ensure input actions.
func _ensure_input_actions() -> void:
	_register_action(STEER_ACTION_NEGATIVE, [KEY_A, KEY_LEFT])
	_register_action(STEER_ACTION_POSITIVE, [KEY_D, KEY_RIGHT])
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


## Preserves compatibility for legacy scene-state property access now owned by extracted presenters.
func _get(property: StringName) -> Variant:
	match property:
		&"_onboarding_active":
			return _run_ui_presenter.is_onboarding_active
		&"_pause_menu_open":
			return _run_ui_presenter.is_pause_menu_open
		&"_touch_controls_enabled_for_runtime":
			return _run_ui_presenter.are_touch_controls_enabled_for_runtime
		&"_has_native_mobile_runtime_override":
			return _run_ui_presenter.has_native_mobile_runtime_override
		&"_native_mobile_runtime_override":
			return _run_ui_presenter.is_native_mobile_runtime_override
		&"_has_mobile_web_runtime_override":
			return _run_ui_presenter.has_mobile_web_runtime_override
		&"_mobile_web_runtime_override":
			return _run_ui_presenter.is_mobile_web_runtime_override
		&"_has_touchscreen_available_override":
			return _run_ui_presenter.has_touchscreen_available_override
		&"_touchscreen_available_override":
			return _run_ui_presenter.is_touchscreen_available_override
		_:
			return null


## Preserves compatibility for legacy scene-state overrides now owned by extracted presenters.
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"_onboarding_active":
			_run_ui_presenter.is_onboarding_active = bool(value)
			return true
		&"_pause_menu_open":
			_run_ui_presenter.is_pause_menu_open = bool(value)
			return true
		&"_touch_controls_enabled_for_runtime":
			_run_ui_presenter.are_touch_controls_enabled_for_runtime = bool(value)
			return true
		&"_has_native_mobile_runtime_override":
			_run_ui_presenter.has_native_mobile_runtime_override = bool(value)
			return true
		&"_native_mobile_runtime_override":
			_run_ui_presenter.is_native_mobile_runtime_override = bool(value)
			return true
		&"_has_mobile_web_runtime_override":
			_run_ui_presenter.has_mobile_web_runtime_override = bool(value)
			return true
		&"_mobile_web_runtime_override":
			_run_ui_presenter.is_mobile_web_runtime_override = bool(value)
			return true
		&"_has_touchscreen_available_override":
			_run_ui_presenter.has_touchscreen_available_override = bool(value)
			return true
		&"_touchscreen_available_override":
			_run_ui_presenter.is_touchscreen_available_override = bool(value)
			return true
		_:
			return false


## Helper for apply recovery failure penalty.
func _apply_recovery_failure_penalty() -> void:
	_run_director.apply_recovery_failure_penalty()
	_run_audio_presenter.play_recovery_fail()
	_run_ui_presenter.refresh_status()
	_run_ui_presenter.refresh_recovery_prompt()


## Starts or refreshes the short-lived in-run bonus callout text.
func _show_bonus_callout(text: String) -> void:
	var anchor_world_position := Vector2.ZERO if _wagon == null else _wagon.global_position
	_run_ui_presenter.show_bonus_callout(
		text,
		anchor_world_position,
		get_viewport().get_canvas_transform()
	)


## Starts or refreshes the short-lived on-screen phase cue.
func _show_phase_callout(text: String) -> void:
	_run_ui_presenter.show_phase_callout(text)


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


## Updates the pause state and keeps the keyboard focus anchored to the active pause menu.
func _set_pause_state(paused: bool) -> void:
	var was_paused := _run_ui_presenter.is_pause_menu_open
	if not _run_ui_presenter.set_pause_state(paused):
		return
	_run_audio_presenter.play_pause_toggle()
	if _run_ui_presenter.is_pause_menu_open and not was_paused and _pause_layer != null:
		_pause_layer.focus_default_button()


## Resumes gameplay after playing the pause-menu click cue.
func _on_pause_resume_pressed() -> void:
	_play_ui_click()
	_set_pause_state(false)


## Restarts the run after playing the pause-menu click cue.
func _on_pause_restart_pressed() -> void:
	if _navigation_click_in_progress:
		return
	_navigation_click_in_progress = true
	await _play_ui_click_and_wait()
	_navigation_click_in_progress = false
	_set_pause_state(false)
	restart_requested.emit()


## Returns to title after playing the pause-menu click cue.
func _on_pause_return_to_title_pressed() -> void:
	if _navigation_click_in_progress:
		return
	_navigation_click_in_progress = true
	await _play_ui_click_and_wait()
	_navigation_click_in_progress = false
	_set_pause_state(false)
	return_to_title_requested.emit()


## Opens the pause menu from the mobile pause button when gameplay is active.
func _on_touch_pause_button_pressed() -> void:
	_set_pause_state(true)
