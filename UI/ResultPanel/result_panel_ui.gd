extends PanelContainer

## Owns the run result panel title, summary, and structured stat rows.


# Constants
const ResultStatRowType := preload(ProjectPaths.RESULT_STAT_ROW_SCRIPT_PATH)
const RESULT_STAT_ROW_SCENE := preload(ProjectPaths.RESULT_STAT_ROW_SCENE_PATH)


const EDITOR_PREVIEW_RESULT_TITLE := "Delivered to Dust Gulch"
const EDITOR_PREVIEW_RESULT_SUMMARY := "New Best Run! | Best Score: 1565 | Best Grade: A"


# Private Fields: OnReady

@onready
var _title_label: Label = $ResultPadding/ResultVBox/ResultTitle

@onready
var _summary_label: Label = $ResultPadding/ResultVBox/ResultSummary

@onready
var _stats_scroll: ScrollContainer = $ResultPadding/ResultVBox/ResultStatsScroll

@onready
var _stats_rows: VBoxContainer = $ResultPadding/ResultVBox/ResultStatsScroll/ResultStatsRows


# Public Methods

## Replaces the current result panel contents with the supplied title, summary, and structured stat rows.
func set_result_data(title: String, summary: String, stat_rows: Array) -> void:
	_title_label.text = title
	_summary_label.text = summary
	_summary_label.visible = not summary.is_empty()
	_rebuild_stat_rows(stat_rows)
	_reset_stats_scroll_position()


## Clears all structured stat rows from the current panel.
func clear_result_data() -> void:
	_title_label.text = ""
	_summary_label.text = ""
	_summary_label.visible = false
	_rebuild_stat_rows([])
	_reset_stats_scroll_position()


## Populates the panel with representative dummy data while editing the scene in Godot.
func show_editor_preview() -> void:
	set_result_data(
		EDITOR_PREVIEW_RESULT_TITLE,
		EDITOR_PREVIEW_RESULT_SUMMARY,
		_build_editor_preview_rows()
	)


# Private Methods

## Rebuilds the visible stat-row children using the supplied structured result data.
func _rebuild_stat_rows(stat_rows: Array) -> void:
	for child in _stats_rows.get_children():
		child.free()

	for stat_row_data_variant in stat_rows:
		var stat_row_data := stat_row_data_variant as ResultStatRowData
		if stat_row_data == null:
			continue

		var stat_row := RESULT_STAT_ROW_SCENE.instantiate() as ResultStatRowType
		if stat_row == null:
			continue

		_stats_rows.add_child(stat_row)
		stat_row.set_row_data(stat_row_data.label, stat_row_data.value)


## Builds the representative editor-preview stat rows for the result panel.
func _build_editor_preview_rows() -> Array:
	return [
		ResultStatRowData.new("Score", "1565"),
		ResultStatRowData.new("Delivery Grade", "A"),
		ResultStatRowData.new("Health", "54"),
		ResultStatRowData.new("Cargo", "88"),
		ResultStatRowData.new("Distance traveled", "500 / 500"),
		ResultStatRowData.new("Hazards Dodged", "12"),
		ResultStatRowData.new("Near Misses", "4"),
		ResultStatRowData.new("Perfect Recoveries", "3"),
		ResultStatRowData.new("Recovery Failures", "2"),
	]


## Returns the stat-list scroll position to the top whenever result content is refreshed.
func _reset_stats_scroll_position() -> void:
	if _stats_scroll == null:
		return

	_stats_scroll.scroll_horizontal = 0
	_stats_scroll.scroll_vertical = 0


# Inner Classes

class ResultStatRowData:
	extends RefCounted
	## Stores one visible result-stat label/value pair for structured panel rendering.

	var label: String
	var value: String


	## Stores the formatted label and value strings for one result-stat row.
	func _init(label_text: String, value_text: String) -> void:
		label = label_text
		value = value_text
