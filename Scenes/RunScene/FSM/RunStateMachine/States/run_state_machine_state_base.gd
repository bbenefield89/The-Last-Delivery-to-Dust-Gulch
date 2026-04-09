@abstract
class_name RunStateMachineStateBase
extends RefCounted

## Defines the minimal typed interface for one top-level RunScene state.


# Imports

const RunStateMachineKeyType := preload(ProjectPaths.RUN_STATE_MACHINE_KEY_SCRIPT_PATH)


# Private Fields

var __scene: Node


# Public Methods

## Binds the owning RunScene node instance or null in unit tests.
func bind(scene: Node = null) -> void:
	__scene = scene


## Returns this state's enum key; derived states must override this and return their owned non-NONE key.
func get_state_key() -> int:
	return RunStateMachineKeyType.Key.NONE


## Handles transition entry; derived states should override this when they need entry behavior.
func enter(_previous_state_key: int) -> void:
	pass


## Handles transition exit; derived states should override this when they need exit behavior.
func exit(_next_state_key: int) -> void:
	pass


## Advances this state by one process tick; derived states should override this when they own process behavior.
func advance(_delta: float) -> void:
	pass


## Handles one input event while this state is active; derived states should override this when they own input behavior.
func handle_input(_event: InputEvent) -> void:
	pass


# Protected Methods

## Returns the bound scene for state implementations that need scene-local access.
func _get_scene() -> Node:
	return __scene
