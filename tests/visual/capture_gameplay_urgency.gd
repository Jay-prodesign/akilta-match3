extends SceneTree

const GAMEPLAY_SCENE := preload("res://src/ui/gameplay/gameplay_screen.tscn")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var screen = GAMEPLAY_SCENE.instantiate()
	root.add_child(screen)
	await _frames(2)
	screen.apply_presentation_settings({"reduced_motion": false, "high_contrast": false, "haptics_enabled": false})
	screen.board_state.moves_remaining = 3
	screen._refresh_hud()
	if String(screen.gameplay_feel_contract().get("moves_urgency_state", "")) != "warning":
		return _fail(screen, "three-move warning state missing")
	if not await _save(screen, "gameplay-low-moves-warning.png"):
		return

	screen.board_state.moves_remaining = 1
	screen.apply_presentation_settings({"reduced_motion": true, "high_contrast": true, "haptics_enabled": false})
	screen._refresh_hud()
	if String(screen.gameplay_feel_contract().get("moves_copy", "")) != "LAST MOVE":
		return _fail(screen, "last-move critical state missing")
	if not await _save(screen, "gameplay-last-move-high-contrast.png"):
		return

	print("CAPTURE_PASS: gameplay low-move urgency states")
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
