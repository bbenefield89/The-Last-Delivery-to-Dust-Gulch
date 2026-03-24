class_name RunAudioPresenter
extends RefCounted

## Owns run-scene audio player setup, runtime cue playback, and audio-state transitions.

const HAZARD_TYPE_POTHOLE := &"pothole"
const HAZARD_TYPE_ROCK := &"rock"
const HAZARD_TYPE_TUMBLEWEED := &"tumbleweed"
const FAILURE_TYPE_WHEEL_LOOSE := &"wheel_loose"
const FAILURE_TYPE_HORSE_PANIC := &"horse_panic"

# Public Fields

var last_announced_failure: StringName = &""
var last_announced_result: StringName = RunState.RESULT_IN_PROGRESS
var tumbleweed_impact_serial := 0

# Private Fields

var _run_state: RunState
var _tree_host: Node
var _music_player: AudioStreamPlayer
var _wagon_loop_player: AudioStreamPlayer
var _impact_player: AudioStreamPlayer
var _pothole_impact_player: AudioStreamPlayer
var _rock_impact_player: AudioStreamPlayer
var _tumbleweed_impact_player: AudioStreamPlayer
var _wheel_loose_ambient_player: AudioStreamPlayer
var _horse_panic_ambient_player: AudioStreamPlayer
var _recovery_step_player: AudioStreamPlayer
var _recovery_success_player: AudioStreamPlayer
var _recovery_fail_player: AudioStreamPlayer
var _pause_toggle_player: AudioStreamPlayer
var _failure_player: AudioStreamPlayer
var _result_player: AudioStreamPlayer
var _ui_click_player: AudioStreamPlayer
var _background_music: AudioStream
var _wagon_loop_sound: AudioStream
var _impact_sound: AudioStream
var _pothole_impact_sound: AudioStream
var _rock_impact_sound: AudioStream
var _tumbleweed_impact_sound: AudioStream
var _wheel_loose_ambient_sound: AudioStream
var _horse_panic_ambient_sound: AudioStream
var _recovery_step_sound: AudioStream
var _recovery_success_sound: AudioStream
var _recovery_fail_sound: AudioStream
var _pause_toggle_sound: AudioStream
var _failure_sound: AudioStream
var _win_stinger: AudioStream
var _collapse_stinger: AudioStream
var _ui_click_sound: AudioStream
var _wagon_loop_start_seconds := 0.0
var _wagon_loop_end_seconds := 0.0


## Binds the scene-owned audio players and host node used for runtime audio operations.
func configure_scene_nodes(
	run_state: RunState,
	tree_host: Node,
	music_player: AudioStreamPlayer,
	wagon_loop_player: AudioStreamPlayer,
	impact_player: AudioStreamPlayer,
	pothole_impact_player: AudioStreamPlayer,
	rock_impact_player: AudioStreamPlayer,
	tumbleweed_impact_player: AudioStreamPlayer,
	wheel_loose_ambient_player: AudioStreamPlayer,
	horse_panic_ambient_player: AudioStreamPlayer,
	recovery_step_player: AudioStreamPlayer,
	recovery_success_player: AudioStreamPlayer,
	recovery_fail_player: AudioStreamPlayer,
	pause_toggle_player: AudioStreamPlayer,
	failure_player: AudioStreamPlayer,
	result_player: AudioStreamPlayer,
	ui_click_player: AudioStreamPlayer
) -> void:
	_run_state = run_state
	_tree_host = tree_host
	_music_player = music_player
	_wagon_loop_player = wagon_loop_player
	_impact_player = impact_player
	_pothole_impact_player = pothole_impact_player
	_rock_impact_player = rock_impact_player
	_tumbleweed_impact_player = tumbleweed_impact_player
	_wheel_loose_ambient_player = wheel_loose_ambient_player
	_horse_panic_ambient_player = horse_panic_ambient_player
	_recovery_step_player = recovery_step_player
	_recovery_success_player = recovery_success_player
	_recovery_fail_player = recovery_fail_player
	_pause_toggle_player = pause_toggle_player
	_failure_player = failure_player
	_result_player = result_player
	_ui_click_player = ui_click_player


## Binds the active run state and resets presenter-owned transition tracking for that run.
func bind_run_state(run_state: RunState) -> void:
	_run_state = run_state
	if _run_state == null:
		last_announced_failure = &""
		last_announced_result = RunState.RESULT_IN_PROGRESS
	else:
		last_announced_failure = _run_state.active_failure
		last_announced_result = _run_state.result
	tumbleweed_impact_serial = 0


## Applies the authored streams, loop points, and mix levels to the bound audio players.
func configure_audio_players(
	background_music: AudioStream,
	wagon_loop_sound: AudioStream,
	impact_sound: AudioStream,
	pothole_impact_sound: AudioStream,
	rock_impact_sound: AudioStream,
	tumbleweed_impact_sound: AudioStream,
	wheel_loose_ambient_sound: AudioStream,
	horse_panic_ambient_sound: AudioStream,
	recovery_step_sound: AudioStream,
	recovery_success_sound: AudioStream,
	recovery_fail_sound: AudioStream,
	pause_toggle_sound: AudioStream,
	failure_sound: AudioStream,
	win_stinger: AudioStream,
	collapse_stinger: AudioStream,
	ui_click_sound: AudioStream,
	wagon_loop_start_seconds: float,
	wagon_loop_end_seconds: float
) -> void:
	_background_music = background_music
	_wagon_loop_sound = wagon_loop_sound
	_impact_sound = impact_sound
	_pothole_impact_sound = pothole_impact_sound
	_rock_impact_sound = rock_impact_sound
	_tumbleweed_impact_sound = tumbleweed_impact_sound
	_wheel_loose_ambient_sound = wheel_loose_ambient_sound
	_horse_panic_ambient_sound = horse_panic_ambient_sound
	_recovery_step_sound = recovery_step_sound
	_recovery_success_sound = recovery_success_sound
	_recovery_fail_sound = recovery_fail_sound
	_pause_toggle_sound = pause_toggle_sound
	_failure_sound = failure_sound
	_win_stinger = win_stinger
	_collapse_stinger = collapse_stinger
	_ui_click_sound = ui_click_sound
	_wagon_loop_start_seconds = wagon_loop_start_seconds
	_wagon_loop_end_seconds = wagon_loop_end_seconds

	if _music_player != null:
		_music_player.stream = _background_music
		_music_player.volume_db = -12.0
	if _wagon_loop_player != null:
		_wagon_loop_player.stream = _wagon_loop_sound
		_wagon_loop_player.volume_db = -8.5
	if _impact_player != null:
		_impact_player.stream = _impact_sound
		_impact_player.volume_db = -4.5
	if _pothole_impact_player != null:
		_pothole_impact_player.stream = _pothole_impact_sound
		_pothole_impact_player.volume_db = -5.0
	if _rock_impact_player != null:
		_rock_impact_player.stream = _rock_impact_sound
		_rock_impact_player.volume_db = -4.5
	if _tumbleweed_impact_player != null:
		_tumbleweed_impact_player.stream = _tumbleweed_impact_sound
		_tumbleweed_impact_player.volume_db = -7.0
	if _wheel_loose_ambient_player != null:
		_wheel_loose_ambient_player.stream = _wheel_loose_ambient_sound
		_wheel_loose_ambient_player.volume_db = -9.0
	if _horse_panic_ambient_player != null:
		_horse_panic_ambient_player.stream = _horse_panic_ambient_sound
		_horse_panic_ambient_player.volume_db = -10.0
	if _recovery_step_player != null:
		_recovery_step_player.stream = _recovery_step_sound
		_recovery_step_player.volume_db = -1.5
	if _recovery_success_player != null:
		_recovery_success_player.stream = _recovery_success_sound
		_recovery_success_player.volume_db = -1.0
	if _recovery_fail_player != null:
		_recovery_fail_player.stream = _recovery_fail_sound
		_recovery_fail_player.volume_db = -1.0
	if _pause_toggle_player != null:
		_pause_toggle_player.stream = _pause_toggle_sound
		_pause_toggle_player.volume_db = -8.0
	if _failure_player != null:
		_failure_player.stream = _failure_sound
		_failure_player.volume_db = -5.0
	if _result_player != null:
		_result_player.volume_db = -6.0
	if _ui_click_player != null:
		_ui_click_player.stream = _ui_click_sound
		_ui_click_player.volume_db = -9.0


## Refreshes music, looped carriage audio, ambient failure loops, and transition cues for the current run state.
func refresh_audio_presentation() -> void:
	if _run_state == null:
		return

	if _music_player != null:
		if _run_state.result == RunState.RESULT_IN_PROGRESS:
			if not _music_player.playing:
				_music_player.play()
		elif _music_player.playing:
			_music_player.stop()

	if _wagon_loop_player != null:
		if _run_state.result == RunState.RESULT_IN_PROGRESS:
			if not _wagon_loop_player.playing:
				_wagon_loop_player.play(_wagon_loop_start_seconds)
			elif _wagon_loop_player.get_playback_position() >= _wagon_loop_end_seconds:
				_wagon_loop_player.seek(_wagon_loop_start_seconds)
		elif _wagon_loop_player.playing:
			_wagon_loop_player.stop()

	refresh_failure_ambient_audio()

	if _run_state.active_failure != last_announced_failure:
		if _run_state.active_failure != &"" and _failure_player != null:
			_failure_player.play()
		last_announced_failure = _run_state.active_failure

	if _run_state.result != last_announced_result:
		match _run_state.result:
			RunState.RESULT_SUCCESS:
				if _result_player != null:
					_result_player.stream = _win_stinger
					_result_player.play()
			RunState.RESULT_COLLAPSED:
				if _result_player != null:
					_result_player.stream = _collapse_stinger
					_result_player.play()
		last_announced_result = _run_state.result


## Routes one hazard hit to its authored impact cue and schedules tumbleweed stop timing when needed.
func play_hazard_impact(hazard_type: StringName) -> void:
	match hazard_type:
		HAZARD_TYPE_POTHOLE:
			if _pothole_impact_player != null:
				_pothole_impact_player.play()
				return
		HAZARD_TYPE_ROCK:
			if _rock_impact_player != null:
				_rock_impact_player.play()
				return
		HAZARD_TYPE_TUMBLEWEED:
			if _tumbleweed_impact_player != null:
				tumbleweed_impact_serial += 1
				_tumbleweed_impact_player.play()
				schedule_tumbleweed_impact_stop(tumbleweed_impact_serial)
				return

	if _impact_player != null:
		_impact_player.play()


## Plays the authored recovery-step cue for one correct non-final recovery input.
func play_recovery_step() -> void:
	if _recovery_step_player == null:
		return
	_recovery_step_player.play()


## Plays the authored recovery-success cue when the active recovery sequence completes.
func play_recovery_success() -> void:
	if _recovery_success_player == null:
		return
	_recovery_success_player.play()


## Plays the authored recovery-fail cue when a recovery timeout applies its penalty.
func play_recovery_fail() -> void:
	if _recovery_fail_player == null:
		return
	_recovery_fail_player.play()


## Plays the authored pause toggle cue whenever the pause state changes.
func play_pause_toggle() -> void:
	if _pause_toggle_player == null:
		return
	_pause_toggle_player.play()


## Plays the shared menu click cue for pause and result buttons.
func play_ui_click() -> void:
	if _ui_click_player == null:
		return
	_ui_click_player.play()


## Plays the shared menu click cue and waits long enough for scene transitions to preserve it.
func play_ui_click_and_wait() -> void:
	if _ui_click_player == null or _ui_click_player.stream == null:
		return
	_ui_click_player.play()
	var tree := _get_tree()
	if tree == null:
		return
	await tree.create_timer(_ui_click_player.stream.get_length(), false).timeout


## Starts and stops sustained failure ambients according to the active failure and run state.
func refresh_failure_ambient_audio() -> void:
	if _run_state == null:
		return

	var should_play_wheel_loose := (
		_run_state.result == RunState.RESULT_IN_PROGRESS
		and _run_state.active_failure == FAILURE_TYPE_WHEEL_LOOSE
	)
	var should_play_horse_panic := (
		_run_state.result == RunState.RESULT_IN_PROGRESS
		and _run_state.active_failure == FAILURE_TYPE_HORSE_PANIC
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


## Stops the tumbleweed cue after the authored crash-length playback window.
func schedule_tumbleweed_impact_stop(serial: int) -> void:
	if _impact_sound == null:
		return
	var stop_after_seconds := _impact_sound.get_length()
	if stop_after_seconds <= 0.0:
		return
	var tree := _get_tree()
	if tree == null:
		return
	var timer := tree.create_timer(stop_after_seconds, false)
	timer.timeout.connect(on_tumbleweed_impact_timeout.bind(serial), CONNECT_ONE_SHOT)


## Stops the active tumbleweed cue only if a newer tumbleweed playback has not replaced it.
func on_tumbleweed_impact_timeout(serial: int) -> void:
	if _tumbleweed_impact_player == null:
		return
	if serial != tumbleweed_impact_serial:
		return
	_tumbleweed_impact_player.stop()


## Returns the current scene tree through the configured host node when timer-backed audio waits are needed.
func _get_tree() -> SceneTree:
	if _tree_host == null:
		return null
	return _tree_host.get_tree()
