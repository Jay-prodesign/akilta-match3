extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const SAVE_PATH := "user://capture_level1_journey.json"
const SETTINGS_PATH := "user://capture_level1_journey_settings.json"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	_cleanup()
	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await _frames(4)

	if String(app.current_route_name()) != "boot":
		return _fail(app, "journey must begin in BOOT while splash is visible")
	if not await _save(app, "journey-00-splash.png"):
		return
	var splash = app.current_screen()
	var enter: Button = splash.get_node_or_null("Layout/Enter") as Button if splash != null else null
	if enter == null:
		return _fail(app, "splash enter control missing")
	enter.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "house":
		return _fail(app, "splash did not enter House")
	if not await _save(app, "journey-01-house-dormant.png"):
		return

	if not app.show_chapters():
		return _fail(app, "House -> Chapter Select failed")
	await _frames(3)
	if not await _save(app, "journey-01b-chapter-select.png"):
		return
	var chapters = app.current_screen()
	var chapter_layout: Control = chapters.get_node("Layout") as Control
	var chapter_world_art: Control = chapters.get_node("HouseWorldBackdrop") as Control
	if chapter_layout == null or chapter_world_art == null or chapter_world_art.get_index() >= chapter_layout.get_index():
		return _fail(app, "Chapter Select world art must stay behind readable interaction controls")
	var active_wing: Button = chapters.get_node("Layout/ChapterGrid/CurioBoutiqueButton") as Button
	if active_wing == null or active_wing.disabled:
		return _fail(app, "Curio Boutique must be the only playable opening wing")
	for chapter_id in ["witch_atelier", "dark_vanity", "archive", "moon_conservatory", "cemetery_garden"]:
		var sealed_wing: Button = chapters.get_node_or_null("Layout/ChapterGrid/Chapter_" + chapter_id) as Button
		if sealed_wing == null or not sealed_wing.disabled:
			return _fail(app, "Unreleased chapter must remain visibly sealed: %s" % chapter_id)
	active_wing.emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "map":
		return _fail(app, "Curio Boutique -> Chapter Map failed")
	var map_screen = app.current_screen()
	var route_panel: Control = map_screen.get_node_or_null("Layout/RoutePanel") as Control if map_screen != null else null
	var route_view: Control = map_screen.get_node_or_null("Layout/RoutePanel/Scroll/RouteView") as Control if map_screen != null else null
	if route_panel == null or route_view == null:
		return _fail(app, "chapter route composition missing")
	if route_view.custom_minimum_size.x < 860.0 or route_view.custom_minimum_size.x > 960.0:
		return _fail(app, "chapter route must use the portrait width without overflowing the 1080 logical viewport")
	if route_view.custom_minimum_size.y < 1450.0 or route_view.custom_minimum_size.y > 1520.0:
		return _fail(app, "chapter route must carry the opening journey across the full map panel")
	if route_panel.size.y < app.get_viewport().get_visible_rect().size.y * 0.45:
		return _fail(app, "chapter route panel must occupy meaningful vertical space on mobile")
	for level_number in [1, 2, 3]:
		var level_label: Label = route_view.get_node_or_null("Label%d" % level_number) as Label
		if level_label == null or level_label.text.strip_edges() == "":
			return _fail(app, "opening level %d must have readable map identity" % level_number)
	if not await _save(app, "journey-02-chapter-map.png"):
		return

	if not app.show_prestart(1):
		return _fail(app, "Map -> Prestart failed")
	await _frames(3)
	if not await _save(app, "journey-03-prestart.png"):
		return

	if not app.start_level(1):
		return _fail(app, "Prestart -> Level 1 failed")
	await _frames(4)
	if not await _save(app, "journey-04-level1-gameplay.png"):
		return

	var gameplay = app.current_screen()
	var board_view = gameplay.get_node_or_null("Layout/BoardView")
	if board_view == null or not board_view.has_method("piece_asset_contract"):
		return _fail(app, "Level 1 board asset contract missing")
	var piece_contract: Dictionary = board_view.piece_asset_contract()
	var piece_families: Dictionary = piece_contract.get("families", {})
	for family in ["moon", "rose", "moth", "key", "leaf"]:
		if not bool(piece_families.get(family, false)):
			return _fail(app, "North Star piece asset did not load: %s" % family)
	if not gameplay.show_pause():
		return _fail(app, "Level 1 pause did not open")
	var booster_tray: PanelContainer = gameplay.get_node_or_null("BoosterTray") as PanelContainer
	if booster_tray == null or booster_tray.visible:
		return _fail(app, "Pause must suspend the gameplay booster tray")
	await _frames(2)
	if not await _save(app, "journey-04b-level1-pause.png"):
		return
	if not gameplay.resume_level():
		return _fail(app, "Level 1 pause did not resume")
	if booster_tray == null or not booster_tray.visible:
		return _fail(app, "Resume must restore the gameplay booster tray")
	await _frames(2)
	var trace = gameplay.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	if trace == null or not bool(trace.accepted) or String(trace.result) != "won":
		return _fail(app, "authored Level 1 teaching move did not win")
	var motion_board_view = gameplay.get_node_or_null("Layout/BoardView")
	if motion_board_view != null and motion_board_view.has_method("is_motion_active") and bool(motion_board_view.is_motion_active()):
		await motion_board_view.trace_motion_finished
	await _frames(2)
	if not gameplay.result_overlay.visible:
		return _fail(app, "Level 1 result did not appear")
	if booster_tray != null and booster_tray.visible:
		return _fail(app, "Win result must hide gameplay-only boosters")
	if not await _save(app, "journey-05-level1-result.png"):
		return

	if not gameplay.continue_after_win():
		return _fail(app, "Level 1 result did not continue")
	await _frames(5)
	if String(app.current_route_name()) != "house":
		return _fail(app, "Level 1 did not return to House")
	if int(app.progress.house_stage) != 1 or not app.progress.curios.has("moon_cameo"):
		return _fail(app, "Moon Cameo House consequence missing")
	if not await _save(app, "journey-06-house-awakened.png"):
		return
	if not app.show_collection():
		return _fail(app, "House -> Curio Collection failed")
	await _frames(3)
	if not await _save(app, "journey-07-curio-collection.png"):
		return

	var collection = app.current_screen()
	var collection_back: Button = collection.get_node_or_null("Layout/Back") as Button
	if collection_back == null:
		return _fail(app, "Curio Collection back control missing")
	collection_back.emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "house":
		return _fail(app, "Collection did not return to House before settings capture")
	if not app.show_settings():
		return _fail(app, "House -> Settings failed")
	await _frames(3)
	var settings_panel: Control = app.get_node_or_null("ScreenHost/SettingsPanel") as Control
	var settings_card: Control = app.get_node_or_null("ScreenHost/SettingsPanel/Card") as Control
	var settings_sigil: TextureRect = app.get_node_or_null("ScreenHost/SettingsPanel/Card/Content/HouseSigil") as TextureRect
	if settings_panel == null or settings_card == null:
		return _fail(app, "Settings surface missing")
	if settings_card.size.x > settings_panel.size.x * 0.94 or settings_card.position.x < 0.0 or settings_card.position.x + settings_card.size.x > settings_panel.size.x:
		return _fail(app, "Settings card must stay inside the portrait viewport")
	if settings_card.size.y > settings_panel.size.y * 0.62:
		return _fail(app, "Settings must read as a focused modal instead of a full-height empty panel")
	if settings_sigil == null or settings_sigil.texture == null:
		return _fail(app, "Settings must carry authored House-world sigil art")
	if not await _save(app, "journey-08-settings.png"):
		return
	if not app.close_settings():
		return _fail(app, "Settings did not close cleanly")
	await _frames(2)
	if not app.show_feature_preview("Events"):
		return _fail(app, "House -> Events preview failed")
	await _frames(3)
	var event_preview: Node = app.get_node_or_null("ScreenHost/FeaturePreview")
	var event_hero: PanelContainer = event_preview.get_node_or_null("FeatureLayout/FeatureHero") as PanelContainer if event_preview != null else null
	var event_hero_title: Label = event_preview.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroTitle") as Label if event_preview != null else null
	var event_art_nodes: Array[Node] = event_preview.find_children("FeatureArtwork", "TextureRect", true, false) if event_preview != null else []
	if event_hero == null or event_hero_title == null or not event_hero_title.text.contains("1 / 3 DISPLAYS AWAKENED"):
		return _fail(app, "Events must open with its authored ritual-status hero")
	if event_art_nodes.size() != 3:
		return _fail(app, "Events must render all three first-party feature illustrations")
	for art_node in event_art_nodes:
		if (art_node as TextureRect).texture == null:
			return _fail(app, "Events feature illustration did not load")
	if not await _save(app, "journey-09-events.png"):
		return
	app.get_node("ScreenHost/FeaturePreview/FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(2)
	if not app.show_feature_preview("Shop"):
		return _fail(app, "House -> Shop preview failed")
	await _frames(3)
	var shop_preview: Node = app.get_node_or_null("ScreenHost/FeaturePreview")
	var shop_hero_title: Label = shop_preview.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroTitle") as Label if shop_preview != null else null
	var shop_art_nodes: Array[Node] = shop_preview.find_children("FeatureArtwork", "TextureRect", true, false) if shop_preview != null else []
	if shop_hero_title == null or shop_hero_title.text != "NO PURCHASES ENABLED":
		return _fail(app, "Shop must lead with an explicit no-purchase trust state")
	if shop_art_nodes.size() != 3:
		return _fail(app, "Shop must render all three first-party feature illustrations")
	for art_node in shop_art_nodes:
		if (art_node as TextureRect).texture == null:
			return _fail(app, "Shop feature illustration did not load")
	if not await _save(app, "journey-10-shop.png"):
		return
	app.get_node("ScreenHost/FeaturePreview/FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(2)
	if not app.show_feature_preview("Profile"):
		return _fail(app, "House -> Profile preview failed")
	await _frames(3)
	var profile_preview: Node = app.get_node_or_null("ScreenHost/FeaturePreview")
	var profile_hero_title: Label = profile_preview.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroTitle") as Label if profile_preview != null else null
	var profile_art_nodes: Array[Node] = profile_preview.find_children("FeatureArtwork", "TextureRect", true, false) if profile_preview != null else []
	if profile_hero_title == null or not profile_hero_title.text.contains("1 CURIOS · RESTORATION STAGE 1"):
		return _fail(app, "Profile must lead with the saved Keeper-state hero")
	if profile_art_nodes.size() != 3:
		return _fail(app, "Profile must render saved journey, reliquary and House restoration cards")
	if not await _save(app, "journey-11-profile.png"):
		return
	app.get_node("ScreenHost/FeaturePreview/FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(2)

	print("CAPTURE_PASS: complete Level 1 player journey")
	app.queue_free()
	await process_frame
	_cleanup()
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _save(app: Node, file_name: String) -> bool:
	var viewport: Viewport = app.get_viewport()
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_fail(app, "empty viewport for %s" % file_name)
		return false
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(file_name)
	if image.save_png(output_path) != OK:
		_fail(app, "save_png failed for %s" % file_name)
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
