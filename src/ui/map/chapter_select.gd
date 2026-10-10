class_name Match3ChapterSelect
extends Control

signal back_requested
signal chapter_requested(chapter_id: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

func _ready() -> void:
	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 28
	layout.offset_right = -28
	layout.offset_top = 34
	layout.offset_bottom = -28
	layout.add_theme_constant_override("separation", 14)
	add_child(layout)
	var world_art := TextureRect.new()
	world_art.name = "HouseWorldBackdrop"
	world_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_art.texture = PieceAssetLoader.ornament("res://assets/world/ch01_curio_boutique/north_star_splash.svg")
	world_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	world_art.modulate = Color(0.90, 0.82, 0.90, 0.72)
	add_child(world_art)
	move_child(world_art, 0)
	var eyebrow := Label.new()
	eyebrow.text = "THE HOUSE AND ITS CHAPTERS"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color("#D8C6C3"))
	layout.add_child(eyebrow)
	var title := Label.new()
	title.text = "Choose a Wing"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#F4E5D3"))
	layout.add_child(title)
	var detail := Label.new()
	detail.text = "Explore, restore and unlock new wings."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 16)
	detail.add_theme_color_override("font_color", Color("#D5AD70"))
	layout.add_child(detail)
	var grid := GridContainer.new()
	grid.name = "ChapterGrid"
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	layout.add_child(grid)
	var chapters := [
		{"id":"curio_boutique","name":"CURIO BOUTIQUE","detail":"Rare finds · Levels 1–3","open":true,"glyph":"✦"},
		{"id":"witch_atelier","name":"WITCH ATELIER","detail":"Potions & experiments","open":false,"glyph":"⚗"},
		{"id":"dark_vanity","name":"DARK VANITY","detail":"Mirrors & secrets","open":false,"glyph":"☽"},
		{"id":"grand_hall","name":"GRAND HALL","detail":"Your restored House","open":false,"glyph":"⌂"},
		{"id":"moon_conservatory","name":"MOON CONSERVATORY","detail":"Celestial botanicals","open":false,"glyph":"❋"},
		{"id":"cemetery_garden","name":"CEMETERY GARDEN","detail":"Resting beauties","open":false,"glyph":"✧"}
	]
	for data in chapters:
		var button := Button.new()
		button.name = "CurioBoutiqueButton" if String(data["id"]) == "curio_boutique" else "Chapter_" + String(data["id"])
		button.custom_minimum_size = Vector2(0, 168)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not bool(data["open"])
		button.text = "%s\n%s\n%s%s" % [String(data["glyph"]), String(data["name"]), String(data["detail"]), "" if bool(data["open"]) else "\nSEALED WING"]
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color("#F4E5D3"))
		button.add_theme_color_override("font_disabled_color", Color("#D2C4D7"))
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#302039") if bool(data["open"]) else Color("#211A2A")
		box.border_color = Color("#D5AD70", 0.92 if bool(data["open"]) else 0.62)
		box.set_border_width_all(1)
		box.set_corner_radius_all(8)
		box.shadow_color = Color(0,0,0,0.4)
		box.shadow_size = 6
		button.add_theme_stylebox_override("normal", box)
		button.add_theme_stylebox_override("hover", box)
		button.add_theme_stylebox_override("disabled", box)
		if bool(data["open"]):
			button.pressed.connect(func(): chapter_requested.emit(String(data["id"])))
		grid.add_child(button)
	var back := Button.new()
	back.text = "BACK TO THE HOUSE"
	back.custom_minimum_size = Vector2(0, 52)
	back.pressed.connect(func(): back_requested.emit())
	layout.add_child(back)
