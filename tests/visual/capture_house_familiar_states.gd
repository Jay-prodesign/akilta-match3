extends SceneTree

const HouseScene := preload("res://src/ui/home/house_home.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var screen = HouseScene.instantiate()
	root.add_child(screen)
	await _frames(2)
	screen.set_available_level_count(3)

	var fresh = ProgressScript.new()
	screen.set_progress(fresh)
	await _frames(2)
	var room = screen.get_node_or_null("Layout/RoomView")
	if room == null or not room.has_method("familiar_contract") or not bool(room.familiar_contract().get("loaded", false)):
		return _fail(screen, "authored familiar world layer missing")
	if str(room.familiar_contract().get("state", "")) != "attention":
		return _fail(screen, "fresh House did not expose attention familiar")
	if not await _save(screen, "familiar-01-attention.png"):
		return

	var restored = ProgressScript.new()
	restored.apply_level_win("familiar-l1", "ch01_level_001", "moon_cameo", 1)
	screen.set_progress(restored)
	await _frames(2)
	if str(room.familiar_contract().get("state", "")) != "idle":
		return _fail(screen, "restored House did not expose idle familiar")
	if not await _save(screen, "familiar-02-idle.png"):
		return

	screen.apply_presentation_settings({"reduced_motion": true})
	screen.show_restoration_ceremony("moon_cameo", 1)
	await _frames(3)
	if str(room.familiar_contract().get("state", "")) != "celebrate":
		return _fail(screen, "restoration did not expose celebrate familiar")
	if not await _save(screen, "familiar-03-celebrate.png"):
		return

	print("CAPTURE_PASS: House familiar character-world states")
	screen.queue_free()
	await process_frame
	quit(0)

func _save(screen: Node, file_name: String) -> bool:
	var image: Image = screen.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return _fail(screen, "empty viewport for %s" % file_name)
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(file_name)
	if image.save_png(output_path) != OK:
		return _fail(screen, "save failed for %s" % file_name)
	print("CAPTURE_FRAME: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	return true

func _fail(screen: Node, message: String) -> bool:
	printerr("CAPTURE_FAIL: %s" % message)
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	quit(1)
	return false

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
