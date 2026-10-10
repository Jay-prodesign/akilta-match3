extends SceneTree

const PROGRESS_PATH := "res://src/progression/player_progress.gd"
const STORE_PATH := "res://src/save/save_store.gd"
const TEST_PATH := "user://akilta_match3_progress_test.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(PROGRESS_PATH) or not ResourceLoader.exists(STORE_PATH):
		printerr("TEST_FAIL: durable progression layer is missing")
		quit(1)
		return

	var ProgressScript = load(PROGRESS_PATH)
	var StoreScript = load(STORE_PATH)
	var progress = ProgressScript.new()
	var store = StoreScript.new(TEST_PATH)
	_cleanup()

	_expect(progress.apply_level_win("tx-level-001", "ch01_level_001", "moon_cameo"), "first win transaction must apply")
	_expect(not progress.apply_level_win("tx-level-001", "ch01_level_001", "moon_cameo"), "same win transaction must be idempotent")
	_expect(int(progress.house_stage) == 1, "first win must awaken House stage 1")
	_expect(int(progress.highest_level_unlocked) == 2, "first win must unlock level 2")
	_expect(progress.curios.count("moon_cameo") == 1, "Curio reward must exist exactly once")
	_expect(store.save(progress.to_dict()), "progress save must succeed")

	var loaded_data: Dictionary = store.load_or_default()
	var restored = ProgressScript.from_dict(loaded_data)
	_expect(int(restored.house_stage) == 1, "saved House stage must restore")
	_expect(restored.curios.count("moon_cameo") == 1, "saved Curio must restore exactly once")
	_expect(not restored.apply_level_win("tx-level-001", "ch01_level_001", "moon_cameo"), "restored transaction ledger must prevent duplicate win")

	# Create a last-known-good backup, then corrupt primary and prove recovery.
	restored.highest_level_unlocked = 3
	_expect(store.save(restored.to_dict()), "second save must succeed and create LKG backup")
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	_expect(file != null, "test must be able to corrupt primary save")
	if file != null:
		file.store_string("{ definitely-not-json")
		file.close()
	var recovered: Dictionary = store.load_or_default()
	_expect(int(recovered.get("house_stage", 0)) == 1, "corrupt primary must recover last-known-good save")

	# Saving after a corrupt primary must preserve the validated backup rather
	# than rotating corrupt bytes into the LKG slot.
	var recovered_progress = ProgressScript.from_dict(recovered)
	recovered_progress.house_stage = 2
	_expect(store.save(recovered_progress.to_dict()), "save after corrupt-primary recovery must succeed")
	var post_recovery: Dictionary = store.load_or_default()
	_expect(int(post_recovery.get("house_stage", 0)) == 2, "recovered save must become the new primary")

	# A future-schema primary is preserved and blocks writes so an older build
	# cannot silently downgrade/overwrite newer player data.
	var future := recovered_progress.to_dict()
	future["schema_version"] = 99
	var future_file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	_expect(future_file != null, "test must create future-schema primary")
	if future_file != null:
		future_file.store_string(JSON.stringify(future))
		future_file.close()
	var fallback: Dictionary = store.load_or_default()
	_expect(store.is_write_blocked(), "future schema must activate write protection")
	_expect(not store.save(recovered_progress.to_dict()), "older build must refuse to overwrite future schema")
	_expect(store.write_blocked_reason == "future_schema", "future-schema refusal must be explicit")
	_expect(not fallback.is_empty(), "valid backup may still be read while future primary is preserved")

	_cleanup()
	_finish()

func _cleanup() -> void:
	for path in [TEST_PATH, TEST_PATH + ".bak", TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: durable progression and exactly-once save")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
