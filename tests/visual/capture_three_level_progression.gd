extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const SAVE_PATH := "user://capture_three_level_progression.json"
const SETTINGS_PATH := "user://capture_three_level_progression_settings.json"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	_cleanup()
	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await _frames(4)
	var splash = app.current_screen()
	var enter := splash.get_node_or_null("Layout/Enter") as Button if splash != null else null
	if enter == null:
		return _fail(app, "three-level journey splash entry missing")
	enter.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "house":
		return _fail(app, "three-level journey did not enter House")

	for level_number in [1, 2, 3]:
		if not await _play_level(app, level_number):
			return
		if String(app.current_route_name()) != "house":
			return _fail(app, "Level %d did not return to House" % level_number)
		if int(app.progress.house_stage) < level_number:
			return _fail(app, "Level %d did not advance House restoration" % level_number)
		var expected_curio: String = String(["moon_cameo", "moth_reliquary", "thorned_locket"][level_number - 1])
		if not app.progress.curios.has(expected_curio):
			return _fail(app, "Level %d did not persist %s" % [level_number, expected_curio])
		if not await _save(app, "progression-house-stage%d.png" % level_number):
			return

	if app.progress.curios.size() != 3 or int(app.progress.house_stage) < 3:
		return _fail(app, "opening trio did not complete 3/3 progression")

	var completed_house = app.current_screen()
	if completed_house == null or not completed_house.has_method("house_hotspot_contract"):
		return _fail(app, "completed House hotspot contract missing")
	if not completed_house.has_method("keeper_house_contract"):
		return _fail(app, "completed House Keeper contract missing")
	var keeper_hotspot: Button = completed_house.get_node_or_null("Layout/RoomView/CurioHotspots/KeeperHotspot") as Button
	if keeper_hotspot == null or keeper_hotspot.disabled:
		return _fail(app, "completed House Keeper hotspot missing")
	keeper_hotspot.emit_signal("pressed")
	await _frames(2)
	var keeper_name: Label = completed_house.get_node_or_null("KeeperRoleOverlay/Card/Content/Name") as Label
	var keeper_role: Label = completed_house.get_node_or_null("KeeperRoleOverlay/Card/Content/Role") as Label
	var keeper_body: Label = completed_house.get_node_or_null("KeeperRoleOverlay/Card/Content/Body") as Label
	if keeper_name == null or keeper_name.text != "THE KEEPER" or keeper_role == null or not keeper_role.text.contains("NO COST") or keeper_body == null or not keeper_body.text.contains("ASK KEEPER"):
		return _fail(app, "House Keeper card must expose truthful familiar role")
	if not await _save(app, "progression-house-keeper-role.png"):
		return
	var keeper_close: Button = completed_house.get_node_or_null("KeeperRoleOverlay/Card/Content/Close") as Button
	if keeper_close == null:
		return _fail(app, "House Keeper card close missing")
	keeper_close.emit_signal("pressed")
	await _frames(2)

	var thorn_hotspot: Button = completed_house.get_node_or_null("Layout/RoomView/CurioHotspots/ThornHotspot") as Button
	if thorn_hotspot == null or thorn_hotspot.disabled:
		return _fail(app, "completed House must expose the restored Thorned Locket hotspot")
	thorn_hotspot.emit_signal("pressed")
	await _frames(2)
	var house_thorn_name: Label = completed_house.get_node_or_null("HouseCurioInspect/Card/Content/Name") as Label
	var house_thorn_effect: Label = completed_house.get_node_or_null("HouseCurioInspect/Card/Content/HouseEffect") as Label
	if house_thorn_name == null or house_thorn_name.text != "THORNED LOCKET" or house_thorn_effect == null or not house_thorn_effect.text.contains("opening cabinet set"):
		return _fail(app, "House Thorned Locket detail must expose persistent House ownership impact")
	if not await _save(app, "progression-house-thorn-detail.png"):
		return
	var house_thorn_close: Button = completed_house.get_node_or_null("HouseCurioInspect/Card/Content/Close") as Button
	if house_thorn_close == null:
		return _fail(app, "House Thorned Locket detail close missing")
	house_thorn_close.emit_signal("pressed")
	await _frames(2)

	if not app.show_collection():
		return _fail(app, "completed House -> Reliquary failed")
	await _frames(3)
	var collection = app.current_screen()
	var count: Label = collection.get_node_or_null("Layout/Count") as Label
	if count == null or not count.text.contains("3 / 3 AWAKENED"):
		return _fail(app, "final Reliquary does not show 3 / 3")
	var moth_card: PanelContainer = collection.get_node_or_null("Layout/Cards/Slot2") as PanelContainer
	var locket_card: PanelContainer = collection.get_node_or_null("Layout/Cards/Slot3") as PanelContainer
	var moth_state: Label = collection.get_node_or_null("Layout/Cards/Slot2/Content/Copy/State") as Label
	var locket_state: Label = collection.get_node_or_null("Layout/Cards/Slot3/Content/Copy/State") as Label
	if moth_card == null or locket_card == null or moth_card.custom_minimum_size.y < 170.0 or locket_card.custom_minimum_size.y < 170.0:
		return _fail(app, "final Reliquary must give Levels 2 and 3 full-size visual reward cards")
	if moth_state == null or moth_state.text != "AWAKENED · RELIC 02":
		return _fail(app, "final Reliquary must show Moth Reliquary as awakened")
	if locket_state == null or locket_state.text != "AWAKENED · RELIC 03":
		return _fail(app, "final Reliquary must show Thorned Locket as awakened")
	if not await _save(app, "progression-final-reliquary.png"):
		return

	var moth_detail_button: Button = collection.get_node_or_null("Layout/Cards/Slot2/DetailActionLayer/InspectAction") as Button
	if moth_detail_button == null:
		return _fail(app, "Moth Reliquary detail action missing")
	moth_detail_button.emit_signal("pressed")
	await _frames(2)
	var moth_detail_art: TextureRect = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/HeroArt") as TextureRect
	var moth_detail_name: Label = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/Name") as Label
	if moth_detail_art == null or moth_detail_art.texture == null or moth_detail_name == null or moth_detail_name.text != "MOTH RELIQUARY":
		return _fail(app, "Moth Reliquary detail must render the awakened reward art")
	if not await _save(app, "progression-final-reliquary-moth-detail.png"):
		return
	var moth_close: Button = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/Close") as Button
	if moth_close == null:
		return _fail(app, "Moth Reliquary detail close action missing")
	moth_close.emit_signal("pressed")
	await _frames(2)

	var locket_detail_button: Button = collection.get_node_or_null("Layout/Cards/Slot3/DetailActionLayer/InspectAction") as Button
	if locket_detail_button == null:
		return _fail(app, "Thorned Locket detail action missing")
	locket_detail_button.emit_signal("pressed")
	await _frames(2)
	var locket_detail_art: TextureRect = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/HeroArt") as TextureRect
	var locket_detail_name: Label = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/Name") as Label
	if locket_detail_art == null or locket_detail_art.texture == null or locket_detail_name == null or locket_detail_name.text != "THORNED LOCKET":
		return _fail(app, "Thorned Locket detail must render the awakened reward art")
	if not await _save(app, "progression-final-reliquary-thorned-detail.png"):
		return
	var locket_view_house: Button = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/ViewInHouse") as Button
	if locket_view_house == null:
		return _fail(app, "owned Thorned Locket detail must expose View In House")
	locket_view_house.emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "house":
		return _fail(app, "Thorned Locket View In House must reach House")
	var handoff_house = app.current_screen()
	var handoff_name: Label = handoff_house.get_node_or_null("HouseCurioInspect/Card/Content/Name") as Label
	if handoff_name == null or handoff_name.text != "THORNED LOCKET":
		return _fail(app, "Reliquary -> House handoff must preserve Thorned Locket identity")
	if not await _save(app, "progression-curio-to-house-thorned.png"):
		return
	var handoff_close: Button = handoff_house.get_node_or_null("HouseCurioInspect/Card/Content/Close") as Button
	if handoff_close == null:
		return _fail(app, "Reliquary -> House handoff close missing")
	handoff_close.emit_signal("pressed")
	await _frames(2)

	if not app.show_feature_preview("Events"):
		return _fail(app, "completed House -> Events failed")
	await _frames(3)
	if String(app.current_route_name()) != "events" or app.current_screen() == null or app.current_screen().name != "EventsScreen":
		return _fail(app, "Events must render as its own S10 route-backed screen")
	var event_progress: Label = app.current_screen().get_node_or_null("FeatureLayout/ChapterRitualProgress") as Label
	var event_hero_kicker: Label = app.current_screen().get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroKicker") as Label
	var event_hero_title: Label = app.current_screen().get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroTitle") as Label
	if event_progress == null or not event_progress.text.begins_with("OPENING RITUAL COMPLETE") or not event_progress.text.contains("3 / 3 DISPLAYS AWAKENED"):
		return _fail(app, "Events does not expose the completed opening ritual state")
	if event_hero_kicker == null or event_hero_kicker.text != "OPENING RITUAL COMPLETE" or event_hero_title == null or not event_hero_title.text.contains("3 / 3 DISPLAYS AWAKENED"):
		return _fail(app, "completed Events hero does not resolve to the 3/3 ritual state")
	var daily_action: Button = app.current_screen().get_node_or_null("FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeAction") as Button
	var daily_truth: Label = app.current_screen().get_node_or_null("FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeTruth") as Label
	if daily_action == null or daily_action.disabled or daily_truth == null or not daily_truth.text.contains("NO BONUS REWARD"):
		return _fail(app, "completed Events must expose truthful Daily House Ritual practice")
	if not await _save(app, "progression-final-events.png"):
		return
	daily_action.emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "prestart":
		return _fail(app, "Daily House Ritual must open replay prestart")
	var daily_prestart = app.current_screen()
	var daily_reward: Label = daily_prestart.get_node_or_null("Layout/Card/Content/Reward") as Label if daily_prestart != null else null
	var daily_note: Label = daily_prestart.get_node_or_null("Layout/Card/Content/Note") as Label if daily_prestart != null else null
	if daily_reward == null or not daily_reward.text.begins_with("OWNED CURIO") or daily_note == null or not daily_note.text.contains("persistent rewards are already secured"):
		return _fail(app, "Daily House Ritual replay prestart must preserve no-farming truth")
	if not await _save(app, "progression-daily-ritual-prestart.png"):
		return
	var daily_back: Button = daily_prestart.get_node_or_null("Layout/Back") as Button if daily_prestart != null else null
	if daily_back == null:
		return _fail(app, "Daily House Ritual replay prestart back action missing")
	daily_back.emit_signal("pressed")
	await _frames(2)
	if String(app.current_route_name()) != "map" or not app.show_house():
		return _fail(app, "Daily House Ritual must return safely through Map to House")
	await _frames(2)
	if not app.show_feature_preview("Events"):
		return _fail(app, "House must reopen Events after Daily House Ritual proof")
	await _frames(2)
	var weekly_button: Button = app.current_screen().get_node_or_null("FeatureLayout/WeeklyMissionsAction") as Button
	if weekly_button == null:
		return _fail(app, "Event Center must expose the S09 Weekly Rituals destination")
	weekly_button.emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "missions" or app.current_screen() == null or app.current_screen().name != "WeeklyMissionsScreen":
		return _fail(app, "Weekly Missions must render as its own S09 route-backed screen")
	var mission_timer: Label = app.current_screen().get_node_or_null("MissionLayout/MissionTimer") as Label
	var mission_truth: Label = app.current_screen().get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/MissionEmptyStateTruth") as Label
	var mission_art: TextureRect = app.current_screen().get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/MissionRewardArt") as TextureRect
	if mission_timer == null or not mission_timer.text.contains("OFFLINE"):
		return _fail(app, "Weekly Missions must expose offline timer truth when no live feed exists")
	if mission_truth == null or not mission_truth.text.contains("NOTHING TO CLAIM"):
		return _fail(app, "Weekly Missions must not fabricate claimable rewards")
	if mission_art == null or mission_art.texture == null:
		return _fail(app, "Weekly Missions empty state must retain authored content artwork")
	if not await _save(app, "progression-final-weekly-missions.png"):
		return
	app.current_screen().get_node("MissionLayout/ReturnToEvents").emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "events" or app.current_screen() == null or app.current_screen().name != "EventsScreen":
		return _fail(app, "Weekly Missions -> Event Center return failed")
	app.current_screen().get_node("FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(3)

	if not app.show_feature_preview("Shop"):
		return _fail(app, "completed House -> Shop failed")
	await _frames(3)
	if String(app.current_route_name()) != "shop" or app.current_screen() == null or app.current_screen().name != "ShopScreen":
		return _fail(app, "Shop must render as its own S11 route-backed screen")
	var shop_notice: Label = app.current_screen().get_node_or_null("FeatureLayout/NoPurchasesNotice") as Label
	var shop_currency: Label = app.current_screen().get_node_or_null("FeatureLayout/ShopCurrencySummary") as Label
	var shop_truth: Label = app.current_screen().get_node_or_null("FeatureLayout/ShopCurrencyTruth") as Label
	var shop_hero_title: Label = app.current_screen().get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroTitle") as Label
	var shop_art: TextureRect = app.current_screen().get_node_or_null("FeatureLayout/FeatureHero/HeroRow/ShopFeaturedOfferArt") as TextureRect
	var shop_disabled_action: Button = app.current_screen().get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/ShopDisabledAction") as Button
	if shop_notice == null or not shop_notice.text.contains("NO PURCHASES OR PAYMENTS"):
		return _fail(app, "Shop must truthfully expose that purchases are disabled")
	if shop_currency == null or not shop_currency.text.contains("HOUSE COINS  12700") or not shop_currency.text.contains("MOONSTONES  523"):
		return _fail(app, "Shop currency summary must reflect persisted review balances")
	if shop_truth == null or not shop_truth.text.contains("NOT PURCHASABLE"):
		return _fail(app, "Shop currency summary must not imply commerce availability")
	if shop_hero_title == null or shop_hero_title.text != "NO PURCHASES ENABLED":
		return _fail(app, "Shop hero must remain an admitted unavailable state")
	if shop_art == null or shop_art.texture == null or shop_disabled_action == null or not shop_disabled_action.disabled:
		return _fail(app, "Shop featured offer must provide art with a disabled commerce CTA")
	if not await _save(app, "progression-final-shop.png"):
		return
	app.current_screen().get_node("FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(3)

	if not app.show_feature_preview("Profile"):
		return _fail(app, "completed House -> Profile failed")
	await _frames(3)
	if String(app.current_route_name()) != "profile_settings" or app.current_screen() == null or app.current_screen().name != "ProfileSettingsScreen":
		return _fail(app, "Profile must render as its own S12 route-backed screen")
	var profile = app.current_screen()
	var profile_copy := ""
	if profile != null:
		for node in profile.find_children("", "Label", true, false):
			profile_copy += (node as Label).text + "\n"
	if not profile_copy.contains("Opening chapter complete · 3 of 3 rituals."):
		return _fail(app, "Profile does not show the completed opening chapter")
	if not profile_copy.contains("3 of 3 opening curios awakened."):
		return _fail(app, "Profile does not show 3/3 curios")
	if not profile_copy.contains("FIRST CABINET SET RESTORED"):
		return _fail(app, "Profile does not expose the restored first cabinet set")
	if not profile_copy.contains("OPENING RESTORATION COMPLETE"):
		return _fail(app, "Profile does not expose completed House restoration")
	var profile_hero_kicker: Label = app.current_screen().get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroKicker") as Label
	var profile_hero_title: Label = app.current_screen().get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroTitle") as Label
	if profile_hero_kicker == null or profile_hero_kicker.text != "FIRST CABINET SET RESTORED":
		return _fail(app, "completed Profile hero must identify the restored first cabinet set")
	if profile_hero_title == null or not profile_hero_title.text.contains("3 CURIOS · RESTORATION STAGE 3"):
		return _fail(app, "completed Profile hero must summarize 3 curios and stage 3")
	var profile_local_save: Label = profile.get_node_or_null("FeatureLayout/SaveHealthCard/SaveHealthContent/LocalSaveStatus") as Label
	var profile_cloud: Label = profile.get_node_or_null("FeatureLayout/SaveHealthCard/SaveHealthContent/CloudSyncStatus") as Label
	if profile_local_save == null or profile_local_save.text != "LOCAL SAVE · HEALTHY":
		return _fail(app, "completed Profile local save health missing")
	if profile_cloud == null or profile_cloud.text != "CLOUD SYNC · NOT CONNECTED":
		return _fail(app, "completed Profile cloud-sync truth missing")
	if not await _save(app, "progression-final-profile.png"):
		return
	var profile_settings_button: Button = profile.get_node_or_null("FeatureLayout/ProfileSettings") as Button
	if profile_settings_button == null:
		return _fail(app, "Profile must expose its Settings destination")
	profile_settings_button.emit_signal("pressed")
	await _frames(3)
	if not app.navigation.is_settings_open():
		return _fail(app, "Profile Settings modal must open without losing S12")
	if String(app.current_route_name()) != "profile_settings":
		return _fail(app, "Settings modal must preserve the Profile route")
	var settings_panel = app.get_node_or_null("ScreenHost/SettingsPanel")
	if settings_panel == null:
		return _fail(app, "Settings modal surface missing")
	var settings_close: Button = settings_panel.get_node_or_null("Card/Content/Close") as Button
	if settings_close == null or settings_close.text != "RETURN TO PROFILE":
		return _fail(app, "Profile Settings must return to its origin screen")
	var reduced_toggle: CheckButton = settings_panel.get_node_or_null("Card/Content/Reduced") as CheckButton
	var contrast_toggle: CheckButton = settings_panel.get_node_or_null("Card/Content/Contrast") as CheckButton
	var saved_note: Label = settings_panel.get_node_or_null("Card/Content/SavedNote") as Label
	if reduced_toggle == null or contrast_toggle == null or saved_note == null:
		return _fail(app, "Settings changed-state controls missing")
	reduced_toggle.button_pressed = true
	reduced_toggle.emit_signal("toggled", true)
	await _frames(2)
	if not saved_note.text.contains("SAVED ON THIS DEVICE") or not saved_note.text.contains("REDUCED MOTION UPDATED"):
		return _fail(app, "Settings changed state must confirm persisted preference")
	contrast_toggle.button_pressed = true
	contrast_toggle.emit_signal("toggled", true)
	await _frames(2)
	if not saved_note.text.contains("HIGH CONTRAST UPDATED"):
		return _fail(app, "Settings high-contrast changed state must confirm persisted preference")
	if settings_panel.has_method("state_contract") and not bool(settings_panel.state_contract().get("high_contrast", false)):
		return _fail(app, "open Settings must apply high contrast before capture")
	if not await _save(app, "progression-final-settings.png"):
		return
	if not app.close_settings():
		return _fail(app, "Profile Settings modal failed to close")
	await _frames(2)
	if String(app.current_route_name()) != "profile_settings" or app.current_screen() != profile:
		return _fail(app, "closing Settings must preserve and reveal the Profile origin")
	app.current_screen().get_node("FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(3)

	if not app.show_chapters():
		return _fail(app, "completed House -> Chapters failed")
	await _frames(2)
	var completed_chapters = app.current_screen()
	var completed_boutique: Button = completed_chapters.get_node_or_null("Layout/ChapterGrid/CurioBoutiqueButton") as Button
	var completed_summary: Label = completed_chapters.get_node_or_null("Layout/ChapterSummary") as Label
	if completed_boutique == null or not completed_boutique.text.contains("RESTORED WING · 3 / 3 DISPLAYS") or not completed_boutique.text.contains("REVISIT RITUALS"):
		return _fail(app, "completed Chapter Select must identify the restored 3/3 Curio Boutique")
	if completed_summary == null or not completed_summary.text.begins_with("The opening wing is restored"):
		return _fail(app, "completed Chapter Select must describe the restored opening wing")
	if not await _save(app, "progression-final-chapters.png"):
		return
	completed_boutique.emit_signal("pressed")
	await _frames(3)
	var completed_map = app.current_screen()
	var progress_label: Label = completed_map.get_node_or_null("Layout/Progress") as Label
	if progress_label == null or not progress_label.text.contains("3 / 3"):
		return _fail(app, "completed map does not show 3 / 3")
	for level_number in [1, 2, 3]:
		var button: Button = completed_map.get_level_button(level_number)
		if button == null or button.disabled or button.text != "✓":
			return _fail(app, "completed map must keep Level %d replayable and awakened" % level_number)
	var level4: Button = completed_map.get_level_button(4)
	var completed_route = completed_map.get_node_or_null("Layout/RoutePanel/Scroll/RouteView")
	if level4 == null or level4.disabled or completed_route == null or String(completed_route.get_level_state(4)) != "locked":
		return _fail(app, "completed opening map must keep Level 4 sealed and inspectable")
	level4.emit_signal("pressed")
	await _frames(2)
	var sealed_contract: Dictionary = completed_map.sealed_explanation_contract()
	if String(sealed_contract.get("sealed_kind", "")) != "future_content" or not bool(sealed_contract.get("no_fake_unlock", false)):
		return _fail(app, "completed opening map must explain Level 4 without fake availability")
	var sealed_close: Button = completed_map.get_node_or_null("LockedExplanation/LockedPanel/Content/Close") as Button
	if sealed_close != null:
		sealed_close.emit_signal("pressed")
		await _frames(2)
	if not await _save(app, "progression-final-map.png"):
		return

	print("CAPTURE_PASS: real three-level progression journey")
	app.queue_free()
	await process_frame
	_cleanup()
	quit(0)

func _play_level(app: Node, level_number: int) -> bool:
	if not app.show_chapters():
		_fail(app, "House -> Chapters failed before Level %d" % level_number)
		return false
	await _frames(2)
	var chapters = app.current_screen()
	var boutique := chapters.get_node_or_null("Layout/ChapterGrid/CurioBoutiqueButton") as Button if chapters != null else null
	var chapter_summary: Label = chapters.get_node_or_null("Layout/ChapterSummary") as Label if chapters != null else null
	var completed_before := level_number - 1
	if boutique == null or boutique.disabled:
		_fail(app, "Curio Boutique entry missing before Level %d" % level_number)
		return false
	if completed_before == 0:
		if not boutique.text.contains("CURRENT WING · 0 / 3 DISPLAYS") or not boutique.text.contains("BEGIN RESTORATION"):
			_fail(app, "Chapter Select must begin at 0 / 3 before Level 1")
			return false
	elif not boutique.text.contains("CURRENT WING · %d / 3 DISPLAYS" % completed_before) or not boutique.text.contains("CONTINUE RESTORATION"):
		_fail(app, "Chapter Select must reflect %d / 3 progress before Level %d" % [completed_before, level_number])
		return false
	if chapter_summary == null:
		_fail(app, "Chapter Select progression summary missing before Level %d" % level_number)
		return false
	boutique.emit_signal("pressed")
	await _frames(2)
	if String(app.current_route_name()) != "map":
		_fail(app, "Chapter map missing before Level %d" % level_number)
		return false
	var map = app.current_screen()
	var route_view = map.get_node_or_null("Layout/RoutePanel/Scroll/RouteView")
	if route_view == null:
		_fail(app, "Chapter route view missing before Level %d" % level_number)
		return false
	if route_view.get_level_center(10).y >= 300.0 or route_view.get_level_center(3).y <= 540.0:
		_fail(app, "Future cabinets must stay compact above the authored opening trio")
		return false
	if route_view.custom_minimum_size.y < 1450.0 or route_view.custom_minimum_size.y > 1520.0:
		_fail(app, "Chapter route must fill one bounded portrait map panel without becoming a scroll journey")
		return false
	if route_view.get_level_center(1).y <= route_view.custom_minimum_size.y * 0.82:
		_fail(app, "Level 1 must anchor the lower map so the authored route uses the full panel")
		return false
	if route_view.custom_minimum_size.x < 860.0 or route_view.custom_minimum_size.x > 960.0:
		_fail(app, "Chapter route must use the portrait width while staying inside the logical viewport")
		return false
	var level_button: Button = map.get_level_button(level_number)
	if level_button == null or level_button.disabled:
		_fail(app, "Level %d is not progression-unlocked" % level_number)
		return false
	if not await _save(app, "progression-map-before-level%d.png" % level_number):
		return false
	level_button.emit_signal("pressed")
	await _frames(2)
	if String(app.current_route_name()) != "prestart":
		_fail(app, "Level %d prestart did not open" % level_number)
		return false
	var prestart = app.current_screen()
	var start: Button = prestart.get_node_or_null("Layout/Card/Content/Start") as Button
	if start == null or start.disabled:
		_fail(app, "Level %d start control unavailable" % level_number)
		return false
	start.emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "gameplay":
		_fail(app, "Level %d gameplay did not start" % level_number)
		return false
	var gameplay = app.current_screen()
	if String(gameplay.current_level_id) != "ch01_level_%03d" % level_number:
		_fail(app, "wrong authored gameplay loaded for Level %d" % level_number)
		return false
	if not await _save(app, "progression-level%d-gameplay.png" % level_number):
		return false
	var file := FileAccess.open("res://content/levels/ch01/level_%03d.json" % level_number, FileAccess.READ)
	if file == null:
		_fail(app, "Level %d content file missing" % level_number)
		return false
	var level_data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not level_data is Dictionary:
		_fail(app, "Level %d content malformed" % level_number)
		return false
	for raw_move in level_data.get("teaching_moves", []):
		var trace = gameplay.attempt_swap(
			Vector2i(int(raw_move[0]), int(raw_move[1])),
			Vector2i(int(raw_move[2]), int(raw_move[3]))
		)
		if trace == null or not trace.accepted:
			_fail(app, "Level %d authored move rejected" % level_number)
			return false
		var board_view = gameplay.get_node_or_null("Layout/BoardView")
		if board_view != null and board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()) and board_view.has_signal("trace_motion_finished"):
			await board_view.trace_motion_finished
		await process_frame
		if gameplay.result_overlay.visible:
			break
	if not gameplay.result_overlay.visible:
		_fail(app, "Level %d did not reach its reward result" % level_number)
		return false
	if not await _save(app, "progression-level%d-result.png" % level_number):
		return false
	gameplay.result_action.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) == "restoration":
		var restoration = app.current_screen()
		var restoration_card: PanelContainer = restoration.get_node_or_null("RestorationOverlay/CeremonyCard") as PanelContainer if restoration != null else null
		var restoration_continue: Button = restoration.get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button if restoration != null else null
		var restoration_room = restoration.get_node_or_null("Layout/RoomView") if restoration != null else null
		if restoration_continue == null or restoration_card == null or restoration_room == null:
			_fail(app, "Level %d restoration ceremony surface is incomplete" % level_number)
			return false
		if restoration_card.size.y > restoration.size.y * 0.18:
			_fail(app, "Level %d restoration ceremony card is taller than its content contract" % level_number)
			return false
		if level_number >= 2:
			var awakening_echo: TextureRect = restoration_room.get_node_or_null("RestorationAwakeningEcho") as TextureRect
			if awakening_echo == null or awakening_echo.texture == null:
				_fail(app, "Level %d restoration must render the Curio awakening echo" % level_number)
				return false
		if not await _save(app, "progression-level%d-restoration.png" % level_number):
			return false
		restoration_continue.emit_signal("pressed")
		await _frames(4)
	if String(app.current_route_name()) != "house":
		_fail(app, "Level %d did not complete S07 Restoration -> S01 House" % level_number)
		return false
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _save(app: Node, file_name: String) -> bool:
	var image: Image = app.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail(app, "empty viewport for %s" % file_name)
		return false
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(file_name)
	if image.save_png(output_path) != OK:
		_fail(app, "save failed for %s" % file_name)
		return false
	print("CAPTURE_FRAME: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	return true

func _fail(app: Node, message: String) -> void:
	printerr("CAPTURE_FAIL: %s" % message)
	if app != null and is_instance_valid(app):
		app.queue_free()
	_cleanup()
	quit(1)

func _cleanup() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
