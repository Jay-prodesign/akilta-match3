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

	_expect(str(app.current_route_name()) == "boot", "new player must remain in BOOT while splash is visible")
	var splash = app.current_screen()
	_expect(splash != null and splash.get_node_or_null("Layout/Enter") != null, "new player must see the authored splash entry surface")
	splash.get_node("Layout/Enter").emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "house", "splash entry must route into House")
	var house = app.current_screen()
	var dormant_cameo: Control = house.get_node("Layout/RoomView/MoonCameoOverlay")
	_expect(not dormant_cameo.visible, "Moon Cameo physical relic must stay hidden before Level 1 is won")
	var settings_button: Button = house.get_node("Layout/ActionDock/Actions/SettingsButton")
	settings_button.emit_signal("pressed")
	await process_frame
	_expect(app.navigation.is_settings_open(), "House settings must open")
	_expect(app.close_settings(), "settings must close cleanly")

	var map_button: Button = house.get_node("Layout/PlayButton")
	map_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "house", "chapter selector remains in House navigation state")
	var chapters = app.current_screen()
	_expect(str(chapters.name) == "ChapterSelect", "House Play CTA must open chapter selection")
	_expect(chapters.get_node_or_null("ProductNavigation") != null, "Chapter Select must retain the shared product navigation")
	chapters.get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "map", "Curio Boutique selection must open its level map")
	var map = app.current_screen()
	_expect(str(map.name) == "ChapterMap", "Curio Boutique must open the authored chapter map")
	_expect(map.get_node_or_null("ProductNavigation") != null, "Chapter Map must retain the shared product navigation")
	var level1_button: Button = map.get_level_button(1)
	var level2_button: Button = map.get_level_button(2)
	_expect(level1_button != null and not level1_button.disabled, "Level 1 must be selectable")
	_expect(level2_button != null and level2_button.disabled, "Level 2 remains progression-locked until Level 1 is won")
	_expect(map.get_level_button(3) != null and map.get_level_button(3).disabled, "Level 3 remains progression-locked until Level 2 is won")
	_expect(map.get_level_button(4) != null and map.get_level_button(4).disabled, "Level 4 and later must remain sealed beyond the three-level playtest scope")

	level1_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "prestart", "Level 1 selection must open prestart")
	var prestart = app.current_screen()
	var prestart_nav = prestart.get_node_or_null("ProductNavigation")
	_expect(prestart_nav != null, "prestart must keep the product bottom navigation available")
	if prestart_nav != null:
		var nav_house := prestart_nav.get_node_or_null("Scroll/Items/NavHouse") as Button
		_expect(nav_house != null, "prestart bottom navigation must expose House")
		if nav_house != null:
			nav_house.emit_signal("pressed")
			await process_frame
			await process_frame
			_expect(str(app.current_route_name()) == "house", "prestart House navigation must unwind safely without stranding the route")
			_expect(app.show_chapters(), "House must reopen chapters after leaving prestart from bottom navigation")
			await process_frame
			app.current_screen().get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
			await process_frame
			var reopened_map = app.current_screen()
			var reopened_level1: Button = reopened_map.get_level_button(1)
			_expect(reopened_level1 != null and not reopened_level1.disabled, "Level 1 must remain selectable after prestart navigation recovery")
			if reopened_level1 != null:
				reopened_level1.emit_signal("pressed")
				await process_frame
			prestart = app.current_screen()
			_expect(str(app.current_route_name()) == "prestart", "Level 1 prestart must reopen after shell navigation recovery")
	var objective: Label = prestart.get_node("Layout/Card/Content/Objective")
	_expect(objective.text == "GOAL · GATHER 6 MOON SIGILS", "prestart must reflect the canonical Level 1 collect-family objective")
	var start_button: Button = prestart.get_node("Layout/Card/Content/Start")
	start_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "gameplay", "prestart must enter gameplay")
	var gameplay = app.current_screen()
	_expect(str(gameplay.current_level_id) == "ch01_level_001", "gameplay must load canonical Level 1")
	_expect(gameplay.show_pause(), "Level 1 must expose a safe pause state")
	_expect(gameplay.pause_overlay.visible, "pause overlay must become visible")
	_expect(str(app.current_route_name()) == "gameplay", "pause must not change the product route")
	_expect(gameplay.attempt_swap(Vector2i(1, 4), Vector2i(2, 4)) == null, "board input must be blocked while paused")
	_expect(gameplay.resume_level(), "paused Level 1 must resume")
	_expect(not gameplay.pause_overlay.visible, "resume must close pause overlay")
	_expect(app.audio_director != null and bool(app.audio_director.contract().get("ambient_loaded", false)), "Level 1 app shell must own the CC0 ambient director")
	_expect(gameplay.get_node_or_null("BoosterTray") != null, "gameplay must expose the touch booster tray")
	var booster_row: HBoxContainer = gameplay.get_node("BoosterTray").get_child(0)
	var hint_booster: Button = booster_row.get_child(0)
	var potion_booster: Button = booster_row.get_child(1)
	hint_booster.emit_signal("pressed")
	_expect(gameplay.hint_label.text == "Follow the moonlit highlight for a legal match.", "hint booster must find and highlight a legal move")
	var moves_before_potion := int(gameplay.board_state.moves_remaining)
	potion_booster.emit_signal("pressed")
	_expect(int(gameplay.board_state.moves_remaining) == moves_before_potion + 3, "potion booster must grant three moves")
	potion_booster.emit_signal("pressed")
	_expect(int(gameplay.board_state.moves_remaining) == moves_before_potion + 3, "potion booster must be limited to once per attempt")

	var trace = gameplay.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	_expect(trace != null and trace.accepted and str(trace.result) == "won", "Level 1 teaching swipe must win")
	var board_view = gameplay.get_node("Layout/BoardView")
	if bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished
	_expect(gameplay.result_overlay.visible, "result beat must appear after motion")
	var win_ritual: Control = gameplay.get_node("ResultOverlay/Card/Content/RewardRitual")
	_expect(String(win_ritual.get("mode")) == "result", "win must reveal the awakened Moon Cameo reward treatment")
	_expect(app.audio_director.get_feedback_count("special") + app.audio_director.get_feedback_count("match") >= 1, "accepted teaching move must produce semantic audio feedback")
	_expect(app.audio_director.get_feedback_count("win") == 1, "Level 1 terminal win must produce one win audio cue")
	_expect(gameplay.continue_after_win(), "win continue must commit progression")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "house", "win must return to House")
	var progress = app.get("progress")
	_expect(int(progress.house_stage) == 1, "House must awaken to stage 1")
	_expect(progress.curios.count("moon_cameo") == 1, "Moon Cameo must persist exactly once")
	var awakened_house = app.current_screen()
	var awakened_cameo: Control = awakened_house.get_node("Layout/RoomView/MoonCameoOverlay")
	_expect(awakened_cameo.visible, "awakened House must display the same shared Moon Cameo component")
	_expect(String(awakened_cameo.get("mode")) == "house", "House relic must use the shared Moon Cameo house mode")

	var collection_button: Button = awakened_house.get_node("Layout/ActionDock/Actions/CollectionButton")
	collection_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "collection", "House Curios control must open collection")
	var collection = app.current_screen()
	var moon_state: Label = collection.get_node("Layout/Cards/MoonCard/Content/State")
	_expect(moon_state.text.begins_with("AWAKENED"), "Moon Cameo must be inspectable as awakened in collection")
	var collection_nav = collection.get_node_or_null("ProductNavigation")
	_expect(collection_nav != null, "Curio Collection must retain the shared product navigation")
	if collection_nav != null:
		collection_nav.get_node("Scroll/Items/NavEvents").emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "house", "secondary navigation must return to House authority before opening Events")
	var events_preview = app.get_node_or_null("ScreenHost/FeaturePreview")
	_expect(events_preview != null and events_preview.get_node("FeatureLayout/FeatureTitle").text == "WEEKLY RITUALS", "Events tab must open from shared product navigation")
	_expect(events_preview != null and events_preview.get_node_or_null("ProductNavigation") != null, "Events preview must retain shared product navigation")
	if events_preview != null:
		events_preview.get_node("ProductNavigation/Scroll/Items/NavShop").emit_signal("pressed")
	await process_frame
	await process_frame
	var shop_preview = app.get_node_or_null("ScreenHost/FeaturePreview")
	_expect(shop_preview != null and shop_preview.get_node("FeatureLayout/FeatureTitle").text == "THE CURIO EMPORIUM", "Shop must open directly from Events navigation")
	_expect(shop_preview != null and shop_preview.get_node_or_null("ProductNavigation") != null, "Shop preview must retain shared product navigation")
	if shop_preview != null:
		shop_preview.get_node("ProductNavigation/Scroll/Items/NavHouse").emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "house", "shared product navigation must return Shop to House")

	# Founder-authorized internal review unlocks Level 2 after Level 1, but keeps Level 4+ sealed.
	_expect(app.show_chapters(), "House must reopen chapter selection for internal review")
	await process_frame
	var chapters_after_win = app.current_screen()
	chapters_after_win.get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
	await process_frame
	var review_map = app.current_screen()
	_expect(review_map.get_level_button(2) != null and not review_map.get_level_button(2).disabled, "winning Level 1 must unlock Level 2 in the authorized internal review")
	_expect(review_map.get_level_button(3) != null and review_map.get_level_button(3).disabled, "Level 3 remains progression-gated until Level 2 is won")
	_expect(review_map.get_level_button(4) != null and review_map.get_level_button(4).disabled, "Level 4 remains sealed outside internal review")
	_expect(app.show_prestart(2), "authorized Level 2 must open its own prestart")
	_expect(not app.start_level(3), "prestart for Level 2 must not launch a different level")
	_expect(app.start_level(2), "authorized Level 2 must enter gameplay")
	_expect(str(app.current_screen().current_level_id) == "ch01_level_002", "Level 2 must load its authored Wax Seal board")
	var level2 = app.current_screen()
	var level2_file = FileAccess.open("res://content/levels/ch01/level_002.json", FileAccess.READ)
	_expect(level2_file != null, "Level 2 authored teaching moves must be available")
	if level2_file != null:
		var level2_data = JSON.parse_string(level2_file.get_as_text())
		level2_file.close()
		if level2_data is Dictionary:
			for move in level2_data.get("teaching_moves", []):
				var trace2 = level2.attempt_swap(Vector2i(int(move[0]), int(move[1])), Vector2i(int(move[2]), int(move[3])))
				_expect(trace2 != null and trace2.accepted, "Level 2 teaching move must be accepted")
				var board2 = level2.get_node_or_null("Layout/BoardView")
				if board2 != null and board2.has_method("is_motion_active") and bool(board2.is_motion_active()) and board2.has_signal("trace_motion_finished"):
					await board2.trace_motion_finished
				await process_frame
				if level2.result_overlay.visible:
					break
	_expect(level2.result_overlay.visible, "Level 2 must reach the Moth Reliquary reward")
	if level2.result_overlay.visible:
		_expect(level2.continue_after_win(), "Level 2 win must save progression")
		await process_frame
		await process_frame
		_expect(int(app.progress.highest_level_unlocked) == 3, "Level 2 win must unlock Level 3")
		_expect(app.progress.curios.has("moth_reliquary"), "Level 2 reward must persist")
		_expect(app.show_chapters(), "House must reopen chapter selection after Level 2")
		await process_frame
		app.current_screen().get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
		await process_frame
		var third_map = app.current_screen()
		_expect(third_map.get_level_button(3) != null and not third_map.get_level_button(3).disabled, "Level 3 must unlock on the map")
		_expect(third_map.get_level_button(4) != null and third_map.get_level_button(4).disabled, "Level 4 must remain sealed")
		_expect(app.show_prestart(3), "Level 3 prestart must open")
		_expect(not app.start_level(2), "Level 3 prestart must not launch Level 2")
		_expect(app.start_level(3), "Level 3 gameplay must load")
		_expect(str(app.current_screen().current_level_id) == "ch01_level_003", "Level 3 must use authored Thornlight board")
		var level3 = app.current_screen()
		var level3_file = FileAccess.open("res://content/levels/ch01/level_003.json", FileAccess.READ)
		_expect(level3_file != null, "Level 3 authored teaching moves must be available")
		if level3_file != null:
			var level3_data = JSON.parse_string(level3_file.get_as_text())
			level3_file.close()
			if level3_data is Dictionary:
				for move in level3_data.get("teaching_moves", []):
					var trace3 = level3.attempt_swap(Vector2i(int(move[0]), int(move[1])), Vector2i(int(move[2]), int(move[3])))
					_expect(trace3 != null and trace3.accepted, "Level 3 teaching move must be accepted")
					var board3 = level3.get_node_or_null("Layout/BoardView")
					if board3 != null and board3.has_method("is_motion_active") and bool(board3.is_motion_active()) and board3.has_signal("trace_motion_finished"):
						await board3.trace_motion_finished
					await process_frame
					if level3.result_overlay.visible:
						break
		_expect(level3.result_overlay.visible, "Level 3 must reach the Thorned Locket reward")
		if level3.result_overlay.visible:
			_expect(level3.continue_after_win(), "Level 3 win must save progression")
			await process_frame
			await process_frame
			_expect(app.progress.curios.has("thorned_locket"), "Level 3 must grant Thorned Locket")
			_expect(int(app.progress.house_stage) >= 3, "Level 3 must restore House stage 3")
			_expect(not app.show_prestart(4), "Level 4 must remain inaccessible after Level 3 win")
		else:
			_expect(app.show_house(), "unfinished Level 3 must safely return to House")
	else:
		_expect(app.show_house(), "unfinished Level 2 must safely return to House")

	app.queue_free()
	await process_frame

	var relaunched = packed.instantiate()
	relaunched.set("save_path_override", TEST_PATH)
	relaunched.set("settings_path_override", SETTINGS_PATH)
	root.add_child(relaunched)
	await process_frame
	await process_frame
	_expect(str(relaunched.current_route_name()) == "boot", "relaunch must preserve the authored splash first impression")
	var relaunch_splash = relaunched.current_screen()
	_expect(relaunch_splash != null and relaunch_splash.get_node_or_null("Layout/Enter") != null, "relaunch splash must expose the enter control")
	relaunch_splash.get_node("Layout/Enter").emit_signal("pressed")
	await process_frame
	await process_frame
	var restored = relaunched.get("progress")
	_expect(str(relaunched.current_route_name()) == "house", "splash entry after relaunch must return to House")
	_expect(int(restored.house_stage) >= 1, "relaunch must preserve House awakening stage")
	_expect(int(restored.highest_level_unlocked) >= 2, "relaunch must preserve unlocked review level")
	_expect(restored.curios.count("moon_cameo") == 1, "relaunch must preserve Moon Cameo")
	if int(restored.highest_level_unlocked) >= 3:
		_expect(restored.curios.count("moth_reliquary") == 1, "relaunch must preserve earned Moth Reliquary exactly once")
	if restored.completed_levels.has("ch01_level_003"):
		_expect(restored.curios.count("thorned_locket") == 1, "relaunch must preserve Thorned Locket exactly once")
		_expect(int(restored.house_stage) >= 3, "relaunch must preserve House stage 3")
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
		print("TEST_PASS: complete three-level review shell journey")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
