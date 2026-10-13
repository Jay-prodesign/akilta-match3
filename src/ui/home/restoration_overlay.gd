extends Control
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

signal continue_requested

@onready var hero_title: Label = $RestorationHeader/RestorationHeroTitle
@onready var dormant_frame: Panel = $DormantDisplayFrame
@onready var dormant_motif: TextureRect = $DormantMotif
@onready var transformation_arrow: Label = $TransformationArrow
@onready var motif_frame: Panel = $RecoveredDisplayFrame
@onready var motif: TextureRect = $AwakeningMotif
@onready var state_rail: PanelContainer = $StateRail
@onready var curio_art: TextureRect = $CeremonyCard/CeremonyContent/CeremonyRow/RestoredCurioArt
@onready var body: Label = $CeremonyCard/CeremonyContent/CeremonyRow/Copy/Body
@onready var continue_button: Button = $CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue

func _ready() -> void:
	ProductionChrome.apply_primary($CeremonyCard)
	ProductionChrome.apply_action_button(continue_button, "primary", "restoration_continue")
	continue_button.pressed.connect(func(): continue_requested.emit())

func configure(curio_name: String, restoration_copy: String, motif_texture: Texture2D, curio_texture: Texture2D) -> bool:
	if curio_name == "" or motif_texture == null or curio_texture == null:
		return false
	hero_title.text = curio_name
	body.text = restoration_copy
	dormant_motif.texture = motif_texture
	motif.texture = motif_texture
	curio_art.texture = curio_texture
	return true

func restoration_contract() -> Dictionary:
	var before_after_pair := (
		dormant_frame != null
		and dormant_motif != null
		and dormant_motif.texture != null
		and motif_frame != null
		and motif != null
		and motif.texture != null
		and dormant_frame.anchor_right < motif_frame.anchor_left
		and transformation_arrow != null
		and transformation_arrow.text == "→"
	)
	return {
		"authored_scene": true,
		"motif_loaded": motif != null and motif.texture != null,
		"curio_art_loaded": curio_art != null and curio_art.texture != null,
		"house_first_composition": motif_frame != null and state_rail != null and motif != null and motif.anchor_left >= 0.54 and motif.anchor_right <= 0.80,
		"before_after_state_rail": state_rail != null and state_rail.get_node_or_null("States/Before") != null and state_rail.get_node_or_null("States/After") != null,
		"before_after_visual_pair": before_after_pair,
		"world_visible_during_restoration": ($Veil as ColorRect).color.a <= 0.20,
		"restoration_hero_hierarchy": hero_title != null and hero_title.get_theme_font_size("font_size") >= 44 and continue_button != null and continue_button.custom_minimum_size.y >= 90.0,
		"visual_parity_gate_v2": before_after_pair and ($Veil as ColorRect).color.a <= 0.20 and hero_title.get_theme_font_size("font_size") >= 44,
	}
