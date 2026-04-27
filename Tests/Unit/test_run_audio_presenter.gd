extends GutTest

# Constants
const RunAudioPresenterType := preload(ProjectPaths.RUN_AUDIO_PRESENTER_SCRIPT_PATH)
const RUN_SCENE := preload(ProjectPaths.RUN_SCENE_PATH)


# Private Methods

## Returns the extracted audio presenter bound to the active test scene.
func _get_run_audio_presenter(scene: Node) -> RunAudioPresenterType:
	return scene._run_audio_presenter as RunAudioPresenterType


# Public Methods

## Verifies hazard impact audio dispatches to specific players and fallback.
func test_hazard_impact_audio_dispatches_to_specific_players_and_fallback() -> void:
	var scene := RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var run_audio_presenter := _get_run_audio_presenter(scene)
	var pothole_impact_player: AudioStreamPlayer = scene.get_node("%PotholeImpactPlayer")
	var rock_impact_player: AudioStreamPlayer = scene.get_node("%RockImpactPlayer")
	var tumbleweed_impact_player: AudioStreamPlayer = scene.get_node("%TumbleweedImpactPlayer")
	var impact_player: AudioStreamPlayer = scene.get_node("%ImpactPlayer")

	run_audio_presenter.play_hazard_impact(&"pothole")
	assert_true(pothole_impact_player.playing)
	assert_eq(pothole_impact_player.stream, scene.POTHOLE_IMPACT_SOUND)

	pothole_impact_player.stop()
	run_audio_presenter.play_hazard_impact(&"rock")
	assert_true(rock_impact_player.playing)
	assert_eq(rock_impact_player.stream, scene.ROCK_IMPACT_SOUND)
	assert_eq(rock_impact_player.stream, scene.POTHOLE_IMPACT_SOUND)

	rock_impact_player.stop()
	run_audio_presenter.play_hazard_impact(&"tumbleweed")
	assert_eq(run_audio_presenter.tumbleweed_impact_serial, 1)
	assert_true(tumbleweed_impact_player.playing)
	assert_eq(tumbleweed_impact_player.stream, scene.TUMBLEWEED_IMPACT_SOUND)
	await get_tree().create_timer(scene.IMPACT_SOUND.get_length() + 0.05, false).timeout
	assert_false(tumbleweed_impact_player.playing)

	tumbleweed_impact_player.stop()
	run_audio_presenter.play_hazard_impact(&"unknown")
	assert_true(impact_player.playing)
	assert_eq(impact_player.stream, scene.IMPACT_SOUND)
	assert_eq(impact_player.volume_db, -4.5)


## Verifies tumbleweed timeout when newer impact replaces older then stale stop is ignored.
func test_tumbleweed_timeout_when_newer_impact_replaces_older_then_stale_stop_is_ignored() -> void:
	var scene := RUN_SCENE.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(1)

	var run_audio_presenter := _get_run_audio_presenter(scene)
	var tumbleweed_impact_player: AudioStreamPlayer = scene.get_node("%TumbleweedImpactPlayer")

	run_audio_presenter.play_hazard_impact(&"tumbleweed")
	var first_serial := run_audio_presenter.tumbleweed_impact_serial
	run_audio_presenter.play_hazard_impact(&"tumbleweed")
	var second_serial := run_audio_presenter.tumbleweed_impact_serial

	assert_true(tumbleweed_impact_player.playing)
	assert_true(second_serial > first_serial)

	run_audio_presenter.on_tumbleweed_impact_timeout(first_serial)
	assert_true(tumbleweed_impact_player.playing)

	run_audio_presenter.on_tumbleweed_impact_timeout(second_serial)
	assert_false(tumbleweed_impact_player.playing)
