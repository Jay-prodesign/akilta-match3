extends SceneTree

const GAMEPLAY_SCENE := "res://src/ui/gameplay/gameplay_screen.tscn"
const LEVEL_PATH := "res://content/levels/ch01/level_001.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(GAMEPLAY_SCENE):
		_fail("Level 1 gameplay scene is missing")
		_finish()
		return
	if not FileAccess.file_exists(LEVEL_PATH):
		_fail("Level 1 content is missing")
		_finish()
		return

	var packed = load(GAMEPLAY_SCENE)
	if packed == null:
		_fail("Level 1 gameplay scene could not load")
		_finish()
		return

	var screen = packed.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.has_method("load_level_path"), "GameplayScreen must expose load_level_path")
	if screen.has_method("load_level_path"):
		var loaded: bool = bool(screen.load_level_path(LEVEL_PATH, 1001))
		_expect(loaded, "GameplayScreen must load authored Level 1 content")

	var board = screen.get("board_state")
	_expect(board != null, "GameplayScreen must own logical board_state")
	if board != null:
		_expect(int(board.width) == 7 and int(board.height) == 7, "Level 1 board must be 7x7")
		_expect(board.families.size() == 8, "Level 1 must use the eight North Star piece families")
		_expect(str(board.objective_type) == "collect_family", "Level 1 must teach collect_family")
		_expect(str(board.objective_family) == "moon", "Level 1 target family must be moon")
		_expect(int(board.objective_target) == 6, "Level 1 target must be six moon pieces")
		_expect(int(board.moves_remaining) == 20, "Level 1 must start with the North Star twenty-move budget")

	var board_view = screen.get_node_or_null("Layout/BoardView")
	_expect(board_view != null, "GameplayScreen must contain BoardView")
	if board_view != null:
		_expect(board_view.has_method("visual_contract"), "BoardView must expose visual_contract")
		_expect(board_view.has_method("motion_contract"), "BoardView must expose trace-driven motion_contract")
		_expect(board_view.has_method("piece_asset_contract"), "BoardView must expose first-party piece asset contract")
		if board_view.has_method("piece_asset_contract"):
			var asset_contract: Dictionary = board_view.piece_asset_contract()
			_expect(str(asset_contract.get("source", "")).begins_with("AKILTA first-party"), "piece assets must remain explicitly first-party originals")
			_expect(not bool(asset_contract.get("paid_dependency", true)), "core piece assets must have no paid dependency")
			var loaded_assets: Dictionary = asset_contract.get("families", {})
			_expect(loaded_assets.size() == 8, "eight first-party piece assets must be registered")
			for family in ["moon", "rose", "moth", "key", "leaf", "cat", "candle", "skull"]:
				_expect(bool(loaded_assets.get(family, false)), "%s first-party piece asset must load" % family)
		_expect(board_view.has_method("teaching_contract"), "BoardView must expose Level 1 teaching contract")
		if board_view.has_method("teaching_contract"):
			var teaching: Dictionary = board_view.teaching_contract()
			_expect(bool(teaching.get("active", false)), "Level 1 authored teaching move must activate the board cue")
			_expect(teaching.get("from", Vector2i(-1, -1)) == Vector2i(1, 4), "teaching cue must start on the authored global special tile")
			_expect(teaching.get("to", Vector2i(-1, -1)) == Vector2i(2, 4), "teaching cue must end on authored destination")
			_expect(str(teaching.get("language", "")) == "ritual_thread", "teaching cue must use House-native ritual-thread language")
		if board_view.has_method("motion_contract"):
			var motion: Dictionary = board_view.motion_contract()
			_expect(str(motion.get("license", "")) == "MIT", "motion acceleration provenance must record donor license")
			_expect(str(motion.get("adaptation", "")) == "trace_driven_owned_renderer", "motion must remain AKILTA-owned presentation adaptation")
			_expect(float(motion.get("total_duration", 0.0)) > 0.0, "motion profile must define a non-zero move-resolution duration")
		if board_view.has_method("visual_contract"):
			var contract: Dictionary = board_view.visual_contract()
			_expect(contract.size() == 8, "BoardView must expose eight visual families")
			var silhouettes: Dictionary = {}
			var motifs: Dictionary = {}
			for family in contract.keys():
				var descriptor: Dictionary = contract[family]
				silhouettes[str(descriptor.get("silhouette", ""))] = true
				motifs[str(descriptor.get("motif", ""))] = true
				_expect(str(descriptor.get("world_role", "")) == "base_family", "each Level 1 piece must declare its world/gameplay role")
				_expect(str(descriptor.get("status", "")) == "first_party_svg_candidate_v2", "Level 1 piece visuals must remain explicitly Founder-unapproved first-party SVG candidates before D-027")
				_expect(str(descriptor.get("material", "")) != "", "each Level 1 piece must declare a candidate material language")
			_expect(silhouettes.size() == 8, "piece silhouettes must be unique; hue-only differentiation is forbidden")
			_expect(motifs.size() == 8, "piece motifs must be unique; hue-only differentiation is forbidden")

	_expect(screen.find_child("Objective", true, false) != null, "HUD must expose Objective")
	_expect(screen.find_child("Moves", true, false) != null, "HUD must expose Moves")
	_expect(screen.get_node_or_null("Layout/BoardView") != null, "board must be the dominant gameplay surface")
	var awakening = screen.get_node_or_null("Layout/Awakening/Content/ProgressView")
	_expect(awakening != null and awakening.has_method("contract"), "Level 1 must expose the Moon Cameo awakening strip")
	if awakening != null and awakening.has_method("contract"):
		var awakening_contract: Dictionary = awakening.contract()
		_expect(int(awakening_contract.get("progress", -1)) == 0, "awakening strip starts at zero")
		_expect(int(awakening_contract.get("target", -1)) == 6, "awakening strip must reflect six-Moon target")
		_expect(str(awakening_contract.get("language", "")) == "awakening_seals", "awakening strip must use House-native seals")

	var teaching_trace = screen.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	_expect(teaching_trace != null and bool(teaching_trace.accepted), "authored teaching swipe must be accepted")
	_expect(int(board.objective_progress) >= 6, "winning teaching move must complete the logical Level 1 objective")
	# HUD intentionally updates after trace-driven animations finish; it must not jump ahead.
	if board_view != null and board_view.has_method("is_motion_active"):
		var deadline_ms := Time.get_ticks_msec() + 8000
		while bool(board_view.is_motion_active()) and Time.get_ticks_msec() < deadline_ms:
			await process_frame
		_expect(not bool(board_view.is_motion_active()), "Level 1 motion must settle within eight seconds")
	if awakening != null and awakening.has_method("contract"):
		_expect(int(awakening.contract().get("progress", 0)) >= 6, "reward meter must fully awaken after the visible move resolves")
	if board_view != null and board_view.has_method("teaching_contract"):
		_expect(not bool(board_view.teaching_contract().get("active", true)), "teaching cue must disappear after the first accepted swipe")

	screen.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: Level 1 gameplay surface contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
