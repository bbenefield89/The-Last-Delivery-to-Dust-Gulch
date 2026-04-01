extends Control

## Owns the transient route-phase callout timing, text, and fade state.


# Imports
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Constants
const CALLOUT_DURATION := 0.95


# Private Fields
var _run_state: RunStateType
var _callout_text := ""
var _callout_remaining := 0.0


# Private Fields: OnReady
@onready
var _panel: PanelContainer = %PhaseCalloutPanel

@onready
var _label: Label = %PhaseCalloutLabel


# Public Methods

## Binds the active run state so the phase callout only appears during active gameplay.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


## Starts or refreshes the active route-phase callout text.
func show_callout(text: String) -> void:
	_callout_text = text
	_callout_remaining = CALLOUT_DURATION
	refresh_callout()


## Clears the active route-phase callout state.
func clear_callout() -> void:
	_callout_text = ""
	_callout_remaining = 0.0


## Advances the route-phase timer and refreshes the visible state for this frame.
func advance(delta: float) -> void:
	if _callout_remaining > 0.0:
		_callout_remaining = max(0.0, _callout_remaining - max(0.0, delta))
		if _callout_remaining == 0.0:
			_callout_text = ""

	refresh_callout()


## Refreshes the current phase callout visibility, text, and fade state.
func refresh_callout() -> void:
	if _panel == null or _label == null:
		return

	var should_show_callout := (
		_run_state != null
		and _run_state.result == RunStateType.RESULT_IN_PROGRESS
		and _callout_remaining > 0.0
		and _callout_text != ""
	)
	_panel.visible = should_show_callout
	if not should_show_callout:
		_label.text = ""
		_panel.self_modulate = Color(1, 1, 1, 1)
		return

	_label.text = _callout_text
	var progress_ratio: float = 1.0 - (_callout_remaining / CALLOUT_DURATION)
	_panel.self_modulate = Color(1, 1, 1, 1.0 - (progress_ratio * 0.25))


## Returns whether the authored phase callout panel is currently visible.
func is_callout_visible() -> bool:
	return _panel != null and _panel.visible
