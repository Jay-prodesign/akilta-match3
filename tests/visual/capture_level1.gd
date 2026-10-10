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
	root.add_child(screen)
	await process_frame
	await process_frame
	await process_frame

	var viewport: Viewport = screen.get_viewport()
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("CAPTURE_FAIL: viewport image empty")
		quit(1)
		return

	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join("level1-gameplay.png")
	var err: int = int(image.save_png(output_path))
	if err != OK:
		printerr("CAPTURE_FAIL: save_png error %d" % err)
		quit(1)
		return

	print("CAPTURE_PASS: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	screen.queue_free()
	await process_frame
	quit(0)
