class_name Match3BoardState
extends RefCounted

const BoardRng = preload("res://src/match3/domain/board_rng.gd")

var width: int = 0
var height: int = 0
var cells: Array[String] = []
var holes: Dictionary = {}
var families: Array[String] = []
var moves_remaining: int = -1
var rng

static func from_level(level_data: Dictionary, seed_value: int):
	var board = new()
	board.width = int(level_data.get("width", 0))
	board.height = int(level_data.get("height", 0))
	board.moves_remaining = int(level_data.get("moves", -1))
	for family in level_data.get("families", []):
		board.families.append(String(family))
	for raw_hole in level_data.get("holes", []):
		if raw_hole is Array and raw_hole.size() >= 2:
			board.holes[Vector2i(int(raw_hole[0]), int(raw_hole[1]))] = true
	board.rng = BoardRng.new(seed_value)
	board.cells.resize(board.width * board.height)
	board.cells.fill("")

	var initial_rows = level_data.get("initial_rows", [])
	if initial_rows is Array and not initial_rows.is_empty():
		board._load_rows(initial_rows)
	else:
		board._generate_without_starting_matches()
	return board

func _load_rows(rows: Array) -> void:
	for y in range(min(height, rows.size())):
		var row = rows[y]
		if not row is Array:
			continue
		for x in range(min(width, row.size())):
			var pos := Vector2i(x, y)
			if is_hole(pos):
				continue
			set_cell(pos, String(row[x]))

func _generate_without_starting_matches() -> void:
	assert(not families.is_empty())
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			if is_hole(pos):
				continue
			var candidates: Array[String] = families.duplicate()
			if x >= 2:
				var left_one := get_cell(Vector2i(x - 1, y))
				var left_two := get_cell(Vector2i(x - 2, y))
				if left_one != "" and left_one == left_two:
					candidates.erase(left_one)
			if y >= 2:
				var up_one := get_cell(Vector2i(x, y - 1))
				var up_two := get_cell(Vector2i(x, y - 2))
				if up_one != "" and up_one == up_two:
					candidates.erase(up_one)
			if candidates.is_empty():
				candidates = families.duplicate()
			set_cell(pos, String(rng.choose(candidates)))

func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

func is_hole(pos: Vector2i) -> bool:
	return holes.has(pos)

func get_cell(pos: Vector2i) -> String:
	if not in_bounds(pos) or is_hole(pos):
		return ""
	return cells[pos.y * width + pos.x]

func set_cell(pos: Vector2i, value: String) -> void:
	assert(in_bounds(pos))
	if is_hole(pos):
		return
	cells[pos.y * width + pos.x] = value

func swap_cells(a: Vector2i, b: Vector2i) -> void:
	var first := get_cell(a)
	set_cell(a, get_cell(b))
	set_cell(b, first)

func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	if not in_bounds(a) or not in_bounds(b) or is_hole(a) or is_hole(b):
		return false
	var delta := (a - b).abs()
	return delta.x + delta.y == 1

func refill_cell(pos: Vector2i) -> String:
	var value := String(rng.choose(families))
	set_cell(pos, value)
	return value

func signature() -> String:
	var parts: Array[String] = []
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			parts.append("#" if is_hole(pos) else get_cell(pos))
	return "|".join(parts)
