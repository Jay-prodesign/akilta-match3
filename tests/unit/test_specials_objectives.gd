extends SceneTree

const BoardState = preload("res://src/match3/domain/board_state.gd")
const SpecialRules = preload("res://src/match3/domain/special_rules.gd")
const WaxSeal = preload("res://src/match3/domain/blockers/wax_seal.gd")
const ObjectiveState = preload("res://src/match3/domain/objective_state.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_creation_grammar()
	_test_special_footprints()
	_test_wax_seal_damage()
	_test_objective_results()
	_test_move_resolution_updates_blocker_objective()
	_test_collect_family_objective_from_resolution()

	if failures.is_empty():
		print("TEST_PASS: specials blockers objectives")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _level() -> Dictionary:
	return {
		"width": 5,
		"height": 5,
		"moves": 8,
		"families": ["moon", "rose", "moth", "key", "leaf"],
		"initial_rows": [
			["moon", "rose", "moth", "key", "leaf"],
			["rose", "moth", "key", "leaf", "moon"],
			["moth", "key", "leaf", "moon", "rose"],
			["key", "leaf", "moon", "rose", "moth"],
			["leaf", "moon", "rose", "moth", "key"]
		]
	}

func _test_creation_grammar() -> void:
	_expect(SpecialRules.kind_for_pattern("horizontal", 4) == "line_h", "four horizontal must map to horizontal line special")
	_expect(SpecialRules.kind_for_pattern("vertical", 4) == "line_v", "four vertical must map to vertical line special")
	_expect(SpecialRules.kind_for_pattern("horizontal", 5) == "global", "five straight must map to global special")
	_expect(SpecialRules.kind_for_pattern("horizontal", 5, "t") == "area", "T/L shape must map to area special")
	_expect(SpecialRules.kind_for_pattern("horizontal", 4, "square") == "smart", "square contract must map to smart special")

func _test_special_footprints() -> void:
	var board = BoardState.from_level(_level(), 11)
	var center := Vector2i(2, 2)
	_expect(SpecialRules.affected_cells(board, center, "line_h").size() == 5, "line_h must cover full row")
	_expect(SpecialRules.affected_cells(board, center, "line_v").size() == 5, "line_v must cover full column")
	_expect(SpecialRules.affected_cells(board, center, "area").size() == 9, "area must cover 3x3 center footprint")
	var global_cells: Array[Vector2i] = SpecialRules.affected_cells(board, center, "global", "moon")
	_expect(global_cells.size() == 5, "global special must target all pieces of selected family")

func _test_wax_seal_damage() -> void:
	var level := _level()
	level["blockers"] = [{"x": 2, "y": 2, "type": "wax_seal", "hp": 2}]
	var board = BoardState.from_level(level, 12)
	var hit: Array[Vector2i] = [Vector2i(2, 1)]
	var first: Array[Dictionary] = WaxSeal.apply_damage(board, hit)
	_expect(first.size() == 1, "adjacent clear must damage Wax Seal once")
	var damaged_seal: Dictionary = board.get_blocker(Vector2i(2, 2))
	_expect(int(damaged_seal.get("hp", 0)) == 1, "Wax Seal hp must decrement")
	_expect(int(damaged_seal.get("max_hp", 0)) == 2, "Wax Seal must preserve authored max hp for cracked-state presentation")
	var second: Array[Dictionary] = WaxSeal.apply_damage(board, hit)
	_expect(second.size() == 1, "second adjacent clear must resolve Wax Seal")
	_expect(board.remaining_blockers() == 0, "Wax Seal must clear at zero hp")

func _test_objective_results() -> void:
	var level := _level()
	level["objective"] = "clear_blockers"
	level["blockers"] = [{"x": 2, "y": 2, "type": "wax_seal", "hp": 1}]
	var board = BoardState.from_level(level, 13)
	_expect(ObjectiveState.evaluate(board) == "playing", "blocker objective with blocker remaining must be playing")
	board.set_blocker_hp(Vector2i(2, 2), 0)
	_expect(ObjectiveState.evaluate(board) == "won", "clearing final blocker must win")
	level["moves"] = 0
	level["blockers"] = [{"x": 1, "y": 1, "type": "wax_seal", "hp": 1}]
	board = BoardState.from_level(level, 14)
	_expect(ObjectiveState.evaluate(board) == "failed", "zero moves with incomplete objective must fail")

func _test_move_resolution_updates_blocker_objective() -> void:
	var board = BoardState.from_level({
		"width": 3,
		"height": 3,
		"moves": 1,
		"objective": "clear_blockers",
		"families": ["moon", "rose", "moth", "key", "leaf"],
		"blockers": [{"x": 1, "y": 1, "type": "wax_seal", "hp": 1}],
		"initial_rows": [
			["moth", "key", "leaf"],
			["rose", "moon", "rose"],
			["moon", "rose", "moon"]
		]
	}, 8080)
	var trace = MoveResolver.try_swap(board, Vector2i(1, 1), Vector2i(1, 2))
	_expect(trace.accepted, "objective fixture swap must be accepted")
	_expect(board.remaining_blockers() == 0, "bottom-row match must damage adjacent Wax Seal")
	_expect(trace.result == "won", "clearing final blocker during resolution must win")
	_expect(trace.event_types().has("blocker_cleared"), "trace must expose blocker clear")


func _test_collect_family_objective_from_resolution() -> void:
	var board = BoardState.from_level({
		"width": 3,
		"height": 3,
		"moves": 3,
		"objective": "collect_family",
		"objective_family": "moon",
		"objective_target": 3,
		"families": ["moon", "rose", "moth", "key", "leaf"],
		"initial_rows": [
			["moth", "key", "leaf"],
			["rose", "moon", "rose"],
			["moon", "rose", "moon"]
		]
	}, 8080)
	_expect(str(board.get("objective_family")) == "moon", "collect objective family must load from level data")
	_expect(int(board.get("objective_target")) == 3, "collect objective target must load from level data")
	_expect(int(board.get("objective_progress")) == 0, "collect objective starts at zero progress")
	var trace = MoveResolver.try_swap(board, Vector2i(1, 1), Vector2i(1, 2))
	_expect(trace.accepted, "collect objective fixture swap must be accepted")
	_expect(int(board.get("objective_progress")) >= 3, "cleared moon pieces must advance collect objective")
	_expect(trace.result == "won", "meeting collect-family target during resolution must win")
	_expect(trace.event_types().has("objective_progress"), "trace must expose objective progress")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
