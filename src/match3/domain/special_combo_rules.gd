class_name Match3SpecialComboRules
extends RefCounted

const SpecialRules = preload("res://src/match3/domain/special_rules.gd")

static func combo_id(kind_a: String, kind_b: String) -> String:
	var family_a: String = _special_family(kind_a)
	var family_b: String = _special_family(kind_b)
	if family_a == "" or family_b == "":
		return ""
	var rank := {"line": 0, "area": 1, "smart": 2, "global": 3}
	if int(rank[family_a]) > int(rank[family_b]):
		var temp := family_a
		family_a = family_b
		family_b = temp
	return "%s_%s" % [family_a, family_b]

static func affected_cells(
	board,
	origin_a: Vector2i,
	origin_b: Vector2i,
	kind_a: String,
	kind_b: String,
	family_a: String = "",
	family_b: String = ""
) -> Array[Vector2i]:
	var combo: String = combo_id(kind_a, kind_b)
	var included: Dictionary = {}
	var anchor: Vector2i = origin_b
	var line_kind: String = kind_a if _special_family(kind_a) == "line" else kind_b
	var target_family: String = family_b if kind_a == SpecialRules.GLOBAL else family_a
	if kind_a == SpecialRules.GLOBAL and kind_b == SpecialRules.GLOBAL:
		target_family = ""

	_add(included, board, origin_a)
	_add(included, board, origin_b)

	match combo:
		"line_line":
			for origin in [origin_a, origin_b]:
				_add_row(included, board, origin.y)
				_add_column(included, board, origin.x)
		"line_area":
			for offset in [-1, 0, 1]:
				_add_row(included, board, anchor.y + offset)
				_add_column(included, board, anchor.x + offset)
		"line_smart":
			for target in _useful_targets(board, 3, anchor):
				_add_directed_line(included, board, target, line_kind)
		"line_global":
			for target in _family_cells(board, target_family):
				_add_directed_line(included, board, target, line_kind)
		"area_area":
			_add_area(included, board, anchor, 2)
		"area_smart":
			for target in _useful_targets(board, 3, anchor):
				_add_area(included, board, target, 1)
		"area_global":
			for target in _family_cells(board, target_family):
				_add_area(included, board, target, 1)
		"smart_smart":
			for target in _useful_targets(board, 6, anchor):
				_add_smart_impact(included, board, target)
		"smart_global":
			var family_cells: Array[Vector2i] = _family_cells(board, target_family)
			var count: int = mini(8, maxi(1, family_cells.size()))
			for target in _useful_targets(board, count, anchor):
				_add_smart_impact(included, board, target)
		"global_global":
			for y in range(board.height):
				for x in range(board.width):
					_add(included, board, Vector2i(x, y))
		_:
			pass
	return _sorted_keys(included)

static func _special_family(kind: String) -> String:
	if kind == SpecialRules.LINE_H or kind == SpecialRules.LINE_V:
		return "line"
	if kind == SpecialRules.AREA:
		return "area"
	if kind == SpecialRules.SMART:
		return "smart"
	if kind == SpecialRules.GLOBAL:
		return "global"
	return ""

static func _add(included: Dictionary, board, pos: Vector2i) -> void:
	if board.in_bounds(pos) and not board.is_hole(pos):
		included[pos] = true

static func _add_row(included: Dictionary, board, y: int) -> void:
	if y < 0 or y >= board.height:
		return
	for x in range(board.width):
		_add(included, board, Vector2i(x, y))

static func _add_column(included: Dictionary, board, x: int) -> void:
	if x < 0 or x >= board.width:
		return
	for y in range(board.height):
		_add(included, board, Vector2i(x, y))

static func _add_directed_line(included: Dictionary, board, target: Vector2i, line_kind: String) -> void:
	if line_kind == SpecialRules.LINE_V:
		_add_column(included, board, target.x)
	else:
		_add_row(included, board, target.y)

static func _add_area(included: Dictionary, board, center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			_add(included, board, Vector2i(x, y))

static func _add_smart_impact(included: Dictionary, board, center: Vector2i) -> void:
	_add(included, board, center)
	for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_add(included, board, center + Vector2i(delta))

static func _family_cells(board, family: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if family == "":
		return result
	for y in range(board.height):
		for x in range(board.width):
			var pos := Vector2i(x, y)
			if String(board.get_cell(pos)) == family:
				result.append(pos)
	return result

static func _useful_targets(board, count: int, fallback: Vector2i) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}

	var blocker_positions: Array[Vector2i] = []
	for raw_pos in board.blockers.keys():
		blocker_positions.append(raw_pos)
	blocker_positions.sort_custom(_sort_pos)
	for pos in blocker_positions:
		_append_candidate(candidates, seen, board, pos)

	if String(board.objective_type) == "collect_family":
		for pos in _family_cells(board, String(board.objective_family)):
			_append_candidate(candidates, seen, board, pos)

	_append_candidate(candidates, seen, board, fallback)
	for y in range(board.height):
		for x in range(board.width):
			_append_candidate(candidates, seen, board, Vector2i(x, y))

	if candidates.size() > count:
		candidates.resize(count)
	return candidates

static func _append_candidate(
	candidates: Array[Vector2i],
	seen: Dictionary,
	board,
	pos: Vector2i
) -> void:
	if not board.in_bounds(pos) or board.is_hole(pos) or seen.has(pos):
		return
	seen[pos] = true
	candidates.append(pos)

static func _sorted_keys(values: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos in values.keys():
		result.append(pos)
	result.sort_custom(_sort_pos)
	return result

static func _sort_pos(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x
	return a.y < b.y
