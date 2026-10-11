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
	_expect(str(app.current_route_name()) == "boot", "new player must begin on splash")
	var splash = app.current_screen()
	_expect(splash != null and splash.get_node_or_null("Layout/Enter") != null, "splash must expose the enter control")
	splash.get_node("Layout/Enter").emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "house", "splash must enter House")
	var house = app.current_screen()
	var primary_play: Button = house.get_node("Layout/PlayButton")
	primary_play.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "prestart", "new-player House CTA must enter focused Level 1 prestart directly")
	_expect(str(app.current_screen().name) == "LevelPrestart", "focused Level 1 prestart must replace chapter-selection ceremony")
	var back_button: Button = app.current_screen().get_node("Layout/Back")
	back_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "house", "prestart back must return to House")
	app.current_screen().get_node("Layout/PlayButton").emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "prestart", "House must reopen prestart after back")
	_expect(not app.show_prestart(2), "direct navigation must not bypass earned progression")
	_expect(not app.start_level(2), "direct gameplay entry must not bypass earned progression")
	_expect(str(app.current_route_name()) == "prestart", "rejected Level 2 navigation must preserve focused Level 1 prestart")
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
	_expect(str(app.current_route_name()) == "restoration", "Level 1 first-time win must route through explicit House Restoration")
	var progress = app.get("progress")
	_expect(progress != null and int(progress.house_stage) == 1, "Level 1 must awaken House stage 1")
	_expect(progress != null and progress.curios.has("moon_cameo"), "Level 1 must grant the Moon Cameo")
	_expect(progress != null and int(progress.highest_level_unlocked) == 2, "winning Level 1 must unlock the provisional Level 2")
	var restoration_continue: Button = app.current_screen().get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button
	_expect(restoration_continue != null, "Level 1 completion must enter the House restoration screen state")
	if restoration_continue != null:
		restoration_continue.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "house", "restoration Continue must return to House")
	var replay_button: Button = app.current_screen().get_node("Layout/PlayButton")
	_expect(not replay_button.disabled and replay_button.text == "PLAY LEVEL 2", "House must offer the next provisional review level after restoration completes")
	_expect(app.show_chapters(), "House must reopen chapter selection after Level 1 restoration")
	await process_frame
	var replay_chapters = app.current_screen()
	_expect(str(replay_chapters.name) == "ChapterSelect", "chapter selection must be reachable")
	replay_chapters.get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "map", "Curio Boutique selection must open chapter map")
	var map = app.current_screen()
	_expect(map.get_level_button(2) != null and not map.get_level_button(2).disabled, "Level 2 must unlock after Level 1 completion")
	_expect(map.get_level_button(3) != null and map.get_level_button(3).disabled, "Level 3 must stay progression-locked until Level 2 completion")
	_expect(app.show_prestart(2), "Level 2 prestart must be accessible in the internal review after Level 1 win")
	_expect(app.current_screen().get_node("Layout/Back").text == "BACK TO MAP", "map-origin prestart must identify the correct back destination")
	app.current_screen().get_node("Layout/Back").emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "map", "map-origin prestart Back must return to chapter map")
	_expect(app.current_screen().get_level_button(2) != null, "returning from prestart must restore chapter level controls")
	app.queue_free()
	await process_frame
	var relaunched = packed.instantiate()
	relaunched.set("save_path_override", TEST_PATH)
	relaunched.set("settings_path_override", SETTINGS_PATH)
	root.add_child(relaunched)
	await process_frame
	await process_frame
	_expect(str(relaunched.current_route_name()) == "boot", "relaunch must show splash before House")
	var relaunch_splash = relaunched.current_screen()
	_expect(relaunch_splash != null and relaunch_splash.get_node_or_null("Layout/Enter") != null, "relaunch splash must expose enter")
	relaunch_splash.get_node("Layout/Enter").emit_signal("pressed")
	await process_frame
	await process_frame
	var restored = relaunched.get("progress")
	_expect(str(relaunched.current_route_name()) == "house", "relaunch splash must enter House")
	_expect(restored != null and int(restored.house_stage) == 1, "relaunch must preserve Level 1 House restoration")
	_expect(restored != null and restored.curios.count("moon_cameo") == 1, "relaunch must preserve Moon Cameo exactly once")
	_expect(relaunched.current_screen().get_node("Layout/PlayButton").text == "PLAY LEVEL 2", "saved House must offer unlocked Level 2")
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
		print("TEST_PASS: Level 1 unlock and replay journey")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
