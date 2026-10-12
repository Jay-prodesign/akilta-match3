class_name Match3LevelPrestart
extends Control

signal back_requested
signal start_requested(level_number: int)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")

@onready var level_label: Label = $Layout/Card/Content/Level
@onready var title_label: Label = $Layout/Card/Content/Title
@onready var objective_label: Label = $Layout/Card/Content/Objective
@onready var moves_label: Label = $Layout/Card/Content/Moves
@onready var reward_label: Label = $Layout/Card/Content/Reward
@onready var note_label: Label = $Layout/Card/Content/Note
@onready var ritual_art: Control = $Layout/Card/Content/RitualArt
@onready var start_button: Button = $Layout/Card/Content/Start
@onready var back_button: Button = $Layout/Back

const AID_ART_PATHS := {
	"hint": "res://assets/pieces/moon_sigil.webp",
	"plus_moves": "res://assets/pieces/potion.webp"
}

var level_number: int = 1

func _ready() -> void:
	_install_world_backdrop()
	_install_level_artwork()
	_build_ritual_aids()
	_style_ritual_actions()
	start_button.pressed.connect(func(): start_requested.emit(level_number))
	back_button.pressed.connect(func(): back_requested.emit())

func _install_world_backdrop() -> void:
	var art := TextureRect.new()
	art.name = "NorthStarWorldBackdrop"
	art.texture = ScreenArt.texture("prestart_bg_curio_boutique")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color.WHITE
	add_child(art)
	move_child(art, 1)

func _install_level_artwork() -> void:
	if ritual_art == null or ritual_art.get_node_or_null("LevelArtwork") != null:
		return
	var art := TextureRect.new()
	art.name = "LevelArtwork"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The cabinet artwork is the ritual backdrop. It must sit behind the parent
	# MoonCameoRitualView so the canonical sealed/owned reward object remains a
	# visible foreground slot instead of being covered by a child texture.
	art.show_behind_parent = true
	art.modulate = Color(0.88, 0.82, 0.90, 0.72)
	art.texture = ScreenArt.texture("prestart_ch01_level01_art")
	ritual_art.add_child(art)

func _build_ritual_aids() -> void:
	var content := get_node_or_null("Layout/Card/Content") as VBoxContainer
	if content == null or content.get_node_or_null("RitualAids") != null:
		return
	var panel := PanelContainer.new()
	panel.name = "RitualAids"
	panel.custom_minimum_size = Vector2(0, 102)
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#120D18", 0.94)
	shell.border_color = Color("#D5AD70", 0.46)
	shell.set_border_width_all(1)
	shell.set_corner_radius_all(12)
	shell.content_margin_left = 10
	shell.content_margin_right = 10
	shell.content_margin_top = 10
	shell.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", shell)
	var start_index := start_button.get_index()
	content.add_child(panel)
	content.move_child(panel, start_index)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	var heading := Label.new()
	heading.name = "RitualAidsHeading"
	heading.text = "RITUAL HELP"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("#D5AD70"))
	heading.add_theme_font_size_override("font_size", 18)
	column.add_child(heading)
	var row := HBoxContainer.new()
	row.name = "AidRow"
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	for entry in [
		{"label":"ASK KEEPER", "art":String(AID_ART_PATHS["hint"])},
		{"label":"FAIL RECOVERY · +3", "art":String(AID_ART_PATHS["plus_moves"])}
	]:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(0, 56)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = Color("#28142D", 0.96)
		chip_style.border_color = Color("#D5AD70", 0.44)
		chip_style.set_border_width_all(1)
		chip_style.set_corner_radius_all(22)
		chip.add_theme_stylebox_override("panel", chip_style)
		row.add_child(chip)
		var chip_row := HBoxContainer.new()
		chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
		chip_row.add_theme_constant_override("separation", 4)
		chip.add_child(chip_row)
		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(36, 36)
		art.texture = PieceAssetLoader.ornament(String(entry["art"]))
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip_row.add_child(art)
		var caption := Label.new()
		caption.text = String(entry["label"])
		caption.add_theme_color_override("font_color", Color("#F4E5D3"))
		caption.add_theme_font_size_override("font_size", 20)
		chip_row.add_child(caption)

func aid_asset_contract() -> Dictionary:
	var loaded := {}
	var raster_runtime := true
	for key in AID_ART_PATHS:
		var path := String(AID_ART_PATHS[key])
		loaded[key] = PieceAssetLoader.ornament(path) != null
		raster_runtime = raster_runtime and (path.ends_with(".webp") or path.ends_with(".png"))
	return {
		"paths": AID_ART_PATHS.duplicate(true),
		"loaded": loaded,
		"raster_runtime": raster_runtime,
		"manual_hint_label": "ASK KEEPER",
		"plus_moves_label": "FAIL RECOVERY · +3",
		"plus_moves_availability": "fail_recovery_only"
	}

func _style_ritual_actions() -> void:
	var gold := Color("#D8B56A")
	var ivory := Color("#F4E5D3")
	var primary := StyleBoxFlat.new()
	primary.bg_color = Color("#4A2848")
	primary.border_color = gold
	primary.set_border_width_all(2)
	primary.set_corner_radius_all(12)
	primary.shadow_color = Color(0.02, 0.01, 0.04, 0.65)
	primary.shadow_size = 10
	var hover := primary.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#61385B")
	var secondary := primary.duplicate() as StyleBoxFlat
	secondary.bg_color = Color("#211827")
	secondary.border_color = Color("#9B819B")
	for button in [start_button, back_button]:
		button.add_theme_stylebox_override("normal", primary if button == start_button else secondary)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.add_theme_color_override("font_color", ivory)
		button.add_theme_color_override("font_hover_color", ivory)
		button.add_theme_font_size_override("font_size", 26 if button == start_button else 21)
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 64.0)

func configure_level(value: int, replay: bool = false) -> bool:
	level_number = value
	var path := "res://content/levels/ch01/level_%03d.json" % level_number
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed
	level_label.text = "LEVEL %d" % level_number
	title_label.text = String(data.get("title", "Hidden Display"))
	moves_label.text = "%d MOVES" % int(data.get("moves", 0))
	var objective_type := String(data.get("objective", ""))
	if objective_type == "collect_family":
		objective_label.text = "GOAL · GATHER %d %s SIGILS" % [
			int(data.get("objective_target", 0)),
			String(data.get("objective_family", "")).to_upper()
		]
	elif objective_type == "clear_blockers":
		objective_label.text = "GOAL · BREAK THE HOUSE SEALS"
	else:
		objective_label.text = "GOAL · AWAKEN THE DISPLAY"
	var curio_id := String(data.get("reward_curio", "moon_cameo"))
	var curio := curio_id.replace("_", " ").capitalize()
	if replay:
		reward_label.text = "OWNED CURIO · %s" % curio.to_upper()
		if note_label != null:
			note_label.text = "Replay this ritual for the puzzle itself. The Curio, House restoration and persistent rewards are already secured."
	else:
		reward_label.text = "REWARD · %s" % curio.to_upper()
		if note_label != null:
			note_label.text = String(data.get("prestart_note", "Recover %s. The House will remember this ritual when you return." % curio))
	if ritual_art != null:
		ritual_art.set("relic_id", curio_id)
		ritual_art.set("mode", "replay" if replay else "prestart")
		var level_art := ritual_art.get_node_or_null("LevelArtwork") as TextureRect
		if level_art != null:
			level_art.visible = true
			level_art.texture = ScreenArt.texture("prestart_ch01_level01_art" if level_number == 1 else "prestart_ch01_shared_art")
		ritual_art.queue_redraw()
	return true
