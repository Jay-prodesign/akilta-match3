class_name Match3ObjectiveState
extends RefCounted

static func evaluate(board) -> String:
	if board.objective_type == "clear_blockers" and board.remaining_blockers() == 0:
		return "won"
	if board.moves_remaining == 0:
		return "failed"
	return "playing"

static func remaining(board) -> int:
	if board.objective_type == "clear_blockers":
		return board.remaining_blockers()
	return 0
