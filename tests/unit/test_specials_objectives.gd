extends SceneTree

func _init() -> void:
	var required := [
		"res://src/match3/domain/special_rules.gd",
		"res://src/match3/domain/blockers/wax_seal.gd",
		"res://src/match3/domain/objective_state.gd"
	]
	for path in required:
		if not ResourceLoader.exists(path):
			printerr("TEST_FAIL: specials/objectives layer is missing")
			quit(1)
			return
	printerr("TEST_FAIL: specials/objectives layer is missing")
	quit(1)
