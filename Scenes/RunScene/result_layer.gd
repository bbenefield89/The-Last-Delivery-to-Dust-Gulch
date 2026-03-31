extends Control

## Owns result-screen visibility, content population, focus navigation, and result button intent signals.


# Signals
signal restart_requested
signal return_to_title_requested


# Imports
const ResultPanelUiType := preload(ProjectPaths.RESULT_PANEL_UI_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Private Fields
var _run_state: RunStateType


# Private Fields: OnReady
@onready
var _panel: ResultPanelUiType = %ResultPanel

@onready
var _restart_button: Button = %ResultRestartButton

@onready
var _return_button: Button = %ResultReturnButton


# Lifecycle Methods

## Configures result-screen navigation and button wiring when the wrapper enters the tree.
func _ready() -> void:
	_configure_navigation()
	_connect_buttons()


# Event Handlers

## Emits the result-screen restart intent upward.
func __on_restart_button_pressed() -> void:
	restart_requested.emit()


## Emits the result-screen return-to-title intent upward.
func __on_return_button_pressed() -> void:
	return_to_title_requested.emit()


# Public Methods

## Binds the active run state so result visibility tracks the current run.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


## Refreshes the end-of-run result panel contents and visibility.
func refresh_screen(best_run_summary: String) -> void:
	if _panel == null:
		return
	if _run_state == null or _run_state.result == RunStateType.RESULT_IN_PROGRESS:
		_hide_screen()
		return

	_show_screen(best_run_summary)


## Shows representative result data while editing the scene in Godot.
func apply_editor_result_preview() -> void:
	if not Engine.is_editor_hint() or _panel == null:
		return

	_panel.visible = true
	_panel.show_editor_preview()


## Gives the result screen a deterministic starting focus for keyboard-only play.
func focus_default_button() -> void:
	if _restart_button != null:
		_restart_button.grab_focus()


## Returns whether the result panel is currently visible.
func is_screen_visible() -> bool:
	return _panel != null and _panel.visible


# Private Methods

## Hides the authored result panel and clears any previously rendered runtime data.
func _hide_screen() -> void:
	_panel.visible = false
	_panel.clear_result_data()


## Shows the authored result panel with the current run summary and stat rows.
func _show_screen(best_run_summary: String) -> void:
	_panel.visible = true
	_panel.set_result_data(_get_result_title(), best_run_summary, _build_result_stat_rows())
	if not _has_button_focus():
		focus_default_button()


## Connects each authored result button to its matching signal-emission handler once.
func _connect_buttons() -> void:
	_connect_button(_restart_button, __on_restart_button_pressed)
	_connect_button(_return_button, __on_return_button_pressed)


## Connects one result button to its pressed handler if that connection is not already present.
func _connect_button(button: Button, handler: Callable) -> void:
	if button == null or button.pressed.is_connected(handler):
		return

	button.pressed.connect(handler)


## Returns whether either result-screen button already owns keyboard focus.
func _has_button_focus() -> bool:
	return (
		(_restart_button != null and _restart_button.has_focus())
		or (_return_button != null and _return_button.has_focus())
	)


## Configures explicit keyboard focus traversal for the result screen buttons.
func _configure_navigation() -> void:
	if _restart_button == null or _return_button == null:
		return

	_enable_button_focus()
	_configure_restart_navigation()
	_configure_return_navigation()


## Enables keyboard focus for the authored result-screen buttons.
func _enable_button_focus() -> void:
	_restart_button.focus_mode = Control.FOCUS_ALL
	_return_button.focus_mode = Control.FOCUS_ALL


## Configures the authored restart button focus neighbors.
func _configure_restart_navigation() -> void:
	var restart_to_return := _restart_button.get_path_to(_return_button)
	_restart_button.focus_neighbor_top = restart_to_return
	_restart_button.focus_neighbor_bottom = restart_to_return
	_restart_button.focus_neighbor_left = restart_to_return
	_restart_button.focus_neighbor_right = restart_to_return
	_restart_button.focus_previous = restart_to_return
	_restart_button.focus_next = restart_to_return


## Configures the authored return button focus neighbors.
func _configure_return_navigation() -> void:
	var return_to_restart := _return_button.get_path_to(_restart_button)
	_return_button.focus_neighbor_top = return_to_restart
	_return_button.focus_neighbor_bottom = return_to_restart
	_return_button.focus_neighbor_left = return_to_restart
	_return_button.focus_neighbor_right = return_to_restart
	_return_button.focus_previous = return_to_restart
	_return_button.focus_next = return_to_restart


## Returns the visible result title that matches the active run outcome.
func _get_result_title() -> String:
	match _run_state.result:
		RunStateType.RESULT_SUCCESS:
			return "Delivered to Dust Gulch"
		RunStateType.RESULT_COLLAPSED:
			return "Wagon Collapsed"
		_:
			return "Run Complete"


## Builds the ordered structured stat rows shown in the result panel.
func _build_result_stat_rows() -> Array:
	var stat_rows: Array = []
	stat_rows.append_array(_build_score_stat_rows())
	stat_rows.append_array(_build_progress_stat_rows())
	stat_rows.append_array(_build_recovery_stat_rows())
	return stat_rows


## Builds the score, grade, and health rows for the visible result panel.
func _build_score_stat_rows() -> Array:
	return [
		ResultPanelUiType.ResultStatRowData.new("Score", "%d" % _run_state.get_score()),
		ResultPanelUiType.ResultStatRowData.new("Delivery Grade", _run_state.get_delivery_grade()),
		ResultPanelUiType.ResultStatRowData.new("Health", "%d" % _run_state.wagon_health),
		ResultPanelUiType.ResultStatRowData.new("Cargo", "%d" % _run_state.cargo_value),
	]


## Builds the route-progress rows for the visible result panel.
func _build_progress_stat_rows() -> Array:
	return [
		ResultPanelUiType.ResultStatRowData.new(
			"Distance traveled",
			"%.0f / %.0f" % [_run_state.get_distance_traveled(), _run_state.route_distance]
		),
		ResultPanelUiType.ResultStatRowData.new("Hazards Dodged", "%d" % _run_state.hazards_dodged),
		ResultPanelUiType.ResultStatRowData.new("Near Misses", "%d" % _run_state.near_misses),
	]


## Builds the recovery-performance rows for the visible result panel.
func _build_recovery_stat_rows() -> Array:
	return [
		ResultPanelUiType.ResultStatRowData.new(
			"Perfect Recoveries",
			"%d" % _run_state.perfect_recoveries
		),
		ResultPanelUiType.ResultStatRowData.new(
			"Recovery Failures",
			"%d" % _run_state.recovery_failures
		),
	]
