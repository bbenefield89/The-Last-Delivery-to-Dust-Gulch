extends GutTest

const RecoverySequenceGeneratorType := preload("res://Scripts/Failures/recovery_sequence_generator.gd")


func _generate_sequence_with_seed(seed: int, progress: float, prompt_pool: Array[StringName]) -> Array[StringName]:
	var generator := RecoverySequenceGeneratorType.new()
	generator.set_seed(seed)
	return generator.generate_sequence(progress, prompt_pool)


func test_generate_sequence_when_early_progress_then_length_stays_between_three_and_four() -> void:
	var prompt_pool: Array[StringName] = [&"steer_left", &"steer_right"]
	var seen_lengths: Dictionary = {}

	for seed in range(1, 31):
		var sequence := _generate_sequence_with_seed(seed, 0.1, prompt_pool)
		assert_true(sequence.size() >= 3)
		assert_true(sequence.size() <= 4)
		seen_lengths[sequence.size()] = true

	assert_true(seen_lengths.has(3))
	assert_true(seen_lengths.has(4))


func test_generate_sequence_when_mid_progress_then_length_stays_between_four_and_five() -> void:
	var prompt_pool: Array[StringName] = [&"steer_left", &"steer_right"]
	var seen_lengths: Dictionary = {}

	for seed in range(31, 61):
		var sequence := _generate_sequence_with_seed(seed, 0.5, prompt_pool)
		assert_true(sequence.size() >= 4)
		assert_true(sequence.size() <= 5)
		seen_lengths[sequence.size()] = true

	assert_true(seen_lengths.has(4))
	assert_true(seen_lengths.has(5))


func test_generate_sequence_when_late_progress_then_length_stays_between_five_and_six() -> void:
	var prompt_pool: Array[StringName] = [&"steer_left", &"steer_right"]
	var seen_lengths: Dictionary = {}

	for seed in range(61, 101):
		var sequence := _generate_sequence_with_seed(seed, 0.9, prompt_pool)
		assert_true(sequence.size() >= 5)
		assert_true(sequence.size() <= 6)
		seen_lengths[sequence.size()] = true

	assert_true(seen_lengths.has(5))
	assert_true(seen_lengths.has(6))


func test_generate_sequence_when_pool_has_two_prompts_then_repeated_prompts_are_allowed() -> void:
	var prompt_pool: Array[StringName] = [&"steer_left", &"steer_right"]
	var found_repeat := false

	for seed in range(1, 51):
		var sequence := _generate_sequence_with_seed(seed, 0.9, prompt_pool)
		for index in range(1, sequence.size()):
			if sequence[index] == sequence[index - 1]:
				found_repeat = true
				break
		if found_repeat:
			break

	assert_true(found_repeat)
