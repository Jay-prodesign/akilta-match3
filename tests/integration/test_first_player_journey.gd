extends SceneTree

const BOOTSTRAP_SCENE := "res://src/app/app_bootstrap.tscn"
const HOUSE_SCENE := "res://src/ui/home/house_home.tscn"
const TEST_PATH := "user://akilta_match3_journey_test.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(HOUSE_SCENE):
		printerr("TEST_FAIL: first player journey House surface is missing")
		quit(1)
		return
	var packed = load(BOOTSTRAP_SCENE)
	if packed == null:
		_fail("AppBootstrap scene must load")
		_finish()
		return

	_cleanup()
	var app = packed.instantiate()
	app.set("save_path_override", TEST_PATH)
	root.add_child(app)
	await process_frame

	_expect(app.has_method("start_level"), "AppBootstrap must expose start_level")
	_expect(app.has_method("complete_level_win"), "AppBootstrap must expose complete_level_win")
	_expect(app.has_method("current_route_name"), "AppBootstrap must expose current_route_name")
	if app.has_method("start_level"):
		app.start_level(1)
		await process_frame
		_expect(str(app.current_route_name()) == "gameplay", "new player must be routable into gameplay")

	if app.has_method("complete_level_win"):
		var applied: bool = bool(app.complete_level_win("tx-first-win", "ch01_level_001", "moon_cameo"))
		await process_frame
		_expect(applied, "first completed level must commit progression")
		_expect(str(app.current_route_name()) == "house", "win must route to House awakening")
		var progress = app.get("progress")
		_expect(progress != null and int(progress.house_stage) == 1, "House must visibly advance to stage 1")
		_expect(progress != null and progress.curios.count("moon_cameo") == 1, "Moon Cameo must be collected")

	app.queue_free()
	await process_frame

	var relaunched = packed.instantiate()
	relaunched.set("save_path_override", TEST_PATH)
	root.add_child(relaunched)
	await process_frame
	var relaunched_progress = relaunched.get("progress")
	_expect(relaunched_progress != null and int(relaunched_progress.house_stage) == 1, "relaunch must preserve House stage")
	_expect(relaunched_progress != null and relaunched_progress.curios.count("moon_cameo") == 1, "relaunch must preserve Curio")
	if relaunched.has_method("complete_level_win"):
		_expect(not bool(relaunched.complete_level_win("tx-first-win", "ch01_level_001", "moon_cameo")), "replayed transaction must not duplicate progression")
	relaunched.queue_free()
	await process_frame

	_cleanup()
	_finish()

func _cleanup() -> void:
	for path in [TEST_PATH, TEST_PATH + ".bak", TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _fail(message: String) -> void:
	failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: first player journey continuity")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
