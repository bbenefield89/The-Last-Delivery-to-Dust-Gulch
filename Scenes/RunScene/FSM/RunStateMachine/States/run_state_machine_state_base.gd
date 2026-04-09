extends RefCounted

## Defines the minimal typed interface for one top-level RunScene state.


# Private Fields

var __scene: Node


# Public Methods

## Binds the owning RunScene node instance or null in unit tests.
func bind(scene: Node = null) -> void:
	__scene = scene


## Returns the stable key for this state instance or an empty key when unimplemented.
func get_state_key() -> StringName:
	return &""


## Runs when the machine transitions into this state.
func enter(_previous_state_key: StringName) -> void:
	pass


## Runs when the machine transitions away from this state.
func exit(_next_state_key: StringName) -> void:
	pass


## Advances this state by one process tick.
func advance(_delta: float) -> void:
	pass


## Handles one input event while this state is active.
func handle_input(_event: InputEvent) -> void:
	pass


# Protected Methods

## Returns the bound scene for state implementations that need scene-local access.
func _get_scene() -> Node:
	return __scene
