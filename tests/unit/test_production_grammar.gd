extends SceneTree

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MatchDetector = preload("res://src/match3/domain/match_detector.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")
const MoveFinder = preload("res://src/match3/domain/move_finder.gd")
const BoardShuffler = preload("res://src/match3/domain/board_shuffler.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_creation_plans()
	_test_resolver_creates_special()
	_test_special_moves_with_piece()
	_test_dead_board_shuffle()
	if failures.is_empty():
		print("TEST_PASS: production special creation and shuffle grammar")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _board(rows: Array):
	return BoardState.from_level({
		"width": rows[0].size(),
		"height": rows.size(),
		"moves": 10,
		"families": ["moon", "rose", "moth", "key", "leaf"],
		"initial_rows": rows
	}, 777)

func _test_creation_plans() -> void:
	var line = _board([
		["moon","moon","moon","moon","rose"],
		["rose","moth","key","leaf","moth"],
		["moth","key","leaf","rose","key"]
	])
	var p: Dictionary = MatchDetector.plan_special_creation(line, [Vector2i(1,0)])
	_expect(String(p.get("kind","")) == "line_h", "four-in-line must plan line special")
	_expect(p.get("position") == Vector2i(1,0), "preferred swapped cell must receive line special")

	var global = _board([
		["moon","moon","moon","moon","moon"],
		["rose","moth","key","leaf","moth"],
		["moth","key","leaf","rose","key"]
	])
	p = MatchDetector.plan_special_creation(global, [Vector2i(2,0)])
	_expect(String(p.get("kind","")) == "global", "five-in-line must plan global special")

	var area = _board([
		["rose","moon","key","leaf","moth"],
		["moon","moon","moon","rose","key"],
		["leaf","moon","rose","moth","key"],
		["moth","key","leaf","rose","moon"]
	])
	p = MatchDetector.plan_special_creation(area, [Vector2i(1,1)])
	_expect(String(p.get("kind","")) == "area", "cross/T-L formation must plan area special")
	_expect(p.get("position") == Vector2i(1,1), "area special must anchor at intersection")

	var smart = _board([
		["moon","moon","rose"],
		["moon","moon","moth"],
		["key","leaf","rose"]
	])
	p = MatchDetector.plan_special_creation(smart, [Vector2i(1,1)])
	_expect(String(p.get("kind","")) == "smart", "compact square must plan smart special")

func _test_resolver_creates_special() -> void:
	var board = _board([
		["moon","rose","moth","key"],
		["rose","moon","key","moth"],
		["moon","moon","rose","moon"],
		["moth","key","moon","rose"]
	])
	var trace = MoveResolver.try_swap(board, Vector2i(2,2), Vector2i(2,3))
	_expect(trace.accepted, "four-match creation swap must be accepted")
	_expect(trace.event_types().has("special_created"), "resolver must emit special_created")
	_expect(board.specials.size() == 1, "created special must survive settle")
	var kinds: Array[String] = []
	for kind in board.specials.values():
		kinds.append(String(kind))
	_expect(kinds.has("line_h"), "horizontal four must create line_h special")

func _test_special_moves_with_piece() -> void:
	var board = _board([
		["moon","rose","moth"],
		["rose","moth","key"],
		["leaf","key","rose"]
	])
	board.set_special(Vector2i(0,0), "line_h")
	board.swap_cells(Vector2i(0,0), Vector2i(1,0))
	_expect(board.get_special(Vector2i(1,0)) == "line_h", "special identity must travel with swapped piece")
	_expect(board.get_special(Vector2i(0,0)) == "", "source cell must release moved special identity")

func _test_dead_board_shuffle() -> void:
	var board = BoardState.from_level({
		"width": 3,
		"height": 3,
		"moves": 5,
		"families": ["moon","rose","moth"],
		"initial_rows": [
			["moon","moon","rose"],
			["moon","rose","rose"],
			["moth","moth","moon"]
		]
	}, 4242)
	_expect(MatchDetector.find_match_cells(board).is_empty(), "dead-board fixture must start settled")
	_expect(not MoveFinder.has_legal_move(board), "fixture must genuinely have no legal move")
	_expect(BoardShuffler.ensure_playable(board), "dead board must be deterministically shuffled")
	_expect(MatchDetector.find_match_cells(board).is_empty(), "shuffle must not introduce automatic matches")
	_expect(MoveFinder.has_legal_move(board), "shuffle must restore at least one legal move")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
