class_name Match3ChapterSelect
extends Control

signal back_requested
signal chapter_requested(chapter_id: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const OPENING_LEVEL_COUNT := 3

var progress
var _curio_boutique_button: Button
var _chapter_summary: Label

func set_progress(value) -> void:
	progress = value
	_refresh_progress_state()

func _refresh_progress_state() -> void:
	if _curio_boutique_button == null or _chapter_summary == null:
		return
	var completed := 0
	var collected := 0
	var restored := 0
	if progress != null:
		completed = mini(int(progress.completed_levels.size()), OPENING_LEVEL_COUNT)
		collected = mini(int(progress.curios.size()), OPENING_LEVEL_COUNT)
		restored = int(progress.house_stage)
	var opening_complete := completed >= OPENING_LEVEL_COUNT and collected >= OPENING_LEVEL_COUNT and restored >= OPENING_LEVEL_COUNT
	if opening_complete:
		_curio_boutique_button.text = "CURIO BOUTIQUE\nRESTORED · 3 / 3 · FIRST CABINET SET"
		_chapter_summary.text = "The opening wing is restored. Revisit its rituals or explore the sealed wings waiting beyond."
		_curio_boutique_button.tooltip_text = "Curio Boutique · opening cabinet set restored · Levels 1–3 replayable"
	elif completed > 0:
		_curio_boutique_button.text = "CURIO BOUTIQUE\n%d / %d DISPLAYS AWAKENED · CONTINUE" % [completed, OPENING_LEVEL_COUNT]
		_chapter_summary.text = "%d of %d opening displays are awake. Continue restoring the Curio Boutique." % [completed, OPENING_LEVEL_COUNT]
		_curio_boutique_button.tooltip_text = "Curio Boutique · %d / %d opening displays awakened" % [completed, OPENING_LEVEL_COUNT]
	else:
		_curio_boutique_button.text = "CURIO BOUTIQUE\nOPENING RITUALS · 0 / 3"
		_chapter_summary.text = "Restore the Curio Boutique first. Other wings remain sealed for later journeys."
		_curio_boutique_button.tooltip_text = "Curio Boutique · opening rituals · Levels 1–3"

func _layout_chapter_hotspots(grid: Control, buttons: Array[Button]) -> void:
	var compact := grid.size.x < 680.0
	var count := buttons.size()
	for i in range(count):
		var button := buttons[i]
		if compact:
			var spacing := 6.0
			var card_height := maxf(48.0, (grid.size.y - spacing * float(count - 1)) / float(count))
			button.position = Vector2(0, float(i) * (card_height + spacing))
			button.size = Vector2(grid.size.x, card_height)
			button.add_theme_font_size_override("font_size", 14)
			button.add_theme_constant_override("icon_max_width", 58)
		else:
			button.position = Vector2(grid.size.x * float(button.get_meta("map_x")), grid.size.y * float(button.get_meta("map_y")))
			button.size = Vector2(grid.size.x * float(button.get_meta("map_w")), grid.size.y * float(button.get_meta("map_h")))
			button.add_theme_font_size_override("font_size", 24)
			button.add_theme_constant_override("icon_max_width", 104)

func _ready() -> void:
	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 16
	layout.offset_right = -16
	layout.offset_top = 22
	layout.offset_bottom = -16
	layout.add_theme_constant_override("separation", 8)
	layout.z_index = 10
	layout.modulate = Color.WHITE
	add_child(layout)

	var world_art := TextureRect.new()
	world_art.name = "HouseWorldBackdrop"
	world_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_art.z_index = -1
	world_art.texture = PieceAssetLoader.ornament("res://assets/world/ch01_curio_boutique/north_star_splash.svg")
	world_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	world_art.modulate = Color(0.90, 0.82, 0.90, 0.72)
	add_child(world_art)
	move_child(world_art, 0)

	var eyebrow := Label.new()
	eyebrow.text = "THE HOUSE AND ITS CHAPTERS"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.add_theme_color_override("font_color", Color("#F0DCCB"))
	layout.add_child(eyebrow)

	var title := Label.new()
	title.text = "Choose a Wing"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	layout.add_child(title)

	var detail := Label.new()
	detail.name = "ChapterSummary"
	detail.text = "Restore the Curio Boutique first. Other wings remain sealed for later journeys."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 17)
	detail.add_theme_color_override("font_color", Color("#E8C987"))
	layout.add_child(detail)
	_chapter_summary = detail

	var grid := Control.new()
	grid.name = "ChapterGrid"
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(grid)

	var chapters := [
		{"id":"curio_boutique","name":"CURIO BOUTIQUE","detail":"Rare finds · Levels 1–3","open":true,"glyph":"✦","art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg","x":0.03,"y":0.16,"w":0.44,"h":0.14},
		{"id":"witch_atelier","name":"WITCH ATELIER","detail":"Potions & experiments","open":false,"glyph":"⚗","art":"res://assets/pieces/potion.svg","x":0.53,"y":0.24,"w":0.44,"h":0.14},
		{"id":"dark_vanity","name":"DARK VANITY","detail":"Mirrors & secrets","open":false,"glyph":"☽","art":"res://assets/pieces/moon_sigil.svg","x":0.03,"y":0.37,"w":0.42,"h":0.14},
		{"id":"archive","name":"THE ARCHIVE","detail":"Forgotten stories","open":false,"glyph":"⌂","art":"res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg","x":0.53,"y":0.45,"w":0.43,"h":0.14},
		{"id":"moon_conservatory","name":"MOON CONSERVATORY","detail":"Celestial botanicals","open":false,"glyph":"❋","art":"res://assets/pieces/thorn_rose.svg","x":0.53,"y":0.64,"w":0.44,"h":0.14},
		{"id":"cemetery_garden","name":"CEMETERY GARDEN","detail":"Resting beauties","open":false,"glyph":"✧","art":"res://assets/pieces/crow.svg","x":0.03,"y":0.73,"w":0.44,"h":0.14}
	]
	var hotspot_buttons: Array[Button] = []
	for data in chapters:
		var button := Button.new()
		button.name = "CurioBoutiqueButton" if String(data["id"]) == "curio_boutique" else "Chapter_" + String(data["id"])
		if String(data["id"]) == "curio_boutique":
			_curio_boutique_button = button
		button.set_meta("map_x", float(data["x"]))
		button.set_meta("map_y", float(data["y"]))
		button.set_meta("map_w", float(data["w"]))
		button.set_meta("map_h", float(data["h"]))
		button.custom_minimum_size = Vector2.ZERO
		button.disabled = not bool(data["open"])
		button.text = "%s\n%s" % [String(data["name"]), String(data["detail"]) if bool(data["open"]) else "SEALED · COMING SOON"]
		button.icon = PieceAssetLoader.ornament(String(data.get("art", "")))
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("icon_max_width", 104)
		button.expand_icon = true
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_color_override("font_color", Color("#FFF7E9"))
		button.add_theme_color_override("font_disabled_color", Color("#E9DDEC"))
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#241827", 0.92) if bool(data["open"]) else Color("#17131D", 0.90)
		box.border_color = Color("#F2D49A", 1.0 if bool(data["open"]) else 0.92)
		box.set_border_width_all(1)
		box.set_corner_radius_all(8)
		box.shadow_color = Color(0, 0, 0, 0.55)
		box.shadow_size = 8
		button.add_theme_stylebox_override("normal", box)
		var hover_box := box.duplicate() as StyleBoxFlat
		hover_box.bg_color = Color("#493052") if bool(data["open"]) else box.bg_color
		hover_box.border_color = Color("#FFE4AA") if bool(data["open"]) else box.border_color
		button.add_theme_stylebox_override("hover", hover_box)
		button.add_theme_stylebox_override("focus", hover_box)
		button.add_theme_stylebox_override("disabled", box)
		if bool(data["open"]):
			button.pressed.connect(func(): chapter_requested.emit(String(data["id"])))
		grid.add_child(button)
		hotspot_buttons.append(button)

	grid.resized.connect(func(): _layout_chapter_hotspots(grid, hotspot_buttons))
	call_deferred("_layout_chapter_hotspots", grid, hotspot_buttons)

	var back := Button.new()
	back.text = "BACK TO THE HOUSE"
	back.custom_minimum_size = Vector2(0, 48)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(func(): back_requested.emit())
	layout.add_child(back)
	_refresh_progress_state()
