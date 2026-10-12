class_name Match3LevelSimulator
extends RefCounted

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")
const MoveFinder = preload("res://src/match3/domain/move_finder.gd")

static func simulate(level: Dictionary, seed_value: int, scripted_moves: Array) -> Dictionary:
	var board = BoardState.from_level(level, seed_value)
	var counts: Dictionary = {}
	var accepted_moves: int = 0
	var result: String = "playing"
	var max_cascade: int = 0
	var opening_legal_moves: int = MoveFinder.legal_move_count(board)
	var playable_cells: int = board.width * board.height - board.holes.size()
	var blocker_hp_total: int = _authored_blocker_hp(level)

	for raw_move in scripted_moves:
		if not raw_move is Array or raw_move.size() != 4:
			return {
				"result": "invalid_script",
				"accepted_moves": accepted_moves,
				"event_counts": counts,
				"seed": seed_value
			}
		var from := Vector2i(int(raw_move[0]), int(raw_move[1]))
		var to := Vector2i(int(raw_move[2]), int(raw_move[3]))
		var trace = MoveResolver.try_swap(board, from, to)
		for event in trace.events:
			var event_type := String(event.get("type", ""))
			if event_type != "":
				counts[event_type] = int(counts.get(event_type, 0)) + 1
			max_cascade = maxi(max_cascade, int(event.get("cascade", 0)))
		if trace.accepted:
			accepted_moves += 1
		result = String(trace.result)
		if result == "won" or result == "failed":
			break

	return {
		"seed": seed_value,
		"result": result,
		"accepted_moves": accepted_moves,
		"authored_moves": scripted_moves.size(),
		"move_budget": int(level.get("moves", 0)),
		"moves_remaining": int(board.moves_remaining),
		"spare_moves": int(board.moves_remaining) if result == "won" else -1,
		"objective_remaining": int(board.objective_remaining()),
		"event_counts": counts,
		"max_cascade": max_cascade,
		"opening_legal_moves": opening_legal_moves,
		"playable_cells": playable_cells,
		"holes": board.holes.size(),
		"blocker_count": level.get("blockers", []).size(),
		"blocker_hp_total": blocker_hp_total,
		"special_count": level.get("specials", []).size(),
		"final_signature": String(board.signature())
	}

static func _authored_blocker_hp(level: Dictionary) -> int:
	var total := 0
	for raw_blocker in level.get("blockers", []):
		if raw_blocker is Dictionary:
			total += maxi(1, int(raw_blocker.get("hp", 1)))
	return total
