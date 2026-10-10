extends SceneTree

const BoardState = preload("res://src/match3/domain/board_state.gd")
const ComboRules = preload("res://src/match3/domain/special_combo_rules.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_full_pair_matrix()
	_test_pair_footprints_are_material()
	_test_special_pair_swap_resolves_without_normal_match()
	_test_global_global_hits_whole_playable_board()
	if failures.is_empty():
		print("TEST_PASS: full special combo matrix")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _level() -> Dictionary:
	return {
		"width": 5,
		"height": 5,
		"moves": 9,
		"families": ["moon","rose","moth","key","leaf"],
		"initial_rows": [
			["moon","rose","moth","key","leaf"],
			["rose","moth","key","leaf","moon"],
			["moth","key","leaf","moon","rose"],
			["key","leaf","moon","rose","moth"],
			["leaf","moon","rose","moth","key"]
		]
	}

func _test_full_pair_matrix() -> void:
	var kinds: Array[String] = ["line_h","area","smart","global"]
	var expected := {
		"line_h|line_h": "line_line",
		"line_h|area": "line_area",
		"line_h|smart": "line_smart",
		"line_h|global": "line_global",
		"area|area": "area_area",
		"area|smart": "area_smart",
		"area|global": "area_global",
		"smart|smart": "smart_smart",
		"smart|global": "smart_global",
		"global|global": "global_global"
	}
	for a_index in range(kinds.size()):
		for b_index in range(a_index, kinds.size()):
			var a: String = kinds[a_index]
			var b: String = kinds[b_index]
			var key := "%s|%s" % [a,b]
			_expect(ComboRules.combo_id(a,b) == String(expected[key]), "pair %s must have deterministic combo id" % key)
			_expect(ComboRules.combo_id(a,b) == ComboRules.combo_id(b,a), "combo id must be commutative for %s" % key)

func _test_pair_footprints_are_material() -> void:
	var board = BoardState.from_level(_level(), 55)
	board.blockers[Vector2i(0,0)] = {"type":"wax_seal","hp":1}
	var pairs := [
		["line_h","line_v"], ["line_h","area"], ["line_h","smart"], ["line_h","global"],
		["area","area"], ["area","smart"], ["area","global"],
		["smart","smart"], ["smart","global"], ["global","global"]
	]
	for pair in pairs:
		var cells: Array[Vector2i] = ComboRules.affected_cells(
			board, Vector2i(2,2), Vector2i(3,2), String(pair[0]), String(pair[1]), "moon", "rose"
		)
		_expect(cells.size() >= 5, "%s combo must produce a material board effect" % ComboRules.combo_id(String(pair[0]),String(pair[1])))

func _test_special_pair_swap_resolves_without_normal_match() -> void:
	var board = BoardState.from_level(_level(), 56)
	board.set_special(Vector2i(1,1), "line_h")
	board.set_special(Vector2i(2,1), "area")
	var trace = MoveResolver.try_swap(board, Vector2i(1,1), Vector2i(2,1))
	_expect(trace.accepted, "special+special adjacent swap must be accepted without a normal match")
	_expect(trace.event_types().has("combo_triggered"), "special pair swap must emit combo_triggered")
	_expect(trace.event_types().has("combo_clear"), "special pair swap must emit combo_clear")
	_expect(board.moves_remaining == 8, "combo swap must consume exactly one move")

func _test_global_global_hits_whole_playable_board() -> void:
	var board = BoardState.from_level(_level(), 57)
	var cells: Array[Vector2i] = ComboRules.affected_cells(
		board, Vector2i(1,1), Vector2i(2,1), "global", "global", "moon", "rose"
	)
	_expect(cells.size() == 25, "global+global must include every playable cell on the 5x5 fixture")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
