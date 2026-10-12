extends SceneTree

const Validator = preload("res://tools/level_authoring/level_validator.gd")
const Simulator = preload("res://tools/simulation/level_simulator.gd")

const ROOT := "res://content/levels"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var summaries: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	var paths: Array[String] = _collect_level_paths(ROOT)
	var total_seed_runs := 0
	if paths.is_empty():
		printerr("CATALOG_FAIL: no authored levels found under %s" % ROOT)
		quit(1)
		return

	for path in paths:
		var level: Dictionary = Validator.load_level(path)
		if level.is_empty():
			failures.append("%s: could not parse level" % path)
			continue

		var level_id: String = String(level.get("id", ""))
		if seen_ids.has(level_id):
			failures.append("%s: duplicate level id" % level_id)
		seen_ids[level_id] = path

		for issue in Validator.validate(level):
			failures.append(String(issue))

		var scripted_moves: Array = level.get("teaching_moves", [])
		var expected_result: String = String(level.get("validation_expected_result", ""))
		var expectations: Dictionary = level.get("validation_expect", {})
		var seed_runs: Array[Dictionary] = []
		for seed_value in _validation_seeds(level):
			var first: Dictionary = Simulator.simulate(level, seed_value, scripted_moves)
			var second: Dictionary = Simulator.simulate(level, seed_value, scripted_moves)
			total_seed_runs += 1
			if first != second:
				failures.append("%s seed %d: simulation is not deterministic" % [level_id, seed_value])
			if expected_result != "" and String(first.get("result", "")) != expected_result:
				failures.append("%s seed %d: expected result %s, got %s" % [level_id, seed_value, expected_result, String(first.get("result", ""))])
			_validate_event_expectations(level_id, seed_value, expectations, first.get("event_counts", {}), failures)
			seed_runs.append(_compact_run(first))

		var primary_seed := int(level.get("validation_seed", 1))
		var primary := Simulator.simulate(level, primary_seed, scripted_moves)
		summaries.append({
			"id": level_id,
			"path": path.trim_prefix(ROOT + "/"),
			"status": String(level.get("content_status", "")),
			"objective": String(level.get("objective", "")),
			"validation_seeds": _validation_seeds(level),
			"seed_runs": seed_runs,
			"metrics": {
				"opening_legal_moves": int(primary.get("opening_legal_moves", 0)),
				"playable_cells": int(primary.get("playable_cells", 0)),
				"holes": int(primary.get("holes", 0)),
				"blocker_count": int(primary.get("blocker_count", 0)),
				"blocker_hp_total": int(primary.get("blocker_hp_total", 0)),
				"special_count": int(primary.get("special_count", 0)),
				"authored_moves": int(primary.get("authored_moves", 0)),
				"move_budget": int(primary.get("move_budget", 0))
			}
		})

	if failures.is_empty():
		print("CATALOG_PASS: %s" % JSON.stringify({
			"level_count": summaries.size(),
			"seed_runs": total_seed_runs,
			"root": ROOT,
			"levels": summaries
		}))
		quit(0)
		return
	for failure in failures:
		printerr("CATALOG_FAIL: %s" % failure)
	quit(1)

func _collect_level_paths(root_path: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		return result
	var files: PackedStringArray = directory.get_files()
	files.sort()
	for file_name in files:
		if file_name.ends_with(".json"):
			result.append(root_path.path_join(file_name))
	var directories: PackedStringArray = directory.get_directories()
	directories.sort()
	for child in directories:
		if child.begins_with("."):
			continue
		result.append_array(_collect_level_paths(root_path.path_join(child)))
	result.sort()
	return result

func _validation_seeds(level: Dictionary) -> Array[int]:
	var seeds: Array[int] = []
	for raw_seed in level.get("validation_seeds", []):
		var seed_value := int(raw_seed)
		if not seeds.has(seed_value):
			seeds.append(seed_value)
	return seeds

func _validate_event_expectations(level_id: String, seed_value: int, expectations: Dictionary, counts: Dictionary, failures: Array[String]) -> void:
	for raw_key in expectations.keys():
		var expectation_key := String(raw_key)
		if not expectation_key.ends_with("_min"):
			continue
		var event_key := expectation_key.trim_suffix("_min")
		var minimum := int(expectations[raw_key])
		if int(counts.get(event_key, 0)) < minimum:
			failures.append("%s seed %d: expected %s >= %d" % [level_id, seed_value, event_key, minimum])

func _compact_run(run: Dictionary) -> Dictionary:
	return {
		"seed": int(run.get("seed", 0)),
		"result": String(run.get("result", "")),
		"accepted_moves": int(run.get("accepted_moves", 0)),
		"spare_moves": int(run.get("spare_moves", -1)),
		"max_cascade": int(run.get("max_cascade", 0)),
		"opening_legal_moves": int(run.get("opening_legal_moves", 0)),
		"events": run.get("event_counts", {})
	}
