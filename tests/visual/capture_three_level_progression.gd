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
	if moth_card == null or locket_card == null or moth_card.custom_minimum_size.y < 140.0 or locket_card.custom_minimum_size.y < 140.0:
		return _fail(app, "final Reliquary must give Levels 2 and 3 meaningful visual reward cards")
	if moth_state == null or moth_state.text != "AWAKENED · RELIC 02":
		return _fail(app, "final Reliquary must show Moth Reliquary as awakened")
	if locket_state == null or locket_state.text != "AWAKENED · RELIC 03":
		return _fail(app, "final Reliquary must show Thorned Locket as awakened")
	if not await _save(app, "progression-final-reliquary.png"):
		return
	collection.get_node("Layout/Back").emit_signal("pressed")
	await _frames(3)

	if not app.show_feature_preview("Events"):
		return _fail(app, "completed House -> Events failed")
	await _frames(3)
	var event_progress: Label = app.get_node_or_null("ScreenHost/FeaturePreview/FeatureLayout/ChapterRitualProgress") as Label
	if event_progress == null or not event_progress.text.begins_with("OPENING RITUAL COMPLETE") or not event_progress.text.contains("3 / 3 DISPLAYS AWAKENED"):
		return _fail(app, "Events does not expose the completed opening ritual state")
	if not await _save(app, "progression-final-events.png"):
		return
	app.get_node("ScreenHost/FeaturePreview/FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(3)

	if not app.show_feature_preview("Profile"):
		return _fail(app, "completed House -> Profile failed")
	await _frames(3)
	var profile = app.get_node_or_null("ScreenHost/FeaturePreview")
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
	if not await _save(app, "progression-final-profile.png"):
		return
	app.get_node("ScreenHost/FeaturePreview/FeatureLayout/BackToHouse").emit_signal("pressed")
	await _frames(3)

	if not app.show_chapters():
		return _fail(app, "completed House -> Chapters failed")
	await _frames(2)
	app.current_screen().get_node("Layout/ChapterGrid/CurioBoutiqueButton").emit_signal("pressed")
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
	if level4 == null or not level4.disabled:
		return _fail(app, "completed opening map must keep Level 4 sealed")
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
	if boutique == null or boutique.disabled:
		_fail(app, "Curio Boutique entry missing before Level %d" % level_number)
		return false
	boutique.emit_signal("pressed")
	await _frames(2)
	if String(app.current_route_name()) != "map":
		_fail(app, "Chapter map missing before Level %d" % level_number)
		return false
	var map = app.current_screen()
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
