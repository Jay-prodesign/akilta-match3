extends SceneTree

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MatchDetector = preload("res://src/match3/domain/match_detector.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_seeded_generation_is_reproducible()
	_test_generated_board_has_no_starting_matches()
	_test_holes_are_preserved()
	_test_horizontal_match_detection()
	_test_invalid_swap_restores_state()
	_test_valid_swap_resolves_deterministically()

	if failures.is_empty():
		print("TEST_PASS: deterministic Match-3 core")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _base_level() -> Dictionary:
	return {
		"width": 8,
		"height": 8,
		"moves": 20,
		"families": ["moon", "rose", "moth", "key", "leaf"]
	}

func _test_seeded_generation_is_reproducible() -> void:
	var first = BoardState.from_level(_base_level(), 424242)
	var second = BoardState.from_level(_base_level(), 424242)
	_expect(first.signature() == second.signature(), "same seed must produce same board")

func _test_generated_board_has_no_starting_matches() -> void:
	var board = BoardState.from_level(_base_level(), 101)
	_expect(MatchDetector.find_match_cells(board).is_empty(), "generated board must not start with matches")

func _test_holes_are_preserved() -> void:
	var level := _base_level()
	level["holes"] = [[3, 3], [4, 3]]
	var board = BoardState.from_level(level, 99)
	_expect(board.is_hole(Vector2i(3, 3)), "declared hole must remain a hole")
	_expect(board.get_cell(Vector2i(3, 3)) == "", "hole must never contain a piece")

func _test_horizontal_match_detection() -> void:
	var board = BoardState.from_level({
		"width": 3,
		"height": 3,
		"moves": 5,
		"families": ["moon", "rose", "moth"],
		"initial_rows": [
			["moon", "moon", "moon"],
			["rose", "moth", "rose"],
			["moth", "rose", "moth"]
		]
	}, 17)
	var matched := MatchDetector.find_match_cells(board)
	_expect(matched == [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], "horizontal triple must report exactly its three cells")

func _invalid_fixture(seed_value: int):
	return BoardState.from_level({
		"width": 3,
		"height": 3,
		"moves": 5,
		"families": ["moon", "rose", "moth", "key", "leaf"],
		"initial_rows": [
			["moon", "rose", "moth"],
			["moth", "moon", "key"],
			["leaf", "moth", "rose"]
		]
	}, seed_value)

func _valid_fixture(seed_value: int):
	return BoardState.from_level({
		"width": 3,
		"height": 3,
		"moves": 5,
		"families": ["moon", "rose", "moth", "key", "leaf"],
		"initial_rows": [
			["moth", "key", "leaf"],
			["rose", "moon", "rose"],
			["moon", "rose", "moon"]
		]
	}, seed_value)

func _test_invalid_swap_restores_state() -> void:
	var board = _invalid_fixture(7)
	var before: String = String(board.signature())
	var trace = MoveResolver.try_swap(board, Vector2i(0, 1), Vector2i(1, 1))
	_expect(not trace.accepted, "non-matching adjacent swap must be rejected")
	_expect(trace.event_types() == ["swap_rejected"], "rejected swap must emit only swap_rejected")
	_expect(board.signature() == before, "rejected swap must restore exact board state")
	_expect(board.moves_remaining == 5, "rejected swap must not consume a move")

func _test_valid_swap_resolves_deterministically() -> void:
	var first = _valid_fixture(8080)
	var second = _valid_fixture(8080)
	var trace_a = MoveResolver.try_swap(first, Vector2i(1, 1), Vector2i(1, 2))
	var trace_b = MoveResolver.try_swap(second, Vector2i(1, 1), Vector2i(1, 2))

	_expect(trace_a.accepted, "swap creating bottom-row triple must be accepted")
	_expect(trace_b.accepted, "replayed valid swap must be accepted")
	_expect(first.moves_remaining == 4, "accepted swap must consume exactly one move")
	_expect(first.signature() == second.signature(), "same seed and move must settle to same board")
	_expect(trace_a.debug_signature() == trace_b.debug_signature(), "same seed and move must emit same logical trace")

	var types: Array[String] = trace_a.event_types()
	for required_type in ["swap_accepted", "match_found", "clear", "gravity", "spawn", "settled"]:
		_expect(types.has(required_type), "valid resolution must emit %s" % required_type)

	_expect(not first.has_empty(), "resolved board must contain no empty playable cells")
	_expect(MatchDetector.find_match_cells(first).is_empty(), "resolver must settle until no automatic matches remain")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
