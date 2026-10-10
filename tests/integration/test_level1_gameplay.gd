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
		_expect(board.families.size() == 5, "Level 1 must use five piece families")
		_expect(str(board.objective_type) == "collect_family", "Level 1 must teach collect_family")
		_expect(str(board.objective_family) == "moon", "Level 1 target family must be moon")
		_expect(int(board.objective_target) == 6, "Level 1 target must be six moon pieces")
		_expect(int(board.moves_remaining) == 12, "Level 1 must start with twelve moves")

	var board_view = screen.get_node_or_null("Layout/BoardView")
	_expect(board_view != null, "GameplayScreen must contain BoardView")
	if board_view != null:
		_expect(board_view.has_method("visual_contract"), "BoardView must expose visual_contract")
		_expect(board_view.has_method("motion_contract"), "BoardView must expose trace-driven motion_contract")
		if board_view.has_method("motion_contract"):
			var motion: Dictionary = board_view.motion_contract()
			_expect(str(motion.get("license", "")) == "MIT", "motion acceleration provenance must record donor license")
			_expect(str(motion.get("adaptation", "")) == "trace_driven_owned_renderer", "motion must remain AKILTA-owned presentation adaptation")
			_expect(float(motion.get("total_duration", 0.0)) > 0.0, "motion profile must define a non-zero move-resolution duration")
		if board_view.has_method("visual_contract"):
			var contract: Dictionary = board_view.visual_contract()
			_expect(contract.size() == 5, "BoardView must expose five visual families")
			var silhouettes: Dictionary = {}
			var motifs: Dictionary = {}
			for family in contract.keys():
				var descriptor: Dictionary = contract[family]
				silhouettes[str(descriptor.get("silhouette", ""))] = true
				motifs[str(descriptor.get("motif", ""))] = true
				_expect(str(descriptor.get("world_role", "")) == "base_family", "each Level 1 piece must declare its world/gameplay role")
				_expect(str(descriptor.get("status", "")) == "art_direction_wip", "Level 1 piece visuals must remain explicitly art-direction WIP before completed Level 1 Founder approval")
				_expect(str(descriptor.get("material", "")) != "", "each Level 1 piece must declare a candidate material language")
			_expect(silhouettes.size() == 5, "piece silhouettes must be unique; hue-only differentiation is forbidden")
			_expect(motifs.size() == 5, "piece motifs must be unique; hue-only differentiation is forbidden")

	_expect(screen.get_node_or_null("Layout/HUD/Objective") != null, "HUD must expose Objective")
	_expect(screen.get_node_or_null("Layout/HUD/Moves") != null, "HUD must expose Moves")
	_expect(screen.get_node_or_null("Layout/BoardView") != null, "board must be the dominant gameplay surface")

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
