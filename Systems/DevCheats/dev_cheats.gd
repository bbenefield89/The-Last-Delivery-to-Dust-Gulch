extends RefCounted

## Owns debug-build-only cheat gating and runtime cheat toggle state.


# Constants

const TOGGLE_HAZARDS_ACTION := &"toggle_hazards"
const TOGGLE_HAZARDS_KEY := KEY_H
const DEFAULT_ARE_RUNTIME_HAZARDS_ENABLED := true


# Public Fields

var are_runtime_hazards_enabled: bool = DEFAULT_ARE_RUNTIME_HAZARDS_ENABLED


# Private Fields

var _are_cheats_forced_off_for_tests := false


# Public Methods

## Returns whether debug-only cheats are available in the current runtime.
func are_cheats_available() -> bool:
	return OS.is_debug_build() and not _are_cheats_forced_off_for_tests


## Registers debug-only cheat input actions when the current runtime allows them.
func register_input_actions() -> void:
	if not are_cheats_available():
		return

	if not InputMap.has_action(TOGGLE_HAZARDS_ACTION):
		InputMap.add_action(TOGGLE_HAZARDS_ACTION)

	var event := InputEventKey.new()
	event.physical_keycode = TOGGLE_HAZARDS_KEY
	if not InputMap.action_has_event(TOGGLE_HAZARDS_ACTION, event):
		InputMap.action_add_event(TOGGLE_HAZARDS_ACTION, event)


## Consumes one input event and returns whether it requested the hazard cheat toggle.
func consume_input(event: InputEvent) -> bool:
	if not are_cheats_available():
		return false

	if not event.is_action_pressed(TOGGLE_HAZARDS_ACTION):
		return false

	return true


## Forces cheats off for automated tests that need release-like behavior.
func force_disable_for_tests() -> void:
	_are_cheats_forced_off_for_tests = true


## Clears any test-only cheat restrictions and restores live runtime detection.
func clear_test_overrides() -> void:
	_are_cheats_forced_off_for_tests = false
