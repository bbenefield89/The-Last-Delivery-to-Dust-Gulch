extends GutTest

# Constants
const DevCheatsType := preload(ProjectPaths.DEV_CHEATS_SCRIPT_PATH)


## Verifies dev cheats are disabled when a release-like override is active.
func test_is_enabled_when_debug_override_is_disabled_then_false() -> void:
	var dev_cheats := DevCheatsType.new()
	dev_cheats.set_debug_build_override(false)

	assert_false(dev_cheats.is_enabled())


## Verifies the hazard toggle cheat is recognized when debug cheats are enabled.
func test_consume_input_when_debug_override_is_enabled_then_toggle_request_is_reported() -> void:
	var dev_cheats := DevCheatsType.new()
	dev_cheats.set_debug_build_override(true)
	var event := InputEventAction.new()
	event.action = DevCheatsType.TOGGLE_HAZARDS_ACTION
	event.pressed = true

	assert_true(dev_cheats.are_hazards_enabled)
	assert_true(dev_cheats.consume_input(event))
	assert_true(dev_cheats.are_hazards_enabled)


## Verifies release-like runtimes ignore cheat input and preserve the default safe state.
func test_consume_input_when_debug_override_is_disabled_then_it_is_ignored() -> void:
	var dev_cheats := DevCheatsType.new()
	dev_cheats.set_debug_build_override(false)
	var event := InputEventAction.new()
	event.action = DevCheatsType.TOGGLE_HAZARDS_ACTION
	event.pressed = true

	assert_false(dev_cheats.consume_input(event))
	assert_true(dev_cheats.are_hazards_enabled)


## Verifies resetting for a new run restores hazard cheats to their default enabled state.
func test_reset_for_new_run_when_hazards_were_disabled_then_default_is_restored() -> void:
	var dev_cheats := DevCheatsType.new()
	dev_cheats.are_hazards_enabled = false

	dev_cheats.reset_for_new_run()

	assert_true(dev_cheats.are_hazards_enabled)
