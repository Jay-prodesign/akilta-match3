extends SceneTree

func _init() -> void:
	var required := [
		"res://src/match3/domain/board_rng.gd",
		"res://src/match3/domain/board_state.gd",
		"res://src/match3/domain/match_detector.gd",
		"res://src/match3/domain/move_resolver.gd",
		"res://src/match3/domain/resolution_trace.gd"
	]
	for path in required:
		if not ResourceLoader.exists(path):
			printerr("TEST_FAIL: deterministic Match-3 core is missing")
			quit(1)
			return

	printerr("TEST_FAIL: deterministic Match-3 core is missing")
	quit(1)
