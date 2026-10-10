extends SceneTree

const BOOTSTRAP_SCENE := "res://src/app/app_bootstrap.tscn"
const TEST_PATH := "user://akilta_match3_approval_gate_test.json"
const SETTINGS_PATH := "user://akilta_match3_approval_gate_settings.json"
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
	house.get_node("Layout/PlayButton").emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "house", "chapter selector remains within House navigation state")
	var chapters = app.current_screen()
	_expect(str(chapters.name) == "ChapterSelect", "House Play must open chapter selection")
	chapters.get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "map", "Curio Boutique must open its chapter map")
	var map = app.current_screen()
	var level1_button: Button = map.get_level_button(1)
	var level2_button: Button = map.get_level_button(2)
	var level3_button: Button = map.get_level_button(3)
	_expect(level1_button != null and not level1_button.disabled, "Level 1 must be playable for founder review")
	_expect(level2_button != null and level2_button.disabled, "Level 2 must stay sealed pending Level 1 approval")
	_expect(level3_button != null and level3_button.disabled, "Level 3 must stay sealed pending Level 1 approval")
	_expect(not app.show_prestart(2), "direct navigation must not bypass the Level 1 approval gate")
	_expect(not app.start_level(2), "direct gameplay entry must not bypass the Level 1 approval gate")
	_expect(str(app.current_route_name()) == "map", "rejected Level 2 navigation must leave the map intact")
	level1_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "prestart", "Level 1 must open prestart")
	app.current_screen().get_node("Layout/Card/Content/Start").emit_signal("pressed")
	await process_frame
	var level1 = app.current_screen()
	_expect(str(app.current_route_name()) == "gameplay", "Level 1 prestart must enter gameplay")
	_expect(level1 != null and str(level1.current_level_id) == "ch01_level_001", "founder gate must test the authored Level 1")
	var trace = level1.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	_expect(trace != null and trace.accepted and str(trace.result) == "won", "Level 1 teaching move must produce the first win")
	await _await_board_motion(level1)
	_expect(level1.result_overlay.visible, "Level 1 must show the win beat before routing away")
	_expect(level1.continue_after_win(), "Level 1 win must save progression")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "house", "Level 1 win must return to House")
	var progress = app.get("progress")
	_expect(progress != null and int(progress.house_stage) == 1, "Level 1 must awaken House stage 1")
	_expect(progress != null and progress.curios.has("moon_cameo"), "Level 1 must grant the Moon Cameo")
	_expect(progress != null and int(progress.highest_level_unlocked) == 2, "save may remember the next progression cursor without bypassing the approval gate")
	var replay_button: Button = app.current_screen().get_node("Layout/PlayButton")
	_expect(not replay_button.disabled and replay_button.text == "REPLAY LEVEL 1", "House must offer replay while later levels await approval")
	replay_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "house", "replay CTA must open chapter selection without changing House navigation state")
	var replay_chapters = app.current_screen()
	_expect(str(replay_chapters.name) == "ChapterSelect", "replay CTA must reopen chapter selection")
	replay_chapters.get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "map", "replayed Curio Boutique selection must open the chapter map")
	map = app.current_screen()
	_expect(map.get_level_button(2) != null and map.get_level_button(2).disabled, "Level 2 must remain sealed after Level 1 completion")
	_expect(map.get_level_button(3) != null and map.get_level_button(3).disabled, "Level 3 must remain sealed after Level 1 completion")
	_expect(not app.show_prestart(2), "Level 2 must remain inaccessible until explicit approval")
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
	_expect(restored != null and int(restored.house_stage) == 1, "relaunch must preserve Level 1 House restoration")
	_expect(restored != null and restored.curios.count("moon_cameo") == 1, "relaunch must preserve Moon Cameo exactly once")
	_expect(relaunched.current_screen().get_node("Layout/PlayButton").text == "REPLAY LEVEL 1", "saved House must keep replay available")
	relaunched.queue_free()
	await process_frame
	_cleanup()
	_finish()

func _await_board_motion(screen) -> void:
	if screen == null:
		return
	var board_view = screen.get_node_or_null("Layout/BoardView")
	if board_view == null or not board_view.has_method("is_motion_active"):
		return
	if bool(board_view.is_motion_active()) and board_view.has_signal("trace_motion_finished"):
		await board_view.trace_motion_finished

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
		print("TEST_PASS: Level 1 approval gate journey")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
