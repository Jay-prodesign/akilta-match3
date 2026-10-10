class_name Match3MatchDetector
extends RefCounted

const SpecialRules = preload("res://src/match3/domain/special_rules.gd")

static func find_runs(board) -> Array[Dictionary]:
	var runs: Array[Dictionary] = []

	for y in range(board.height):
		var run_value := ""
		var run_start := 0
		var run_length := 0
		for x in range(board.width + 1):
			var value := ""
			if x < board.width:
				value = board.get_cell(Vector2i(x, y))
			if value != "" and value == run_value:
				run_length += 1
			else:
				if run_value != "" and run_length >= 3:
					var cells: Array[Vector2i] = []
					for rx in range(run_start, run_start + run_length):
						cells.append(Vector2i(rx, y))
					runs.append({"family": run_value, "orientation": "horizontal", "cells": cells})
				run_value = value
				run_start = x
				run_length = 1 if value != "" else 0

	for x in range(board.width):
		var run_value := ""
		var run_start := 0
		var run_length := 0
		for y in range(board.height + 1):
			var value := ""
			if y < board.height:
				value = board.get_cell(Vector2i(x, y))
			if value != "" and value == run_value:
				run_length += 1
			else:
				if run_value != "" and run_length >= 3:
					var cells: Array[Vector2i] = []
					for ry in range(run_start, run_start + run_length):
						cells.append(Vector2i(x, ry))
					runs.append({"family": run_value, "orientation": "vertical", "cells": cells})
				run_value = value
				run_start = y
				run_length = 1 if value != "" else 0
	return runs

static func find_squares(board) -> Array[Dictionary]:
	var squares: Array[Dictionary] = []
	for y in range(board.height - 1):
		for x in range(board.width - 1):
			var origin := Vector2i(x, y)
			var family: String = String(board.get_cell(origin))
			if family == "":
				continue
			var cells: Array[Vector2i] = [
				origin,
				Vector2i(x + 1, y),
				Vector2i(x, y + 1),
				Vector2i(x + 1, y + 1)
			]
			var same := true
			for pos in cells:
				if board.get_cell(pos) != family:
					same = false
					break
			if same:
				squares.append({"family": family, "shape": "square", "cells": cells})
	return squares

static func find_match_cells(board) -> Array[Vector2i]:
	var matched: Dictionary = {}
	for run in find_runs(board):
		for pos in run["cells"]:
			matched[pos] = true
	for square in find_squares(board):
		for pos in square["cells"]:
			matched[pos] = true
	return _sorted_keys(matched)

static func plan_special_creation(board, preferred: Array[Vector2i] = []) -> Dictionary:
	var runs: Array[Dictionary] = find_runs(board)
	var area_candidates: Array[Dictionary] = []
	for a in runs:
		for b in runs:
			if String(a["orientation"]) == String(b["orientation"]):
				continue
			if String(a["family"]) != String(b["family"]):
				continue
			var intersection := Vector2i(-1, -1)
			for pos in a["cells"]:
				if b["cells"].has(pos):
					intersection = pos
					break
			if intersection.x < 0:
				continue
			var combined: Dictionary = {}
			for pos in a["cells"]:
				combined[pos] = true
			for pos in b["cells"]:
				combined[pos] = true
			area_candidates.append({
				"kind": SpecialRules.AREA,
				"family": String(a["family"]),
				"position": intersection,
				"cells": _sorted_keys(combined)
			})
	var picked: Dictionary = _pick_candidate(area_candidates, preferred)
	if not picked.is_empty():
		return picked

	var global_candidates: Array[Dictionary] = []
	for run in runs:
		var cells: Array = run["cells"]
		if cells.size() >= 5:
			global_candidates.append({
				"kind": SpecialRules.GLOBAL,
				"family": String(run["family"]),
				"position": _preferred_or_middle(cells, preferred),
				"cells": cells.duplicate()
			})
	picked = _pick_candidate(global_candidates, preferred)
	if not picked.is_empty():
		return picked

	var smart_candidates: Array[Dictionary] = []
	for square in find_squares(board):
		var cells: Array = square["cells"]
		smart_candidates.append({
			"kind": SpecialRules.SMART,
			"family": String(square["family"]),
			"position": _preferred_or_middle(cells, preferred),
			"cells": cells.duplicate()
		})
	picked = _pick_candidate(smart_candidates, preferred)
	if not picked.is_empty():
		return picked

	var line_candidates: Array[Dictionary] = []
	for run in runs:
		var cells: Array = run["cells"]
		if cells.size() == 4:
			var orientation: String = String(run["orientation"])
			line_candidates.append({
				"kind": SpecialRules.LINE_V if orientation == "vertical" else SpecialRules.LINE_H,
				"family": String(run["family"]),
				"position": _preferred_or_middle(cells, preferred),
				"cells": cells.duplicate()
			})
	return _pick_candidate(line_candidates, preferred)

static func _pick_candidate(candidates: Array[Dictionary], preferred: Array[Vector2i]) -> Dictionary:
	if candidates.is_empty():
		return {}
	for preferred_pos in preferred:
		for candidate in candidates:
			if candidate["cells"].has(preferred_pos):
				candidate["position"] = preferred_pos
				return candidate
	return candidates[0]

static func _preferred_or_middle(cells: Array, preferred: Array[Vector2i]) -> Vector2i:
	for preferred_pos in preferred:
		if cells.has(preferred_pos):
			return preferred_pos
	return cells[int(cells.size() / 2)]

static func _sorted_keys(values: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos in values.keys():
		result.append(pos)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return result
