extends SceneTree

func _init() -> void:
	var required := [
		"res://content/levels/ch01/level_001.json",
		"res://src/match3/presentation/piece_visuals.gd",
		"res://src/match3/presentation/board_view.gd",
		"res://src/ui/gameplay/gameplay_screen.gd",
		"res://src/ui/gameplay/gameplay_screen.tscn"
	]
	for path in required:
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			printerr("TEST_FAIL: playable Level 1 surface is missing")
			quit(1)
			return
	printerr("TEST_FAIL: playable Level 1 surface is missing")
	quit(1)
