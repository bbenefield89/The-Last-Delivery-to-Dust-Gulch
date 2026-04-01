extends Control

## Owns the transient in-run bonus callout timing, layout, and positioning.


# Constants
const CALLOUT_DURATION := 1.1
const CALLOUT_START_OFFSET := Vector2(0.0, -64.0)
const CALLOUT_END_OFFSET := Vector2(0.0, -82.0)


# Private Fields
var _callout_text := ""
var _callout_remaining := 0.0
var _anchor_world_position := Vector2.ZERO


# Private Fields: OnReady
@onready
var _panel: Control = %BonusCalloutPanel

@onready
var _label: Label = %BonusCalloutLabel


# Public Methods

## Starts or refreshes the current bonus callout and renders it immediately.
func show_callout(
	text: String,
	anchor_world_position: Vector2,
	canvas_transform: Transform2D
) -> void:
	_callout_text = text
	_callout_remaining = CALLOUT_DURATION
	_anchor_world_position = anchor_world_position
	refresh_callout(canvas_transform)


## Clears the current bonus callout without mutating the authored nodes directly elsewhere.
func clear_callout() -> void:
	_callout_text = ""
	_callout_remaining = 0.0


## Advances the active callout timer and refreshes the visible state for this frame.
func advance(delta: float, canvas_transform: Transform2D) -> void:
	if _callout_remaining > 0.0:
		_callout_remaining = max(0.0, _callout_remaining - max(0.0, delta))
		if _callout_remaining == 0.0:
			_callout_text = ""

	refresh_callout(canvas_transform)


## Refreshes the current callout visibility, text, position, and fade state.
func refresh_callout(canvas_transform: Transform2D) -> void:
	if _panel == null or _label == null:
		return

	var should_show_callout := _callout_remaining > 0.0 and _callout_text != ""
	_panel.visible = should_show_callout
	if not should_show_callout:
		_label.text = ""
		_panel.self_modulate = Color(1, 1, 1, 1)
		return

	_label.text = _callout_text
	var progress_ratio: float = 1.0 - (_callout_remaining / CALLOUT_DURATION)
	var canvas_position: Vector2 = canvas_transform * _anchor_world_position
	var flyout_offset: Vector2 = CALLOUT_START_OFFSET.lerp(CALLOUT_END_OFFSET, progress_ratio)
	var panel_size: Vector2 = _panel.size
	_panel.position = canvas_position + flyout_offset - (panel_size * 0.5)
	_panel.self_modulate = Color(1, 1, 1, 1.0 - progress_ratio)


## Returns whether the authored bonus panel is currently visible.
func is_callout_visible() -> bool:
	return _panel != null and _panel.visible
