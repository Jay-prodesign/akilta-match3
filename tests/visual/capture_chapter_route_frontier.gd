extends SceneTree

const MapScene := preload("res://src/ui/map/chapter_map.tscn")
const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const Typography = preload("res://src/ui/theme/typography.gd")
const CurioMaterials = preload("res://src/ui/theme/curio_materials.gd")
const ProgressScript = preload("res://src/progression/player_progress.gd")
const LevelCatalog = preload("res://src/content/level_catalog.gd")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var states := [
		{"name":"chapter-route-00-frontier1.png","wins":0},
		{"name":"chapter-route-01-frontier2.png","wins":1},
		{"name":"chapter-route-02-frontier3.png","wins":2},
		{"name":"chapter-route-03-complete.png","wins":3},
	]
	var catalog = LevelCatalog.new()
	if not catalog.load_default() or not catalog.validate().is_empty():
		return _fail(null, "S03 canonical level catalog failed to load")
	for state in states:
		var screen = MapScene.instantiate()
		screen.canonical_level_cap = catalog.count()
		screen.visible_route_levels = max(10, catalog.count())
		screen.set_level_catalog(catalog.entries())
		root.add_child(screen)
		Typography.apply(screen)
		CurioMaterials.apply(screen)
		await process_frame
		var progress = _progress_with_wins(int(state["wins"]))
		screen.set_progress(progress)
		ProductNavigation.attach(screen, "map", Callable(), NodePath("Layout"))
		await process_frame
		await process_frame
		var route = screen.get_node_or_null("Layout/RoutePanel/Scroll/RouteView")
		if route == null:
			return _fail(screen, "S03 route view missing")
		var expected_frontier := int(state["wins"]) + 1 if int(state["wins"]) < 3 else -1
		if route.get_frontier_level() != expected_frontier:
			return _fail(screen, "S03 frontier mismatch for %s" % String(state["name"]))
		var focus: TextureRect = route.get_node_or_null("FrontierFocus") as TextureRect
		if focus == null or focus.texture == null:
			return _fail(screen, "S03 authored frontier focus missing")
		var relic_art: TextureRect = route.get_node_or_null("RelicArt1") as TextureRect
		if relic_art == null or relic_art.texture == null:
			return _fail(screen, "S03 catalog-driven raster Curio route art missing")
		if (expected_frontier > 0) != focus.visible:
			return _fail(screen, "S03 frontier focus visibility mismatch")
		if not await _save(screen, String(state["name"])):
			return
		screen.queue_free()
		await process_frame
	print("CAPTURE_PASS: S03 frontier state progression")
	quit(0)

func _progress_with_wins(count: int):
	var progress = ProgressScript.new()
	if count >= 1:
		progress.apply_level_win("route-v1", "ch01_level_001", "moon_cameo", 1)
	if count >= 2:
		progress.apply_level_win("route-v2", "ch01_level_002", "moth_reliquary", 2)
	if count >= 3:
		progress.apply_level_win("route-v3", "ch01_level_003", "thorned_locket", 3)
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
