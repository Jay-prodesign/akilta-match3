class_name Match3BoardState
extends RefCounted

const BoardRng = preload("res://src/match3/domain/board_rng.gd")

var width: int = 0
var height: int = 0
var cells: Array[String] = []
var holes: Dictionary = {}
var families: Array[String] = []
var moves_remaining: int = -1
var objective_type: String = ""
var objective_family: String = ""
var objective_target: int = 0
var objective_progress: int = 0
var specials: Dictionary = {}
var blockers: Dictionary = {}
var rng

static func from_level(level_data: Dictionary, seed_value: int):
	var board = new()
	board.width = int(level_data.get("width", 0))
	board.height = int(level_data.get("height", 0))
	board.moves_remaining = int(level_data.get("moves", -1))
	board.objective_type = String(level_data.get("objective", ""))
	board.objective_family = String(level_data.get("objective_family", ""))
	board.objective_target = int(level_data.get("objective_target", 0))
	board.objective_progress = int(level_data.get("objective_progress", 0))
	for family in level_data.get("families", []):
		board.families.append(String(family))
	for raw_hole in level_data.get("holes", []):
		if raw_hole is Array and raw_hole.size() >= 2:
			board.holes[Vector2i(int(raw_hole[0]), int(raw_hole[1]))] = true
	board.rng = BoardRng.new(seed_value)
	board.cells.resize(board.width * board.height)
	board.cells.fill("")

	for raw_special in level_data.get("specials", []):
		if raw_special is Dictionary:
			var special_pos := Vector2i(int(raw_special.get("x", -1)), int(raw_special.get("y", -1)))
			if board.in_bounds(special_pos) and not board.is_hole(special_pos):
				board.specials[special_pos] = String(raw_special.get("kind", ""))

	for raw_blocker in level_data.get("blockers", []):
		if raw_blocker is Dictionary:
			var blocker_pos := Vector2i(int(raw_blocker.get("x", -1)), int(raw_blocker.get("y", -1)))
			if board.in_bounds(blocker_pos) and not board.is_hole(blocker_pos):
				var blocker_hp: int = maxi(1, int(raw_blocker.get("hp", 1)))
				board.blockers[blocker_pos] = {
					"type": String(raw_blocker.get("type", "wax_seal")),
					"hp": blocker_hp,
					"max_hp": blocker_hp
				}

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
			if x >= 1 and y >= 1:
				var left := get_cell(Vector2i(x - 1, y))
				var up := get_cell(Vector2i(x, y - 1))
				var diagonal := get_cell(Vector2i(x - 1, y - 1))
				if left != "" and left == up and up == diagonal:
					candidates.erase(left)
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
	var first: String = get_cell(a)
	var second: String = get_cell(b)
	var first_special: String = get_special(a)
	var second_special: String = get_special(b)
	set_cell(a, second)
	set_cell(b, first)
	set_special(a, second_special)
	set_special(b, first_special)

func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	if not in_bounds(a) or not in_bounds(b) or is_hole(a) or is_hole(b):
		return false
	var delta := (a - b).abs()
	return delta.x + delta.y == 1

func refill_cell(pos: Vector2i) -> String:
	var value := String(rng.choose(families))
	set_cell(pos, value)
	return value

func get_special(pos: Vector2i) -> String:
	return String(specials.get(pos, ""))

func set_special(pos: Vector2i, kind: String) -> void:
	if kind == "":
		specials.erase(pos)
	else:
		specials[pos] = kind

func get_blocker(pos: Vector2i) -> Dictionary:
	return blockers.get(pos, {}).duplicate(true)

func set_blocker_hp(pos: Vector2i, hp: int) -> void:
	if not blockers.has(pos):
		return
	if hp <= 0:
		blockers.erase(pos)
		return
	var state: Dictionary = blockers[pos]
	state["hp"] = hp
	blockers[pos] = state

func remaining_blockers() -> int:
	return blockers.size()

func record_collected(family: String, count: int = 1) -> void:
	if objective_type == "collect_family" and family == objective_family:
		objective_progress = min(objective_target, objective_progress + max(0, count))

func objective_remaining() -> int:
	if objective_type == "collect_family":
		return max(0, objective_target - objective_progress)
	if objective_type == "clear_blockers":
		return remaining_blockers()
	return 0

func has_empty() -> bool:
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			if not is_hole(pos) and get_cell(pos) == "":
				return true
	return false

func signature() -> String:
	var parts: Array[String] = []
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			if is_hole(pos):
				parts.append("#")
				continue
			var token := get_cell(pos)
			var special := get_special(pos)
			if special != "":
				token += "@%s" % special
			if blockers.has(pos):
				var blocker: Dictionary = blockers[pos]
				token += "!%s:%d" % [String(blocker.get("type", "")), int(blocker.get("hp", 0))]
			parts.append(token)
	return "|".join(parts) + "|objective=%s:%s:%d/%d|moves=%d" % [
		objective_type,
		objective_family,
		objective_progress,
		objective_target,
		moves_remaining
	]
