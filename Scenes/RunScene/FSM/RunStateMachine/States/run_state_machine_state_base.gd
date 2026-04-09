extends RefCounted

## Defines the minimal typed interface for one top-level RunScene state.


# Protected Fields

var _scene: Node
var _state_key: StringName = &""


# Public Methods

## Binds the owning RunScene node instance (or null in unit tests) and the registered state key.
func bind(scene: Node = null, state_key: StringName = &"") -> void:
	_scene = scene
	_state_key = state_key


## Returns the registered key for this state instance.
func get_state_key() -> StringName:
	return _state_key


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
	return _scene
