extends GutTest

# Constants
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


const TITLE_SCREEN_SCENE := preload(ProjectPaths.TITLE_SCREEN_SCENE_PATH)


# Private Fields

var _default_best_run_backup: PackedByteArray = PackedByteArray()
var _had_default_best_run_backup := false


# Public Methods



## Runs before each.
func before_each() -> void:
	_backup_default_best_run_file()
	_delete_default_best_run_file()


## Runs after each.
func after_each() -> void:
	_restore_default_best_run_file()


# Private Methods



## Sends a single keyboard press and release through the input pipeline for focus tests.
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


## Saves any existing default best-run file so title-screen tests can restore it after isolation cleanup.
func _backup_default_best_run_file() -> void:
	_default_best_run_backup = PackedByteArray()
	_had_default_best_run_backup = false
	if not FileAccess.file_exists(RunStateType.BEST_RUN_SAVE_PATH):
		return

	var file := FileAccess.open(RunStateType.BEST_RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	_default_best_run_backup = file.get_buffer(file.get_length())
	_had_default_best_run_backup = true


## Restores the caller's default best-run file after each title-screen test run.
func _restore_default_best_run_file() -> void:
	_delete_default_best_run_file()
	if not _had_default_best_run_backup:
		return

	var file := FileAccess.open(RunStateType.BEST_RUN_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_buffer(_default_best_run_backup)
	_default_best_run_backup = PackedByteArray()
	_had_default_best_run_backup = false


## Deletes the default best-run file so title-screen tests can drive real _ready() summary loading deterministically.
func _delete_default_best_run_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(RunStateType.BEST_RUN_SAVE_PATH)
	if FileAccess.file_exists(RunStateType.BEST_RUN_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)


# Public Methods



## Verifies play button emits play requested.

func test_play_button_emits_play_requested() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	watch_signals(title_screen)
	await title_screen._on_play_pressed()

	assert_signal_emitted(title_screen, "play_requested")


## Verifies quit button emits quit requested.

func test_quit_button_emits_quit_requested() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	watch_signals(title_screen)
	await title_screen._on_quit_pressed()

	assert_signal_emitted(title_screen, "quit_requested")


## Verifies title screen uses western panel style.

func test_title_screen_uses_western_panel_style() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var panel: PanelContainer = title_screen.get_node("Panel")
	var stylebox := panel.get_theme_stylebox("panel")

	assert_not_null(stylebox)
	assert_eq(stylebox.bg_color, Color(0.156863, 0.101961, 0.0666667, 0.94))


## Verifies title screen background uses cover stretch mode.

func test_title_screen_background_uses_cover_stretch_mode() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var background: TextureRect = title_screen.get_node("%Background")

	assert_not_null(background.texture)
	assert_eq(background.expand_mode, TextureRect.EXPAND_IGNORE_SIZE)
	assert_eq(background.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert_eq(background.anchor_right, 1.0)
	assert_eq(background.anchor_bottom, 1.0)


## Verifies title screen play and quit buttons play ui click sound.

func test_title_screen_play_and_quit_buttons_play_ui_click_sound() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var play_button: Button = title_screen.get_node("Panel/Margin/Content/Buttons/PlayButton")
	var quit_button: Button = title_screen.get_node("Panel/Margin/Content/Buttons/QuitButton")
	var ui_click_player: AudioStreamPlayer = title_screen.get_node("UIClickPlayer")
	play_button.pressed.emit()
	assert_true(ui_click_player.playing)
	assert_eq(ui_click_player.stream, title_screen.UI_CLICK_SOUND)
	await get_tree().create_timer(ui_click_player.stream.get_length(), false).timeout

	ui_click_player.stop()
	quit_button.pressed.emit()
	assert_true(ui_click_player.playing)
	assert_eq(ui_click_player.stream, title_screen.UI_CLICK_SOUND)
	await get_tree().create_timer(ui_click_player.stream.get_length(), false).timeout


## Verifies the title screen lands keyboard focus on the primary action as soon as it opens.

func test_title_screen_when_ready_then_play_button_has_default_focus() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)
	await wait_process_frames(1)

	var play_button: Button = title_screen.get_node("Panel/Margin/Content/Buttons/PlayButton")
	var quit_button: Button = title_screen.get_node("Panel/Margin/Content/Buttons/QuitButton")

	assert_true(play_button.has_focus())
	assert_false(quit_button.has_focus())


## Verifies the title buttons move focus in a predictable cycle with keyboard navigation.

func test_title_screen_when_navigating_with_keyboard_then_focus_moves_between_buttons() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)
	await wait_process_frames(1)

	var play_button: Button = title_screen.get_node("Panel/Margin/Content/Buttons/PlayButton")
	var quit_button: Button = title_screen.get_node("Panel/Margin/Content/Buttons/QuitButton")

	await _send_key_input(KEY_DOWN)

	assert_false(play_button.has_focus())
	assert_true(quit_button.has_focus())

	await _send_key_input(KEY_UP)

	assert_true(play_button.has_focus())
	assert_false(quit_button.has_focus())


## Verifies keyboard confirm activates the focused play action.

func test_title_screen_when_confirming_focused_play_button_then_play_requested_emits() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)
	await wait_process_frames(1)

	var ui_click_player: AudioStreamPlayer = title_screen.get_node("UIClickPlayer")
	ui_click_player.stream = null

	watch_signals(title_screen)
	await _send_key_input(KEY_ENTER)

	assert_signal_emitted(title_screen, "play_requested")


## Verifies keyboard confirm activates the focused quit action.

func test_title_screen_when_confirming_focused_quit_button_then_quit_requested_emits() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)
	await wait_process_frames(1)

	var quit_button: Button = title_screen.get_node("Panel/Margin/Content/Buttons/QuitButton")
	var ui_click_player: AudioStreamPlayer = title_screen.get_node("UIClickPlayer")
	ui_click_player.stream = null

	quit_button.grab_focus()
	watch_signals(title_screen)
	await _send_key_input(KEY_ENTER)

	assert_signal_emitted(title_screen, "quit_requested")


## Verifies title screen starts menu music.

func test_title_screen_starts_menu_music() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var player: AudioStreamPlayer = title_screen.get_node("TitleMusicPlayer")
	var ui_click_player: AudioStreamPlayer = title_screen.get_node("UIClickPlayer")

	assert_not_null(player.stream)
	assert_true(player.playing)
	assert_eq(ui_click_player.stream, title_screen.UI_CLICK_SOUND)


## Verifies title screen when no best run exists then empty summary is shown.

func test_title_screen_when_no_best_run_exists_then_empty_summary_is_shown() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var best_summary: Label = title_screen.get_node("%BestRunSummary")

	assert_eq(best_summary.text, title_screen.BEST_RUN_EMPTY_TEXT)


## Verifies title screen when best run exists then score and grade are shown.

func test_title_screen_when_best_run_exists_then_score_and_grade_are_shown() -> void:
	assert_eq(
		RunStateType.save_best_run(RunStateType.BestRunData.new(2185, "S", true), RunStateType.BEST_RUN_SAVE_PATH),
		OK
	)
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var best_summary: Label = title_screen.get_node("%BestRunSummary")

	assert_string_contains(best_summary.text, "Best Score: 2185")
	assert_string_contains(best_summary.text, "Best Grade: S")
