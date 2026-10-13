extends SceneTree

const HouseScene := preload("res://src/ui/home/house_home.tscn")
const ProgressScript := preload("res://src/progression/player_progress.gd")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var screen = HouseScene.instantiate()
	root.add_child(screen)
	await _frames(2)
	screen.set_available_level_count(3)
	screen.apply_presentation_settings({"reduced_motion": false})
	var progress = ProgressScript.new()
	progress.apply_level_win("vfx-l1", "ch01_level_001", "moon_cameo", 1)
	progress.apply_level_win("vfx-l2", "ch01_level_002", "moth_reliquary", 2)
	progress.apply_level_win("vfx-l3", "ch01_level_003", "thorned_locket", 3)
	screen.set_progress(progress)
	screen.show_restoration_ceremony("thorned_locket", 3)
	await _frames(2)
	await create_timer(0.24).timeout
	var contract: Dictionary = screen.restoration_vfx_contract()
	if String(contract.get("slot", "")) != "S07/house_hero/awakening_fx":
		return _fail(screen, "canonical S07 awakening_fx slot missing")
	if not bool(contract.get("active", false)) or not bool(contract.get("echo_spawned", false)):
		return _fail(screen, "House awaken VFX not active in capture window")
	if not await _save(screen, "restoration-awaken-vfx.png"):
		return
	print("CAPTURE_PASS: S07 House awaken VFX")
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
