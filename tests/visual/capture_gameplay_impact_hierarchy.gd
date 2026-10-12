extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var level2 = GameplayScene.instantiate()
	root.add_child(level2)
	await _frames(2)
	if not level2.load_level_path("res://content/levels/ch01/level_002.json", 1002):
		return _fail(level2, "Level 2 load failed")
	var blocker_trace = level2.attempt_swap(Vector2i(4, 2), Vector2i(4, 3))
	if blocker_trace == null or not blocker_trace.event_types().has("blocker_cleared"):
		return _fail(level2, "Level 2 blocker impact missing")
	await create_timer(0.24).timeout
	if not await _save(level2, "gameplay-blocker-clear-impact.png"):
		return
	level2.queue_free()
	await _frames(2)

	var level3 = GameplayScene.instantiate()
	root.add_child(level3)
	await _frames(2)
	if not level3.load_level_path("res://content/levels/ch01/level_003.json", 1003):
		return _fail(level3, "Level 3 load failed")
	var create_trace = level3.attempt_swap(Vector2i(2, 3), Vector2i(2, 4))
	if create_trace == null or not create_trace.event_types().has("special_created"):
		return _fail(level3, "Level 3 special creation missing")
	var board_view = level3.get_node("Layout/BoardView")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished
	await _frames(2)
	var trigger_trace = level3.attempt_swap(Vector2i(3, 3), Vector2i(3, 4))
	if trigger_trace == null or not trigger_trace.event_types().has("special_triggered"):
		return _fail(level3, "Level 3 special trigger missing")
	await create_timer(0.22).timeout
	if not await _save(level3, "gameplay-special-trigger-impact.png"):
		return
	print("CAPTURE_PASS: gameplay blocker and special impact hierarchy")
	level3.queue_free()
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
