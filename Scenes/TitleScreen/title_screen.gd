extends Control

const TITLE_MUSIC := preload("res://Assets/Audio/Confronting The Man In Black.ogg")

signal play_requested
signal quit_requested


@onready var _play_button: Button = $Panel/Margin/Content/Buttons/PlayButton
@onready var _quit_button: Button = $Panel/Margin/Content/Buttons/QuitButton
@onready var _title_music_player: AudioStreamPlayer = $TitleMusicPlayer


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_title_music_player.stream = TITLE_MUSIC
	_title_music_player.volume_db = -12.0
	_title_music_player.play()


func _exit_tree() -> void:
	_title_music_player.stop()
	_title_music_player.stream = null


func _on_play_pressed() -> void:
	play_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()
