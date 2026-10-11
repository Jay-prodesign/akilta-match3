extends SceneTree

const MapScene := preload("res://src/ui/map/chapter_map.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = MapScene.instantiate()
	screen.canonical_level_cap = 3
	screen.visible_route_levels = 10
	root.add_child(screen)
	await process_frame
	await process_frame
	var route = screen.get_node_or_null("Layout/RoutePanel/Scroll/RouteView")
	if route == null:
		return _fail(screen, "S03 route view missing")
	var focus: TextureRect = route.get_node_or_null("FrontierFocus") as TextureRect
	var focus_label: Label = route.get_node_or_null("FrontierFocusLabel") as Label
	_expect(focus != null and focus.texture != null, "S03 frontier_focus must use authored state art")
	_expect(focus_label != null and focus_label.text == "CURRENT RITUAL", "S03 frontier focus label missing")

	var fresh = ProgressScript.new()
	screen.set_progress(fresh)
	await process_frame
	_expect(route.get_frontier_level() == 1, "0/3 frontier must be Level 1")
	_expect(route.get_level_state(1) == "current", "Level 1 must be current at 0/3")
	_expect(route.get_level_state(2) == "locked" and route.get_level_state(3) == "locked", "Levels 2–3 must be locked at 0/3")
	_expect(focus.visible and focus_label.visible, "current frontier marker must be visible at 0/3")

	var p1 = ProgressScript.new()
	p1.apply_level_win("frontier-l1", "ch01_level_001", "moon_cameo", 1)
	screen.set_progress(p1)
	await process_frame
	_expect(route.get_frontier_level() == 2, "1/3 frontier must advance to Level 2")
	_expect(route.get_level_state(1) == "completed", "Level 1 must become completed")
	_expect(route.get_level_state(2) == "current", "Level 2 must become current")
	_expect(route.get_level_state(3) == "locked", "Level 3 must remain locked at 1/3")

	var p2 = ProgressScript.new()
	p2.apply_level_win("frontier2-l1", "ch01_level_001", "moon_cameo", 1)
	p2.apply_level_win("frontier2-l2", "ch01_level_002", "moth_reliquary", 2)
	screen.set_progress(p2)
	await process_frame
	_expect(route.get_frontier_level() == 3, "2/3 frontier must advance to Level 3")
	_expect(route.get_level_state(1) == "completed" and route.get_level_state(2) == "completed", "Levels 1–2 must remain completed")
	_expect(route.get_level_state(3) == "current", "Level 3 must become current")

	var p3 = ProgressScript.new()
	p3.apply_level_win("frontier3-l1", "ch01_level_001", "moon_cameo", 1)
	p3.apply_level_win("frontier3-l2", "ch01_level_002", "moth_reliquary", 2)
	p3.apply_level_win("frontier3-l3", "ch01_level_003", "thorned_locket", 3)
	screen.set_progress(p3)
	await process_frame
	_expect(route.get_frontier_level() == -1, "3/3 route must have no unfinished current frontier")
	_expect(route.get_level_state(1) == "completed" and route.get_level_state(2) == "completed" and route.get_level_state(3) == "completed", "opening trio must all be completed at 3/3")
	_expect(route.get_level_state(4) == "locked", "future route must remain locked after opening completion")
	_expect(not focus.visible and not focus_label.visible, "frontier focus must disappear when opening trio is complete")

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("TEST_PASS: S03 current frontier state contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _fail(screen: Node, message: String) -> void:
	printerr("TEST_FAIL: %s" % message)
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	quit(1)
