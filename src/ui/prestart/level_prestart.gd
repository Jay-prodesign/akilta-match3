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
@onready var world_backdrop: TextureRect = $NorthStarWorldBackdrop
@onready var level_artwork: TextureRect = $Layout/Card/Content/RitualArt/LevelArtwork
@onready var keeper_aid_art: TextureRect = $Layout/Card/Content/RitualAids/Column/AidRow/KeeperChip/Content/Art
@onready var recovery_aid_art: TextureRect = $Layout/Card/Content/RitualAids/Column/AidRow/RecoveryChip/Content/Art

const AID_ART_PATHS := {
	"hint": "res://assets/pieces/moon_sigil.webp",
	"plus_moves": "res://assets/pieces/potion.webp"
}

var level_number: int = 1

func _ready() -> void:
	world_backdrop.texture = ScreenArt.texture("prestart_bg_curio_boutique")
	level_artwork.texture = ScreenArt.texture("prestart_ch01_level01_art")
	keeper_aid_art.texture = PieceAssetLoader.ornament(String(AID_ART_PATHS["hint"]))
	recovery_aid_art.texture = PieceAssetLoader.ornament(String(AID_ART_PATHS["plus_moves"]))
	start_button.pressed.connect(func(): start_requested.emit(level_number))
	back_button.pressed.connect(func(): back_requested.emit())

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
		"plus_moves_availability": "fail_recovery_only",
		"authored_world_backdrop": world_backdrop != null and world_backdrop.texture != null,
		"authored_level_artwork": level_artwork != null and level_artwork.texture != null,
		"authored_ritual_aids": keeper_aid_art != null and keeper_aid_art.texture != null and recovery_aid_art != null and recovery_aid_art.texture != null,
		"north_star_readability": title_label != null and title_label.get_theme_font_size("font_size") >= 48 and objective_label != null and objective_label.get_theme_font_size("font_size") >= 32 and start_button != null and start_button.custom_minimum_size.y >= 84.0,
		"note_subordinate": note_label != null and not note_label.visible,
		"runtime_ui_factory": false
	}

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
		level_artwork.visible = true
		level_artwork.texture = ScreenArt.texture("prestart_ch01_level01_art" if level_number == 1 else "prestart_ch01_shared_art")
		ritual_art.queue_redraw()
	return true
