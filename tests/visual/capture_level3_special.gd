extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://src/ui/gameplay/gameplay_screen.tscn")
	if packed == null:
		printerr("CAPTURE_FAIL: gameplay scene missing")
		quit(1)
		return

	var screen = packed.instantiate()
	screen.set("default_level_path", "res://content/levels/ch01/level_003.json")
	screen.set("default_seed", 1003)
	root.add_child(screen)
	await process_frame
	await process_frame

	var trace = screen.attempt_swap(Vector2i(2, 3), Vector2i(2, 4))
	if trace == null or not trace.accepted or not trace.event_types().has("special_created"):
		printerr("CAPTURE_FAIL: Level 3 teaching move did not create special")
		quit(1)
		return
	var board_view = screen.get_node_or_null("Layout/BoardView")
	if board_view == null:
		printerr("CAPTURE_FAIL: Level 3 board view missing")
		quit(1)
		return
	# Capture the settled player-visible special state, not the first animation
	# frame where the resolver is already final but presentation intentionally
	# still shows the pre-move snapshot.
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished
	await process_frame
	await process_frame

	var viewport: Viewport = screen.get_viewport()
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("CAPTURE_FAIL: Level 3 viewport image empty")
		quit(1)
		return
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join("level3-line-special.png")
	var err: int = int(image.save_png(output_path))
	if err != OK:
		printerr("CAPTURE_FAIL: Level 3 save_png error %d" % err)
		quit(1)
		return
	print("CAPTURE_PASS: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	screen.queue_free()
	await process_frame
	quit(0)
