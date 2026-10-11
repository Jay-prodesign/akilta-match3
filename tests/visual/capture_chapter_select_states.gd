extends SceneTree

const ChapterScene := preload("res://src/ui/map/chapter_select.tscn")
const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const Typography = preload("res://src/ui/theme/typography.gd")
const CurioMaterials = preload("res://src/ui/theme/curio_materials.gd")
const ProgressScript = preload("res://src/progression/player_progress.gd")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var states := [
		{"name":"chapters-00-first-wing.png","wins":0},
		{"name":"chapters-01-current-partial.png","wins":2},
		{"name":"chapters-02-current-complete.png","wins":3},
	]
	for state in states:
		var screen = ChapterScene.instantiate()
		root.add_child(screen)
		Typography.apply(screen)
		CurioMaterials.apply(screen)
		await process_frame
		var progress = _progress_with_wins(int(state["wins"]))
		screen.set_progress(progress)
		ProductNavigation.attach(screen, "map", Callable(), NodePath("Layout"))
		await process_frame
		await process_frame
		var current: Button = screen.get_chapter_button("curio_boutique")
		if current == null or current.disabled:
			return _fail(screen, "current Curio Boutique hotspot unavailable")
		for id in ["witch_atelier", "dark_vanity", "archive", "moon_conservatory", "cemetery_garden"]:
			var future: Button = screen.get_chapter_button(id)
			if future == null or not future.disabled or future.icon != null:
				return _fail(screen, "future wing state is not a truthful sealed card: %s" % id)
		if not await _save(screen, String(state["name"])):
			return
		screen.queue_free()
		await process_frame
	print("CAPTURE_PASS: S02 Chapters production states")
	quit(0)

func _progress_with_wins(count: int):
	var progress = ProgressScript.new()
	progress.lives = 4
	progress.coins = 321
	progress.gems = 7
	if count >= 1:
		progress.apply_level_win("s02-v1", "ch01_level_001", "moon_cameo", 1)
	if count >= 2:
		progress.apply_level_win("s02-v2", "ch01_level_002", "moth_reliquary", 2)
	if count >= 3:
		progress.apply_level_win("s02-v3", "ch01_level_003", "thorned_locket", 3)
	return progress

func _save(screen: Node, file_name: String) -> bool:
	var image: Image = screen.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail(screen, "empty viewport for %s" % file_name)
		return false
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(file_name)
	if image.save_png(output_path) != OK:
		_fail(screen, "save failed for %s" % file_name)
		return false
	print("CAPTURE_FRAME: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	return true

func _fail(screen: Node, message: String) -> void:
	printerr("CAPTURE_FAIL: %s" % message)
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	quit(1)
