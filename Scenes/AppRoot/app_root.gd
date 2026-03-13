extends Node

const RUN_SCENE := preload("res://Scenes/RunScene/RunScene.tscn")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")
const RESTART_ACTION := "restart_run"

@export var starting_distance: float = 500.0

var run_state: RunStateType
var _run_scene: Node


func _ready() -> void:
	_ensure_restart_action()
	_start_new_run()


func _unhandled_input(event: InputEvent) -> void:
	if run_state == null:
		return
	if run_state.result == RunStateType.RESULT_IN_PROGRESS:
		return
	if event.is_action_pressed(RESTART_ACTION):
		_start_new_run()


func _start_new_run() -> void:
	if is_instance_valid(_run_scene):
		_run_scene.queue_free()

	run_state = RunStateType.new()
	run_state.configure_route_distance(starting_distance)
	_run_scene = RUN_SCENE.instantiate()
	add_child(_run_scene)
	if _run_scene.has_method("setup"):
		_run_scene.setup(run_state)


func _ensure_restart_action() -> void:
	if not InputMap.has_action(RESTART_ACTION):
		InputMap.add_action(RESTART_ACTION)

	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	if not InputMap.action_has_event(RESTART_ACTION, event):
		InputMap.action_add_event(RESTART_ACTION, event)
