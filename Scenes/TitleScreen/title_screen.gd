extends Control

## Owns the title-screen presentation, menu input, and best-run summary display.


# Signals

signal play_requested
signal quit_requested


# Constants
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


const TITLE_MUSIC := preload(AssetPaths.TITLE_MUSIC_AUDIO_PATH)
const UI_CLICK_SOUND := preload(AssetPaths.UI_CLICK_SOUND_PATH)
const BEST_RUN_EMPTY_TEXT := "Best Run: None yet"


# Private Fields

var _navigation_click_in_progress: bool = false
var _best_run_save_path: String = RunStateType.BEST_RUN_SAVE_PATH


# Private Fields: OnReady

@onready
var _play_button: Button = $Panel/Margin/Content/Buttons/PlayButton

@onready
var _quit_button: Button = $Panel/Margin/Content/Buttons/QuitButton

@onready
var _best_run_summary: Label = %BestRunSummary

@onready
var _title_music_player: AudioStreamPlayer = $TitleMusicPlayer

@onready
var _ui_click_player: AudioStreamPlayer = $UIClickPlayer


# Lifecycle Methods

## Wires title-screen buttons and starts the menu audio presentation.
func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_configure_keyboard_navigation()
	_refresh_best_run_summary()
	_title_music_player.stream = TITLE_MUSIC
	_title_music_player.volume_db = -12.0
	_title_music_player.play()
	_ui_click_player.stream = UI_CLICK_SOUND
	_ui_click_player.volume_db = -9.0
	call_deferred("_focus_default_button")


## Releases title-screen audio streams when the screen leaves the tree.
func _exit_tree() -> void:
	_title_music_player.stop()
	_title_music_player.stream = null
	_ui_click_player.stop()
	_ui_click_player.stream = null


# Event Handlers

## Emits the play request after playing the shared UI click cue.
func _on_play_pressed() -> void:
	if _navigation_click_in_progress:
		return
	_navigation_click_in_progress = true
	await _play_ui_click_and_wait()
	_navigation_click_in_progress = false
	play_requested.emit()


## Emits the quit request after playing the shared UI click cue.
func _on_quit_pressed() -> void:
	if _navigation_click_in_progress:
		return
	_navigation_click_in_progress = true
	await _play_ui_click_and_wait()
	_navigation_click_in_progress = false
	quit_requested.emit()


# Private Methods

## Plays the shared title-screen click cue when the UI player is available.
func _play_ui_click() -> void:
	if _ui_click_player == null:
		return
	_ui_click_player.play()


## Plays the shared title-screen click cue and waits long enough for scene transitions to preserve it.
func _play_ui_click_and_wait() -> void:
	if _ui_click_player == null or _ui_click_player.stream == null:
		return
	_ui_click_player.play()
	await get_tree().create_timer(_ui_click_player.stream.get_length(), false).timeout


## Loads and displays the locally stored best-run summary on the title panel.
func _refresh_best_run_summary() -> void:
	if _best_run_summary == null:
		return

	var best_run := RunStateType.load_best_run(_best_run_save_path)
	if not best_run.has_value:
		_best_run_summary.text = BEST_RUN_EMPTY_TEXT
		return

	_best_run_summary.text = "Best Score: %d | Best Grade: %s" % [best_run.score, best_run.grade]


## Configures explicit keyboard traversal between the title-screen options.
func _configure_keyboard_navigation() -> void:
	if _play_button == null or _quit_button == null:
		return

	_play_button.focus_mode = Control.FOCUS_ALL
	_quit_button.focus_mode = Control.FOCUS_ALL

	var play_to_quit := _play_button.get_path_to(_quit_button)
	var quit_to_play := _quit_button.get_path_to(_play_button)

	_play_button.focus_neighbor_left = play_to_quit
	_play_button.focus_neighbor_right = play_to_quit
	_play_button.focus_neighbor_top = play_to_quit
	_play_button.focus_neighbor_bottom = play_to_quit
	_play_button.focus_next = play_to_quit
	_play_button.focus_previous = play_to_quit

	_quit_button.focus_neighbor_left = quit_to_play
	_quit_button.focus_neighbor_right = quit_to_play
	_quit_button.focus_neighbor_top = quit_to_play
	_quit_button.focus_neighbor_bottom = quit_to_play
	_quit_button.focus_next = quit_to_play
	_quit_button.focus_previous = quit_to_play


## Gives the title screen a deterministic starting focus for keyboard-only play.
func _focus_default_button() -> void:
	if _play_button == null:
		return
	_play_button.grab_focus()
