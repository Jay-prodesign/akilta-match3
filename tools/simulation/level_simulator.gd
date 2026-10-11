class_name Match3LevelSimulator
extends RefCounted

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")

static func simulate(level: Dictionary, seed_value: int, scripted_moves: Array) -> Dictionary:
	var board = BoardState.from_level(level, seed_value)
	var counts: Dictionary = {}
	var accepted_moves: int = 0
	var result: String = "playing"

	for raw_move in scripted_moves:
		if not raw_move is Array or raw_move.size() != 4:
			return {"result": "invalid_script", "accepted_moves": accepted_moves, "event_counts": counts}
		var from := Vector2i(int(raw_move[0]), int(raw_move[1]))
		var to := Vector2i(int(raw_move[2]), int(raw_move[3]))
		var trace = MoveResolver.try_swap(board, from, to)
		for event_type in trace.event_types():
			var key: String = String(event_type)
			counts[key] = int(counts.get(key, 0)) + 1
		if trace.accepted:
			accepted_moves += 1
		result = String(trace.result)
		if result == "won" or result == "failed":
			break

	return {
		"result": result,
		"accepted_moves": accepted_moves,
		"event_counts": counts,
		"objective_remaining": int(board.objective_remaining()),
		"moves_remaining": int(board.moves_remaining),
		"final_signature": String(board.signature())
	}
