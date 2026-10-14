extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")
const SaveStoreScript = preload("res://src/save/save_store.gd")
const SAVE_PATH := "user://capture_returning_player_resume.json"
const SETTINGS_PATH := "user://capture_returning_player_resume_settings.json"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	_cleanup()
	var progress = ProgressScript.new()
	progress.apply_level_win("return-visual-l1", "ch01_level_001", "moon_cameo", 1)
	progress.apply_level_win("return-visual-l2", "ch01_level_002", "moth_reliquary", 2)
	progress.lives = 3
	progress.coins = 777
	progress.gems = 9
	var store = SaveStoreScript.new(SAVE_PATH)
	if not store.save(progress.to_dict()):
		return _fail(null, "could not seed returning-player visual state")

	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await _frames(4)
	var splash = app.current_screen()
	var enter := splash.get_node_or_null("Layout/Enter") as Button if splash != null else null
	if enter == null:
		return _fail(app, "returning-player Splash enter missing")
	enter.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "house":
		return _fail(app, "returning-player House missing")
	var banner := app.current_screen().get_node_or_null("Layout/ReturningPlayerBanner") as PanelContainer
	var headline := app.current_screen().get_node_or_null("Layout/Headline") as Label
	if banner == null or banner.visible or headline == null or not headline.text.contains("WELCOME BACK") or not headline.text.contains("2 / 3 CURIOS"):
		return _fail(app, "returning-player state must live in the primary Home title without an extra banner")
	if not await _save(app, "returning-01-house-resume.png"):
		return

	var play := app.current_screen().get_node_or_null("Layout/PlayButton") as Button
	if play == null:
		return _fail(app, "returning-player next action missing")
	play.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "map":
		return _fail(app, "returning-player map missing")
	var level3: Button = app.current_screen().get_level_button(3)
	if level3 == null or level3.disabled:
		return _fail(app, "returning-player frontier Level 3 is not available")
	if not await _save(app, "returning-02-map-frontier.png"):
		return

	print("CAPTURE_PASS: returning player resume journey")
	app.queue_free()
	await process_frame
	_cleanup()
	quit(0)

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
