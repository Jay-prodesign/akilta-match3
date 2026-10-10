extends SceneTree

const BOARD_STATE_PATH := "res://src/match3/domain/board_state.gd"
const MATCH_DETECTOR_PATH := "res://src/match3/domain/match_detector.gd"
const MOVE_RESOLVER_PATH := "res://src/match3/domain/move_resolver.gd"

var _failures: Array[String] = []

func _init() -> void:
	if not ResourceLoader.exists(BOARD_STATE_PATH):
		_fail("BoardState production script is missing")
		_finish()
		return
	if not ResourceLoader.exists(MATCH_DETECTOR_PATH):
		_fail("MatchDetector production script is missing")
		_finish()
		return
	if not ResourceLoader.exists(MOVE_RESOLVER_PATH):
		_fail("MoveResolver production script is missing")
		_finish()
		return

	var board_state_script = load(BOARD_STATE_PATH)
	var detector_script = load(MATCH_DETECTOR_PATH)
	var resolver_script = load(MOVE_RESOLVER_PATH)

	_test_seed_determinism(board_state_script)
	_test_match_detection(board_state_script, detector_script)
	_test_rejected_swap_restores_board(board_state_script, resolver_script)
	_test_valid_swap_resolves_deterministically(board_state_script, detector_script, resolver_script)

	_finish()

func _test_seed_determinism(board_state_script) -> void:
	var a = board_state_script.generated(5, 5, 5, 424242)
	var b = board_state_script.generated(5, 5, 5, 424242)
	_expect_eq(a.signature(), b.signature(), "same seed must generate identical logical board")

func _test_match_detection(board_state_script, detector_script) -> void:
	var board = board_state_script.from_rows([
		[0, 0, 0],
		[1, 2, 1],
		[2, 1, 2],
	], 7, 3)
	var matches: Array = detector_script.find_matches(board)
	_expect_eq(matches.size(), 1, "one horizontal match should be detected")
	if matches.size() == 1:
		_expect_eq(str(matches[0].get("kind")), "horizontal", "match kind should be horizontal")
		_expect_eq((matches[0].get("cells") as Array).size(), 3, "match should contain three cells")

func _test_rejected_swap_restores_board(board_state_script, resolver_script) -> void:
	var board = _swap_fixture(board_state_script, 99)
	var before := board.signature()
	var trace = resolver_script.try_swap(board, Vector2i(1, 0), Vector2i(2, 0))
	_expect_true(trace.has_type("swap_rejected"), "non-matching adjacent swap should be rejected")
	_expect_eq(board.signature(), before, "rejected swap must restore the exact board")

func _test_valid_swap_resolves_deterministically(board_state_script, detector_script, resolver_script) -> void:
	var a = _swap_fixture(board_state_script, 991)
	var b = _swap_fixture(board_state_script, 991)

	var trace_a = resolver_script.try_swap(a, Vector2i(2, 1), Vector2i(2, 2))
	var trace_b = resolver_script.try_swap(b, Vector2i(2, 1), Vector2i(2, 2))

	for required_type in ["swap_accepted", "match_found", "clear", "gravity", "spawn"]:
		_expect_true(trace_a.has_type(required_type), "valid cascade must emit %s" % required_type)

	_expect_eq(a.signature(), b.signature(), "same seed + same move must end on identical board")
	_expect_eq(str(trace_a.types()), str(trace_b.types()), "same seed + same move must emit identical trace type order")
	_expect_true(not a.has_empty(), "resolved board must be fully refilled")
	_expect_true(detector_script.find_matches(a).is_empty(), "resolver must settle until no automatic match remains")

func _swap_fixture(board_state_script, seed_value: int):
	return board_state_script.from_rows([
		[0, 0, 1],
		[0, 0, 1],
		[1, 1, 0],
	], seed_value, 3)

func _expect_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)

func _expect_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s — expected=%s actual=%s" % [message, str(expected), str(actual)])

func _fail(message: String) -> void:
	_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("TEST_PASS: deterministic Match-3 core contract")
		quit(0)
		return
	for failure in _failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
