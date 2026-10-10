class_name Match3ObjectiveState
extends RefCounted

static func evaluate(board) -> String:
	if board.objective_type == "clear_blockers" and board.remaining_blockers() == 0:
		return "won"
	if board.objective_type == "collect_family" and board.objective_target > 0 and board.objective_progress >= board.objective_target:
		return "won"
	if board.moves_remaining == 0:
		return "failed"
	return "playing"

static func remaining(board) -> int:
	return int(board.objective_remaining())
