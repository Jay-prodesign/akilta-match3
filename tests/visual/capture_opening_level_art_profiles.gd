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
	for entry in LEVELS:
		var level_number := int(entry["number"])
		var level_path := String(entry["path"])
		var expected_profile := String(entry["profile"])
		var screen = packed.instantiate()
		root.add_child(screen)
		await process_frame
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

		var level_file := FileAccess.open(level_path, FileAccess.READ)
		if level_file == null:
			printerr("CAPTURE_FAIL: Level %d authored teaching moves missing" % level_number)
			screen.queue_free()
			quit(1)
			return
		var level_data: Variant = JSON.parse_string(level_file.get_as_text())
		level_file.close()
		if not level_data is Dictionary:
			printerr("CAPTURE_FAIL: Level %d data malformed" % level_number)
			screen.queue_free()
			quit(1)
			return
		for move in level_data.get("teaching_moves", []):
			var trace = screen.attempt_swap(
				Vector2i(int(move[0]), int(move[1])),
				Vector2i(int(move[2]), int(move[3]))
			)
			if trace == null or not trace.accepted:
				printerr("CAPTURE_FAIL: Level %d authored move rejected" % level_number)
				screen.queue_free()
				quit(1)
				return
			if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()) and board_view.has_signal("trace_motion_finished"):
				await board_view.trace_motion_finished
			await process_frame
			if screen.result_overlay.visible:
				break
		if not screen.result_overlay.visible:
			printerr("CAPTURE_FAIL: Level %d authored path did not reach result/reward" % level_number)
			screen.queue_free()
			quit(1)
			return
		var booster_tray: PanelContainer = screen.get_node_or_null("BoosterTray") as PanelContainer
		if booster_tray != null and booster_tray.visible:
			printerr("CAPTURE_FAIL: Level %d result must hide gameplay-only boosters" % level_number)
			screen.queue_free()
			quit(1)
			return
		var result_name: Label = screen.get_node("ResultOverlay/Card/Content/RewardName")
		var result_eyebrow: Label = screen.get_node("ResultOverlay/Card/Content/Eyebrow")
		var result_house_change: Label = screen.get_node("ResultOverlay/Card/Content/HouseChange")
		var expected_name := "MOTH RELIQUARY · RECOVERED" if level_number == 2 else "THORNED LOCKET · RECOVERED"
		var expected_result_relic := "RELIC 02" if level_number == 2 else "RELIC 03"
		if result_name.text != expected_name or not result_eyebrow.text.ends_with(expected_result_relic):
			printerr("CAPTURE_FAIL: Level %d result identifies the wrong Curio" % level_number)
			screen.queue_free()
			quit(1)
			return
		if level_number == 2 and not result_house_change.text.contains("Moth Reliquary"):
			printerr("CAPTURE_FAIL: Level 2 result does not explain its House consequence")
			screen.queue_free()
			quit(1)
			return
		if level_number == 3 and not result_house_change.text.contains("Thorned Locket"):
			printerr("CAPTURE_FAIL: Level 3 result does not explain its House consequence")
			screen.queue_free()
			quit(1)
			return
		await process_frame
		var result_image: Image = screen.get_viewport().get_texture().get_image()
		var result_path := ProjectSettings.globalize_path("res://artifacts/level%d-result.png" % level_number)
		if result_image == null or result_image.is_empty() or result_image.save_png(result_path) != OK:
			printerr("CAPTURE_FAIL: Level %d result screenshot could not save" % level_number)
			screen.queue_free()
			quit(1)
			return
		print("CAPTURE_PASS: Level %d result reward -> %s" % [level_number, result_path])
		screen.queue_free()
		await process_frame

		var prestart_scene := load("res://src/ui/prestart/level_prestart.tscn")
		if prestart_scene == null:
			printerr("CAPTURE_FAIL: Level %d prestart scene missing" % level_number)
			quit(1)
			return
		var prestart = prestart_scene.instantiate()
		root.add_child(prestart)
		await process_frame
		if not prestart.configure_level(level_number):
			printerr("CAPTURE_FAIL: Level %d prestart content could not load" % level_number)
			prestart.queue_free()
			quit(1)
			return
		await process_frame
		await process_frame
		var prestart_art = prestart.get_node_or_null("Layout/Card/Content/RitualArt")
		var prestart_note: Label = prestart.get_node_or_null("Layout/Card/Content/Note") as Label
		var expected_prestart_relic := "moth_reliquary" if level_number == 2 else "thorned_locket"
		var expected_note_fragment := "Moth Reliquary" if level_number == 2 else "Thorned Locket"
		if prestart_note == null or not prestart_note.text.contains(expected_note_fragment):
			printerr("CAPTURE_FAIL: Level %d prestart story does not match its Curio reward" % level_number)
			prestart.queue_free()
			quit(1)
			return
		if prestart_art == null or str(prestart_art.get("relic_id")) != expected_prestart_relic:
			printerr("CAPTURE_FAIL: Level %d prestart art does not match its reward" % level_number)
			prestart.queue_free()
			quit(1)
			return
		var prestart_image: Image = prestart.get_viewport().get_texture().get_image()
		var prestart_path := ProjectSettings.globalize_path("res://artifacts/level%d-prestart.png" % level_number)
		if prestart_image == null or prestart_image.is_empty() or prestart_image.save_png(prestart_path) != OK:
			printerr("CAPTURE_FAIL: Level %d prestart screenshot could not save" % level_number)
			prestart.queue_free()
			quit(1)
			return
		print("CAPTURE_PASS: Level %d prestart reward art %s -> %s" % [level_number, expected_prestart_relic, prestart_path])
		prestart.queue_free()
		await process_frame
	quit(0)
