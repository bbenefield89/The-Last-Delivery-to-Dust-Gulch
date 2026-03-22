extends Control

const TITLE_MUSIC := preload("res://Assets/Audio/Confronting The Man In Black.ogg")
const UI_CLICK_SOUND := preload("res://Assets/Sfx/Button-Click-85854.mp3")
const BEST_RUN_EMPTY_TEXT := "Best Run: None yet"

signal play_requested
signal quit_requested


# Private Fields

var _navigation_click_in_progress: bool = false
var _best_run_save_path: String = RunState.BEST_RUN_SAVE_PATH


@onready var _play_button: Button = $Panel/Margin/Content/Buttons/PlayButton
@onready var _quit_button: Button = $Panel/Margin/Content/Buttons/QuitButton
@onready var _best_run_summary: Label = %BestRunSummary
@onready var _title_music_player: AudioStreamPlayer = $TitleMusicPlayer
@onready var _ui_click_player: AudioStreamPlayer = $UIClickPlayer


## Wires title-screen buttons and starts the menu audio presentation.
func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_refresh_best_run_summary()
	_title_music_player.stream = TITLE_MUSIC
	_title_music_player.volume_db = -12.0
	_title_music_player.play()
	_ui_click_player.stream = UI_CLICK_SOUND
	_ui_click_player.volume_db = -9.0


## Releases title-screen audio streams when the screen leaves the tree.
func _exit_tree() -> void:
	_title_music_player.stop()
	_title_music_player.stream = null
	_ui_click_player.stop()
	_ui_click_player.stream = null


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

	var best_run := RunState.load_best_run(_best_run_save_path)
	if not best_run.has_value:
		_best_run_summary.text = BEST_RUN_EMPTY_TEXT
		return

	_best_run_summary.text = "Best Score: %d | Best Grade: %s" % [best_run.score, best_run.grade]
