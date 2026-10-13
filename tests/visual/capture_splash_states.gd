extends SceneTree

const SPLASH_SCENE := preload("res://src/ui/splash/splash_screen.tscn")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var screen = SPLASH_SCENE.instantiate()
	root.add_child(screen)
	await _frames(2)

	screen.set_boot_state("loading")
	await create_timer(0.62).timeout
	if not await _save(screen, "splash-00-loading.png"):
		return

	screen.set_boot_state("ready")
	await create_timer(0.34).timeout
	if not await _save(screen, "splash-01-ready.png"):
		return

	screen.set_boot_state("recoverable_error", "The local House record was unreadable. A safe new record was prepared; the damaged file was not treated as progress.", true)
	await create_timer(0.34).timeout
	if not await _save(screen, "splash-02-recovered.png"):
		return

	screen.set_boot_state("recoverable_error", "This House record was created by a newer build. Update the game before entering so that record is not overwritten.", false)
	await create_timer(0.34).timeout
	if not await _save(screen, "splash-03-update-required.png"):
		return

	print("CAPTURE_PASS: S00 boot state progression")
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
