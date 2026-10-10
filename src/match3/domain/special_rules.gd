class_name Match3SpecialRules
extends RefCounted

const LINE_H := "line_h"
const LINE_V := "line_v"
const AREA := "area"
const SMART := "smart"
const GLOBAL := "global"

static func kind_for_pattern(orientation: String, size: int, shape: String = "") -> String:
	if shape == "square":
		return SMART
	if shape == "t" or shape == "l":
		return AREA
	if size >= 5:
		return GLOBAL
	if size == 4:
		return LINE_V if orientation == "vertical" else LINE_H
	return ""

static func affected_cells(board, origin: Vector2i, kind: String, target_family: String = "") -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	match kind:
		LINE_H:
			for x in range(board.width):
				_append_if_playable(board, result, Vector2i(x, origin.y))
		LINE_V:
			for y in range(board.height):
				_append_if_playable(board, result, Vector2i(origin.x, y))
		AREA:
			for y in range(origin.y - 1, origin.y + 2):
				for x in range(origin.x - 1, origin.x + 2):
					_append_if_playable(board, result, Vector2i(x, y))
		SMART:
			var target := _smart_target(board, origin)
			_append_if_playable(board, result, target)
			for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				_append_if_playable(board, result, target + delta)
		GLOBAL:
			var family := target_family
			if family == "":
				family = board.get_cell(origin)
			if family != "":
				for y in range(board.height):
					for x in range(board.width):
						var pos := Vector2i(x, y)
						if board.get_cell(pos) == family:
							result.append(pos)
	return _sorted_unique(result)

static func _smart_target(board, fallback: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for raw_pos in board.blockers.keys():
		candidates.append(raw_pos)
	if not candidates.is_empty():
		candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			if a.y == b.y:
				return a.x < b.x
			return a.y < b.y
		)
		return candidates[0]
	return fallback

static func _append_if_playable(board, result: Array[Vector2i], pos: Vector2i) -> void:
	if board.in_bounds(pos) and not board.is_hole(pos):
		result.append(pos)

static func _sorted_unique(values: Array[Vector2i]) -> Array[Vector2i]:
	var seen: Dictionary = {}
	for pos in values:
		seen[pos] = true
	var result: Array[Vector2i] = []
	for pos in seen.keys():
		result.append(pos)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return result
