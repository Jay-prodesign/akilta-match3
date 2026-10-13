extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await _frames(2)
	if not screen.load_level_path("res://content/levels/ch01/level_003.json", 1003):
		return _fail(screen, "Level 3 load failed")
	var trace = screen.attempt_swap(Vector2i(2, 3), Vector2i(2, 4))
	if trace == null or not bool(trace.accepted):
		return _fail(screen, "Level 3 first move failed")
	var board_view = screen.get_node("Layout/BoardView")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished
	await _frames(2)
	var feel: Dictionary = screen.gameplay_feel_contract()
	if not String(feel.get("objective_copy", "")).contains("THIS MOVE"):
		return _fail(screen, "objective progress copy missing")
	if not await _save(screen, "gameplay-objective-progress.png"):
		return

	var trigger = screen.attempt_swap(Vector2i(3, 3), Vector2i(3, 4))
	if trigger == null or String(trigger.result) != "won":
		return _fail(screen, "Level 3 terminal move failed")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished
	await create_timer(0.30).timeout
	await _frames(2)
	var transition: Dictionary = screen.terminal_transition_contract()
	if String(transition.get("kind", "")) != "won" or bool(transition.get("active", true)):
		return _fail(screen, "win transition did not settle")
	if not await _save(screen, "gameplay-win-terminal-settled.png"):
		return
	print("CAPTURE_PASS: gameplay objective and terminal transition feel")
	screen.queue_free()
	await process_frame
	quit(0)

func _save(screen: Node, file_name: String) -> bool:
	var image: Image = screen.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return _fail(screen, "empty viewport for %s" % file_name)
	var dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(file_name)
	if image.save_png(path) != OK:
		return _fail(screen, "save failed for %s" % file_name)
	print("CAPTURE_FRAME: %s %dx%d" % [path, image.get_width(), image.get_height()])
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
