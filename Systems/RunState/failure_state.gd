extends RefCounted

## Stores the active failure metadata for the current run.


# Constants

const TYPE_WHEEL_LOOSE := &"wheel_loose"
const TYPE_HORSE_PANIC := &"horse_panic"
const TYPE_CARGO_SPILL := &"cargo_spill"
const TYPE_AXLE_JAM := &"axle_jam"


# Public Fields

var failure_type: StringName
var source_hazard: StringName
var elapsed_time: float = 0.0
var trigger_progress_ratio: float = 0.0


# Lifecycle Methods

## Builds a typed failure snapshot with its source hazard and trigger timing metadata.
func _init(
	initial_failure_type: StringName = &"",
	initial_source_hazard: StringName = &"",
	initial_trigger_progress_ratio: float = 0.0
) -> void:
	failure_type = initial_failure_type
	source_hazard = initial_source_hazard
	trigger_progress_ratio = initial_trigger_progress_ratio
