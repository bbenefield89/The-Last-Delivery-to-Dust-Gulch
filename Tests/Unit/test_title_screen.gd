extends GutTest

const TITLE_SCREEN_SCENE := preload("res://Scenes/TitleScreen/TitleScreen.tscn")


func test_play_button_emits_play_requested() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	watch_signals(title_screen)
	title_screen._on_play_pressed()

	assert_signal_emitted(title_screen, "play_requested")


func test_quit_button_emits_quit_requested() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	watch_signals(title_screen)
	title_screen._on_quit_pressed()

	assert_signal_emitted(title_screen, "quit_requested")


func test_title_screen_uses_western_panel_style() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var panel: PanelContainer = title_screen.get_node("Panel")
	var stylebox := panel.get_theme_stylebox("panel")

	assert_not_null(stylebox)
	assert_eq(stylebox.bg_color, Color(0.156863, 0.101961, 0.0666667, 0.94))


func test_title_screen_starts_menu_music() -> void:
	var title_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child_autofree(title_screen)

	var player: AudioStreamPlayer = title_screen.get_node("TitleMusicPlayer")

	assert_not_null(player.stream)
	assert_true(player.playing)
