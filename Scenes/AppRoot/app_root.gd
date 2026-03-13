extends Node

const RUN_SCENE := preload("res://Scenes/RunScene/RunScene.tscn")
const RunStateType := preload("res://Scripts/RunState/run_state.gd")

@export var starting_distance: float = 500.0

var run_state: RunStateType
var _run_scene: Node


func _ready() -> void:
	run_state = RunStateType.new()
	run_state.configure_route_distance(starting_distance)
	_run_scene = RUN_SCENE.instantiate()
	add_child(_run_scene)
	if _run_scene.has_method("setup"):
		_run_scene.setup(run_state)
