extends Node2D

signal restart_requested
signal return_to_title_requested

const HazardSpawnerType := preload("res://Systems/HazardSpawner/hazard_spawner.gd")
const RecoverySequenceGeneratorType := preload("res://Systems/RecoverySequenceGenerator/recovery_sequence_generator.gd")
const RunDirectorType := preload("res://Systems/RunDirector/run_director.gd")
const RunHazardResolverType := preload("res://Systems/RunHazardResolver/run_hazard_resolver.gd")
const RunPresentationType := preload("res://Systems/RunPresentation/run_presentation.gd")
const RunUiPresenterType := preload("res://Systems/RunUiPresenter/run_ui_presenter.gd")
const RunStateType := preload("res://Systems/RunState/run_state.gd")
const BACKGROUND_MUSIC := preload("res://Assets/Audio/We Ride At Dawn! (loop).ogg")
const CARRIAGE_SHEET_TEXTURE := preload("res://Assets/Tilesets/Carriage/Carriage-32x64-Sheet.png")
const CARRIAGE_SHEET_FRAMES: Array[Rect2i] = [
	Rect2i(0, 0, 32, 64),
	Rect2i(32, 0, 32, 64),
]
const CARRIAGE_ANIMATION_FPS := 4.0
const HORSE_SHEET_TEXTURE := preload("res://Assets/Tilesets/Horse/Horse-16x48-Sheet.png")
const HORSE_SHEET_FRAMES: Array[Rect2i] = [
	Rect2i(0, 0, 16, 48),
	Rect2i(16, 0, 16, 48),
	Rect2i(32, 0, 16, 48),
	Rect2i(48, 0, 16, 48),
]
const HORSE_ANIMATION_FPS := 4.0
const DESERT_TEXTURE := preload("res://Assets/Tilesets/Desert/Desert-3-32x32.png")
const ROAD_TEXTURE := preload("res://Assets/Tilesets/Road/Road-4-tiled-32x32.png")
const SHRUB_TEXTURES: Array[Texture2D] = [
	preload("res://Assets/Tilesets/Shrubs/Shrub-1-32x32.png"),
	preload("res://Assets/Tilesets/Shrubs/Shrub-2-32x32.png"),
	preload("res://Assets/Tilesets/Shrubs/Shrub-3-32x32.png"),
	preload("res://Assets/Tilesets/Shrubs/Shrub-4-32x32.png"),
]
const SIGN_TEXTURE := preload("res://Assets/Tilesets/Sign/Sign-32x48.png")
const WAGON_LOOP_SOUND := preload("res://Assets/Sfx/Horse-and-Chariot-30-sec-73615.mp3")
const IMPACT_SOUND := preload("res://Assets/Sfx/Car-Crash-376874.mp3")
const POTHOLE_IMPACT_SOUND := preload("res://Assets/Sfx/Car-Crash-376874.mp3")
const ROCK_IMPACT_SOUND := preload("res://Assets/Sfx/Car-Crash-376874.mp3")
const TUMBLEWEED_IMPACT_SOUND := preload("res://Assets/Sfx/Tumbleweed-98357.mp3")
const WHEEL_LOOSE_AMBIENT_SOUND := preload("res://Assets/Sfx/Loose-Wheel-411689.mp3")
const HORSE_PANIC_AMBIENT_SOUND := preload("res://Assets/Sfx/Horse-Panic-261131.mp3")
const RECOVERY_STEP_SOUND := preload("res://Assets/Sfx/Button-Click-85854.mp3")
const RECOVERY_SUCCESS_SOUND := preload("res://Assets/Sfx/Recovery-Step-Success-374193.mp3")
const RECOVERY_FAIL_SOUND := preload("res://Assets/Sfx/Recovery-Step-Failure-437420.mp3")
const ARROW_FONT = preload("res://Assets/Fonts/kenney_input_keyboard_mouse.ttf")
const PAUSE_TOGGLE_SOUND := preload("res://Assets/Sfx/Pause-Open-Close-333828.mp3")
const WIN_STINGER := preload("res://Assets/Sfx/Win-Fanfare-368589.mp3")
const COLLAPSE_STINGER := preload("res://Assets/Sfx/Wagon-Collapse-379298.mp3")
const HORSE_SPOOK_SOUND := preload("res://Assets/Sfx/Horse-Panic-261131.mp3")
const UI_CLICK_SOUND := preload("res://Assets/Sfx/Button-Click-85854.mp3")
const STEER_ACTION_NEGATIVE := "steer_left"
const STEER_ACTION_POSITIVE := "steer_right"
const PAUSE_ACTION := "pause_run"
const STEER_SPEED := 180.0
const ROAD_HALF_WIDTH := 104.0
const WAGON_BASE_Y := RunPresentationType.WAGON_BASE_Y
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
const PHASE_CALLOUT_DURATION := 0.95
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
const NEAR_MISS_MAX_HORIZONTAL_CLEARANCE := 12.0
const BONUS_CALLOUT_DURATION := 1.1
const BONUS_CALLOUT_START_OFFSET := Vector2(0.0, -64.0)
const BONUS_CALLOUT_END_OFFSET := Vector2(0.0, -82.0)
const RECOVERY_STEP_ROW_MAX_WIDTH := RunUiPresenterType.RECOVERY_STEP_ROW_MAX_WIDTH
const RECOVERY_STEP_MIN_WIDTH := RunUiPresenterType.RECOVERY_STEP_MIN_WIDTH
const RECOVERY_STEP_HEIGHT := RunUiPresenterType.RECOVERY_STEP_HEIGHT
const RECOVERY_STEP_MAX_WIDTH := RunUiPresenterType.RECOVERY_STEP_MAX_WIDTH
const RECOVERY_STEP_FONT_SIZE_RATIO := RunUiPresenterType.RECOVERY_STEP_FONT_SIZE_RATIO
const RECOVERY_STEP_MIN_FONT_SIZE := RunUiPresenterType.RECOVERY_STEP_MIN_FONT_SIZE
const RECOVERY_STEP_MAX_FONT_SIZE := RunUiPresenterType.RECOVERY_STEP_MAX_FONT_SIZE
const RECOVERY_STEP_SPACING := RunUiPresenterType.RECOVERY_STEP_SPACING
const RECOVERY_STEP_BASELINE_SEQUENCE_LENGTH := RunUiPresenterType.RECOVERY_STEP_BASELINE_SEQUENCE_LENGTH
const SCROLL_LOOP_HEIGHT := RunPresentationType.SCROLL_LOOP_HEIGHT
const ROADSIDE_DECOR_SPACING := RunPresentationType.ROADSIDE_DECOR_SPACING
const ROADSIDE_DECOR_COUNT := RunPresentationType.ROADSIDE_DECOR_COUNT
const WAGON_COLLISION_SIZE := Vector2(32.0, 64.0)
const RECOVERY_STEP_PENDING_COLOR := RunUiPresenterType.RECOVERY_STEP_PENDING_COLOR
const RECOVERY_STEP_ACTIVE_COLOR := RunUiPresenterType.RECOVERY_STEP_ACTIVE_COLOR
const RECOVERY_STEP_DONE_COLOR := RunUiPresenterType.RECOVERY_STEP_DONE_COLOR
const SCRUB_COLOR := Color(0.47451, 0.443137, 0.219608, 0.95)
const SIGN_WOOD_COLOR := Color(0.415686, 0.266667, 0.121569, 1.0)
const SIGN_TEXT_COLOR := Color(0.956863, 0.913725, 0.760784, 1.0)
const DUST_BASE_AMOUNT_RATIO := RunPresentationType.DUST_BASE_AMOUNT_RATIO
const ONBOARDING_TITLE := RunUiPresenterType.ONBOARDING_TITLE
const ONBOARDING_BODY := RunUiPresenterType.ONBOARDING_BODY
const ONBOARDING_HINT := RunUiPresenterType.ONBOARDING_HINT
const WAGON_LOOP_START_SECONDS := 5.0
const WAGON_LOOP_END_SECONDS := 10.0

var _run_state: RunStateType
var _run_presentation: RunPresentationType = RunPresentationType.new()
var _run_ui_presenter: RunUiPresenterType = RunUiPresenterType.new()
var _run_director: RefCounted = RunDirectorType.new()
var _run_hazard_resolver: RefCounted = RunHazardResolverType.new()
var _last_announced_failure: StringName = &""
var _last_announced_result: StringName = RunStateType.RESULT_IN_PROGRESS
var _navigation_click_in_progress := false
var _tumbleweed_impact_serial := 0
var _bonus_callout_text := ""
var _bonus_callout_remaining := 0.0
var _bonus_callout_anchor_world_position := Vector2.ZERO
var _phase_callout_text := ""
var _phase_callout_remaining := 0.0
var _best_run_save_path := RunStateType.BEST_RUN_SAVE_PATH
var _recovery_sequence_generator: RecoverySequenceGeneratorType = RecoverySequenceGeneratorType.new()

@onready var _backdrop: Sprite2D = $World/Backdrop
@onready var _road: Sprite2D = $World/Road
@onready var _camera: Camera2D = %Camera
@onready var _hazard_spawner: HazardSpawnerType = %HazardSpawner
@onready var _scroll_root: Node2D = %ScrollRoot
@onready var _scroll_segment_a: Node2D = %ScrollSegmentA
@onready var _scroll_segment_b: Node2D = %ScrollSegmentB
@onready var _wagon: Polygon2D = %Wagon
@onready var _wagon_shadow: AnimatedSprite2D = $World/Wagon/Shadow
@onready var _wagon_sprite: AnimatedSprite2D = $World/Wagon/CarriageSprite
@onready var _horse_left_sprite: AnimatedSprite2D = $World/Wagon/HorseTeam/HorseLeft
@onready var _horse_right_sprite: AnimatedSprite2D = $World/Wagon/HorseTeam/HorseRight
@onready var _dust_trail: CPUParticles2D = %DustTrail
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _distance_bar: ProgressBar = %DistanceBar
@onready var _distance_band_markers: Control = %DistanceBandMarkers
@onready var _cargo_label: Label = %CargoLabel
@onready var _bonus_callout_panel: Control = %BonusCalloutPanel
@onready var _bonus_callout_label: Label = %BonusCalloutLabel
@onready var _phase_callout_panel: PanelContainer = %PhaseCalloutPanel
@onready var _phase_callout_label: Label = %PhaseCalloutLabel
@onready var _touch_layer: CanvasLayer = %TouchLayer
@onready var _touch_left_button: Button = %TouchLeft
@onready var _touch_right_button: Button = %TouchRight
@onready var _touch_pause_button: Button = %TouchPause
@onready var _onboarding_panel: PanelContainer = %OnboardingPanel
@onready var _onboarding_title: Label = %OnboardingTitle
@onready var _onboarding_body: Label = %OnboardingBody
@onready var _onboarding_hint: Label = %OnboardingHint
@onready var _pause_overlay: Control = %PauseOverlay
@onready var _pause_panel: PanelContainer = %PausePanel
@onready var _pause_resume_button: Button = %PauseResumeButton
@onready var _pause_restart_button: Button = %PauseRestartButton
@onready var _pause_return_button: Button = %PauseReturnButton
@onready var _recovery_panel: PanelContainer = %RecoveryPanel
@onready var _recovery_title: Label = %RecoveryTitle
@onready var _recovery_hint: Label = %RecoveryHint
@onready var _recovery_steps: HBoxContainer = %RecoverySteps
@onready var _result_panel: PanelContainer = %ResultPanel
@onready var _result_title: Label = %ResultTitle
@onready var _result_summary: Label = %ResultSummary
@onready var _result_stats: Label = %ResultStats
@onready var _result_restart_button: Button = $ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultRestartButton
@onready var _result_return_button: Button = $ResultLayer/ResultMargin/ResultPanel/ResultPadding/ResultVBox/ResultButtons/ResultReturnButton
@onready var _music_player: AudioStreamPlayer = %MusicPlayer
@onready var _wagon_loop_player: AudioStreamPlayer = %WagonLoopPlayer
@onready var _impact_player: AudioStreamPlayer = %ImpactPlayer
@onready var _pothole_impact_player: AudioStreamPlayer = %PotholeImpactPlayer
@onready var _rock_impact_player: AudioStreamPlayer = %RockImpactPlayer
@onready var _tumbleweed_impact_player: AudioStreamPlayer = %TumbleweedImpactPlayer
@onready var _wheel_loose_ambient_player: AudioStreamPlayer = %WheelLooseAmbientPlayer
@onready var _horse_panic_ambient_player: AudioStreamPlayer = %HorsePanicAmbientPlayer
@onready var _recovery_step_player: AudioStreamPlayer = %RecoveryStepPlayer
@onready var _recovery_success_player: AudioStreamPlayer = %RecoverySuccessPlayer
@onready var _recovery_fail_player: AudioStreamPlayer = %RecoveryFailPlayer
@onready var _pause_toggle_player: AudioStreamPlayer = %PauseTogglePlayer
@onready var _failure_player: AudioStreamPlayer = %FailurePlayer
@onready var _result_player: AudioStreamPlayer = %ResultPlayer
@onready var _ui_click_player: AudioStreamPlayer = %UIClickPlayer


## Binds a fresh run state and resets transient scene-only UI flow.
func setup(run_state: RunStateType) -> void:
	_run_state = run_state
	_run_state.load_persisted_best_run(_best_run_save_path)
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		_run_state.record_best_run_if_needed(_best_run_save_path)
	_run_ui_presenter.bind_run_state(_run_state)
	_run_ui_presenter.reset_for_new_run()
	_bonus_callout_text = ""
	_bonus_callout_remaining = 0.0
	_bonus_callout_anchor_world_position = Vector2.ZERO
	_phase_callout_text = ""
	_phase_callout_remaining = 0.0
	_last_announced_failure = _run_state.active_failure
	_last_announced_result = _run_state.result
	_run_director.bind_run_state(_run_state, _recovery_sequence_generator)
	_run_presentation.bind_run_state(_run_state)
	_refresh_status()
	_refresh_onboarding_prompt()
	_refresh_bonus_callout()
	_refresh_phase_callout()
	_refresh_recovery_prompt()
	_refresh_pause_menu()
	_refresh_result_screen()
	_refresh_touch_controls()
	_refresh_audio_presentation()


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
	_run_ui_presenter.configure_scene_nodes(
		_run_state,
		_health_bar,
		_health_label,
		_distance_bar,
		_distance_band_markers,
		_cargo_label,
		_touch_layer,
		_touch_left_button,
		_touch_right_button,
		_touch_pause_button,
		_onboarding_panel,
		_onboarding_title,
		_onboarding_body,
		_onboarding_hint,
		_pause_overlay,
		_pause_panel,
		_pause_resume_button,
		_pause_restart_button,
		_pause_return_button,
		_recovery_panel,
		_recovery_title,
		_recovery_hint,
		_recovery_steps,
		_result_panel,
		_result_title,
		_result_summary,
		_result_stats,
		_result_restart_button,
		_result_return_button,
		ARROW_FONT
	)
	_configure_environment_art()
	_ensure_scroll_visuals()
	_configure_vehicle_sprites()
	_configure_distance_bar_band_markers()
	_refresh_phase_callout()
	_configure_touch_buttons()
	_configure_dust_trail()
	_configure_audio_players()
	_set_process_mode_recursive(_pause_overlay, Node.PROCESS_MODE_ALWAYS)
	_touch_left_button.button_down.connect(_on_touch_left_button_down)
	_touch_left_button.button_up.connect(_on_touch_left_button_up)
	_touch_right_button.button_down.connect(_on_touch_right_button_down)
	_touch_right_button.button_up.connect(_on_touch_right_button_up)
	_touch_pause_button.pressed.connect(_on_touch_pause_button_pressed)
	_pause_resume_button.pressed.connect(_on_pause_resume_pressed)
	_pause_restart_button.pressed.connect(_on_pause_restart_pressed)
	_pause_return_button.pressed.connect(_on_pause_return_to_title_pressed)
	_result_restart_button.pressed.connect(_on_result_restart_pressed)
	_result_return_button.pressed.connect(_on_result_return_to_title_pressed)
	_configure_pause_menu_navigation()
	_configure_result_menu_navigation()
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_refresh_status()
	_refresh_onboarding_prompt()
	_refresh_bonus_callout()
	_refresh_pause_menu()
	_refresh_recovery_prompt()
	_refresh_result_screen()
	_refresh_touch_controls()
	_refresh_audio_presentation()


## Applies the imported carriage, shadow, and horse art to the existing wagon rig nodes.
func _configure_vehicle_sprites() -> void:
	if _wagon != null:
		_wagon.color = Color(1, 1, 1, 0)
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
	_run_presentation.configure_environment_art(DESERT_TEXTURE, ROAD_TEXTURE)


## Applies the shared input-prompt font styling to the mobile touch buttons.
func _configure_touch_buttons() -> void:
	if _touch_left_button != null:
		_touch_left_button.add_theme_font_override("font", ARROW_FONT)
		_touch_left_button.add_theme_stylebox_override("normal", _make_touch_button_stylebox())
		_touch_left_button.add_theme_stylebox_override("hover", _make_touch_button_stylebox(RECOVERY_STEP_ACTIVE_COLOR))
		_touch_left_button.add_theme_stylebox_override("pressed", _make_touch_button_stylebox(RECOVERY_STEP_DONE_COLOR))
		_touch_left_button.text = char(0xE020)
	if _touch_right_button != null:
		_touch_right_button.add_theme_font_override("font", ARROW_FONT)
		_touch_right_button.add_theme_stylebox_override("normal", _make_touch_button_stylebox())
		_touch_right_button.add_theme_stylebox_override("hover", _make_touch_button_stylebox(RECOVERY_STEP_ACTIVE_COLOR))
		_touch_right_button.add_theme_stylebox_override("pressed", _make_touch_button_stylebox(RECOVERY_STEP_DONE_COLOR))
		_touch_right_button.text = char(0xE022)
	if _touch_pause_button != null:
		_touch_pause_button.text = char(0xE061)
		_touch_pause_button.add_theme_font_override("font", ARROW_FONT)
		_touch_pause_button.add_theme_font_size_override("font_size", 52)
		_touch_pause_button.add_theme_stylebox_override("normal", _make_touch_button_stylebox())
		_touch_pause_button.add_theme_stylebox_override("hover", _make_touch_button_stylebox(RECOVERY_STEP_ACTIVE_COLOR))
		_touch_pause_button.add_theme_stylebox_override("pressed", _make_touch_button_stylebox(RECOVERY_STEP_DONE_COLOR))
		_touch_pause_button.rotation = PI / 2


## Builds a touch-button stylebox that matches the recovery-step chips.
func _make_touch_button_stylebox(background_color: Color = RECOVERY_STEP_PENDING_COLOR) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = background_color
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.745098, 0.592157, 0.305882, 0.95)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	return stylebox


## Rebuilds the distance bar markers from the authored route-band thresholds.
func _configure_distance_bar_band_markers() -> void:
	_run_ui_presenter.configure_distance_bar_band_markers(
		DISTANCE_BAR_BAND_BOUNDARIES,
		DISTANCE_BAR_MARKER_COLOR,
		DISTANCE_BAR_MARKER_HALF_WIDTH
	)


## Stops transient input/audio state when the run scene leaves the tree.
func _exit_tree() -> void:
	_release_touch_steer_actions()
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
		_refresh_bonus_callout()
		_refresh_phase_callout()
		return
	if _run_ui_presenter.pause_menu_open:
		_refresh_onboarding_prompt()
		_refresh_bonus_callout()
		_tick_phase_callout(delta)
		_refresh_phase_callout()
		_refresh_pause_menu()
		_refresh_result_screen()
		_refresh_touch_controls()
		_refresh_audio_presentation()
		return
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		_tick_bonus_callout(delta)
		_tick_phase_callout(delta)
		_update_impact_feedback(delta)
		_update_wagon_visual()
		_update_camera_framing()
		_refresh_status()
		_refresh_onboarding_prompt()
		_refresh_bonus_callout()
		_refresh_phase_callout()
		_refresh_pause_menu()
		_refresh_recovery_prompt()
		_refresh_result_screen()
		_refresh_touch_controls()
		_refresh_audio_presentation()
		return
	if _run_ui_presenter.onboarding_active:
		_tick_bonus_callout(delta)
		_tick_phase_callout(delta)
		_run_presentation.advance_scroll(_run_state.current_speed, delta)
		_update_impact_feedback(delta)
		_update_wagon_visual()
		_update_scroll_visuals()
		_update_camera_framing()
		_refresh_status()
		_refresh_onboarding_prompt()
		_refresh_bonus_callout()
		_refresh_phase_callout()
		_refresh_pause_menu()
		_refresh_recovery_prompt()
		_refresh_result_screen()
		_refresh_touch_controls()
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
			_run_director,
			_wagon.position,
			WAGON_COLLISION_SIZE,
			NEAR_MISS_MAX_HORIZONTAL_CLEARANCE
		)
	)
	_advance_failure_triggers(delta)
	_sync_completed_run_best_state()
	_tick_bonus_callout(delta)
	_tick_phase_callout(delta)
	_update_impact_feedback(delta)
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_refresh_status()
	_refresh_onboarding_prompt()
	_refresh_bonus_callout()
	_refresh_phase_callout()
	_refresh_pause_menu()
	_refresh_recovery_prompt()
	_refresh_result_screen()
	_refresh_touch_controls()
	_refresh_audio_presentation()

## Refreshes the compact run HUD values from the bound run state.
func _refresh_status() -> void:
	_run_ui_presenter.refresh_status()


## Shows a short in-run score callout while a bonus announcement is active.
func _refresh_bonus_callout() -> void:
	if _bonus_callout_panel == null or _bonus_callout_label == null:
		return

	var is_visible := _bonus_callout_remaining > 0.0 and _bonus_callout_text != ""
	_bonus_callout_panel.visible = is_visible
	if not is_visible:
		_bonus_callout_label.text = ""
		_bonus_callout_panel.self_modulate = Color(1, 1, 1, 1)
		return

	_bonus_callout_label.text = _bonus_callout_text
	var progress_ratio: float = 1.0 - (_bonus_callout_remaining / BONUS_CALLOUT_DURATION)
	var canvas_position: Vector2 = get_viewport().get_canvas_transform() * _bonus_callout_anchor_world_position
	var flyout_offset: Vector2 = BONUS_CALLOUT_START_OFFSET.lerp(BONUS_CALLOUT_END_OFFSET, progress_ratio)
	var panel_size: Vector2 = _bonus_callout_panel.size
	_bonus_callout_panel.position = canvas_position + flyout_offset - (panel_size * 0.5)
	_bonus_callout_panel.self_modulate = Color(1, 1, 1, 1.0 - progress_ratio)


## Shows a short route-phase cue while an authored phase transition is active.
func _refresh_phase_callout() -> void:
	if _phase_callout_panel == null or _phase_callout_label == null:
		return

	var is_visible := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and _phase_callout_remaining > 0.0
		and _phase_callout_text != ""
	)
	_phase_callout_panel.visible = is_visible
	if not is_visible:
		_phase_callout_label.text = ""
		_phase_callout_panel.self_modulate = Color(1, 1, 1, 1)
		return

	_phase_callout_label.text = _phase_callout_text
	var progress_ratio: float = 1.0 - (_phase_callout_remaining / PHASE_CALLOUT_DURATION)
	_phase_callout_panel.self_modulate = Color(1, 1, 1, 1.0 - (progress_ratio * 0.25))


## Shows only the active recovery sequence prompt when gameplay allows it.
func _refresh_recovery_prompt() -> void:
	_run_ui_presenter.refresh_recovery_prompt()


## Refreshes onboarding visibility for the active run.
func _refresh_onboarding_prompt() -> void:
	_run_ui_presenter.refresh_onboarding_prompt()


## Configures explicit keyboard focus traversal for the pause menu buttons.
func _configure_pause_menu_navigation() -> void:
	_run_ui_presenter.configure_pause_menu_navigation()


## Configures explicit keyboard focus traversal for the result screen buttons.
func _configure_result_menu_navigation() -> void:
	_run_ui_presenter.configure_result_menu_navigation()


## Refreshes pause-menu visibility for the active run.
func _refresh_pause_menu() -> void:
	_run_ui_presenter.refresh_pause_menu()


## Refreshes the end-of-run result panel contents and visibility.
func _refresh_result_screen() -> void:
	_run_ui_presenter.refresh_result_screen(_build_best_run_summary())


## Persists a newly completed run exactly once when it beats the stored best score.
func _sync_completed_run_best_state() -> void:
	if _run_state == null:
		return
	if _run_state.result == RunStateType.RESULT_IN_PROGRESS:
		return
	if _last_announced_result == _run_state.result:
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


## Shows touch controls only while the run is actively playable on a supported runtime.
func _refresh_touch_controls() -> void:
	var was_visible := false if _touch_layer == null else _touch_layer.visible
	_run_ui_presenter.refresh_touch_controls()
	if was_visible and not _run_ui_presenter.should_show_touch_controls():
		_release_touch_steer_actions()


## Enables touch controls automatically for native mobile and touch-capable mobile web runtimes.
func _refresh_touch_controls_runtime_state() -> void:
	_run_ui_presenter.refresh_touch_controls()


## Returns whether the current runtime is a native Android or iOS build.
func _is_native_mobile_runtime() -> bool:
	return _run_ui_presenter.is_native_mobile_runtime()


## Returns whether the current runtime is a web export hosted on Android or iOS.
func _is_mobile_web_runtime() -> bool:
	return _run_ui_presenter.is_mobile_web_runtime()


## Returns whether the active runtime currently reports touchscreen capability.
func _is_touchscreen_available() -> bool:
	return _run_ui_presenter.is_touchscreen_available()


## Returns whether the touch layer should currently be visible and interactive.
func _should_show_touch_controls() -> bool:
	return _run_ui_presenter.should_show_touch_controls()


## Reveals touch controls after the first real touch on mobile web runtimes with delayed capability reporting.
func _reveal_touch_controls_from_first_touch(event: InputEvent) -> void:
	_run_ui_presenter.reveal_touch_controls_from_first_touch(event)


## Routes pause, onboarding, and recovery input for the run scene.
func _input(event: InputEvent) -> void:
	_reveal_touch_controls_from_first_touch(event)
	if _run_state == null:
		return
	if event != null and event.is_action_pressed(PAUSE_ACTION):
		if _run_state.result == RunStateType.RESULT_IN_PROGRESS:
			_set_pause_state(not _run_ui_presenter.pause_menu_open)
		return
	if _run_ui_presenter.pause_menu_open and event != null and event.is_action_pressed("ui_cancel", false, true):
		_set_pause_state(false)
		return
	if _run_ui_presenter.pause_menu_open:
		if _handle_pause_menu_click(event):
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			return
	if _run_ui_presenter.onboarding_active:
		if _should_dismiss_onboarding(event):
			_run_ui_presenter.onboarding_active = false
			_refresh_onboarding_prompt()
			if _run_director.route_phase_callout_zone == ROUTE_PHASE_WARM_UP:
				_show_phase_callout(_get_route_phase_display_name(_run_director.route_phase_callout_zone))
		return
	if not _run_state.has_active_recovery_sequence():
		return

	var action_name := _extract_recovery_action(event)
	if action_name == &"":
		return

	var recovery_result: RefCounted = _run_director.handle_recovery_action(action_name)
	if recovery_result.was_wrong_input:
		return

	if recovery_result.bonus_callout_text != "":
		_show_bonus_callout(recovery_result.bonus_callout_text)
	if recovery_result.play_step_sound and _recovery_step_player != null:
		_recovery_step_player.play()
	if recovery_result.recovery_completed and _recovery_success_player != null:
		_recovery_success_player.play()

	_refresh_status()
	_refresh_recovery_prompt()


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
		_show_phase_callout(update.phase_callout_text)
	if update.recovery_penalty_applied and _recovery_fail_player != null:
		_recovery_fail_player.play()


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
	match hazard_type:
		&"pothole":
			if _pothole_impact_player != null:
				_pothole_impact_player.play()
				return
		&"rock":
			if _rock_impact_player != null:
				_rock_impact_player.play()
				return
		&"tumbleweed":
			if _tumbleweed_impact_player != null:
				_tumbleweed_impact_serial += 1
				_tumbleweed_impact_player.play()
				_schedule_tumbleweed_impact_stop(_tumbleweed_impact_serial)
				return

	if _impact_player != null:
		_impact_player.play()


## Stops the tumbleweed cue after the same playback window used by the crash impact cue.
func _schedule_tumbleweed_impact_stop(serial: int) -> void:
	var stop_after_seconds := IMPACT_SOUND.get_length()
	if stop_after_seconds <= 0.0:
		return
	var timer := get_tree().create_timer(stop_after_seconds, false)
	timer.timeout.connect(_on_tumbleweed_impact_timeout.bind(serial), CONNECT_ONE_SHOT)


## Stops the active tumbleweed cue only if a newer tumbleweed playback has not replaced it.
func _on_tumbleweed_impact_timeout(serial: int) -> void:
	if _tumbleweed_impact_player == null:
		return
	if serial != _tumbleweed_impact_serial:
		return
	_tumbleweed_impact_player.stop()


## Ensures the looping roadside segments are populated through the presentation owner.
func _ensure_scroll_visuals() -> void:
	_run_presentation.ensure_scroll_visuals()


## Updates the looping world segments and tiled environment scroll windows.
func _update_scroll_visuals() -> void:
	_run_presentation.update_scroll_visuals()


## Applies the authored dust particle configuration through the presentation owner.
func _configure_dust_trail() -> void:
	_run_presentation.configure_dust_trail()


func _configure_audio_players() -> void:
	if _music_player != null:
		_music_player.stream = BACKGROUND_MUSIC
		_music_player.volume_db = -12.0
	if _wagon_loop_player != null:
		_wagon_loop_player.stream = WAGON_LOOP_SOUND
		_wagon_loop_player.volume_db = -8.5
	if _impact_player != null:
		_impact_player.stream = IMPACT_SOUND
		_impact_player.volume_db = -4.5
	if _pothole_impact_player != null:
		_pothole_impact_player.stream = POTHOLE_IMPACT_SOUND
		_pothole_impact_player.volume_db = -5.0
	if _rock_impact_player != null:
		_rock_impact_player.stream = ROCK_IMPACT_SOUND
		_rock_impact_player.volume_db = -4.5
	if _tumbleweed_impact_player != null:
		_tumbleweed_impact_player.stream = TUMBLEWEED_IMPACT_SOUND
		_tumbleweed_impact_player.volume_db = -7.0
	if _wheel_loose_ambient_player != null:
		_wheel_loose_ambient_player.stream = WHEEL_LOOSE_AMBIENT_SOUND
		_wheel_loose_ambient_player.volume_db = -9.0
	if _horse_panic_ambient_player != null:
		_horse_panic_ambient_player.stream = HORSE_PANIC_AMBIENT_SOUND
		_horse_panic_ambient_player.volume_db = -10.0
	if _recovery_step_player != null:
		_recovery_step_player.stream = RECOVERY_STEP_SOUND
		_recovery_step_player.volume_db = -1.5
	if _recovery_success_player != null:
		_recovery_success_player.stream = RECOVERY_SUCCESS_SOUND
		_recovery_success_player.volume_db = -1.0
	if _recovery_fail_player != null:
		_recovery_fail_player.stream = RECOVERY_FAIL_SOUND
		_recovery_fail_player.volume_db = -1.0
	if _pause_toggle_player != null:
		_pause_toggle_player.stream = PAUSE_TOGGLE_SOUND
		_pause_toggle_player.volume_db = -8.0
	if _failure_player != null:
		_failure_player.stream = HORSE_SPOOK_SOUND
		_failure_player.volume_db = -5.0
	if _result_player != null:
		_result_player.volume_db = -6.0
	if _ui_click_player != null:
		_ui_click_player.stream = UI_CLICK_SOUND
		_ui_click_player.volume_db = -9.0


func _refresh_audio_presentation() -> void:
	if _run_state == null:
		return

	_run_presentation.refresh_dust_presentation(RunStateType.DEFAULT_FORWARD_SPEED)

	if _music_player != null:
		if _run_state.result == RunStateType.RESULT_IN_PROGRESS:
			if not _music_player.playing:
				_music_player.play()
		elif _music_player.playing:
			_music_player.stop()

	if _wagon_loop_player != null:
		if _run_state.result == RunStateType.RESULT_IN_PROGRESS:
			if not _wagon_loop_player.playing:
				_wagon_loop_player.play(WAGON_LOOP_START_SECONDS)
			elif _wagon_loop_player.get_playback_position() >= WAGON_LOOP_END_SECONDS:
				_wagon_loop_player.seek(WAGON_LOOP_START_SECONDS)
		elif _wagon_loop_player.playing:
			_wagon_loop_player.stop()

	_refresh_failure_ambient_audio()

	if _run_state.active_failure != _last_announced_failure:
		if _run_state.active_failure != &"" and _failure_player != null:
			_failure_player.play()
		_last_announced_failure = _run_state.active_failure

	if _run_state.result != _last_announced_result:
		match _run_state.result:
			RunStateType.RESULT_SUCCESS:
				if _result_player != null:
					_result_player.stream = WIN_STINGER
					_result_player.play()
			RunStateType.RESULT_COLLAPSED:
				if _result_player != null:
					_result_player.stream = COLLAPSE_STINGER
					_result_player.play()
		_last_announced_result = _run_state.result


## Starts and stops sustained failure ambients according to the active failure and run state.
func _refresh_failure_ambient_audio() -> void:
	if _run_state == null:
		return

	var should_play_wheel_loose := (
		_run_state.result == RunStateType.RESULT_IN_PROGRESS
		and _run_state.active_failure == &"wheel_loose"
	)
	var should_play_horse_panic := (
		_run_state.result == RunStateType.RESULT_IN_PROGRESS
		and _run_state.active_failure == &"horse_panic"
	)

	if _wheel_loose_ambient_player != null:
		if should_play_wheel_loose:
			if not _wheel_loose_ambient_player.playing:
				_wheel_loose_ambient_player.play()
		elif _wheel_loose_ambient_player.playing:
			_wheel_loose_ambient_player.stop()

	if _horse_panic_ambient_player != null:
		if should_play_horse_panic:
			if not _horse_panic_ambient_player.playing:
				_horse_panic_ambient_player.play()
		elif _horse_panic_ambient_player.playing:
			_horse_panic_ambient_player.stop()


func _ensure_input_actions() -> void:
	_register_action(STEER_ACTION_NEGATIVE, [KEY_A, KEY_LEFT])
	_register_action(STEER_ACTION_POSITIVE, [KEY_D, KEY_RIGHT])
	_register_action(PAUSE_ACTION, [KEY_ESCAPE])


func _register_action(action_name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _set_process_mode_recursive(node: Node, mode: ProcessMode) -> void:
	if node == null:
		return

	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)


## Preserves compatibility for legacy scene-state property access now owned by extracted presenters.
func _get(property: StringName) -> Variant:
	match property:
		&"_onboarding_active":
			return _run_ui_presenter.onboarding_active
		&"_pause_menu_open":
			return _run_ui_presenter.pause_menu_open
		&"_touch_controls_enabled_for_runtime":
			return _run_ui_presenter.touch_controls_enabled_for_runtime
		&"_has_native_mobile_runtime_override":
			return _run_ui_presenter.has_native_mobile_runtime_override
		&"_native_mobile_runtime_override":
			return _run_ui_presenter.native_mobile_runtime_override
		&"_has_mobile_web_runtime_override":
			return _run_ui_presenter.has_mobile_web_runtime_override
		&"_mobile_web_runtime_override":
			return _run_ui_presenter.mobile_web_runtime_override
		&"_has_touchscreen_available_override":
			return _run_ui_presenter.has_touchscreen_available_override
		&"_touchscreen_available_override":
			return _run_ui_presenter.touchscreen_available_override
		_:
			return null


## Preserves compatibility for legacy scene-state overrides now owned by extracted presenters.
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"_onboarding_active":
			_run_ui_presenter.onboarding_active = bool(value)
			return true
		&"_pause_menu_open":
			_run_ui_presenter.pause_menu_open = bool(value)
			return true
		&"_touch_controls_enabled_for_runtime":
			_run_ui_presenter.touch_controls_enabled_for_runtime = bool(value)
			return true
		&"_has_native_mobile_runtime_override":
			_run_ui_presenter.has_native_mobile_runtime_override = bool(value)
			return true
		&"_native_mobile_runtime_override":
			_run_ui_presenter.native_mobile_runtime_override = bool(value)
			return true
		&"_has_mobile_web_runtime_override":
			_run_ui_presenter.has_mobile_web_runtime_override = bool(value)
			return true
		&"_mobile_web_runtime_override":
			_run_ui_presenter.mobile_web_runtime_override = bool(value)
			return true
		&"_has_touchscreen_available_override":
			_run_ui_presenter.has_touchscreen_available_override = bool(value)
			return true
		&"_touchscreen_available_override":
			_run_ui_presenter.touchscreen_available_override = bool(value)
			return true
		_:
			return false


## Converts the latest input event into the expected recovery action name.
func _extract_recovery_action(event: InputEvent) -> StringName:
	if event == null:
		return &""
	if event.is_action_pressed(STEER_ACTION_NEGATIVE, false, true):
		return STEER_ACTION_NEGATIVE
	if event.is_action_pressed(STEER_ACTION_POSITIVE, false, true):
		return STEER_ACTION_POSITIVE
	return &""


## Checks whether the current input event should dismiss the onboarding card.
func _should_dismiss_onboarding(event: InputEvent) -> bool:
	return _run_ui_presenter.should_dismiss_onboarding(event)


## Handles direct pause-menu mouse clicks when the modal is open.
func _handle_pause_menu_click(event: InputEvent) -> bool:
	match _run_ui_presenter.get_pause_menu_click_action(event):
		RunUiPresenterType.PAUSE_MENU_ACTION_RESUME:
			_on_pause_resume_pressed()
			return true
		RunUiPresenterType.PAUSE_MENU_ACTION_RESTART:
			_on_pause_restart_pressed()
			return true
		RunUiPresenterType.PAUSE_MENU_ACTION_RETURN_TO_TITLE:
			_on_pause_return_to_title_pressed()
			return true
		_:
			return false


## Injects a synthetic steering action event so touch input shares the keyboard gameplay path.
func _parse_touch_action_event(action_name: StringName, pressed: bool) -> void:
	var action_event := InputEventAction.new()
	action_event.action = action_name
	action_event.pressed = pressed
	Input.parse_input_event(action_event)


## Releases both steering actions to avoid held touch state leaking across scene transitions.
func _release_touch_steer_actions() -> void:
	_parse_touch_action_event(STEER_ACTION_NEGATIVE, false)
	_parse_touch_action_event(STEER_ACTION_POSITIVE, false)


func _get_recovery_title(failure_type: StringName) -> String:
	return _run_ui_presenter.get_recovery_title(failure_type)


func _get_recovery_hint(failure_type: StringName) -> String:
	return _run_ui_presenter.get_recovery_hint(failure_type)


func _apply_recovery_failure_penalty() -> void:
	_run_director.apply_recovery_failure_penalty()
	if _recovery_fail_player != null:
		_recovery_fail_player.play()
	_refresh_status()
	_refresh_recovery_prompt()


## Returns the chip size that keeps the full recovery row inside a fixed width budget.
func _get_recovery_step_minimum_size() -> Vector2:
	return _run_ui_presenter.get_recovery_step_minimum_size()


## Returns the prompt font size that matches the active recovery chip width.
func _get_recovery_step_font_size() -> int:
	return _run_ui_presenter.get_recovery_step_font_size()


## Builds one recovery-step chip using the current compactness rules for the active sequence.
func _build_recovery_step(index: int) -> PanelContainer:
	return _run_ui_presenter.build_recovery_step(index)


func _get_recovery_step_color(index: int) -> Color:
	return _run_ui_presenter.get_recovery_step_color(index)


func _format_recovery_action(action_name: StringName) -> String:
	return _run_ui_presenter.format_recovery_action(action_name)


## Starts or refreshes the short-lived in-run bonus callout text.
func _show_bonus_callout(text: String) -> void:
	_bonus_callout_text = text
	_bonus_callout_remaining = BONUS_CALLOUT_DURATION
	_bonus_callout_anchor_world_position = Vector2.ZERO if _wagon == null else _wagon.global_position
	_refresh_bonus_callout()


## Starts or refreshes the short-lived on-screen phase cue.
func _show_phase_callout(text: String) -> void:
	_phase_callout_text = text
	_phase_callout_remaining = PHASE_CALLOUT_DURATION
	_refresh_phase_callout()


## Counts down the active bonus callout and hides it after the display window expires.
func _tick_bonus_callout(delta: float) -> void:
	if _bonus_callout_remaining <= 0.0:
		return

	_bonus_callout_remaining = max(0.0, _bonus_callout_remaining - max(0.0, delta))
	if _bonus_callout_remaining == 0.0:
		_bonus_callout_text = ""
	_refresh_bonus_callout()


## Counts down the active phase cue and hides it after the display window expires.
func _tick_phase_callout(delta: float) -> void:
	if _phase_callout_remaining <= 0.0:
		return

	_phase_callout_remaining = max(0.0, _phase_callout_remaining - max(0.0, delta))
	if _phase_callout_remaining == 0.0:
		_phase_callout_text = ""
	_refresh_phase_callout()


## Plays the shared menu click cue for pause and result buttons.
func _play_ui_click() -> void:
	if _ui_click_player == null:
		return
	_ui_click_player.play()


## Plays the shared menu click cue and waits long enough for scene transitions to preserve it.
func _play_ui_click_and_wait() -> void:
	if _ui_click_player == null or _ui_click_player.stream == null:
		return
	_ui_click_player.play()
	await get_tree().create_timer(_ui_click_player.stream.get_length(), false).timeout


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
	var was_paused := _run_ui_presenter.pause_menu_open
	if not _run_ui_presenter.set_pause_state(paused):
		return
	if _pause_toggle_player != null:
		_pause_toggle_player.play()
	_refresh_pause_menu()
	if _run_ui_presenter.pause_menu_open and not was_paused:
		_focus_default_pause_button()
	_refresh_recovery_prompt()
	_refresh_touch_controls()


## Gives the pause menu a deterministic starting focus for keyboard-only play.
func _focus_default_pause_button() -> void:
	_run_ui_presenter.focus_default_pause_button()


## Gives the result screen a deterministic starting focus for keyboard-only play.
func _focus_default_result_button() -> void:
	_run_ui_presenter.focus_default_result_button()


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


## Presses the left steering action while the mobile left button is held.
func _on_touch_left_button_down() -> void:
	if not _should_show_touch_controls():
		return
	_parse_touch_action_event(STEER_ACTION_NEGATIVE, true)


## Releases the left steering action when the mobile left button is released.
func _on_touch_left_button_up() -> void:
	if not _run_ui_presenter.touch_controls_enabled_for_runtime:
		return
	_parse_touch_action_event(STEER_ACTION_NEGATIVE, false)


## Presses the right steering action while the mobile right button is held.
func _on_touch_right_button_down() -> void:
	if not _should_show_touch_controls():
		return
	_parse_touch_action_event(STEER_ACTION_POSITIVE, true)


## Releases the right steering action when the mobile right button is released.
func _on_touch_right_button_up() -> void:
	if not _run_ui_presenter.touch_controls_enabled_for_runtime:
		return
	_parse_touch_action_event(STEER_ACTION_POSITIVE, false)


## Opens the pause menu from the mobile pause button when gameplay is active.
func _on_touch_pause_button_pressed() -> void:
	if not _should_show_touch_controls():
		return
	_set_pause_state(true)

