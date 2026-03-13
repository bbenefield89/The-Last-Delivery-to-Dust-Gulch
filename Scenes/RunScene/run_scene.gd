extends Control

const RunStateType := preload("res://Scripts/RunState/run_state.gd")

var _run_state: RunStateType

@onready var _status_label: Label = %StatusLabel


func setup(run_state: RunStateType) -> void:
	_run_state = run_state
	_refresh_status()


func _ready() -> void:
	_refresh_status()


func _refresh_status() -> void:
	if _status_label == null:
		return

	if _run_state == null:
		_status_label.text = "Run scene loaded.\nAwaiting run state."
		return

	_status_label.text = "Run ready.\nDistance: %.0f\nHealth: %d\nResult: %s" % [
		_run_state.distance_remaining,
		_run_state.wagon_health,
		String(_run_state.result),
	]
