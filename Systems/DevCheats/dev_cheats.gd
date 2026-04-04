extends RefCounted

## Owns debug-build-only cheat gating and runtime cheat toggle state.


# Constants

const TOGGLE_HAZARDS_ACTION := &"toggle_hazards"
const TOGGLE_HAZARDS_KEY := KEY_H
const DEFAULT_HAZARDS_ENABLED := true
const DEBUG_BUILD_OVERRIDE_INHERIT := -1
const DEBUG_BUILD_OVERRIDE_DISABLED := 0
const DEBUG_BUILD_OVERRIDE_ENABLED := 1


# Public Fields

var are_hazards_enabled: bool = DEFAULT_HAZARDS_ENABLED


# Private Fields

var _debug_build_override: int = DEBUG_BUILD_OVERRIDE_INHERIT


# Public Methods

## Restores cheat-owned runtime state to its default values for one new run.
func reset_for_new_run() -> void:
	are_hazards_enabled = DEFAULT_HAZARDS_ENABLED


## Returns whether debug-only cheats are available in the current runtime.
func is_enabled() -> bool:
	match _debug_build_override:
		DEBUG_BUILD_OVERRIDE_DISABLED:
			return false
		DEBUG_BUILD_OVERRIDE_ENABLED:
			return true
		_:
			return OS.is_debug_build()


## Registers debug-only cheat input actions when the current runtime allows them.
func register_input_actions() -> void:
	if not is_enabled():
		return

	if not InputMap.has_action(TOGGLE_HAZARDS_ACTION):
		InputMap.add_action(TOGGLE_HAZARDS_ACTION)

	var event := InputEventKey.new()
	event.physical_keycode = TOGGLE_HAZARDS_KEY
	if not InputMap.action_has_event(TOGGLE_HAZARDS_ACTION, event):
		InputMap.action_add_event(TOGGLE_HAZARDS_ACTION, event)


## Consumes one input event and returns whether it requested the hazard cheat toggle.
func consume_input(event: InputEvent) -> bool:
	if not is_enabled():
		return false
	if not event.is_action_pressed(TOGGLE_HAZARDS_ACTION):
		return false

	return true


## Overrides debug-build detection for automated tests that need release-like behavior.
func set_debug_build_override(is_debug_build: bool) -> void:
	_debug_build_override = (
		DEBUG_BUILD_OVERRIDE_ENABLED
		if is_debug_build
		else DEBUG_BUILD_OVERRIDE_DISABLED
	)


## Clears any test-only debug-build override and restores live runtime detection.
func clear_debug_build_override() -> void:
	_debug_build_override = DEBUG_BUILD_OVERRIDE_INHERIT
