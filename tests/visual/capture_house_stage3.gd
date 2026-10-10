extends SceneTree

const ProgressScript = preload("res://src/progression/player_progress.gd")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://src/ui/home/house_home.tscn")
	if packed == null:
		printerr("CAPTURE_FAIL: House scene missing")
		quit(1)
		return

	var progress = ProgressScript.new()
	progress.house_stage = 3
	progress.highest_level_unlocked = 4
	progress.curios.append("moon_cameo")
	progress.curios.append("moth_reliquary")
	progress.curios.append("thorned_locket")

	var screen = packed.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_available_level_count(3)
	screen.set_progress(progress)
	await process_frame
	await process_frame

	var viewport: Viewport = screen.get_viewport()
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("CAPTURE_FAIL: House stage 3 viewport image empty")
		quit(1)
		return
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join("house-stage3.png")
	var err: int = int(image.save_png(output_path))
	if err != OK:
		printerr("CAPTURE_FAIL: House stage 3 save_png error %d" % err)
		quit(1)
		return
	print("CAPTURE_PASS: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	screen.queue_free()
	await process_frame
	quit(0)
