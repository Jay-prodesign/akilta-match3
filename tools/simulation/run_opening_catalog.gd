extends SceneTree

const Validator = preload("res://tools/level_authoring/level_validator.gd")
const Simulator = preload("res://tools/simulation/level_simulator.gd")

const ROOT := "res://content/levels/ch01"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var summaries: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	var directory := DirAccess.open(ROOT)
	if directory == null:
		printerr("CATALOG_FAIL: cannot open %s" % ROOT)
		quit(1)
		return

	var files: PackedStringArray = directory.get_files()
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".json"):
			continue
		var path: String = ROOT.path_join(file_name)
		var level: Dictionary = Validator.load_level(path)
		if level.is_empty():
			failures.append("%s: could not parse level" % path)
			continue

		var level_id: String = String(level.get("id", ""))
		if seen_ids.has(level_id):
			failures.append("%s: duplicate level id" % level_id)
		seen_ids[level_id] = true

		for issue in Validator.validate(level):
			failures.append(String(issue))

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
			"id": level_id,
			"result": first.get("result", ""),
			"accepted_moves": first.get("accepted_moves", 0),
			"events": first.get("event_counts", {})
		})

	if failures.is_empty():
		print("CATALOG_PASS: %s" % JSON.stringify(summaries))
		quit(0)
		return
	for failure in failures:
		printerr("CATALOG_FAIL: %s" % failure)
	quit(1)
