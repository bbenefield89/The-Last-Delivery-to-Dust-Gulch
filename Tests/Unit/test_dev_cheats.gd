extends GutTest

# Constants
const DevCheatsType := preload(ProjectPaths.DEV_CHEATS_SCRIPT_PATH)


## Verifies dev cheats are disabled when tests force them off.
func test_are_cheats_available_when_forced_off_for_tests_then_false() -> void:
	var dev_cheats := DevCheatsType.new()
	dev_cheats.force_disable_for_tests()

	assert_false(dev_cheats.are_cheats_available())


## Verifies the hazard toggle cheat is recognized when cheats are available.
func test_consume_input_when_cheats_are_available_then_toggle_request_is_reported() -> void:
	var dev_cheats := DevCheatsType.new()
	var event := InputEventAction.new()
	event.action = DevCheatsType.TOGGLE_HAZARDS_ACTION
	event.pressed = true

	assert_true(dev_cheats.are_runtime_hazards_enabled)
	assert_true(dev_cheats.consume_input(event))
	assert_true(dev_cheats.are_runtime_hazards_enabled)


## Verifies release-like runtimes ignore cheat input and preserve the default safe state.
func test_consume_input_when_cheats_are_forced_off_then_it_is_ignored() -> void:
	var dev_cheats := DevCheatsType.new()
	dev_cheats.force_disable_for_tests()
	var event := InputEventAction.new()
	event.action = DevCheatsType.TOGGLE_HAZARDS_ACTION
	event.pressed = true

	assert_false(dev_cheats.consume_input(event))
	assert_true(dev_cheats.are_runtime_hazards_enabled)


## Verifies clearing test overrides restores normal debug-build cheat availability.
func test_clear_test_overrides_when_cheats_are_forced_off_then_debug_availability_returns() -> void:
	var dev_cheats := DevCheatsType.new()
	dev_cheats.force_disable_for_tests()

	assert_false(dev_cheats.are_cheats_available())

	dev_cheats.clear_test_overrides()

	assert_true(dev_cheats.are_cheats_available())
