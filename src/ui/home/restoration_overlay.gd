extends Control
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

signal continue_requested

@onready var hero_title: Label = $RestorationHeader/RestorationHeroTitle
@onready var transformation_stage: PanelContainer = $TransformationStage
@onready var before_house: Control = $TransformationStage/PreviewRow/BeforeCard/BeforeContent/House
@onready var after_house: Control = $TransformationStage/PreviewRow/AfterCard/AfterContent/House
@onready var motif_frame: Panel = $RecoveredDisplayFrame
@onready var motif: TextureRect = $AwakeningMotif
@onready var state_rail: PanelContainer = $StateRail
@onready var curio_art: TextureRect = $CeremonyCard/CeremonyContent/CeremonyRow/RestoredCurioArt
@onready var body: Label = $CeremonyCard/CeremonyContent/CeremonyRow/Copy/Body
@onready var continue_button: Button = $CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue

func _ready() -> void:
	$CeremonyCard.set_meta("restoration_material", "scene_authored_flat")
	continue_button.set_meta("restoration_material", "scene_authored_flat")
	continue_button.pressed.connect(func(): continue_requested.emit())

func configure(curio_id: String, curio_name: String, restoration_copy: String, motif_texture: Texture2D, curio_texture: Texture2D, stage: int, current_curios: Array[String]) -> bool:
	if curio_id == "" or curio_name == "" or motif_texture == null or curio_texture == null or stage <= 0:
		return false
	hero_title.text = curio_name
	body.text = restoration_copy
	motif.texture = motif_texture
	curio_art.texture = curio_texture
	var previous_curios := current_curios.duplicate()
	previous_curios.erase(curio_id)
	if before_house.has_method("apply_presentation_settings"):
		before_house.apply_presentation_settings({"reduced_motion": true})
	if after_house.has_method("apply_presentation_settings"):
		after_house.apply_presentation_settings({"reduced_motion": true})
	if before_house.has_method("set_restoration_full_bleed"):
		before_house.set_restoration_full_bleed(true)
	if after_house.has_method("set_restoration_full_bleed"):
		after_house.set_restoration_full_bleed(true)
	if before_house.has_method("set_house_state"):
		before_house.set_house_state(maxi(0, stage - 1), previous_curios)
	if after_house.has_method("set_house_state"):
		after_house.set_house_state(stage, current_curios)
	return true

func restoration_contract() -> Dictionary:
	var before_contract: Dictionary = before_house.living_house_contract() if before_house != null and before_house.has_method("living_house_contract") else {}
	var after_contract: Dictionary = after_house.living_house_contract() if after_house != null and after_house.has_method("living_house_contract") else {}
	return {
		"authored_scene": true,
		"motif_loaded": motif != null and motif.texture != null,
		"curio_art_loaded": curio_art != null and curio_art.texture != null,
		"house_first_composition": transformation_stage != null and transformation_stage.visible and before_house != null and after_house != null and not motif.visible,
		"before_after_house_previews": int(before_contract.get("stage", -1)) >= 0 and int(after_contract.get("stage", -1)) == int(before_contract.get("stage", -1)) + 1 and bool(before_contract.get("same_camera", false)) and bool(after_contract.get("same_camera", false)),
		"before_after_state_rail": state_rail != null and state_rail.get_node_or_null("States/Before") != null and state_rail.get_node_or_null("States/After") != null,
		"curio_motif_subordinate": motif != null and not motif.visible and curio_art != null and curio_art.visible,
		"scene_authored_summary_material": ($CeremonyCard as PanelContainer).get_theme_stylebox("panel") is StyleBoxFlat and continue_button.get_theme_stylebox("normal") is StyleBoxFlat and String($CeremonyCard.get_meta("restoration_material", "")) == "scene_authored_flat" and String(continue_button.get_meta("restoration_material", "")) == "scene_authored_flat",
	}
