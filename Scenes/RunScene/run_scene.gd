extends Node2D

signal restart_requested
signal return_to_title_requested

const HazardSpawnerType := preload("res://Scripts/Hazards/hazard_spawner.gd")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")
const BACKGROUND_MUSIC := preload("res://Assets/Audio/We Ride At Dawn! (loop).ogg")
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
const STEER_SPEED := 300.0
const ROAD_HALF_WIDTH := 180.0
const WAGON_BASE_Y := 0.0
const WAGON_BASE_COLOR := Color(0.301961, 0.180392, 0.101961, 1.0)
const WAGON_HIT_COLOR := Color(0.760784, 0.447059, 0.239216, 1.0)
const CAMERA_VERTICAL_OFFSET := 260.0
const IMPACT_FLASH_DURATION := 0.18
const IMPACT_WOBBLE_DURATION := 0.32
const IMPACT_SHAKE_DURATION := 0.28
const IMPACT_WOBBLE_DEGREES := 9.0
const IMPACT_WOBBLE_FREQUENCY := 22.0
const IMPACT_SHAKE_AMPLITUDE := 10.0
const WHEEL_LOOSE_STEER_MULTIPLIER := 0.6
const WHEEL_LOOSE_DRIFT_SPEED := 32.0
const WHEEL_LOOSE_DRIFT_FREQUENCY := 8.0
const WHEEL_LOOSE_WOBBLE_DEGREES := 14.0
const WHEEL_LOOSE_WOBBLE_FREQUENCY := 15.0
const HORSE_PANIC_STEER_MULTIPLIER := 0.3
const HORSE_PANIC_DRIFT_SPEED := 150.0
const HORSE_PANIC_DRIFT_FREQUENCY := 5.0
const HORSE_PANIC_WOBBLE_DEGREES := 8.0
const HORSE_PANIC_WOBBLE_FREQUENCY := 10.0
const BAD_LUCK_INTERVAL_EARLY := 13.0
const BAD_LUCK_INTERVAL_LATE := 8.0
const WHEEL_LOOSE_RECOVERY_SEQUENCE: Array[StringName] = [
	&"steer_left",
	&"steer_right",
	&"steer_left",
]
const HORSE_PANIC_RECOVERY_SEQUENCE: Array[StringName] = [
	&"steer_left",
	&"steer_right",
	&"steer_left",
	&"steer_right",
]
const WHEEL_LOOSE_RECOVERY_DURATION := 3.1
const HORSE_PANIC_RECOVERY_DURATION := 3.7
const POST_FAILURE_STEER_MULTIPLIER := 0.75
const POST_FAILURE_DRIFT_SPEED := 55.0
const POST_FAILURE_DRIFT_FREQUENCY := 6.0
const WHEEL_LOOSE_FAILURE_HEALTH_LOSS := 10
const WHEEL_LOOSE_FAILURE_CARGO_LOSS := 6
const WHEEL_LOOSE_FAILURE_SPEED_LOSS := 55.0
const WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION := 1.9
const HORSE_PANIC_FAILURE_CARGO_LOSS := 14
const HORSE_PANIC_FAILURE_SPEED_LOSS := 65.0
const HORSE_PANIC_FAILURE_INSTABILITY_DURATION := 2.2
const SCROLL_LOOP_HEIGHT := 2880.0
const CENTER_DASH_SPACING := 240.0
const CENTER_DASH_SIZE := Vector2(14.0, 140.0)
const CENTER_DASH_COUNT := 13
const ROADSIDE_DECOR_SPACING := 320.0
const ROADSIDE_DECOR_COUNT := 10
const WAGON_COLLISION_SIZE := Vector2(72.0, 112.0)
const RECOVERY_STEP_PENDING_COLOR := Color(0.25098, 0.203922, 0.145098, 0.92)
const RECOVERY_STEP_ACTIVE_COLOR := Color(0.780392, 0.623529, 0.317647, 0.98)
const RECOVERY_STEP_DONE_COLOR := Color(0.419608, 0.54902, 0.290196, 0.95)
const DASH_COLOR := Color(0.886275, 0.811765, 0.572549, 0.8)
const SCRUB_COLOR := Color(0.47451, 0.443137, 0.219608, 0.95)
const SIGN_WOOD_COLOR := Color(0.415686, 0.266667, 0.121569, 1.0)
const SIGN_TEXT_COLOR := Color(0.956863, 0.913725, 0.760784, 1.0)
const DUST_BASE_AMOUNT_RATIO := 0.35
const ONBOARDING_TITLE := "Last Delivery to Dust Gulch"
const ONBOARDING_BODY := (
	"Steer with A/D or Left/Right. Dodge the hazards, protect your cargo, "
	+ "and hold the wagon together until you reach Dust Gulch."
)
const ONBOARDING_HINT := "Press Left, Right, Enter, or click to begin the run."
const WAGON_LOOP_START_SECONDS := 5.0
const WAGON_LOOP_END_SECONDS := 10.0

var _run_state: RunStateType
var _scroll_offset := 0.0
var _impact_flash_remaining := 0.0
var _impact_wobble_remaining := 0.0
var _impact_shake_remaining := 0.0
var _impact_time := 0.0
var _bad_luck_elapsed := 0.0
var _last_announced_failure: StringName = &""
var _last_announced_result: StringName = RunStateType.RESULT_IN_PROGRESS
var _navigation_click_in_progress := false
var _tumbleweed_impact_serial := 0
var _pause_menu_open := false
var _onboarding_active := false

@onready var _camera: Camera2D = %Camera
@onready var _hazard_spawner: HazardSpawnerType = %HazardSpawner
@onready var _scroll_root: Node2D = %ScrollRoot
@onready var _scroll_segment_a: Node2D = %ScrollSegmentA
@onready var _scroll_segment_b: Node2D = %ScrollSegmentB
@onready var _wagon: Polygon2D = %Wagon
@onready var _dust_trail: CPUParticles2D = %DustTrail
@onready var _health_label: Label = %HealthLabel
@onready var _cargo_label: Label = %CargoLabel
@onready var _speed_label: Label = %SpeedLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
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
	_onboarding_active = true
	_pause_menu_open = false
	_bad_luck_elapsed = 0.0
	_last_announced_failure = _run_state.active_failure
	_last_announced_result = _run_state.result
	_refresh_status()
	_refresh_onboarding_prompt()
	_refresh_recovery_prompt()
	_refresh_pause_menu()
	_refresh_result_screen()
	_refresh_touch_controls()
	_refresh_audio_presentation()


## Wires scene-local input, UI, visuals, and audio dependencies.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	_ensure_scroll_visuals()
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
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_refresh_status()
	_refresh_onboarding_prompt()
	_refresh_pause_menu()
	_refresh_recovery_prompt()
	_refresh_result_screen()
	_refresh_touch_controls()
	_refresh_audio_presentation()


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
		return
	if _pause_menu_open:
		_refresh_onboarding_prompt()
		_refresh_pause_menu()
		_refresh_result_screen()
		_refresh_touch_controls()
		_refresh_audio_presentation()
		return
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		_update_impact_feedback(delta)
		_update_wagon_visual()
		_update_camera_framing()
		_refresh_status()
		_refresh_onboarding_prompt()
		_refresh_pause_menu()
		_refresh_recovery_prompt()
		_refresh_result_screen()
		_refresh_touch_controls()
		_refresh_audio_presentation()
		return
	if _onboarding_active:
		_scroll_offset = fposmod(_scroll_offset + _run_state.current_speed * delta, SCROLL_LOOP_HEIGHT)
		_update_impact_feedback(delta)
		_update_wagon_visual()
		_update_scroll_visuals()
		_update_camera_framing()
		_refresh_status()
		_refresh_onboarding_prompt()
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
			lateral_drift = sin(_impact_time * WHEEL_LOOSE_DRIFT_FREQUENCY) * WHEEL_LOOSE_DRIFT_SPEED
		&"horse_panic":
			steer_multiplier = HORSE_PANIC_STEER_MULTIPLIER
			lateral_drift = sin(_impact_time * HORSE_PANIC_DRIFT_FREQUENCY) * HORSE_PANIC_DRIFT_SPEED
		_:
			if _run_state.has_temporary_control_instability():
				steer_multiplier = POST_FAILURE_STEER_MULTIPLIER
				lateral_drift = sin(_impact_time * POST_FAILURE_DRIFT_FREQUENCY) * POST_FAILURE_DRIFT_SPEED

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
	_scroll_offset = fposmod(_scroll_offset + _run_state.current_speed * delta, SCROLL_LOOP_HEIGHT)
	_hazard_spawner.advance(_run_state.current_speed * delta, _run_state.get_delivery_progress_ratio())
	_apply_hazard_collisions()
	_advance_failure_triggers(delta)
	_check_for_loss()
	_check_for_success()
	_update_impact_feedback(delta)
	_update_wagon_visual()
	_update_scroll_visuals()
	_update_camera_framing()
	_refresh_status()
	_refresh_onboarding_prompt()
	_refresh_pause_menu()
	_refresh_recovery_prompt()
	_refresh_result_screen()
	_refresh_touch_controls()
	_refresh_audio_presentation()


func _refresh_status() -> void:
	if _health_label == null or _cargo_label == null or _speed_label == null or _progress_label == null or _progress_bar == null:
		return

	if _run_state == null:
		_health_label.text = "Health: --"
		_cargo_label.text = "Cargo: --"
		_speed_label.text = "Speed: --"
		_progress_label.text = "Distance: --"
		_progress_bar.value = 0.0
		return

	_health_label.text = "Health: %d" % _run_state.wagon_health
	_cargo_label.text = "Cargo: %d" % _run_state.cargo_value
	_speed_label.text = "Speed: %.0f" % _run_state.current_speed
	_progress_label.text = "Distance: %.0f / %.0f" % [
		_run_state.distance_remaining,
		_run_state.route_distance,
	]
	_progress_bar.value = _run_state.get_delivery_progress_ratio() * 100.0


## Shows only the active recovery sequence prompt when gameplay allows it.
func _refresh_recovery_prompt() -> void:
	if _recovery_panel == null or _recovery_steps == null or _recovery_title == null or _recovery_hint == null:
		return
	if _run_state == null:
		_recovery_panel.visible = false
		return

	var has_recovery := (
		_run_state.result == RunStateType.RESULT_IN_PROGRESS
		and not _pause_menu_open
		and _run_state.has_active_recovery_sequence()
	)
	_recovery_panel.visible = has_recovery
	if not has_recovery:
		for child in _recovery_steps.get_children():
			child.queue_free()
		return

	for child in _recovery_steps.get_children():
		child.queue_free()

	_recovery_title.text = _get_recovery_title(_run_state.active_failure)
	_recovery_hint.text = _get_recovery_hint(_run_state.active_failure)

	for i in range(_run_state.recovery_sequence.size()):
		_recovery_steps.add_child(_build_recovery_step(i))


## Refreshes pause-menu visibility for the active run.
func _refresh_onboarding_prompt() -> void:
	if _onboarding_panel == null or _onboarding_title == null or _onboarding_body == null or _onboarding_hint == null:
		return

	var is_visible := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and _onboarding_active
		and not _pause_menu_open
	)
	_onboarding_panel.visible = is_visible
	if not is_visible:
		return

	_onboarding_title.text = ONBOARDING_TITLE
	_onboarding_body.text = ONBOARDING_BODY
	_onboarding_hint.text = ONBOARDING_HINT


## Refreshes pause-menu visibility for the active run.
func _refresh_pause_menu() -> void:
	if _pause_overlay == null or _pause_panel == null:
		return
	var is_visible := _run_state != null and _run_state.result == RunStateType.RESULT_IN_PROGRESS and _pause_menu_open
	_pause_overlay.visible = is_visible
	_pause_panel.visible = is_visible


## Refreshes the end-of-run result panel contents and visibility.
func _refresh_result_screen() -> void:
	if _result_panel == null or _result_title == null or _result_summary == null or _result_stats == null:
		return
	if _run_state == null or _run_state.result == RunStateType.RESULT_IN_PROGRESS:
		_result_panel.visible = false
		return

	_result_panel.visible = true
	match _run_state.result:
		RunStateType.RESULT_SUCCESS:
			_result_title.text = "Delivered to Dust Gulch"
			_result_summary.text = "You made it in one piece. Restart the route or return to title."
		RunStateType.RESULT_COLLAPSED:
			_result_title.text = "Wagon Collapsed"
			_result_summary.text = "The delivery failed. Restart the route or return to title."
		_:
			_result_title.text = "Run Complete"
			_result_summary.text = "Restart the route or return to title."

	_result_stats.text = "Health: %d\nCargo: %d\nDistance traveled: %.0f / %.0f" % [
		_run_state.wagon_health,
		_run_state.cargo_value,
		_run_state.get_distance_traveled(),
		_run_state.route_distance,
	]


## Shows touch controls only while the run is actively playable.
func _refresh_touch_controls() -> void:
	if _touch_layer == null:
		return

	var is_visible := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and not _pause_menu_open
	)
	_touch_layer.visible = is_visible


func _update_wagon_visual() -> void:
	if _wagon == null or _run_state == null:
		return

	_wagon.position = Vector2(_run_state.lateral_position, WAGON_BASE_Y)


func _update_camera_framing() -> void:
	if _camera == null or _wagon == null:
		return

	var camera_position := Vector2(0.0, _wagon.position.y - CAMERA_VERTICAL_OFFSET)
	if _impact_shake_remaining > 0.0:
		var shake_strength := _impact_shake_remaining / IMPACT_SHAKE_DURATION
		camera_position += Vector2(
			cos(_impact_time * 31.0),
			sin(_impact_time * 43.0)
		) * IMPACT_SHAKE_AMPLITUDE * shake_strength

	_camera.position = camera_position


func _apply_hazard_collisions() -> void:
	if _hazard_spawner == null or _run_state == null:
		return

	var collisions := _hazard_spawner.collect_collisions(_wagon.position, WAGON_COLLISION_SIZE)
	for collision in collisions:
		_run_state.wagon_health = max(0, _run_state.wagon_health - collision["damage"])
		_run_state.cargo_value = max(0, _run_state.cargo_value - collision.get("cargo_damage", 0))
		_run_state.last_hit_hazard = collision["type"]
		_attempt_failure_trigger_from_collision(collision["type"])
		_trigger_impact_feedback()
		_play_hazard_impact(collision["type"])
		(collision["node"] as Node).queue_free()


func _advance_failure_triggers(delta: float) -> void:
	if _run_state == null:
		return

	_run_state.tick_failure(delta)
	_run_state.tick_temporary_control_instability(delta)
	_run_state.tick_recovery_transients(delta)
	var had_active_recovery_sequence := _run_state.has_active_recovery_sequence()
	_sync_recovery_sequence()
	if had_active_recovery_sequence and _run_state.tick_recovery_sequence(delta):
		_apply_recovery_failure_penalty()
		return
	if _run_state.has_active_failure():
		return

	_bad_luck_elapsed += delta
	if _bad_luck_elapsed < _get_bad_luck_interval():
		return

	_bad_luck_elapsed = 0.0
	_run_state.start_failure(&"horse_panic", &"bad_luck")


func _attempt_failure_trigger_from_collision(hazard_type: StringName) -> void:
	if _run_state == null:
		return
	if _run_state.has_active_failure():
		return

	match hazard_type:
		&"rock", &"pothole":
			if _run_state.start_failure(&"wheel_loose", hazard_type):
				_bad_luck_elapsed = 0.0
		&"tumbleweed":
			if _run_state.start_failure(&"horse_panic", hazard_type):
				_bad_luck_elapsed = 0.0


func _get_bad_luck_interval() -> float:
	if _run_state == null:
		return BAD_LUCK_INTERVAL_EARLY

	return lerp(
		BAD_LUCK_INTERVAL_EARLY,
		BAD_LUCK_INTERVAL_LATE,
		_run_state.get_delivery_progress_ratio()
	)


func _check_for_success() -> void:
	if _run_state == null:
		return
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	if _run_state.distance_remaining > 0.0:
		return

	_run_state.distance_remaining = 0.0
	_run_state.result = RunStateType.RESULT_SUCCESS
	_run_state.current_speed = 0.0


func _check_for_loss() -> void:
	if _run_state == null:
		return
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		return
	if _run_state.wagon_health > 0:
		return

	_run_state.wagon_health = 0
	_run_state.result = RunStateType.RESULT_COLLAPSED
	_run_state.current_speed = 0.0


func _sync_recovery_sequence() -> void:
	if _run_state == null:
		return

	if _run_state.active_failure == &"wheel_loose":
		if not _run_state.has_active_recovery_sequence():
			_run_state.start_recovery_sequence(WHEEL_LOOSE_RECOVERY_SEQUENCE, WHEEL_LOOSE_RECOVERY_DURATION)
		return
	if _run_state.active_failure == &"horse_panic":
		if not _run_state.has_active_recovery_sequence():
			_run_state.start_recovery_sequence(HORSE_PANIC_RECOVERY_SEQUENCE, HORSE_PANIC_RECOVERY_DURATION)
		return

	if _run_state.has_active_recovery_sequence():
		_run_state.clear_recovery_sequence()


## Routes pause, onboarding, and recovery input for the run scene.
func _input(event: InputEvent) -> void:
	if _run_state == null:
		return
	if event != null and event.is_action_pressed(PAUSE_ACTION):
		if _run_state.result == RunStateType.RESULT_IN_PROGRESS:
			_set_pause_state(not _pause_menu_open)
		return
	if _pause_menu_open:
		if _handle_pause_menu_click(event):
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			return
	if _onboarding_active:
		if _should_dismiss_onboarding(event):
			_onboarding_active = false
			_refresh_onboarding_prompt()
		return
	if not _run_state.has_active_recovery_sequence():
		return

	var action_name := _extract_recovery_action(event)
	if action_name == &"":
		return

	var expected_action := _run_state.get_current_recovery_prompt()
	if _run_state.advance_recovery_sequence(action_name):
		if _recovery_step_player != null:
			_recovery_step_player.play()
		_run_state.resolve_recovery_success()
		if _recovery_success_player != null:
			_recovery_success_player.play()
	elif action_name == expected_action:
		if _recovery_step_player != null:
			_recovery_step_player.play()

	_refresh_status()
	_refresh_recovery_prompt()


func _update_impact_feedback(delta: float) -> void:
	if _wagon == null:
		return

	_impact_time += delta
	_impact_flash_remaining = max(0.0, _impact_flash_remaining - delta)
	_impact_wobble_remaining = max(0.0, _impact_wobble_remaining - delta)
	_impact_shake_remaining = max(0.0, _impact_shake_remaining - delta)

	_wagon.color = WAGON_HIT_COLOR if _impact_flash_remaining > 0.0 else WAGON_BASE_COLOR
	if _run_state != null and _run_state.active_failure == &"wheel_loose":
		_wagon.rotation = sin(_impact_time * WHEEL_LOOSE_WOBBLE_FREQUENCY) * deg_to_rad(WHEEL_LOOSE_WOBBLE_DEGREES)
	elif _run_state != null and _run_state.active_failure == &"horse_panic":
		_wagon.rotation = sin(_impact_time * HORSE_PANIC_WOBBLE_FREQUENCY) * deg_to_rad(HORSE_PANIC_WOBBLE_DEGREES)
	elif _impact_wobble_remaining > 0.0:
		var wobble_strength := _impact_wobble_remaining / IMPACT_WOBBLE_DURATION
		_wagon.rotation = sin(_impact_time * IMPACT_WOBBLE_FREQUENCY) * deg_to_rad(IMPACT_WOBBLE_DEGREES) * wobble_strength
	else:
		_wagon.rotation = 0.0


func _trigger_impact_feedback() -> void:
	_impact_flash_remaining = IMPACT_FLASH_DURATION
	_impact_wobble_remaining = IMPACT_WOBBLE_DURATION
	_impact_shake_remaining = IMPACT_SHAKE_DURATION
	_impact_time = 0.0


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


func _ensure_scroll_visuals() -> void:
	if _scroll_root == null:
		return

	if _scroll_segment_a.get_child_count() == 0:
		_populate_scroll_segment(_scroll_segment_a)

	if _scroll_segment_b.get_child_count() == 0:
		_populate_scroll_segment(_scroll_segment_b)


func _update_scroll_visuals() -> void:
	if _scroll_root == null or _scroll_segment_a == null or _scroll_segment_b == null:
		return

	_scroll_segment_a.position.y = _scroll_offset
	_scroll_segment_b.position.y = _scroll_offset - SCROLL_LOOP_HEIGHT


func _populate_scroll_segment(segment: Node2D) -> void:
	for i in range(CENTER_DASH_COUNT):
		var dash := Polygon2D.new()
		dash.polygon = PackedVector2Array([
			Vector2(-CENTER_DASH_SIZE.x * 0.5, -CENTER_DASH_SIZE.y * 0.5),
			Vector2(CENTER_DASH_SIZE.x * 0.5, -CENTER_DASH_SIZE.y * 0.5),
			Vector2(CENTER_DASH_SIZE.x * 0.5, CENTER_DASH_SIZE.y * 0.5),
			Vector2(-CENTER_DASH_SIZE.x * 0.5, CENTER_DASH_SIZE.y * 0.5),
		])
		dash.position = Vector2(0.0, -SCROLL_LOOP_HEIGHT + (i * CENTER_DASH_SPACING))
		dash.color = DASH_COLOR
		segment.add_child(dash)

	for i in range(ROADSIDE_DECOR_COUNT):
		var left_scrub := _make_scrub_cluster()
		left_scrub.position = Vector2(-300.0, -SCROLL_LOOP_HEIGHT + (i * ROADSIDE_DECOR_SPACING))
		segment.add_child(left_scrub)

		var right_scrub := _make_scrub_cluster()
		right_scrub.position = Vector2(300.0, -SCROLL_LOOP_HEIGHT + (i * ROADSIDE_DECOR_SPACING) + 120.0)
		right_scrub.scale.x = -1.0
		segment.add_child(right_scrub)

	var sign := _make_road_sign("Dust Gulch")
	sign.position = Vector2(-430.0, -SCROLL_LOOP_HEIGHT + 520.0)
	segment.add_child(sign)


func _make_scrub_cluster() -> Polygon2D:
	var scrub := Polygon2D.new()
	scrub.polygon = PackedVector2Array([
		Vector2(-26.0, 20.0),
		Vector2(-8.0, -12.0),
		Vector2(0.0, 6.0),
		Vector2(10.0, -18.0),
		Vector2(28.0, 18.0),
		Vector2(4.0, 28.0),
	])
	scrub.color = SCRUB_COLOR
	return scrub


func _make_road_sign(sign_text: String) -> Node2D:
	var sign_root := Node2D.new()
	sign_root.name = "RoadsideSign"

	var post := Polygon2D.new()
	post.polygon = PackedVector2Array([
		Vector2(-6.0, -8.0),
		Vector2(6.0, -8.0),
		Vector2(6.0, 74.0),
		Vector2(-6.0, 74.0),
	])
	post.color = SIGN_WOOD_COLOR
	sign_root.add_child(post)

	var board := Polygon2D.new()
	board.position = Vector2(0.0, -18.0)
	board.polygon = PackedVector2Array([
		Vector2(-68.0, -24.0),
		Vector2(68.0, -24.0),
		Vector2(68.0, 24.0),
		Vector2(-68.0, 24.0),
	])
	board.color = SIGN_WOOD_COLOR.darkened(0.08)
	sign_root.add_child(board)

	var label := Label.new()
	label.text = sign_text
	label.position = Vector2(-60.0, -34.0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", SIGN_TEXT_COLOR)
	sign_root.add_child(label)
	return sign_root


func _configure_dust_trail() -> void:
	if _dust_trail == null:
		return

	_dust_trail.emitting = true
	_dust_trail.amount = 24
	_dust_trail.lifetime = 0.85
	_dust_trail.preprocess = 0.2
	_dust_trail.local_coords = false
	_dust_trail.direction = Vector2(0.0, 1.0)
	_dust_trail.spread = 36.0
	_dust_trail.initial_velocity_min = 40.0
	_dust_trail.initial_velocity_max = 78.0
	_dust_trail.gravity = Vector2(0.0, 120.0)
	_dust_trail.scale_amount_min = 2.2
	_dust_trail.scale_amount_max = 4.8
	_dust_trail.color = Color(0.839216, 0.72549, 0.513725, 0.62)
	_dust_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust_trail.emission_rect_extents = Vector2(28.0, 10.0)


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

	var should_emit_dust := _run_state.result == RunStateType.RESULT_IN_PROGRESS and _run_state.current_speed > 0.0
	if _dust_trail != null:
		_dust_trail.emitting = should_emit_dust
		_dust_trail.speed_scale = max(
			DUST_BASE_AMOUNT_RATIO,
			_run_state.current_speed / RunStateType.DEFAULT_FORWARD_SPEED
		)

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
	if event == null:
		return false
	if event.is_action_pressed(STEER_ACTION_NEGATIVE, false, true):
		return true
	if event.is_action_pressed(STEER_ACTION_POSITIVE, false, true):
		return true
	if event.is_action_pressed("ui_accept", false, true):
		return true

	var mouse_event := event as InputEventMouseButton
	return mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed


## Handles direct pause-menu mouse clicks when the modal is open.
func _handle_pause_menu_click(event: InputEvent) -> bool:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return false
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return false

	var click_position := mouse_event.position
	if _pause_resume_button != null and _pause_resume_button.get_global_rect().has_point(click_position):
		_on_pause_resume_pressed()
		return true
	if _pause_restart_button != null and _pause_restart_button.get_global_rect().has_point(click_position):
		_on_pause_restart_pressed()
		return true
	if _pause_return_button != null and _pause_return_button.get_global_rect().has_point(click_position):
		_on_pause_return_to_title_pressed()
		return true
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
	match failure_type:
		&"wheel_loose":
			return "Wheel Loose: Secure the Wagon"
		&"horse_panic":
			return "Horse Panic: Calm the Team"
		_:
			return "Recovery"


func _get_recovery_hint(failure_type: StringName) -> String:
	match failure_type:
		&"wheel_loose":
			return "Steering is compromised. Match the sequence to lock the wheel."
		&"horse_panic":
			return "The wagon is swerving. Complete the full left-right pattern."
		_:
			return "Follow the prompts left to right."


func _apply_recovery_failure_penalty() -> void:
	if _run_state == null:
		return

	if _recovery_fail_player != null:
		_recovery_fail_player.play()

	match _run_state.active_failure:
		&"wheel_loose":
			_run_state.apply_recovery_failure_penalty(
				WHEEL_LOOSE_FAILURE_HEALTH_LOSS,
				WHEEL_LOOSE_FAILURE_CARGO_LOSS,
				WHEEL_LOOSE_FAILURE_SPEED_LOSS,
				WHEEL_LOOSE_FAILURE_INSTABILITY_DURATION
			)
		&"horse_panic":
			_run_state.apply_recovery_failure_penalty(
				0,
				HORSE_PANIC_FAILURE_CARGO_LOSS,
				HORSE_PANIC_FAILURE_SPEED_LOSS,
				HORSE_PANIC_FAILURE_INSTABILITY_DURATION
			)

	_refresh_status()
	_refresh_recovery_prompt()


func _build_recovery_step(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120.0, 88.0)
	panel.modulate = _get_recovery_step_color(index)

	var label := Label.new()
	label.text = _format_recovery_action(_run_state.recovery_sequence[index])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_font_override("font", ARROW_FONT)
	panel.add_child(label)
	return panel


func _get_recovery_step_color(index: int) -> Color:
	if index < _run_state.recovery_prompt_index:
		return RECOVERY_STEP_DONE_COLOR
	if index == _run_state.recovery_prompt_index:
		return RECOVERY_STEP_ACTIVE_COLOR
	return RECOVERY_STEP_PENDING_COLOR


func _format_recovery_action(action_name: StringName) -> String:
	match action_name:
		&"steer_left":
			return char(0xE020)
		&"steer_right":
			return char(0xE022)
		_:
			return String(action_name).to_upper()


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


func _set_pause_state(paused: bool) -> void:
	if _run_state == null:
		return
	var was_paused := _pause_menu_open
	if _run_state.result != RunStateType.RESULT_IN_PROGRESS:
		paused = false

	_pause_menu_open = paused
	if was_paused != _pause_menu_open and _pause_toggle_player != null:
		_pause_toggle_player.play()
	_refresh_pause_menu()
	_refresh_recovery_prompt()


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
	_parse_touch_action_event(STEER_ACTION_NEGATIVE, true)


## Releases the left steering action when the mobile left button is released.
func _on_touch_left_button_up() -> void:
	_parse_touch_action_event(STEER_ACTION_NEGATIVE, false)


## Presses the right steering action while the mobile right button is held.
func _on_touch_right_button_down() -> void:
	_parse_touch_action_event(STEER_ACTION_POSITIVE, true)


## Releases the right steering action when the mobile right button is released.
func _on_touch_right_button_up() -> void:
	_parse_touch_action_event(STEER_ACTION_POSITIVE, false)


## Opens the pause menu from the mobile pause button when gameplay is active.
func _on_touch_pause_button_pressed() -> void:
	_set_pause_state(true)
