extends SceneTree

const BOOTSTRAP_SCENE := "res://src/app/app_bootstrap.tscn"
const TEST_PATH := "user://akilta_match3_opening_journey_test.json"
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
	root.add_child(app)
	await process_frame
	_expect(str(app.current_route_name()) == "gameplay", "new player must boot into gameplay")
	var level1 = app.current_screen()
	_expect(level1 != null and str(level1.current_level_id) == "ch01_level_001", "opening route must load authored Level 1")
	var first_trace = level1.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	_expect(first_trace != null and first_trace.accepted, "Level 1 teaching swipe must be accepted")
	_expect(first_trace != null and str(first_trace.result) == "won", "Level 1 teaching swipe must produce the first win")
	_expect(level1.result_overlay.visible, "win must hold on a result beat before routing away")
	_expect(str(app.current_route_name()) == "gameplay", "win beat must remain on gameplay until player continues")
	_expect(level1.continue_after_win(), "win continue must commit the journey")
	await process_frame
	_expect(str(app.current_route_name()) == "house", "Level 1 continue must route to House")
	var progress = app.get("progress")
	_expect(progress != null and int(progress.house_stage) == 1, "Level 1 must awaken House stage 1")
	_expect(progress != null and progress.curios.has("moon_cameo"), "Level 1 must grant Moon Cameo exactly once")
	var house = app.current_screen()
	var button: Button = house.get_node("Layout/PlayButton")
	_expect(not button.disabled and button.text == "ENTER LEVEL 2", "House must expose real Level 2 CTA")
	button.emit_signal("pressed")
	await process_frame
	var level2 = app.current_screen()
	_expect(str(app.current_route_name()) == "gameplay", "House CTA must route back into gameplay")
	_expect(level2 != null and str(level2.current_level_id) == "ch01_level_002", "CTA must load authored Level 2, not replay Level 1")
	_expect(str(level2.board_state.objective_type) == "clear_blockers", "Level 2 must teach Wax Seal objective")
	_expect(int(level2.board_state.remaining_blockers()) == 2, "Level 2 must begin with two Wax Seals")
	var second_trace = level2.attempt_swap(Vector2i(4, 2), Vector2i(4, 3))
	_expect(second_trace != null and second_trace.accepted, "Level 2 teaching swipe must be accepted")
	_expect(second_trace != null and str(second_trace.result) == "won", "Level 2 teaching swipe must clear both Wax Seals")
	_expect(int(level2.board_state.remaining_blockers()) == 0, "Wax Seal tutorial must resolve both blockers")
	_expect(level2.continue_after_win(), "Level 2 win must continue to House")
	await process_frame
	progress = app.get("progress")
	_expect(str(app.current_route_name()) == "house", "Level 2 continue must return to House")
	_expect(progress != null and int(progress.house_stage) == 2, "Level 2 must awaken House stage 2")
	_expect(progress != null and progress.curios.has("moth_reliquary"), "Level 2 must grant Moth Reliquary")
	_expect(progress != null and int(progress.highest_level_unlocked) == 3, "Level 2 completion must advance progression cursor")
	var stage2_house = app.current_screen()
	var stage2_button: Button = stage2_house.get_node("Layout/PlayButton")
	_expect(not stage2_button.disabled and stage2_button.text == "ENTER LEVEL 3", "House must expose authored Level 3")
	stage2_button.emit_signal("pressed")
	await process_frame

	var level3 = app.current_screen()
	_expect(level3 != null and str(level3.current_level_id) == "ch01_level_003", "Level 3 CTA must open the authored line-special lesson")
	var create_trace = level3.attempt_swap(Vector2i(2, 3), Vector2i(2, 4))
	_expect(create_trace != null and create_trace.accepted, "Level 3 special-creation swipe must be accepted")
	_expect(create_trace != null and create_trace.event_types().has("special_created"), "Level 3 first move must generate a special")
	_expect(create_trace != null and str(create_trace.result) == "playing", "creating the Line special must not finish Level 3")
	_expect(level3.board_state.specials.size() >= 1, "generated Line special must remain on the board")
	var activate_trace = level3.attempt_swap(Vector2i(3, 3), Vector2i(3, 4))
	_expect(activate_trace != null and activate_trace.accepted, "Level 3 activation swipe must be accepted")
	_expect(activate_trace != null and activate_trace.event_types().has("special_triggered"), "Level 3 second move must trigger the generated Line special")
	_expect(activate_trace != null and str(activate_trace.result) == "won", "Line special must collect the key and win Level 3")
	_expect(level3.continue_after_win(), "Level 3 win must return to House")
	await process_frame

	progress = app.get("progress")
	_expect(int(progress.house_stage) == 3, "Level 3 must awaken House stage 3")
	_expect(progress.curios.has("thorned_locket"), "Level 3 must grant Thorned Locket")
	_expect(int(progress.highest_level_unlocked) == 4, "Level 3 completion must advance progression cursor")
	var stage3_house = app.current_screen()
	var stage3_button: Button = stage3_house.get_node("Layout/PlayButton")
	_expect(stage3_button.disabled, "House must not route into unauthored Level 4")
	_expect(stage3_button.text == "MORE CURIOS STIR SOON", "stage 3 must truthfully stop at current authored content")

	app.queue_free()
	await process_frame
	var relaunched = packed.instantiate()
	relaunched.set("save_path_override", TEST_PATH)
	root.add_child(relaunched)
	await process_frame
	var restored = relaunched.get("progress")
	_expect(str(relaunched.current_route_name()) == "house", "relaunch after progression must return to House")
	_expect(restored != null and int(restored.house_stage) == 3, "relaunch must preserve House stage 3")
	_expect(restored != null and restored.curios.count("moon_cameo") == 1, "Moon Cameo must remain exactly once")
	_expect(restored != null and restored.curios.count("moth_reliquary") == 1, "Moth Reliquary must remain exactly once")
	_expect(restored != null and restored.curios.count("thorned_locket") == 1, "Thorned Locket must remain exactly once")
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
		print("TEST_PASS: real three-level opening journey")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
