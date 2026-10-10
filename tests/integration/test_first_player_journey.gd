extends SceneTree

const BOOTSTRAP_SCENE := "res://src/app/app_bootstrap.tscn"
const TEST_PATH := "user://akilta_match3_journey_test.json"
const SETTINGS_PATH := "user://akilta_match3_journey_settings.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	var packed = load(BOOTSTRAP_SCENE)
	if packed == null:
		_fail("AppBootstrap scene must load")
		_finish()
		return

	var app = packed.instantiate()
	app.set("save_path_override", TEST_PATH)
	app.set("settings_path_override", SETTINGS_PATH)
	root.add_child(app)
	await process_frame
	await process_frame

	_expect(str(app.current_route_name()) == "house", "new player must boot into House")
	var house = app.current_screen()
	var settings_button: Button = house.get_node("Layout/SettingsButton")
	settings_button.emit_signal("pressed")
	await process_frame
	_expect(app.navigation.is_settings_open(), "House settings must open")
	_expect(app.close_settings(), "settings must close cleanly")

	var map_button: Button = house.get_node("Layout/PlayButton")
	map_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "map", "House CTA must route to chapter map")
	var map = app.current_screen()
	var level1_button: Button = map.get_level_button(1)
	var level2_button: Button = map.get_level_button(2)
	_expect(level1_button != null and not level1_button.disabled, "Level 1 must be selectable")
	_expect(level2_button != null and level2_button.disabled, "Level 2 route must remain sealed before D-027")
	_expect(map.get_level_button(10) != null, "chapter map must expose the longer ten-display route without unlocking future levels")

	level1_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "prestart", "Level 1 selection must open prestart")
	var prestart = app.current_screen()
	var objective: Label = prestart.get_node("Layout/Card/Content/Objective")
	_expect(objective.text == "GOAL · GATHER 6 MOON SIGILS", "prestart must reflect the canonical Level 1 collect-family objective")
	var start_button: Button = prestart.get_node("Layout/Card/Content/Start")
	start_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "gameplay", "prestart must enter gameplay")
	var gameplay = app.current_screen()
	_expect(str(gameplay.current_level_id) == "ch01_level_001", "gameplay must load canonical Level 1")

	var trace = gameplay.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	_expect(trace != null and trace.accepted and str(trace.result) == "won", "Level 1 teaching swipe must win")
	var board_view = gameplay.get_node("Layout/BoardView")
	if bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished
	_expect(gameplay.result_overlay.visible, "result beat must appear after motion")
	_expect(gameplay.continue_after_win(), "win continue must commit progression")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "house", "win must return to House")
	var progress = app.get("progress")
	_expect(int(progress.house_stage) == 1, "House must awaken to stage 1")
	_expect(progress.curios.count("moon_cameo") == 1, "Moon Cameo must persist exactly once")

	var awakened_house = app.current_screen()
	var collection_button: Button = awakened_house.get_node("Layout/CollectionButton")
	collection_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "collection", "House Curios control must open collection")
	var collection = app.current_screen()
	var moon_state: Label = collection.get_node("Layout/Cards/MoonCard/Content/State")
	_expect(moon_state.text == "AWAKENED", "Moon Cameo must be inspectable as awakened in collection")
	collection.get_node("Layout/Back").emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "house", "collection must return to House")

	app.queue_free()
	await process_frame

	var relaunched = packed.instantiate()
	relaunched.set("save_path_override", TEST_PATH)
	relaunched.set("settings_path_override", SETTINGS_PATH)
	root.add_child(relaunched)
	await process_frame
	await process_frame
	var restored = relaunched.get("progress")
	_expect(str(relaunched.current_route_name()) == "house", "relaunch must return to House")
	_expect(int(restored.house_stage) == 1, "relaunch must preserve House stage")
	_expect(restored.curios.count("moon_cameo") == 1, "relaunch must preserve Moon Cameo")
	relaunched.queue_free()
	await process_frame
	_cleanup()
	_finish()

func _cleanup() -> void:
	for path in [TEST_PATH, TEST_PATH + ".bak", TEST_PATH + ".tmp", SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _fail(message: String) -> void:
	failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: complete Level 1 shell journey")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
