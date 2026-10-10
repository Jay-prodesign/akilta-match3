class_name Match3MoveResolver
extends RefCounted

const MatchDetector = preload("res://src/match3/domain/match_detector.gd")
const ResolutionTrace = preload("res://src/match3/domain/resolution_trace.gd")

const MAX_CASCADES := 64

static func try_swap(board, from: Vector2i, to: Vector2i):
	var trace = ResolutionTrace.new()
	if not board.is_adjacent(from, to):
		trace.add_event("swap_rejected", {"reason": "not_adjacent"})
		return trace

	var before: String = String(board.signature())
	board.swap_cells(from, to)
	var matches := MatchDetector.find_match_cells(board)
	if matches.is_empty():
		board.swap_cells(from, to)
		trace.add_event("swap_rejected", {"reason": "no_match"})
		assert(board.signature() == before)
		return trace

	trace.accepted = true
	trace.add_event("swap_accepted", {"from": _pos_key(from), "to": _pos_key(to)})
	if board.moves_remaining > 0:
		board.moves_remaining -= 1

	var cascade := 0
	while not matches.is_empty() and cascade < MAX_CASCADES:
		cascade += 1
		trace.add_event("match_found", {"cascade": cascade, "cells": _pos_keys(matches)})
		var cleared: Array[String] = []
		for pos in matches:
			cleared.append(_pos_key(pos))
			board.set_cell(pos, "")
		trace.add_event("clear", {"cascade": cascade, "cells": cleared})

		_apply_gravity(board, trace, cascade)
		_refill(board, trace, cascade)
		matches = MatchDetector.find_match_cells(board)

	if cascade >= MAX_CASCADES and not matches.is_empty():
		trace.add_event("resolution_guard", {"cascade": cascade})

	trace.add_event("settled", {"cascades": cascade, "signature": board.signature()})
	return trace

static func _apply_gravity(board, trace, cascade: int) -> void:
	for x in range(board.width):
		var write_y := board.height - 1
		for read_y in range(board.height - 1, -1, -1):
			var read_pos := Vector2i(x, read_y)
			if board.is_hole(read_pos):
				continue
			while write_y >= 0 and board.is_hole(Vector2i(x, write_y)):
				write_y -= 1
			if write_y < 0:
				break
			var value := board.get_cell(read_pos)
			if value != "":
				var write_pos := Vector2i(x, write_y)
				if write_pos != read_pos:
					board.set_cell(write_pos, value)
					board.set_cell(read_pos, "")
					trace.add_event("gravity", {
						"cascade": cascade,
						"from": _pos_key(read_pos),
						"to": _pos_key(write_pos)
					})
				write_y -= 1

static func _refill(board, trace, cascade: int) -> void:
	for y in range(board.height):
		for x in range(board.width):
			var pos := Vector2i(x, y)
			if board.is_hole(pos) or board.get_cell(pos) != "":
				continue
			var value := board.refill_cell(pos)
			trace.add_event("spawn", {
				"cascade": cascade,
				"at": _pos_key(pos),
				"family": value
			})

static func _pos_keys(positions: Array[Vector2i]) -> Array[String]:
	var result: Array[String] = []
	for pos in positions:
		result.append(_pos_key(pos))
	return result

static func _pos_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]
