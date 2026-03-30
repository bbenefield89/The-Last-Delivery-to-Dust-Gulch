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
var _result_panel: ResultPanelUiType = %ResultPanel

@onready
var _result_restart_button: Button = %ResultRestartButton

@onready
var _result_return_button: Button = %ResultReturnButton


# Lifecycle Methods

## Configures result-screen navigation and button wiring when the wrapper enters the tree.
func _ready() -> void:
	_configure_result_menu_navigation()

	if (
		_result_restart_button != null
		and not _result_restart_button.pressed.is_connected(_on_result_restart_button_pressed)
	):
		_result_restart_button.pressed.connect(_on_result_restart_button_pressed)
	if (
		_result_return_button != null
		and not _result_return_button.pressed.is_connected(_on_result_return_button_pressed)
	):
		_result_return_button.pressed.connect(_on_result_return_button_pressed)


# Event Handlers

## Emits the result-screen restart intent upward.
func _on_result_restart_button_pressed() -> void:
	restart_requested.emit()


## Emits the result-screen return-to-title intent upward.
func _on_result_return_button_pressed() -> void:
	return_to_title_requested.emit()


# Public Methods

## Binds the active run state so result visibility tracks the current run.
func bind_run_state(run_state: RunStateType) -> void:
	_run_state = run_state


## Refreshes the end-of-run result panel contents and visibility.
func refresh_result_screen(best_run_summary: String) -> void:
	if _result_panel == null:
		return
	if _run_state == null or _run_state.result == RunStateType.RESULT_IN_PROGRESS:
		_result_panel.visible = false
		_result_panel.clear_result_data()
		return

	_result_panel.visible = true
	_result_panel.set_result_data(_get_result_title(), best_run_summary, _build_result_stat_rows())
	if (
		_result_restart_button != null
		and _result_return_button != null
		and not _result_restart_button.has_focus()
		and not _result_return_button.has_focus()
	):
		focus_default_result_button()


## Shows representative result data while editing the scene in Godot.
func apply_editor_result_preview() -> void:
	if not Engine.is_editor_hint():
		return
	if _result_panel == null:
		return

	_result_panel.visible = true
	_result_panel.show_editor_preview()


## Gives the result screen a deterministic starting focus for keyboard-only play.
func focus_default_result_button() -> void:
	if _result_restart_button == null:
		return
	_result_restart_button.grab_focus()


## Returns whether the result panel is currently visible.
func is_result_screen_visible() -> bool:
	return _result_panel != null and _result_panel.visible


# Private Methods

## Configures explicit keyboard focus traversal for the result screen buttons.
func _configure_result_menu_navigation() -> void:
	if _result_restart_button == null or _result_return_button == null:
		return

	_result_restart_button.focus_mode = Control.FOCUS_ALL
	_result_return_button.focus_mode = Control.FOCUS_ALL

	var restart_to_return := _result_restart_button.get_path_to(_result_return_button)
	var return_to_restart := _result_return_button.get_path_to(_result_restart_button)

	_result_restart_button.focus_neighbor_top = restart_to_return
	_result_restart_button.focus_neighbor_bottom = restart_to_return
	_result_restart_button.focus_neighbor_left = restart_to_return
	_result_restart_button.focus_neighbor_right = restart_to_return
	_result_restart_button.focus_previous = restart_to_return
	_result_restart_button.focus_next = restart_to_return

	_result_return_button.focus_neighbor_top = return_to_restart
	_result_return_button.focus_neighbor_bottom = return_to_restart
	_result_return_button.focus_neighbor_left = return_to_restart
	_result_return_button.focus_neighbor_right = return_to_restart
	_result_return_button.focus_previous = return_to_restart
	_result_return_button.focus_next = return_to_restart


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
	return [
		ResultPanelUiType.ResultStatRowData.new("Score", "%d" % _run_state.get_score()),
		ResultPanelUiType.ResultStatRowData.new("Delivery Grade", _run_state.get_delivery_grade()),
		ResultPanelUiType.ResultStatRowData.new("Health", "%d" % _run_state.wagon_health),
		ResultPanelUiType.ResultStatRowData.new("Cargo", "%d" % _run_state.cargo_value),
		ResultPanelUiType.ResultStatRowData.new(
			"Distance traveled",
			"%.0f / %.0f" % [_run_state.get_distance_traveled(), _run_state.route_distance]
		),
		ResultPanelUiType.ResultStatRowData.new("Hazards Dodged", "%d" % _run_state.hazards_dodged),
		ResultPanelUiType.ResultStatRowData.new("Near Misses", "%d" % _run_state.near_misses),
		ResultPanelUiType.ResultStatRowData.new(
			"Perfect Recoveries",
			"%d" % _run_state.perfect_recoveries
		),
		ResultPanelUiType.ResultStatRowData.new(
			"Recovery Failures",
			"%d" % _run_state.recovery_failures
		),
	]
