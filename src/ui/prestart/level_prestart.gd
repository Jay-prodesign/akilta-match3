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
@onready var ritual_art: Control = $Layout/Card/Content/RitualArt
@onready var start_button: Button = $Layout/Card/Content/Start
@onready var back_button: Button = $Layout/Back

var level_number: int = 1

func _ready() -> void:
	_install_world_backdrop()
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
	if ritual_art != null:
		ritual_art.set("relic_id", curio_id)
		ritual_art.queue_redraw()
	return true
