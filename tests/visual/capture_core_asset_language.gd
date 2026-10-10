extends SceneTree

const BoardState = preload("res://src/match3/domain/board_state.gd")
const BoardView = preload("res://src/match3/presentation/board_view.gd")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var surface := Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(surface)

	var backdrop := ColorRect.new()
	backdrop.color = Color("#100D12")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_child(backdrop)

	var title := Label.new()
	title.position = Vector2(56, 64)
	title.size = Vector2(968, 54)
	title.text = "CORE ASSET LANGUAGE · FOUNDER GATE SPECIMEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#F1E8DD"))
	title.add_theme_font_size_override("font_size", 32)
	surface.add_child(title)

	var subtitle := Label.new()
	subtitle.position = Vector2(56, 122)
	subtitle.size = Vector2(968, 42)
	subtitle.text = "Base families · House-native specials · Wax Seal blocker"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#BFA5D8"))
	subtitle.add_theme_font_size_override("font_size", 21)
	surface.add_child(subtitle)

	var board := BoardView.new()
	board.position = Vector2(64, 220)
	board.size = Vector2(952, 520)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(board)

	var level := {
		"width": 8,
		"height": 3,
		"moves": 99,
		"objective": "collect_family",
		"objective_family": "moon",
		"objective_target": 99,
		"families": ["moon", "rose", "moth", "key", "leaf", "cat", "candle", "skull"],
		"initial_rows": [
			["moon", "rose", "moth", "key", "leaf", "cat", "candle", "skull"],
			["skull", "candle", "cat", "leaf", "key", "moth", "rose", "moon"],
			["moth", "moon", "skull", "rose", "candle", "key", "cat", "leaf"]
		],
		"specials": [
			{"x": 0, "y": 1, "kind": "global"},
			{"x": 1, "y": 1, "kind": "line_h"},
			{"x": 2, "y": 1, "kind": "line_v"},
			{"x": 3, "y": 1, "kind": "area"},
			{"x": 4, "y": 1, "kind": "smart"}
		],
		"blockers": [
			{"x": 1, "y": 2, "type": "wax_seal", "hp": 1},
			{"x": 3, "y": 2, "type": "wax_seal", "hp": 2}
		]
	}
	board.set_board(BoardState.from_level(level, 7070))

	var row1 := Label.new()
	row1.position = Vector2(90, 820)
	row1.size = Vector2(900, 36)
	row1.text = "ROW 1 · eight distinct North Star base families"
	row1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row1.add_theme_color_override("font_color", Color("#D9CDD5"))
	row1.add_theme_font_size_override("font_size", 18)
	surface.add_child(row1)

	var row2 := Label.new()
	row2.position = Vector2(90, 862)
	row2.size = Vector2(900, 36)
	row2.text = "ROW 2 · eclipse/global · horizontal beam · vertical beam · ritual burst · seeker"
	row2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row2.add_theme_color_override("font_color", Color("#D8B56A"))
	row2.add_theme_font_size_override("font_size", 18)
	surface.add_child(row2)

	var row3 := Label.new()
	row3.position = Vector2(90, 904)
	row3.size = Vector2(900, 72)
	row3.text = "ROW 3 · Wax Seal treatment over the same learned base vocabulary\nCandidate/procedural presentation · NOT shipping art"
	row3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row3.add_theme_color_override("font_color", Color("#C7728F"))
	row3.add_theme_font_size_override("font_size", 18)
	surface.add_child(row3)

	await process_frame
	await process_frame
	await process_frame

	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("CAPTURE_FAIL: core asset specimen viewport image empty")
		quit(1)
		return

	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join("core-asset-language.png")
	var err: int = int(image.save_png(output_path))
	if err != OK:
		printerr("CAPTURE_FAIL: save_png error %d" % err)
		quit(1)
		return

	print("CAPTURE_PASS: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	surface.queue_free()
	await process_frame
	quit(0)
