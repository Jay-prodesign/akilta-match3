extends SceneTree

const LEVELS := [
	{"number": 2, "path": "res://content/levels/ch01/level_002.json", "profile": "sealed_display"},
	{"number": 3, "path": "res://content/levels/ch01/level_003.json", "profile": "thornlight_arrangement"}
]

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
	for entry in LEVELS:
		var level_number := int(entry["number"])
		var level_path := String(entry["path"])
		var expected_profile := String(entry["profile"])
		if not screen.load_level_path(level_path, 1000 + level_number):
			printerr("CAPTURE_FAIL: Level %d could not load" % level_number)
			screen.queue_free()
			quit(1)
			return
		if str(screen.get("current_level_id")) != "ch01_level_%03d" % level_number:
			printerr("CAPTURE_FAIL: wrong level loaded for Level %d" % level_number)
			screen.queue_free()
			quit(1)
			return
		var board_view = screen.get_node_or_null("Layout/BoardView")
		if board_view == null or str(board_view.get("_visual_profile")) != expected_profile:
			printerr("CAPTURE_FAIL: Level %d art profile mismatch" % level_number)
			screen.queue_free()
			quit(1)
			return
		var reward_label: Label = screen.get_node_or_null("Layout/Awakening/Content/Label")
		var progress_copy: Label = screen.get_node_or_null("Layout/Awakening/Content/ProgressCopy")
		if reward_label == null or progress_copy == null:
			printerr("CAPTURE_FAIL: Level %d relic progress strip missing" % level_number)
			screen.queue_free()
			quit(1)
			return
		var expected_relic := "RELIC · MOTH RELIQUARY" if level_number == 2 else "RELIC · THORNED LOCKET"
		var expected_unit := "SEALS" if level_number == 2 else "SIGILS"
		if reward_label.text != expected_relic or not progress_copy.text.contains(expected_unit):
			printerr("CAPTURE_FAIL: Level %d objective strip does not match reward/objective" % level_number)
			screen.queue_free()
			quit(1)
			return
		await process_frame
		await process_frame
		var image: Image = screen.get_viewport().get_texture().get_image()
		if image == null or image.is_empty():
			printerr("CAPTURE_FAIL: Level %d viewport image empty" % level_number)
			screen.queue_free()
			quit(1)
			return
		var output_dir := ProjectSettings.globalize_path("res://artifacts")
		DirAccess.make_dir_recursive_absolute(output_dir)
		var output_path := output_dir.path_join("level%d-gameplay.png" % level_number)
		if image.save_png(output_path) != OK:
			printerr("CAPTURE_FAIL: Level %d screenshot could not save" % level_number)
			screen.queue_free()
			quit(1)
			return
		print("CAPTURE_PASS: Level %d art profile %s -> %s" % [level_number, expected_profile, output_path])
	screen.queue_free()
	await process_frame
	quit(0)
