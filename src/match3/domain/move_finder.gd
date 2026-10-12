class_name Match3MoveFinder
extends RefCounted

const MatchDetector = preload("res://src/match3/domain/match_detector.gd")

static func has_legal_move(board) -> bool:
	return not first_legal_move(board).is_empty()

static func first_legal_move(board) -> Dictionary:
	for y in range(board.height):
		for x in range(board.width):
			var from := Vector2i(x, y)
			if board.is_hole(from):
				continue
			for delta in [Vector2i.RIGHT, Vector2i.DOWN]:
				var to: Vector2i = from + delta
				if not board.in_bounds(to) or board.is_hole(to):
					continue
				if _is_legal_swap(board, from, to):
					return {"from": from, "to": to}
	return {}

static func legal_move_count(board) -> int:
	var count := 0
	for y in range(board.height):
		for x in range(board.width):
			var from := Vector2i(x, y)
			if board.is_hole(from):
				continue
			for delta in [Vector2i.RIGHT, Vector2i.DOWN]:
				var to: Vector2i = from + delta
				if not board.in_bounds(to) or board.is_hole(to):
					continue
				if _is_legal_swap(board, from, to):
					count += 1
	return count

static func _is_legal_swap(board, from: Vector2i, to: Vector2i) -> bool:
	var first_special: String = String(board.get_special(from))
	var second_special: String = String(board.get_special(to))
	board.swap_cells(from, to)
	var legal: bool = (first_special != "" and second_special != "") or not MatchDetector.find_match_cells(board).is_empty()
	board.swap_cells(from, to)
	return legal
