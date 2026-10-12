extends SceneTree

const Validator = preload("res://tools/level_authoring/level_validator.gd")
const Simulator = preload("res://tools/simulation/level_simulator.gd")
const LevelCatalog = preload("res://src/content/level_catalog.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var summaries: Array[Dictionary] = []
	var catalog = LevelCatalog.load_default()
	if catalog == null:
		printerr("CATALOG_FAIL: canonical level catalog could not load")
		quit(1)
		return
	for issue in catalog.validate():
		failures.append(String(issue))

	var managed_paths: Dictionary = {}
	for entry in catalog.entries():
		var path := String(entry.get("path", ""))
		managed_paths[path] = true
		var level: Dictionary = Validator.load_level(path)
		if level.is_empty():
			failures.append("%s: could not parse level" % path)
			continue
		for issue in Validator.validate(level):
			failures.append(String(issue))
		var level_id: String = String(level.get("id", ""))
		var seed_value: int = int(level.get("validation_seed", 1))
		var scripted_moves: Array = level.get("teaching_moves", [])
		var first: Dictionary = Simulator.simulate(level, seed_value, scripted_moves)
		var second: Dictionary = Simulator.simulate(level, seed_value, scripted_moves)
		if first != second:
			failures.append("%s: scripted simulation is not deterministic" % level_id)
		var expected_result: String = String(level.get("validation_expected_result", ""))
		if expected_result != "" and String(first.get("result", "")) != expected_result:
			failures.append("%s: expected result %s, got %s" % [level_id, expected_result, String(first.get("result", ""))])
		var expectations: Dictionary = level.get("validation_expect", {})
		var counts: Dictionary = first.get("event_counts", {})
		for raw_key in expectations.keys():
			var expectation_key: String = String(raw_key)
			if not expectation_key.ends_with("_min"):
				continue
			var event_key: String = expectation_key.trim_suffix("_min")
			var minimum: int = int(expectations[raw_key])
			if int(counts.get(event_key, 0)) < minimum:
				failures.append("%s: expected %s >= %d" % [level_id, event_key, minimum])
		summaries.append({
			"number": int(entry.get("number", 0)),
			"id": level_id,
			"result": first.get("result", ""),
			"accepted_moves": first.get("accepted_moves", 0),
			"events": first.get("event_counts", {})
		})

	var root := DirAccess.open("res://content/levels/ch01")
	if root != null:
		for file_name in root.get_files():
			if file_name.begins_with("level_") and file_name.ends_with(".json"):
				var path := "res://content/levels/ch01".path_join(file_name)
				if not managed_paths.has(path):
					failures.append("%s: level file is not registered in canonical catalog" % path)

	if failures.is_empty():
		print("CATALOG_PASS: %s" % JSON.stringify(summaries))
		quit(0)
		return
	for failure in failures:
		printerr("CATALOG_FAIL: %s" % failure)
	quit(1)
