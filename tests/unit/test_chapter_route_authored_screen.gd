extends SceneTree

const ChapterMapScene = preload("res://src/ui/map/chapter_map.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = ChapterMapScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var title := screen.get_node_or_null("Layout/Title") as Label
	var progress_label := screen.get_node_or_null("Layout/Progress") as Label
	var intro := screen.get_node_or_null("Layout/Intro") as Label
	_expect(title != null and title.get_theme_font_size("font_size") >= 52, "S03 Chapter title must retain mobile-readable hierarchy")
	_expect(progress_label != null and progress_label.get_theme_font_size("font_size") >= 26, "S03 chapter progress must remain legible")
	_expect(intro != null and intro.get_theme_font_size("font_size") >= 21, "S03 chapter intro copy must remain legible")
	var visual_contract: Dictionary = screen.north_star_map_contract()
	_expect(bool(visual_contract.get("strong_title", false)), "S03 must retain a strong North Star chapter title")
	_expect(bool(visual_contract.get("progress_plate", false)), "S03 progress must sit on an authored readable plate")
	_expect(bool(visual_contract.get("concise_route_instruction", false)), "S03 route instruction must not become a tiny paragraph")
	_expect(bool(visual_contract.get("route_world_dominant", false)), "S03 authored route world must remain the dominant visual surface")
	var route = screen.get_node_or_null("Layout/RoutePanel/Scroll/RouteView")
	_expect(route != null, "S03 authored RouteView missing")
	if route == null:
		return _finish()

	route.set_canonical_level_cap(3)
	var progress = ProgressScript.new()
	route.set_progress(progress)
	await process_frame

	var contract: Dictionary = route.route_authored_contract()
	_expect(bool(contract.get("authored_level_slots", false)), "S03 must author all visible route level and label slots")
	_expect(bool(contract.get("authored_frontier_slots", false)), "S03 frontier focus and label slots must be authored")
	_expect(bool(contract.get("frontier_raster_loaded", false)), "S03 frontier marker must use production raster art")
	_expect(bool(contract.get("raster_relics_loaded", false)), "S03 opening relic identity art must use production raster assets")
	_expect(bool(contract.get("opening_label_readability", false)), "S03 opening ritual captions must retain readable authored plates")
	_expect(bool(contract.get("frontier_label_readability", false)), "S03 CURRENT RITUAL label must retain readable authored plate")
	_expect(not bool(contract.get("runtime_node_factory", true)), "S03 must not rebuild route nodes at runtime")

	for level_number in range(1, 11):
		var button := route.get_level_button(level_number) as Button
		_expect(button != null, "Authored route button missing for level %d" % level_number)
		if button != null:
			_expect(button.size.x >= 52.0 and button.size.y >= 52.0, "Route level %d must retain a mobile touch target" % level_number)

	_expect(route.get_frontier_level() == 1, "Fresh route frontier must point to Level 1")
	var frontier_focus := route.get_node_or_null("FrontierFocus") as TextureRect
	var frontier_label := route.get_node_or_null("FrontierFocusLabel") as Label
	_expect(frontier_focus != null and frontier_focus.visible and frontier_focus.texture != null, "Fresh route must expose authored frontier marker")
	_expect(frontier_label != null and frontier_label.visible and frontier_label.text == "CURRENT RITUAL", "Fresh route must expose authored frontier label")

	progress.apply_level_win("route-l1", "ch01_level_001", "moon_cameo", 1)
	route.set_progress(progress)
	await process_frame
	_expect(route.get_frontier_level() == 2, "After Level 1 completion frontier must advance to Level 2")
	_expect(route.get_level_state(1) == "completed", "Completed Level 1 state lost")
	_expect(route.get_level_state(2) == "current", "Level 2 must become the current ritual")

	for level_number in [1, 2, 3]:
		var art := route.get_node_or_null("RelicArt%d" % level_number) as TextureRect
		_expect(art != null and art.texture != null, "Authored raster relic art missing for opening level %d" % level_number)

	screen.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored Chapter Route production screen")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
