class_name Match3BoardRng
extends RefCounted

var _rng: RandomNumberGenerator

func _init(seed_value: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

func next_index(size: int) -> int:
	assert(size > 0)
	return _rng.randi_range(0, size - 1)

func choose(values: Array) -> Variant:
	assert(not values.is_empty())
	return values[next_index(values.size())]
