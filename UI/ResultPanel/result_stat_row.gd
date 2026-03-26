extends HBoxContainer

## Owns one structured stat row in the run result panel.


# Private Fields: OnReady

@onready
var _stat_name_label: Label = $StatNameLabel

@onready
var _stat_value_label: Label = $StatValueLabel


# Public Methods

## Applies the supplied label/value pair to this visible result-stat row.
func set_row_data(stat_name: String, stat_value: String) -> void:
	if _stat_name_label == null:
		_stat_name_label = $StatNameLabel
	if _stat_value_label == null:
		_stat_value_label = $StatValueLabel

	_stat_name_label.text = stat_name
	_stat_value_label.text = stat_value
