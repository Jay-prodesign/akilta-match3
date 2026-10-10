class_name Match3ChapterSelect
extends Control

signal back_requested
signal chapter_requested(chapter_id: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

func _layout_chapter_hotspots(grid: Control, buttons: Array[Button]) -> void:
	for button in buttons:
		button.position = Vector2(grid.size.x * float(button.get_meta("map_x")), grid.size.y * float(button.get_meta("map_y")))
		button.size = Vector2(grid.size.x * float(button.get_meta("map_w")), grid.size.y * float(button.get_meta("map_h")))

func _ready() -> void:
	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 28
	layout.offset_right = -28
	layout.offset_top = 34
	layout.offset_bottom = -28
	layout.add_theme_constant_override("separation", 14)
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
	eyebrow.add_theme_font_size_override("font_size", 20)
	eyebrow.add_theme_color_override("font_color", Color("#F0DCCB"))
	layout.add_child(eyebrow)

	var title := Label.new()
	title.text = "Choose a Wing"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	layout.add_child(title)

	var detail := Label.new()
	detail.text = "Explore, restore and unlock new wings."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 22)
	detail.add_theme_color_override("font_color", Color("#E8C987"))
	layout.add_child(detail)

	var grid := Control.new()
	grid.name = "ChapterGrid"
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(grid)

	var chapters := [
		{"id":"curio_boutique","name":"CURIO BOUTIQUE","detail":"Rare finds · Levels 1–3","open":true,"glyph":"✦","art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg","x":0.03,"y":0.16,"w":0.44,"h":0.14},
		{"id":"witch_atelier","name":"WITCH ATELIER","detail":"Potions & experiments","open":false,"glyph":"⚗","art":"res://assets/pieces/potion.svg","x":0.53,"y":0.24,"w":0.44,"h":0.14},
		{"id":"dark_vanity","name":"DARK VANITY","detail":"Mirrors & secrets","open":false,"glyph":"☽","art":"res://assets/pieces/moon_sigil.svg","x":0.03,"y":0.37,"w":0.42,"h":0.14},
		{"id":"grand_hall","name":"GRAND HALL","detail":"Your restored House","open":false,"glyph":"⌂","art":"res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg","x":0.53,"y":0.45,"w":0.43,"h":0.14},
		{"id":"moon_conservatory","name":"MOON CONSERVATORY","detail":"Celestial botanicals","open":false,"glyph":"❋","art":"res://assets/pieces/thorn_rose.svg","x":0.53,"y":0.64,"w":0.44,"h":0.14},
		{"id":"cemetery_garden","name":"CEMETERY GARDEN","detail":"Resting beauties","open":false,"glyph":"✧","art":"res://assets/pieces/crow.svg","x":0.03,"y":0.73,"w":0.44,"h":0.14}
	]
	var hotspot_buttons: Array[Button] = []
	for data in chapters:
		var button := Button.new()
		button.name = "CurioBoutiqueButton" if String(data["id"]) == "curio_boutique" else "Chapter_" + String(data["id"])
		button.set_meta("map_x", float(data["x"]))
		button.set_meta("map_y", float(data["y"]))
		button.set_meta("map_w", float(data["w"]))
		button.set_meta("map_h", float(data["h"]))
		button.custom_minimum_size = Vector2(240, 110)
		button.disabled = not bool(data["open"])
		button.text = "%s\n%s%s" % [String(data["name"]), String(data["detail"]), "" if bool(data["open"]) else "\nSEALED WING"]
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
		button.add_theme_stylebox_override("hover", box)
		button.add_theme_stylebox_override("disabled", box)
		if bool(data["open"]):
			button.pressed.connect(func(): chapter_requested.emit(String(data["id"])))
		grid.add_child(button)
		hotspot_buttons.append(button)

	grid.resized.connect(func(): _layout_chapter_hotspots(grid, hotspot_buttons))
	call_deferred("_layout_chapter_hotspots", grid, hotspot_buttons)

	var back := Button.new()
	back.text = "BACK TO THE HOUSE"
	back.custom_minimum_size = Vector2(0, 60)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(func(): back_requested.emit())
	layout.add_child(back)
