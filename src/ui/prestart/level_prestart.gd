class_name Match3LevelPrestart
extends Control

signal back_requested
signal start_requested(level_number: int)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")
const HapticsController = preload("res://src/feedback/haptics_controller.gd")
const Typography = preload("res://src/ui/theme/typography.gd")

@onready var level_label: Label = $Layout/LevelPlaque/Level
@onready var title_label: Label = $Layout/Card/Content/Title
@onready var objective_label: Label = $Layout/Card/Content/ObjectiveBand/Row/ObjectiveCluster/Copy/Objective
@onready var moves_label: Label = $Layout/Card/Content/ObjectiveBand/Row/MovesPlate/Moves
@onready var reward_label: Label = $Layout/Card/Content/Reward
@onready var note_label: Label = $Layout/Card/Content/Note
@onready var ritual_art: Control = $Layout/Card/Content/RitualArt
@onready var start_button: Button = $Layout/Card/Content/Start
@onready var back_button: Button = $Layout/Back
@onready var world_backdrop: TextureRect = $NorthStarWorldBackdrop
@onready var level_artwork: TextureRect = $Layout/Card/Content/RitualArt/LevelArtwork
@onready var objective_icon: TextureRect = $Layout/Card/Content/ObjectiveBand/Row/ObjectiveCluster/Icon
@onready var level_plaque: PanelContainer = $Layout/LevelPlaque
@onready var objective_band: PanelContainer = $Layout/Card/Content/ObjectiveBand
@onready var ritual_aids: PanelContainer = $Layout/Card/Content/RitualAids
@onready var keeper_chip: PanelContainer = $Layout/Card/Content/RitualAids/Column/AidRow/KeeperChip
@onready var recovery_chip: PanelContainer = $Layout/Card/Content/RitualAids/Column/AidRow/RecoveryChip
@onready var keeper_aid_art: TextureRect = $Layout/Card/Content/RitualAids/Column/AidRow/KeeperChip/Content/Art
@onready var recovery_aid_art: TextureRect = $Layout/Card/Content/RitualAids/Column/AidRow/RecoveryChip/Content/Art

const AID_ART_PATHS := {
	"hint": "res://assets/pieces/black_cat.webp",
	"plus_moves": "res://assets/pieces/potion.webp"
}
const OBJECTIVE_ART_PATHS := {
	"moon": "res://assets/pieces/moon_sigil.webp",
	"rose": "res://assets/pieces/thorn_rose.webp",
	"moth": "res://assets/pieces/luna_moth.webp",
	"wax_seal": "res://assets/blockers/ch01_blocker_wax_seal_intact_v01.webp"
}

var level_number: int = 1
var haptics = HapticsController.new()
var _reduced_motion := false
var _intro_tween: Tween

func _ready() -> void:
	ProductionChrome.apply_primary($Layout/Card)
	ProductionChrome.apply_gameplay_level_plaque(level_plaque)
	ProductionChrome.apply_gameplay_shell(objective_band, "objective")
	ProductionChrome.apply_gameplay_booster_tray(ritual_aids)
	ProductionChrome.apply_compact_panel(keeper_chip, "prestart_keeper_aid")
	ProductionChrome.apply_compact_panel(recovery_chip, "prestart_recovery_aid")
	ProductionChrome.apply_gameplay_action_button(start_button, "primary", "prestart_play")
	ProductionChrome.apply_gameplay_action_button(back_button, "utility", "prestart_back")
	var display_font := Typography.display_font()
	if display_font != null:
		level_label.add_theme_font_override("font", display_font)
		title_label.add_theme_font_override("font", display_font)
	world_backdrop.texture = ScreenArt.texture("prestart_bg_curio_boutique")
	level_artwork.texture = ScreenArt.texture("prestart_ch01_level01_art")
	objective_icon.texture = PieceAssetLoader.ornament(String(OBJECTIVE_ART_PATHS["moon"]))
	keeper_aid_art.texture = PieceAssetLoader.ornament(String(AID_ART_PATHS["hint"]))
	recovery_aid_art.texture = PieceAssetLoader.ornament(String(AID_ART_PATHS["plus_moves"]))
	_wire_tactile_button(start_button)
	_wire_tactile_button(back_button)
	start_button.pressed.connect(func(): start_requested.emit(level_number))
	back_button.pressed.connect(func(): back_requested.emit())
	call_deferred("_play_intro")

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
		"north_star_readability": title_label != null and title_label.get_theme_font_size("font_size") >= 44 and objective_label != null and objective_label.get_theme_font_size("font_size") >= 28 and start_button != null and start_button.custom_minimum_size.y >= 84.0,
		"north_star_decision_stack": level_plaque != null and level_plaque.custom_minimum_size.y >= 84.0 and ritual_art != null and ritual_art.custom_minimum_size.y <= 210.0 and objective_band != null and objective_band.custom_minimum_size.y >= 150.0 and ritual_aids != null and ritual_aids.custom_minimum_size.y >= 190.0,
		"truthful_aid_semantics": ($Layout/Card/Content/RitualAids/Column/RitualAidsHeading as Label).text == "RITUAL AIDS" and ($Layout/Card/Content/RitualAids/Column/AidRow/KeeperChip/Content/State as Label).text.contains("HINT") and ($Layout/Card/Content/RitualAids/Column/AidRow/RecoveryChip/Content/State as Label).text.contains("ON FAIL"),
		"note_subordinate": note_label != null and not note_label.visible,
		"asset_backed_prestart_chrome": ($Layout/Card as PanelContainer).get_theme_stylebox("panel") is StyleBoxTexture and level_plaque.get_theme_stylebox("panel") is StyleBoxTexture and objective_band.get_theme_stylebox("panel") is StyleBoxTexture and ritual_aids.get_theme_stylebox("panel") is StyleBoxTexture and keeper_chip.get_theme_stylebox("panel") is StyleBoxTexture and recovery_chip.get_theme_stylebox("panel") is StyleBoxTexture and start_button.get_theme_stylebox("normal") is StyleBoxTexture and back_button.get_theme_stylebox("normal") is StyleBoxTexture,
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
	moves_label.text = "%d\nMOVES" % int(data.get("moves", 0))
	var objective_type := String(data.get("objective", ""))
	if objective_type == "collect_family":
		var family := String(data.get("objective_family", "moon"))
		objective_label.text = "GATHER %d\n%s SIGILS" % [
			int(data.get("objective_target", 0)),
			family.to_upper()
		]
		objective_icon.texture = PieceAssetLoader.ornament(String(OBJECTIVE_ART_PATHS.get(family, OBJECTIVE_ART_PATHS["moon"])))
	elif objective_type == "clear_blockers":
		objective_label.text = "BREAK\nHOUSE SEALS"
		objective_icon.texture = PieceAssetLoader.ornament(String(OBJECTIVE_ART_PATHS["wax_seal"]))
	else:
		objective_label.text = "AWAKEN\nDISPLAY"
		objective_icon.texture = PieceAssetLoader.ornament(String(OBJECTIVE_ART_PATHS["moon"]))
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


func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	haptics.apply_settings(state)

func _wire_tactile_button(button: Button) -> void:
	if button == null:
		return
	button.button_down.connect(func(): _press_tactile_button(button))
	button.button_up.connect(func(): _release_tactile_button(button))
	button.mouse_exited.connect(func(): _release_tactile_button(button))

func _press_tactile_button(button: Button) -> void:
	if button == null or button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	haptics.request_ui()
	button.modulate = Color(1.04, 1.02, 1.06, 1.0)
	if _reduced_motion:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.065)

func _release_tactile_button(button: Button) -> void:
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	if _reduced_motion:
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color.WHITE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_intro() -> void:
	if _reduced_motion:
		return
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	var reveal_nodes: Array[Control] = [level_plaque, ritual_art, objective_band, ritual_aids, start_button]
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	for index in range(reveal_nodes.size()):
		var node := reveal_nodes[index]
		if node == null:
			continue
		node.pivot_offset = node.size * 0.5
		node.modulate = Color(1, 1, 1, 0)
		node.scale = Vector2(0.97, 0.97)
		var delay := float(index) * 0.045
		_intro_tween.tween_property(node, "modulate", Color.WHITE, 0.18).set_delay(delay)
		_intro_tween.tween_property(node, "scale", Vector2.ONE, 0.26).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
