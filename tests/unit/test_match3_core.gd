extends SceneTree

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MatchDetector = preload("res://src/match3/domain/match_detector.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_seeded_generation_is_reproducible()
	_test_generated_board_has_no_starting_matches()
	_test_holes_are_preserved()
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

func _fixture_board(seed_value: int):
	return BoardState.from_level({
		"width": 3,
		"height": 3,
		"moves": 5,
		"families": ["moon", "rose", "moth", "key", "leaf"],
		"initial_rows": [
			["moon", "rose", "moon"],
			["moth", "moon", "key"],
			["leaf", "moth", "rose"]
		]
	}, seed_value)

func _test_invalid_swap_restores_state() -> void:
	var board = _fixture_board(7)
	var before: String = String(board.signature())
	var trace = MoveResolver.try_swap(board, Vector2i(0, 1), Vector2i(1, 1))
	_expect(not trace.accepted, "non-matching adjacent swap must be rejected")
	_expect(board.signature() == before, "rejected swap must restore exact board state")
	_expect(board.moves_remaining == 5, "rejected swap must not consume a move")

func _test_valid_swap_resolves_deterministically() -> void:
	var first = _fixture_board(8080)
	var second = _fixture_board(8080)
	var trace_a = MoveResolver.try_swap(first, Vector2i(1, 0), Vector2i(1, 1))
	var trace_b = MoveResolver.try_swap(second, Vector2i(1, 0), Vector2i(1, 1))
	_expect(trace_a.accepted, "swap creating top-row triple must be accepted")
	_expect(trace_b.accepted, "replayed valid swap must be accepted")
	_expect(first.moves_remaining == 4, "accepted swap must consume exactly one move")
	_expect(first.signature() == second.signature(), "same seed and move must settle to same board")
	_expect(trace_a.debug_signature() == trace_b.debug_signature(), "same seed and move must emit same logical trace")
	_expect(trace_a.event_types().has("match_clear"), "valid resolution must emit match_clear")
	_expect(trace_a.event_types().has("settled"), "valid resolution must end with settled")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
