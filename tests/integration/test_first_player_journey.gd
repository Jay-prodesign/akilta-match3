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

	var play_button: Button = house.get_node("Layout/PlayButton")
	play_button.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "map", "House primary CTA must enter the current Curio Boutique route")
	var route = app.current_screen()
	_expect(route != null and route.get_level_button(1) != null and not route.get_level_button(1).disabled, "Golden Loop route must expose playable Level 1")
	route.get_level_button(1).emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "prestart", "Level 1 node must enter the focused pre-start")
	var prestart = app.current_screen()
	_expect(str(prestart.name) == "LevelPrestart", "route Level 1 node must open the Level 1 screen contract")
	_expect(prestart.get_node_or_null("ProductNavigation") == null, "pre-start must not carry the meta bottom navigation")
	var prestart_back: Button = prestart.get_node_or_null("Layout/Back") as Button
	_expect(prestart_back != null, "pre-start must own a focused back affordance")
	var objective: Label = prestart.get_node("Layout/Card/Content/Objective")
	_expect(objective.text == "GOAL · GATHER 6 MOON SIGILS", "prestart must reflect the canonical Level 1 collect-family objective")
	_expect(prestart.has_method("aid_asset_contract"), "prestart must expose its contract-owned aid artwork")
	if prestart.has_method("aid_asset_contract"):
		var prestart_aids: Dictionary = prestart.aid_asset_contract()
		_expect(bool(prestart_aids.get("raster_runtime", false)), "prestart aids must use raster runtime artwork")
		var prestart_loaded: Dictionary = prestart_aids.get("loaded", {})
		_expect(bool(prestart_loaded.get("hint", false)), "prestart Hint artwork must load")
		_expect(bool(prestart_loaded.get("plus_moves", false)), "prestart +3 Moves artwork must load")
	var start_button: Button = prestart.get_node("Layout/Card/Content/Start")
	start_button.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "gameplay", "prestart must enter gameplay")
	var gameplay = app.current_screen()
	_expect(str(gameplay.current_level_id) == "ch01_level_001", "gameplay must load canonical Level 1")
	_expect(gameplay.get_node_or_null("ProductNavigation") == null and gameplay.get_node_or_null("BottomNavigation") == null, "gameplay must remain a focused play surface without meta bottom navigation")
	_expect(gameplay.show_pause(), "Level 1 must expose a safe pause state")
	_expect(gameplay.pause_overlay.visible, "pause overlay must become visible")
	_expect(str(app.current_route_name()) == "gameplay", "pause must not change the product route")
	_expect(gameplay.attempt_swap(Vector2i(1, 4), Vector2i(2, 4)) == null, "board input must be blocked while paused")
	_expect(gameplay.resume_level(), "paused Level 1 must resume")
	_expect(not gameplay.pause_overlay.visible, "resume must close pause overlay")
	_expect(app.audio_director != null and bool(app.audio_director.contract().get("ambient_loaded", false)), "Level 1 app shell must own the CC0 ambient director")
	_expect(gameplay.get_node_or_null("BoosterTray") != null, "gameplay must expose the touch booster tray")
	_expect(gameplay.has_method("booster_asset_contract"), "gameplay must expose the booster art/state contract")
	if gameplay.has_method("booster_asset_contract"):
		var booster_assets: Dictionary = gameplay.booster_asset_contract()
		_expect(bool(booster_assets.get("raster_runtime", false)), "gameplay booster tray must use raster runtime artwork")
		var loaded_boosters: Dictionary = booster_assets.get("loaded", {})
		for booster_key in ["hint", "plus_moves", "retry"]:
			_expect(bool(loaded_boosters.get(booster_key, false)), "%s booster artwork must load" % booster_key)
	var booster_row: HBoxContainer = gameplay.get_node("BoosterTray/BoosterActions")
	var hint_booster: Button = booster_row.get_node("HintBoost")
	var potion_booster: Button = booster_row.get_node("PlusMovesBoost")
	hint_booster.emit_signal("pressed")
	_expect(gameplay.hint_label.text == "Follow the moonlit highlight for a legal match.", "hint booster must find and highlight a legal move")
	var moves_before_potion := int(gameplay.board_state.moves_remaining)
	potion_booster.emit_signal("pressed")
	_expect(int(gameplay.board_state.moves_remaining) == moves_before_potion + 3, "potion booster must grant three moves")
	_expect(potion_booster.disabled, "+3 Moves booster must visibly disable after its one allowed use")
	if gameplay.has_method("booster_asset_contract"):
		_expect(bool(gameplay.booster_asset_contract().get("plus_moves_disabled", false)), "booster contract must expose consumed +3 Moves state")
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
	_expect(str(app.current_route_name()) == "restoration", "first-time win must route through explicit House Restoration")
	var progress = app.get("progress")
	_expect(int(progress.house_stage) == 1, "House must awaken to stage 1")
	_expect(progress.curios.count("moon_cameo") == 1, "Moon Cameo must persist exactly once")
	var awakened_house = app.current_screen()
	var awakened_cameo: Control = awakened_house.get_node("Layout/RoomView/MoonCameoOverlay")
	_expect(awakened_cameo.visible, "awakened House must display the same shared Moon Cameo component")
	_expect(String(awakened_cameo.get("mode")) == "house", "House relic must use the shared Moon Cameo house mode")

	var restoration_overlay: Control = awakened_house.get_node_or_null("RestorationOverlay") as Control
	_expect(restoration_overlay != null, "first-time Level 1 win must enter the same-camera House restoration state")
	var restoration_continue: Button = awakened_house.get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button
	_expect(restoration_continue != null, "House restoration must expose a focused Continue CTA")
	if restoration_continue != null:
		restoration_continue.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "house", "restoration Continue must return to House")
	var house_curios_nav: Button = awakened_house.get_node_or_null("ProductNavigation/Scroll/Items/NavCurios") as Button
	_expect(house_curios_nav != null and house_curios_nav.visible, "House navigation must return after restoration completes")
	if house_curios_nav != null:
		house_curios_nav.emit_signal("pressed")
	await process_frame
	_expect(str(app.current_route_name()) == "collection", "House Curios control must open collection")
	var collection = app.current_screen()
	var moon_state: Label = collection.get_node("Layout/Cards/MoonCard/Content/State")
	_expect(moon_state.text.begins_with("AWAKENED"), "Moon Cameo must be inspectable as awakened in collection")
	_expect(collection.has_method("curio_asset_contract"), "Curio Collection must expose the production Curio asset contract")
	if collection.has_method("curio_asset_contract"):
		var curio_assets: Dictionary = collection.curio_asset_contract()
		_expect(bool(curio_assets.get("raster_runtime", false)), "Reliquary must use one raster runtime family for all opening Curios")
		var loaded_curios: Dictionary = curio_assets.get("loaded", {})
		for asset_key in ["moon_sealed", "moon_awakened", "moth_reliquary", "thorned_locket"]:
			_expect(bool(loaded_curios.get(asset_key, false)), "%s production Curio art must load in Reliquary" % asset_key)
	var moon_details: Button = collection.get_node_or_null("Layout/Cards/MoonCard/DetailActionLayer/InspectAction") as Button
	_expect(moon_details != null, "awakened Moon Cameo card must expose Curio Detail")
	if moon_details != null:
		moon_details.emit_signal("pressed")
		await process_frame
		var detail_state: Label = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/State") as Label
		var detail_origin: Label = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/Origin") as Label
		_expect(detail_state != null and detail_state.text.contains("AWAKENED"), "Curio Detail must verify owned state truthfully")
		_expect(detail_origin != null and detail_origin.text.contains("LEVEL 1"), "Curio Detail must preserve the earned origin")
		var detail_close: Button = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/Close") as Button
		_expect(detail_close != null, "Curio Detail must be dismissible")
		if detail_close != null:
			detail_close.emit_signal("pressed")
			await process_frame
		_expect(collection.get_node_or_null("CurioDetailOverlay") == null, "closing Curio Detail must return to the Reliquary")
	var collection_nav = collection.get_node_or_null("ProductNavigation")
	_expect(collection_nav != null, "Curio Collection must retain the shared product navigation")
	if collection_nav != null:
		collection_nav.get_node("Scroll/Items/NavEvents").emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "events", "Events destination must own a real route instead of masquerading as House")
	var events_preview = app.current_screen()
	_expect(events_preview != null and events_preview.name == "EventsScreen" and events_preview.get_node("FeatureLayout/FeatureTitle").text == "EVENT CENTER", "Events tab must open as the S10 Event Center screen")
	_expect(events_preview != null and events_preview.get_node_or_null("ProductNavigation") != null, "Events screen must retain shared product navigation")
	if events_preview != null:
		var weekly_action: Button = events_preview.get_node_or_null("FeatureLayout/WeeklyMissionsAction") as Button
		_expect(weekly_action != null, "Event Center must expose the S09 Weekly Rituals destination")
		if weekly_action != null:
			weekly_action.emit_signal("pressed")
			await process_frame
			await process_frame
			_expect(str(app.current_route_name()) == "missions", "Weekly Rituals must own the S09 MISSIONS route")
			var mission_screen = app.current_screen()
			_expect(mission_screen != null and mission_screen.name == "WeeklyMissionsScreen", "S09 must render as its own route-backed screen")
			var mission_timer: Label = mission_screen.get_node_or_null("MissionLayout/MissionTimer") as Label if mission_screen != null else null
			var mission_empty: PanelContainer = mission_screen.get_node_or_null("MissionLayout/MissionEmptyState") as PanelContainer if mission_screen != null else null
			var mission_art: TextureRect = mission_screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/MissionRewardArt") as TextureRect if mission_screen != null else null
			var mission_availability: Label = mission_screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/MissionAvailability") as Label if mission_screen != null else null
			var mission_truth: Label = mission_screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/MissionEmptyStateTruth") as Label if mission_screen != null else null
			_expect(mission_timer != null and mission_timer.text.contains("OFFLINE"), "S09 must disclose unavailable live reset timing")
			_expect(mission_truth != null and mission_truth.text.contains("NOTHING TO CLAIM"), "S09 must not fabricate claimable weekly rewards")
			_expect(mission_empty != null and String(mission_empty.get_meta("offline_contract", "")) == "truthful_empty_state", "S09 must identify the truthful offline empty-state contract")
			_expect(mission_empty != null and mission_empty.size_flags_vertical == Control.SIZE_EXPAND_FILL, "S09 offline altar must own the available vertical stage rather than look like a small unfinished card")
			_expect(mission_art != null and mission_art.texture != null and String(mission_art.get_meta("asset_path", "")).ends_with(".webp"), "S09 offline altar must use production raster Curio artwork")
			_expect(mission_availability != null and mission_availability.text.contains("ONLY WHEN A MISSION FEED IS CONNECTED"), "S09 must explain when live rituals can appear without fabricating a schedule")
			if mission_screen != null:
				mission_screen.get_node("MissionLayout/ReturnToEvents").emit_signal("pressed")
				await process_frame
				await process_frame
			_expect(str(app.current_route_name()) == "events", "S09 back must return to S10 Event Center")
			events_preview = app.current_screen()
	if events_preview != null:
		events_preview.get_node("ProductNavigation/Scroll/Items/NavShop").emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(str(app.current_route_name()) == "shop", "Shop destination must own a real route")
	var shop_preview = app.current_screen()
	_expect(shop_preview != null and shop_preview.name == "ShopScreen" and shop_preview.get_node("FeatureLayout/FeatureTitle").text == "THE CURIO EMPORIUM", "Shop must open directly from Events navigation")
	_expect(shop_preview != null and shop_preview.get_node_or_null("ProductNavigation") != null, "Shop screen must retain shared product navigation")
	_expect(shop_preview != null and shop_preview.get_node_or_null("FeatureLayout/NoPurchasesNotice") != null, "Shop must truthfully expose that purchases are disabled")
	var shop_currency: Label = shop_preview.get_node_or_null("FeatureLayout/ShopCurrencySummary") as Label if shop_preview != null else null
	var shop_truth: Label = shop_preview.get_node_or_null("FeatureLayout/ShopCurrencyTruth") as Label if shop_preview != null else null
	var shop_offer_art: TextureRect = shop_preview.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/ShopFeaturedOfferArt") as TextureRect if shop_preview != null else null
	var shop_disabled_action: Button = shop_preview.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/ShopDisabledAction") as Button if shop_preview != null else null
	_expect(shop_currency != null and shop_currency.text.contains("HOUSE COINS") and shop_currency.text.contains("MOONSTONES"), "Shop must expose real local currency balances")
	_expect(shop_truth != null and shop_truth.text.contains("NOT PURCHASABLE"), "Shop balances must be explicitly non-purchasable")
	_expect(shop_offer_art != null and shop_offer_art.texture != null, "Shop featured offer must own content artwork")
	_expect(shop_disabled_action != null and shop_disabled_action.disabled, "Shop commerce CTA must remain disabled before commerce is connected")
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
		_expect(str(app.current_route_name()) == "restoration", "first-time Level 2 reward must enter S07 restoration before House")
		var level2_restoration: Button = app.current_screen().get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button
		_expect(level2_restoration != null, "Level 2 restoration must expose Continue")
		if level2_restoration != null:
			level2_restoration.emit_signal("pressed")
		await process_frame
		_expect(str(app.current_route_name()) == "house", "Level 2 restoration Continue must return to S01 House")
		_expect(int(app.progress.highest_level_unlocked) == 3, "Level 2 win must unlock Level 3")
		_expect(app.progress.curios.has("moth_reliquary"), "Level 2 reward must persist")
		_expect(app.show_chapters(), "House must reopen chapter selection after Level 2 restoration")
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
			_expect(str(app.current_route_name()) == "restoration", "first-time Level 3 reward must enter S07 restoration before House")
			var level3_restoration: Button = app.current_screen().get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button
			_expect(level3_restoration != null, "Level 3 restoration must expose Continue")
			if level3_restoration != null:
				level3_restoration.emit_signal("pressed")
			await process_frame
			_expect(str(app.current_route_name()) == "house", "Level 3 restoration Continue must return to S01 House")
			_expect(app.progress.curios.has("thorned_locket"), "Level 3 must grant Thorned Locket")
			_expect(int(app.progress.house_stage) >= 3, "Level 3 must restore House stage 3")
			_expect(not app.show_prestart(4), "Level 4 must remain inaccessible after Level 3 win")
			_expect(app.show_chapters(), "completed opening chapter must reopen chapter selection")
			await process_frame
			app.current_screen().get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
			await process_frame
			var completed_map = app.current_screen()
			var completed_progress: Label = completed_map.get_node("Layout/Progress")
			var completed_intro: Label = completed_map.get_node("Layout/Intro")
			_expect(completed_progress.text.contains("3 / 3"), "completed Curio Boutique map must show 3 / 3 displays awakened")
			_expect(completed_intro.text.begins_with("The opening cabinet set is restored"), "completed map must stop instructing the player to restore already-awakened displays")
			var completed_route = completed_map.get_node("Layout/RoutePanel/Scroll/RouteView")
			_expect(completed_route.get_node("Label2").text.contains("MOTH RELIQUARY RECOVERED"), "completed Level 2 map node must preserve its Curio consequence")
			_expect(completed_route.get_node("Label3").text.contains("THORNED LOCKET RECOVERED"), "completed Level 3 map node must preserve its Curio consequence")
			_expect(completed_map.get_level_button(4) != null and completed_map.get_level_button(4).disabled, "completed opening chapter must keep Level 4 sealed")
			_expect(app.show_house(), "completed map must return safely to House")
			var completed_house = app.current_screen()
			var completion_banner: PanelContainer = completed_house.get_node_or_null("Layout/ChapterCompletionBanner")
			var completion_label: Label = completed_house.get_node_or_null("Layout/ChapterCompletionBanner/Label")
			_expect(completion_banner != null and completion_banner.visible, "completed House must show the opening cabinet completion banner")
			_expect(completion_label != null and completion_label.text.contains("OPENING CABINET SET COMPLETE"), "completed House banner must name the opening cabinet completion")
			_expect(app.show_feature_preview("Events"), "completed House must open Events")
			await process_frame
			_expect(str(app.current_route_name()) == "events", "completed House must enter the Events route")
			var completed_event_progress: Label = app.current_screen().get_node_or_null("FeatureLayout/ChapterRitualProgress")
			_expect(completed_event_progress != null and completed_event_progress.text.begins_with("OPENING RITUAL COMPLETE"), "Events must reflect the completed 3/3 opening ritual")
			app.current_screen().get_node("FeatureLayout/BackToHouse").emit_signal("pressed")
			await process_frame
			_expect(app.show_feature_preview("Profile"), "completed House must open Profile")
			await process_frame
			_expect(str(app.current_route_name()) == "profile_settings", "Profile must own the S12 route")
			var profile_preview = app.current_screen()
			var profile_copy := ""
			if profile_preview != null:
				for label_node in profile_preview.find_children("", "Label", true, false):
					profile_copy += (label_node as Label).text + "\n"
			_expect(profile_copy.contains("FIRST CABINET SET RESTORED"), "Profile must summarize the completed opening chapter")
			_expect(profile_copy.contains("OPENING RESTORATION COMPLETE"), "Profile must summarize the completed House restoration")
			var profile_settings_button: Button = profile_preview.get_node_or_null("FeatureLayout/ProfileSettings") as Button
			_expect(profile_settings_button != null, "Profile must expose its real Settings state")
			if profile_settings_button != null:
				profile_settings_button.emit_signal("pressed")
				await process_frame
				_expect(app.navigation.is_settings_open(), "Profile Settings must open without leaving S12")
				_expect(str(app.current_route_name()) == "profile_settings", "Settings modal must preserve the Profile route")
				var settings_panel = app.get_node_or_null("ScreenHost/SettingsPanel")
				var settings_close: Button = settings_panel.get_node_or_null("Card/Content/Close") as Button if settings_panel != null else null
				var reduced: CheckButton = settings_panel.get_node_or_null("Card/Content/Reduced") as CheckButton if settings_panel != null else null
				var saved_note: Label = settings_panel.get_node_or_null("Card/Content/SavedNote") as Label if settings_panel != null else null
				_expect(settings_close != null and settings_close.text == "RETURN TO PROFILE", "Profile-origin Settings must return to Profile")
				_expect(reduced != null and saved_note != null, "Settings controls and saved-state feedback must exist")
				if reduced != null:
					reduced.button_pressed = true
					reduced.emit_signal("toggled", true)
					await process_frame
				_expect(bool(app.user_settings.get_value("reduced_motion", false)), "Settings change must persist into user settings")
				_expect(saved_note != null and saved_note.text.contains("SAVED ON THIS DEVICE"), "Settings changed state must visibly confirm persistence")
				_expect(app.close_settings(), "Profile Settings must close cleanly")
				_expect(app.current_screen() == profile_preview and str(app.current_route_name()) == "profile_settings", "closing Settings must reveal the original Profile screen")
			app.current_screen().get_node("FeatureLayout/BackToHouse").emit_signal("pressed")
			await process_frame
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
