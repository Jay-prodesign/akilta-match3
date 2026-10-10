extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const SPLASH_SCENE := preload("res://src/ui/splash/splash_screen.tscn")
const SAVE_PATH := "user://capture_level1_journey.json"
const SETTINGS_PATH := "user://capture_level1_journey_settings.json"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	_cleanup()
	var splash = SPLASH_SCENE.instantiate()
	root.add_child(splash)
	await _frames(3)
	if not await _save(splash, "journey-00-splash.png"):
		return
	splash.queue_free()
	await process_frame
	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await _frames(4)

	if String(app.current_route_name()) != "house":
		return _fail(app, "journey did not boot into House")
	if not await _save(app, "journey-01-house-dormant.png"):
		return

	if not app.show_chapters():
		return _fail(app, "House -> Chapter Select failed")
	await _frames(3)
	if not await _save(app, "journey-01b-chapter-select.png"):
		return
	var chapters = app.current_screen()
	chapters.get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "map":
		return _fail(app, "Curio Boutique -> Chapter Map failed")
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
	await _frames(2)
	if not await _save(app, "journey-04b-level1-pause.png"):
		return
	if not gameplay.resume_level():
		return _fail(app, "Level 1 pause did not resume")
	await _frames(2)
	var trace = gameplay.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	if trace == null or not bool(trace.accepted) or String(trace.result) != "won":
		return _fail(app, "authored Level 1 teaching move did not win")
	var board_view = gameplay.get_node_or_null("Layout/BoardView")
	if board_view != null and board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished
	await _frames(2)
	if not gameplay.result_overlay.visible:
		return _fail(app, "Level 1 result did not appear")
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
	if not await _save(app, "journey-08-settings.png"):
		return
	if not app.close_settings():
		return _fail(app, "Settings did not close cleanly")
	await _frames(2)
	if not app.show_feature_preview("Events"):
		return _fail(app, "House -> Events preview failed")
	await _frames(3)
	if not await _save(app, "journey-09-events.png"):
		return
	app.get_node("ScreenHost/FeaturePreview/FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(2)
	if not app.show_feature_preview("Shop"):
		return _fail(app, "House -> Shop preview failed")
	await _frames(3)
	if not await _save(app, "journey-10-shop.png"):
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
