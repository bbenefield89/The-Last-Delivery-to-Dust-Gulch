extends GutTest

const TITLE_SCREEN_SCENE := preload("res://Scenes/TitleScreen/TitleScreen.tscn")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")
const TEST_BEST_RUN_SAVE_PATH := "user://dg30_test_title_best_run.cfg"


func before_each() -> void:
	_delete_test_best_run_file()


func after_each() -> void:
	_delete_test_best_run_file()


func test_play_button_emits_play_requested() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	watch_signals(title_screen)
	await title_screen._on_play_pressed()

	assert_signal_emitted(title_screen, "play_requested")


func test_quit_button_emits_quit_requested() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	watch_signals(title_screen)
	await title_screen._on_quit_pressed()

	assert_signal_emitted(title_screen, "quit_requested")


func test_title_screen_uses_western_panel_style() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var panel: PanelContainer = title_screen.get_node("Panel")
	var stylebox := panel.get_theme_stylebox("panel")

	assert_not_null(stylebox)
	assert_eq(stylebox.bg_color, Color(0.156863, 0.101961, 0.0666667, 0.94))


func test_title_screen_background_uses_cover_stretch_mode() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var background: TextureRect = title_screen.get_node("%Background")

	assert_not_null(background.texture)
	assert_eq(background.expand_mode, TextureRect.EXPAND_IGNORE_SIZE)
	assert_eq(background.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert_eq(background.anchor_right, 1.0)
	assert_eq(background.anchor_bottom, 1.0)


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


func test_title_screen_starts_menu_music() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var player: AudioStreamPlayer = title_screen.get_node("TitleMusicPlayer")
	var ui_click_player: AudioStreamPlayer = title_screen.get_node("UIClickPlayer")

	assert_not_null(player.stream)
	assert_true(player.playing)
	assert_eq(ui_click_player.stream, title_screen.UI_CLICK_SOUND)


func test_title_screen_when_no_best_run_exists_then_empty_summary_is_shown() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	title_screen._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(title_screen)

	var best_summary: Label = title_screen.get_node("%BestRunSummary")

	assert_eq(best_summary.text, title_screen.BEST_RUN_EMPTY_TEXT)


func test_title_screen_when_best_run_exists_then_score_and_grade_are_shown() -> void:
	assert_eq(
		RunStateType.save_best_run(RunStateType.BestRunData.new(2185, "S", true), TEST_BEST_RUN_SAVE_PATH),
		OK
	)
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	title_screen._best_run_save_path = TEST_BEST_RUN_SAVE_PATH
	add_child_autofree(title_screen)

	var best_summary: Label = title_screen.get_node("%BestRunSummary")

	assert_string_contains(best_summary.text, "Best Score: 2185")
	assert_string_contains(best_summary.text, "Best Grade: S")


func _delete_test_best_run_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_BEST_RUN_SAVE_PATH)
	if FileAccess.file_exists(TEST_BEST_RUN_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
