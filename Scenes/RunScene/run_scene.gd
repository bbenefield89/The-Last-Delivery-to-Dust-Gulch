extends Control

const RunStateType := preload("res://Scripts/RunState/run_state.gd")
const STEER_ACTION_NEGATIVE := "steer_left"
const STEER_ACTION_POSITIVE := "steer_right"
const STEER_SPEED := 300.0
const ROAD_HALF_WIDTH := 220.0

var _run_state: RunStateType

@onready var _playfield: Control = %Playfield
@onready var _wagon: ColorRect = %Wagon
@onready var _status_label: Label = %StatusLabel


func setup(run_state: RunStateType) -> void:
	_run_state = run_state
	_refresh_status()


func _ready() -> void:
	_ensure_input_actions()
	_update_wagon_visual()
	_refresh_status()


func _process(delta: float) -> void:
	if _run_state == null:
		return

	var steer_input := Input.get_axis(STEER_ACTION_NEGATIVE, STEER_ACTION_POSITIVE)
	_run_state.lateral_position = clamp(
		_run_state.lateral_position + steer_input * STEER_SPEED * delta,
		-ROAD_HALF_WIDTH,
		ROAD_HALF_WIDTH,
	)
	_run_state.distance_remaining = max(
		0.0,
		_run_state.distance_remaining - _run_state.current_speed * delta,
	)
	_update_wagon_visual()
	_refresh_status()


func _refresh_status() -> void:
	if _status_label == null:
		return

	if _run_state == null:
		_status_label.text = "Run scene loaded.\nAwaiting run state."
		return

	_status_label.text = "Run ready.\nDistance: %.0f\nHealth: %d\nSpeed: %.0f\nLane offset: %.0f\nResult: %s" % [
		_run_state.distance_remaining,
		_run_state.wagon_health,
		_run_state.current_speed,
		_run_state.lateral_position,
		String(_run_state.result),
	]


func _update_wagon_visual() -> void:
	if _wagon == null or _playfield == null or _run_state == null:
		return

	var playfield_size := _playfield.size
	_wagon.position = Vector2(
		(playfield_size.x * 0.5) - (_wagon.size.x * 0.5) + _run_state.lateral_position,
		playfield_size.y - 180.0,
	)


func _ensure_input_actions() -> void:
	_register_action(STEER_ACTION_NEGATIVE, [KEY_A, KEY_LEFT])
	_register_action(STEER_ACTION_POSITIVE, [KEY_D, KEY_RIGHT])


func _register_action(action_name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)
