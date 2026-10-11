class_name Match3LevelPrestart
extends Control

signal back_requested
signal start_requested(level_number: int)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

@onready var level_label: Label = $Layout/Card/Content/Level
@onready var title_label: Label = $Layout/Card/Content/Title
@onready var objective_label: Label = $Layout/Card/Content/Objective
@onready var moves_label: Label = $Layout/Card/Content/Moves
@onready var reward_label: Label = $Layout/Card/Content/Reward
@onready var note_label: Label = $Layout/Card/Content/Note
@onready var ritual_art: Control = $Layout/Card/Content/RitualArt
@onready var start_button: Button = $Layout/Card/Content/Start
@onready var back_button: Button = $Layout/Back

var level_number: int = 1

func _ready() -> void:
	_install_world_backdrop()
	_style_ritual_actions()
	start_button.pressed.connect(func(): start_requested.emit(level_number))
	back_button.pressed.connect(func(): back_requested.emit())

func _install_world_backdrop() -> void:
	var art := TextureRect.new()
	art.name = "NorthStarWorldBackdrop"
	art.texture = PieceAssetLoader.ornament("res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(0.78, 0.70, 0.80, 0.34)
	add_child(art)
	move_child(art, 1)

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
		button.add_theme_font_size_override("font_size", 24 if button == start_button else 19)
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 58.0)

func configure_level(value: int) -> bool:
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
	reward_label.text = "REWARD · %s" % curio.to_upper()
	if note_label != null:
		note_label.text = String(data.get("prestart_note", "Recover %s. The House will remember this ritual when you return." % curio))
	if ritual_art != null:
		ritual_art.set("relic_id", curio_id)
		ritual_art.queue_redraw()
	return true
