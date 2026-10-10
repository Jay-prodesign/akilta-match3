class_name Match3BoardShuffler
extends RefCounted

const MatchDetector = preload("res://src/match3/domain/match_detector.gd")
const MoveFinder = preload("res://src/match3/domain/move_finder.gd")

const MAX_ATTEMPTS := 128

static func ensure_playable(board, trace = null) -> bool:
	if MoveFinder.has_legal_move(board):
		return false

	var positions: Array[Vector2i] = []
	var original: Array[Dictionary] = []
	for y in range(board.height):
		for x in range(board.width):
			var pos := Vector2i(x, y)
			if board.is_hole(pos):
				continue
			positions.append(pos)
			original.append({
				"family": String(board.get_cell(pos)),
				"special": String(board.get_special(pos))
			})

	for attempt in range(1, MAX_ATTEMPTS + 1):
		var shuffled: Array[Dictionary] = original.duplicate(true)
		for i in range(shuffled.size() - 1, 0, -1):
			var j: int = board.rng.next_index(i + 1)
			var temp: Dictionary = shuffled[i]
			shuffled[i] = shuffled[j]
			shuffled[j] = temp
		_apply_tokens(board, positions, shuffled)
		if MatchDetector.find_match_cells(board).is_empty() and MoveFinder.has_legal_move(board):
			if trace != null:
				trace.add_event("shuffle", {"attempt": attempt, "signature": board.signature()})
			return true

	_apply_tokens(board, positions, original)
	return false

static func _apply_tokens(board, positions: Array[Vector2i], tokens: Array[Dictionary]) -> void:
	for i in range(positions.size()):
		var token: Dictionary = tokens[i]
		board.set_cell(positions[i], String(token.get("family", "")))
		board.set_special(positions[i], String(token.get("special", "")))
