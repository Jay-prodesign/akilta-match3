extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await _frames(2)
	var trace = screen.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	if trace == null or not bool(trace.accepted) or String(trace.result) != "won":
		return _fail(screen, "Level 1 win fixture failed")
	var board_view = screen.get_node("Layout/BoardView")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished
	await create_timer(0.30).timeout
	var terminal: Dictionary = screen.terminal_result_contract()
	if String(terminal.get("objective_summary", "")).find("6 / 6 MOON SIGILS") < 0:
		return _fail(screen, "win objective summary missing")
	if not await _save(screen, "gameplay-win-result-hierarchy.png"):
		return
	print("CAPTURE_PASS: terminal win result hierarchy")
	screen.queue_free()
	await process_frame
	quit(0)

func _save(screen: Node, file_name: String) -> bool:
	var image: Image = screen.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return _fail(screen, "empty viewport")
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(file_name)
	if image.save_png(output_path) != OK:
		return _fail(screen, "save failed")
	print("CAPTURE_FRAME: %s" % output_path)
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
