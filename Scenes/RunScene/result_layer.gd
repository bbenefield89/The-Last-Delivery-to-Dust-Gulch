extends Control

## Owns result-screen visibility, content population, focus navigation, and result button intent signals.


# Signals
signal restart_requested
signal return_to_title_requested


# Imports
const ResultPanelUiType := preload(ProjectPaths.RESULT_PANEL_UI_SCRIPT_PATH)
const RunStateType := preload(ProjectPaths.RUN_STATE_SCRIPT_PATH)


# Private Fields
var __run_state: RunStateType


# Private Fields: OnReady
@onready
var __panel: ResultPanelUiType = %ResultPanel

@onready
var __restart_button: Button = %ResultRestartButton

@onready
var __return_button: Button = %ResultReturnButton


# Lifecycle Methods

## Configures result-screen navigation and button wiring when the wrapper enters the tree.
func _ready() -> void:
	__configure_navigation()
	__connect_buttons()


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
	__run_state = run_state


## Refreshes the end-of-run result panel contents and visibility.
func refresh_screen(best_run_summary: String) -> void:
	if __panel == null:
		return
	if __run_state == null or __run_state.result == RunStateType.RESULT_IN_PROGRESS:
		__hide_screen()
		return

	__show_screen(best_run_summary)


## Shows representative result data while editing the scene in Godot.
func apply_editor_result_preview() -> void:
	if not Engine.is_editor_hint() or __panel == null:
		return

	__panel.visible = true
	__panel.show_editor_preview()


## Gives the result screen a deterministic starting focus for keyboard-only play.
func focus_default_button() -> void:
	if __restart_button != null:
		__restart_button.grab_focus()


## Returns whether the result panel is currently visible.
func is_screen_visible() -> bool:
	return __panel != null and __panel.visible


# Private Methods

## Hides the authored result panel and clears any previously rendered runtime data.
func __hide_screen() -> void:
	__panel.visible = false
	__panel.clear_result_data()


## Shows the authored result panel with the current run summary and stat rows.
func __show_screen(best_run_summary: String) -> void:
	__panel.visible = true
	__panel.set_result_data(__get_result_title(), best_run_summary, __build_result_stat_rows())
	if not __has_button_focus():
		focus_default_button()


## Connects each authored result button to its matching signal-emission handler once.
func __connect_buttons() -> void:
	__connect_button(__restart_button, __on_restart_button_pressed)
	__connect_button(__return_button, __on_return_button_pressed)


## Connects one result button to its pressed handler if that connection is not already present.
func __connect_button(button: Button, handler: Callable) -> void:
	if button == null or button.pressed.is_connected(handler):
		return

	button.pressed.connect(handler)


## Returns whether either result-screen button already owns keyboard focus.
func __has_button_focus() -> bool:
	return (
		(__restart_button != null and __restart_button.has_focus())
		or (__return_button != null and __return_button.has_focus())
	)


## Configures explicit keyboard focus traversal for the result screen buttons.
func __configure_navigation() -> void:
	if __restart_button == null or __return_button == null:
		return

	__enable_button_focus()
	__configure_restart_navigation()
	__configure_return_navigation()


## Enables keyboard focus for the authored result-screen buttons.
func __enable_button_focus() -> void:
	__restart_button.focus_mode = Control.FOCUS_ALL
	__return_button.focus_mode = Control.FOCUS_ALL


## Configures the authored restart button focus neighbors.
func __configure_restart_navigation() -> void:
	var restart_to_return := __restart_button.get_path_to(__return_button)
	__restart_button.focus_neighbor_top = restart_to_return
	__restart_button.focus_neighbor_bottom = restart_to_return
	__restart_button.focus_neighbor_left = restart_to_return
	__restart_button.focus_neighbor_right = restart_to_return
	__restart_button.focus_previous = restart_to_return
	__restart_button.focus_next = restart_to_return


## Configures the authored return button focus neighbors.
func __configure_return_navigation() -> void:
	var return_to_restart := __return_button.get_path_to(__restart_button)
	__return_button.focus_neighbor_top = return_to_restart
	__return_button.focus_neighbor_bottom = return_to_restart
	__return_button.focus_neighbor_left = return_to_restart
	__return_button.focus_neighbor_right = return_to_restart
	__return_button.focus_previous = return_to_restart
	__return_button.focus_next = return_to_restart


## Returns the visible result title that matches the active run outcome.
func __get_result_title() -> String:
	match __run_state.result:
		RunStateType.RESULT_SUCCESS:
			return "Delivered to Dust Gulch"
		RunStateType.RESULT_COLLAPSED:
			return "Wagon Collapsed"
		_:
			return "Run Complete"


## Builds the ordered structured stat rows shown in the result panel.
func __build_result_stat_rows() -> Array:
	var stat_rows: Array = []
	stat_rows.append_array(__build_score_stat_rows())
	stat_rows.append_array(__build_progress_stat_rows())
	stat_rows.append_array(__build_recovery_stat_rows())
	return stat_rows


## Builds the score, grade, and health rows for the visible result panel.
func __build_score_stat_rows() -> Array:
	return [
		ResultPanelUiType.ResultStatRowData.new("Score", "%d" % __run_state.get_score()),
		ResultPanelUiType.ResultStatRowData.new("Delivery Grade", __run_state.get_delivery_grade()),
		ResultPanelUiType.ResultStatRowData.new("Health", "%d" % __run_state.wagon_health),
		ResultPanelUiType.ResultStatRowData.new("Cargo", "%d" % __run_state.cargo_value),
	]


## Builds the route-progress rows for the visible result panel.
func __build_progress_stat_rows() -> Array:
	return [
		ResultPanelUiType.ResultStatRowData.new(
			"Distance traveled",
			"%.0f / %.0f" % [__run_state.get_distance_traveled(), __run_state.route_distance]
		),
		ResultPanelUiType.ResultStatRowData.new("Hazards Dodged", "%d" % __run_state.hazards_dodged),
		ResultPanelUiType.ResultStatRowData.new("Near Misses", "%d" % __run_state.near_misses),
	]


## Builds the recovery-performance rows for the visible result panel.
func __build_recovery_stat_rows() -> Array:
	return [
		ResultPanelUiType.ResultStatRowData.new(
			"Perfect Recoveries",
			"%d" % __run_state.perfect_recoveries
		),
		ResultPanelUiType.ResultStatRowData.new(
			"Recovery Failures",
			"%d" % __run_state.recovery_failures
		),
	]
