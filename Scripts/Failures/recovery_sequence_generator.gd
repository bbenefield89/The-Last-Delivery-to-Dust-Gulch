class_name RecoverySequenceGenerator
extends RefCounted

## Builds recovery prompt sequences from route progress and a supplied prompt pool.

const EARLY_LENGTH_WEIGHTS := [
	{"length": 3, "weight": 4},
	{"length": 4, "weight": 1},
]
const MID_LENGTH_WEIGHTS := [
	{"length": 4, "weight": 4},
	{"length": 5, "weight": 1},
]
const LATE_LENGTH_WEIGHTS := [
	{"length": 5, "weight": 4},
	{"length": 6, "weight": 1},
]

# Private Fields

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Randomizes the internal RNG for normal runtime prompt generation.
func _init() -> void:
	_rng.randomize()


## Seeds the internal RNG so generator behavior can be reproduced in tests.
func set_seed(seed: int) -> void:
	_rng.seed = seed


## Randomizes the internal RNG for normal runtime prompt generation.
func randomize() -> void:
	_rng.randomize()


## Builds a prompt sequence from progress only, allowing repeated prompts when rolled.
func generate_sequence(route_progress_ratio: float, prompt_pool: Array[StringName]) -> Array[StringName]:
	var normalized_progress := clamp(route_progress_ratio, 0.0, 1.0)
	if prompt_pool.is_empty():
		return []

	var sequence_length := _roll_sequence_length(normalized_progress)
	var sequence: Array[StringName] = []
	for index in range(sequence_length):
		sequence.append(_roll_prompt(prompt_pool))

	return sequence


## Rolls the sequence length from the active progress band's weighted options.
func _roll_sequence_length(route_progress_ratio: float) -> int:
	if route_progress_ratio < 0.33:
		return _roll_weighted_length(EARLY_LENGTH_WEIGHTS)
	if route_progress_ratio < 0.66:
		return _roll_weighted_length(MID_LENGTH_WEIGHTS)
	return _roll_weighted_length(LATE_LENGTH_WEIGHTS)


## Rolls one prompt from the supplied pool, allowing the same prompt to repeat.
func _roll_prompt(prompt_pool: Array[StringName]) -> StringName:
	var prompt_index := _rng.randi_range(0, prompt_pool.size() - 1)
	return prompt_pool[prompt_index]


## Rolls one sequence length from a weight table keyed by candidate length.
func _roll_weighted_length(length_weights: Array) -> int:
	var total_weight := 0
	for length_weight in length_weights:
		total_weight += int(length_weight["weight"])

	var roll := _rng.randi_range(1, total_weight)
	var running_total := 0
	for length_weight in length_weights:
		running_total += int(length_weight["weight"])
		if roll <= running_total:
			return int(length_weight["length"])

	return int(length_weights.back()["length"])
