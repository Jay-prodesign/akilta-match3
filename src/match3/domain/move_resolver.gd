class_name Match3MoveResolver
extends RefCounted

const MatchDetector = preload("res://src/match3/domain/match_detector.gd")
const ResolutionTrace = preload("res://src/match3/domain/resolution_trace.gd")
const SpecialRules = preload("res://src/match3/domain/special_rules.gd")
const ComboRules = preload("res://src/match3/domain/special_combo_rules.gd")
const WaxSeal = preload("res://src/match3/domain/blockers/wax_seal.gd")
const ObjectiveState = preload("res://src/match3/domain/objective_state.gd")
const BoardShuffler = preload("res://src/match3/domain/board_shuffler.gd")

const MAX_CASCADES := 64

static func try_swap(board, from: Vector2i, to: Vector2i):
	var trace = ResolutionTrace.new()
	var from_kind: String = String(board.get_special(from))
	var to_kind: String = String(board.get_special(to))
	var from_family: String = String(board.get_cell(from))
	var to_family: String = String(board.get_cell(to))
	if not board.is_adjacent(from, to):
		trace.add_event("swap_rejected", {
			"reason": "not_adjacent",
			"from": _pos_key(from),
			"to": _pos_key(to),
			"from_family": from_family,
			"to_family": to_family
		})
		return trace

	var before: String = String(board.signature())
	var combo_id: String = ComboRules.combo_id(from_kind, to_kind)
	var is_combo: bool = combo_id != ""
	var single_special: bool = not is_combo and (from_kind != "" or to_kind != "")

	board.swap_cells(from, to)
	var matches: Array[Vector2i] = MatchDetector.find_match_cells(board)
	if not is_combo and not single_special and matches.is_empty():
		board.swap_cells(from, to)
		trace.add_event("swap_rejected", {
			"reason": "no_match",
			"from": _pos_key(from),
			"to": _pos_key(to),
			"from_family": from_family,
			"to_family": to_family
		})
		assert(board.signature() == before)
		return trace

	trace.accepted = true
	trace.add_event("swap_accepted", {
		"from": _pos_key(from),
		"to": _pos_key(to),
		"from_family": from_family,
		"to_family": to_family,
		"from_special": from_kind,
		"to_special": to_kind
	})
	if board.moves_remaining > 0:
		board.moves_remaining -= 1

	var cascade: int = 0
	if single_special:
		cascade = 1
		var active_kind: String = from_kind if from_kind != "" else to_kind
		var active_pos: Vector2i = to if from_kind != "" else from
		var target_family: String = to_family if from_kind != "" else from_family
		var affected: Array[Vector2i] = SpecialRules.affected_cells(board, active_pos, active_kind, target_family)
		if not affected.has(active_pos):
			affected.append(active_pos)
		trace.add_event("special_triggered", {
			"cascade": cascade,
			"at": _pos_key(active_pos),
			"kind": active_kind,
			"target_family": target_family
		})
		# The swapped special has already selected its target family; do not
		# trigger it a second time using the tile family at its new position.
		board.set_special(active_pos, "")
		var expanded: Array[Vector2i] = _expand_existing_specials(board, affected, trace, cascade)
		_clear_cells(board, expanded, trace, cascade, "clear")
		_apply_gravity(board, trace, cascade)
		_refill(board, trace, cascade)
		matches = MatchDetector.find_match_cells(board)
	elif is_combo:
		cascade = 1
		var combo_cells: Array[Vector2i] = ComboRules.affected_cells(
			board,
			from,
			to,
			from_kind,
			to_kind,
			from_family,
			to_family
		)
		trace.add_event("combo_triggered", {
			"combo": combo_id,
			"from": _pos_key(from),
			"to": _pos_key(to),
			"cells": _pos_keys(combo_cells)
		})
		_clear_cells(board, combo_cells, trace, cascade, "combo_clear")
		_apply_gravity(board, trace, cascade)
		_refill(board, trace, cascade)
		matches = MatchDetector.find_match_cells(board)

	while not matches.is_empty() and cascade < MAX_CASCADES:
		cascade += 1
		trace.add_event("match_found", {"cascade": cascade, "cells": _pos_keys(matches)})
		var preferred: Array[Vector2i] = []
		if cascade == 1:
			preferred.append(to)
			preferred.append(from)
		var creation: Dictionary = {}
		if not _contains_existing_special(board, matches):
			creation = MatchDetector.plan_special_creation(board, preferred)
		var clear_cells: Array[Vector2i] = _expand_existing_specials(board, matches, trace, cascade)
		var creation_pos := Vector2i(-1, -1)
		if not creation.is_empty():
			creation_pos = creation["position"]
			clear_cells.erase(creation_pos)

		_clear_cells(board, clear_cells, trace, cascade, "clear")

		if not creation.is_empty():
			board.set_special(creation_pos, String(creation["kind"]))
			trace.add_event("special_created", {
				"cascade": cascade,
				"at": _pos_key(creation_pos),
				"kind": String(creation["kind"]),
				"family": String(creation["family"])
			})

		_apply_gravity(board, trace, cascade)
		_refill(board, trace, cascade)
		matches = MatchDetector.find_match_cells(board)

	if cascade >= MAX_CASCADES and not matches.is_empty():
		trace.add_event("resolution_guard", {"cascade": cascade})

	var pre_shuffle_result: String = ObjectiveState.evaluate(board)
	if pre_shuffle_result == "playing":
		BoardShuffler.ensure_playable(board, trace)
	trace.result = ObjectiveState.evaluate(board)
	trace.add_event("settled", {
		"cascades": cascade,
		"signature": board.signature(),
		"result": trace.result,
		"objective_remaining": ObjectiveState.remaining(board)
	})
	return trace

static func _clear_cells(board, clear_cells: Array[Vector2i], trace, cascade: int, event_type: String) -> void:
	var objective_before: int = int(board.objective_progress)
	var cleared: Array[String] = []
	var cleared_pieces: Array[Dictionary] = []
	for pos in clear_cells:
		cleared.append(_pos_key(pos))
		var cleared_family: String = String(board.get_cell(pos))
		var cleared_special: String = String(board.get_special(pos))
		cleared_pieces.append({
			"at": _pos_key(pos),
			"family": cleared_family,
			"special": cleared_special
		})
		if cleared_family != "":
			board.record_collected(cleared_family, 1)
		board.set_cell(pos, "")
		board.set_special(pos, "")

	trace.add_event(event_type, {
		"cascade": cascade,
		"cells": cleared,
		"pieces": cleared_pieces,
		"objective_progress": int(board.objective_progress),
		"objective_remaining": int(board.objective_remaining())
	})
	if int(board.objective_progress) != objective_before:
		trace.add_event("objective_progress", {
			"objective": String(board.objective_type),
			"family": String(board.objective_family),
			"before": objective_before,
			"progress": int(board.objective_progress),
			"target": int(board.objective_target),
			"remaining": int(board.objective_remaining())
		})

	for blocker_event in WaxSeal.apply_damage(board, clear_cells):
		trace.add_event(String(blocker_event.get("type", "")), blocker_event)

static func _contains_existing_special(board, cells: Array[Vector2i]) -> bool:
	for pos in cells:
		if String(board.get_special(pos)) != "":
			return true
	return false

static func _expand_existing_specials(board, initial: Array[Vector2i], trace, cascade: int) -> Array[Vector2i]:
	var pending: Array[Vector2i] = initial.duplicate()
	var included: Dictionary = {}
	var cursor := 0
	while cursor < pending.size():
		var pos := pending[cursor]
		cursor += 1
		if included.has(pos):
			continue
		included[pos] = true
		var kind: String = String(board.get_special(pos))
		if kind == "":
			continue
		trace.add_event("special_triggered", {
			"cascade": cascade,
			"at": _pos_key(pos),
			"kind": kind
		})
		for affected in SpecialRules.affected_cells(board, pos, kind):
			if not included.has(affected):
				pending.append(affected)
	var result: Array[Vector2i] = []
	for pos in included.keys():
		result.append(pos)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return result

static func _apply_gravity(board, trace, cascade: int) -> void:
	for x in range(board.width):
		var write_y: int = int(board.height) - 1
		for read_y in range(board.height - 1, -1, -1):
			var read_pos := Vector2i(x, read_y)
			if board.is_hole(read_pos):
				continue
			while write_y >= 0 and board.is_hole(Vector2i(x, write_y)):
				write_y -= 1
			if write_y < 0:
				break
			var value: String = String(board.get_cell(read_pos))
			if value != "":
				var write_pos := Vector2i(x, write_y)
				if write_pos != read_pos:
					var special: String = String(board.get_special(read_pos))
					board.set_cell(write_pos, value)
					board.set_special(write_pos, special)
					board.set_cell(read_pos, "")
					board.set_special(read_pos, "")
					trace.add_event("gravity", {
						"cascade": cascade,
						"from": _pos_key(read_pos),
						"to": _pos_key(write_pos),
						"family": value,
						"special": special
					})
				write_y -= 1

static func _refill(board, trace, cascade: int) -> void:
	for y in range(board.height):
		for x in range(board.width):
			var pos := Vector2i(x, y)
			if board.is_hole(pos) or board.get_cell(pos) != "":
				continue
			var value: String = String(board.refill_cell(pos))
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
