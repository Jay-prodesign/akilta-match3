extends Control
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

signal continue_requested
signal interaction_feedback_requested(kind: String)

const HOUSE_IDENTITY_TEXT := "THE HOUSE"

var _reduced_motion: bool = false
var _presented: bool = false
var _closing: bool = false
var _reveal_tween: Tween
var _exit_tween: Tween
var _continue_tactile_tween: Tween

@onready var veil: ColorRect = $Veil
@onready var restoration_header: VBoxContainer = $RestorationHeader
@onready var hero_title: Label = $RestorationHeader/RestorationHeroTitle
@onready var hero_copy: Label = $RestorationHeader/HeroCopy
@onready var transformation_stage: PanelContainer = $TransformationStage
@onready var preview_row: HBoxContainer = $TransformationStage/PreviewRow
@onready var before_card: PanelContainer = $TransformationStage/PreviewRow/BeforeCard
@onready var stage_arrow: Label = $TransformationStage/PreviewRow/Arrow
@onready var after_card: PanelContainer = $TransformationStage/PreviewRow/AfterCard
@onready var before_house: Control = $TransformationStage/PreviewRow/BeforeCard/BeforeContent/House
@onready var after_house: Control = $TransformationStage/PreviewRow/AfterCard/AfterContent/House
@onready var motif_frame: Panel = $RecoveredDisplayFrame
@onready var motif: TextureRect = $AwakeningMotif
@onready var state_rail: PanelContainer = $StateRail
@onready var ceremony_card: PanelContainer = $CeremonyCard
@onready var curio_art: TextureRect = $CeremonyCard/CeremonyContent/CeremonyRow/RestoredCurioArt
@onready var body: Label = $CeremonyCard/CeremonyContent/CeremonyRow/Copy/Body
@onready var continue_button: Button = $CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue

func _ready() -> void:
	ceremony_card.set_meta("restoration_material", "scene_authored_flat")
	continue_button.set_meta("restoration_material", "scene_authored_flat")
	_bind_continue_tactile()
	continue_button.pressed.connect(_request_continue)

func configure(curio_id: String, curio_name: String, restoration_copy: String, motif_texture: Texture2D, curio_texture: Texture2D, stage: int, current_curios: Array[String]) -> bool:
	if curio_id == "" or curio_name == "" or motif_texture == null or curio_texture == null or stage <= 0:
		return false
	hero_title.text = HOUSE_IDENTITY_TEXT
	hero_copy.text = "%s · AWAKENED" % curio_name.to_upper()
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
	call_deferred("_play_reveal")
	return true


func apply_presentation_settings(settings: Dictionary) -> void:
	_reduced_motion = bool(settings.get("reduced_motion", false))
	continue_button.set_meta("restoration_tactile_reduced_motion", _reduced_motion)
	if _reduced_motion:
		_stop_continue_tactile()
		continue_button.scale = Vector2.ONE
		continue_button.modulate = Color.WHITE
		if _presented and not _closing:
			_settle_reveal()

func _bind_continue_tactile() -> void:
	continue_button.set_meta("restoration_tactile_bound", true)
	continue_button.set_meta("restoration_tactile_press_scale", 0.96)
	continue_button.set_meta("restoration_tactile_reduced_motion", _reduced_motion)
	continue_button.button_down.connect(_press_continue_tactile)
	continue_button.button_up.connect(_release_continue_tactile)
	continue_button.mouse_exited.connect(_release_continue_tactile)
	continue_button.focus_exited.connect(_release_continue_tactile)

func _press_continue_tactile() -> void:
	if continue_button == null or continue_button.disabled or _closing:
		return
	_stop_continue_tactile()
	continue_button.pivot_offset = continue_button.size * 0.5
	continue_button.set_meta("restoration_tactile_phase", "pressed")
	interaction_feedback_requested.emit("ui")
	if _reduced_motion:
		continue_button.scale = Vector2.ONE
		continue_button.modulate = Color.WHITE
		return
	_continue_tactile_tween = create_tween()
	_continue_tactile_tween.set_parallel(true)
	_continue_tactile_tween.tween_property(continue_button, "scale", Vector2(0.96, 0.96), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_continue_tactile_tween.tween_property(continue_button, "modulate", Color(1.0, 0.95, 0.86, 1.0), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _release_continue_tactile() -> void:
	if continue_button == null:
		return
	_stop_continue_tactile()
	continue_button.pivot_offset = continue_button.size * 0.5
	continue_button.set_meta("restoration_tactile_phase", "release")
	if _reduced_motion:
		continue_button.scale = Vector2.ONE
		continue_button.modulate = Color.WHITE
		continue_button.set_meta("restoration_tactile_phase", "idle")
		return
	_continue_tactile_tween = create_tween()
	_continue_tactile_tween.set_parallel(true)
	_continue_tactile_tween.tween_property(continue_button, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_continue_tactile_tween.tween_property(continue_button, "modulate", Color.WHITE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_continue_tactile_tween.finished.connect(func(): continue_button.set_meta("restoration_tactile_phase", "idle"))

func _stop_continue_tactile() -> void:
	if _continue_tactile_tween != null and _continue_tactile_tween.is_valid():
		_continue_tactile_tween.kill()
	_continue_tactile_tween = null

func _play_reveal() -> void:
	if _presented or restoration_header == null or ceremony_card == null:
		return
	_presented = true
	set_meta("restoration_reveal_phase", "opening")
	if _reduced_motion:
		_settle_reveal()
		return

	veil.modulate = Color(1, 1, 1, 0)
	restoration_header.pivot_offset = restoration_header.size * 0.5
	restoration_header.scale = Vector2(0.985, 0.985)
	restoration_header.modulate = Color(1, 1, 1, 0)
	ceremony_card.pivot_offset = ceremony_card.size * 0.5
	ceremony_card.scale = Vector2(0.97, 0.97)
	ceremony_card.modulate = Color(1, 1, 1, 0)

	_reveal_tween = create_tween()
	_reveal_tween.set_parallel(true)
	_reveal_tween.tween_property(veil, "modulate", Color.WHITE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(restoration_header, "modulate", Color.WHITE, 0.18).set_delay(0.02).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(restoration_header, "scale", Vector2.ONE, 0.18).set_delay(0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(ceremony_card, "modulate", Color.WHITE, 0.22).set_delay(0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(ceremony_card, "scale", Vector2.ONE, 0.24).set_delay(0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reveal_tween.finished.connect(func(): set_meta("restoration_reveal_phase", "idle"))

func _request_continue() -> void:
	if _closing:
		return
	_closing = true
	set_meta("restoration_reveal_phase", "closing")
	_stop_continue_tactile()
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	if _reduced_motion:
		continue_requested.emit()
		return
	_exit_tween = create_tween()
	_exit_tween.set_parallel(true)
	_exit_tween.tween_property(ceremony_card, "modulate", Color(1, 1, 1, 0), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_exit_tween.tween_property(ceremony_card, "scale", Vector2(0.97, 0.97), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_exit_tween.tween_property(restoration_header, "modulate", Color(1, 1, 1, 0), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_exit_tween.tween_property(veil, "modulate", Color(1, 1, 1, 0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_exit_tween.finished.connect(func(): continue_requested.emit())

func _settle_reveal() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	veil.modulate = Color.WHITE
	restoration_header.modulate = Color.WHITE
	restoration_header.scale = Vector2.ONE
	ceremony_card.modulate = Color.WHITE
	ceremony_card.scale = Vector2.ONE
	continue_button.scale = Vector2.ONE
	continue_button.modulate = Color.WHITE
	if not _closing:
		set_meta("restoration_reveal_phase", "idle")

func restoration_contract() -> Dictionary:
	var before_contract: Dictionary = before_house.living_house_contract() if before_house != null and before_house.has_method("living_house_contract") else {}
	var after_contract: Dictionary = after_house.living_house_contract() if after_house != null and after_house.has_method("living_house_contract") else {}
	var adjacent_same_camera_truth := (
		int(before_contract.get("stage", -1)) >= 0
		and int(after_contract.get("stage", -1)) == int(before_contract.get("stage", -1)) + 1
		and bool(before_contract.get("same_camera", false))
		and bool(after_contract.get("same_camera", false))
	)
	return {
		"authored_scene": true,
		"motif_loaded": motif != null and motif.texture != null,
		"curio_art_loaded": curio_art != null and curio_art.texture != null,
		"house_first_composition": transformation_stage != null and not transformation_stage.visible and state_rail != null and not state_rail.visible and ceremony_card != null and ceremony_card.anchor_top >= 0.68,
		"world_first_restoration": transformation_stage != null and not transformation_stage.visible and veil != null and veil.color.a <= 0.10,
		"comparison_previews_hidden": transformation_stage != null and not transformation_stage.visible and state_rail != null and not state_rail.visible,
		"hidden_adjacent_state_truth": adjacent_same_camera_truth,
		"summary_card_low_and_compact": ceremony_card != null and ceremony_card.anchor_top >= 0.68 and ceremony_card.anchor_bottom <= 0.88,
		"house_first_header": hero_title.text == HOUSE_IDENTITY_TEXT and hero_copy.text.ends_with("· AWAKENED"),
		"curio_motif_subordinate": motif != null and not motif.visible and curio_art != null and curio_art.visible,
		"scene_authored_summary_material": ($CeremonyCard as PanelContainer).get_theme_stylebox("panel") is StyleBoxFlat and continue_button.get_theme_stylebox("normal") is StyleBoxFlat and String($CeremonyCard.get_meta("restoration_material", "")) == "scene_authored_flat" and String(continue_button.get_meta("restoration_material", "")) == "scene_authored_flat",
		"summary_material_kind": String(ceremony_card.get_meta("restoration_material", "")),
		"reveal_choreography": _presented and has_meta("restoration_reveal_phase"),
		"reveal_phase": String(get_meta("restoration_reveal_phase", "not_presented")),
		"staged_house_payoff": restoration_header != null and ceremony_card != null and transformation_stage != null and not transformation_stage.visible,
		"continue_tactile": continue_button != null and bool(continue_button.get_meta("restoration_tactile_bound", false)) and float(continue_button.get_meta("restoration_tactile_press_scale", 1.0)) <= 0.96,
		"reduced_motion_supported": true,
		"feedback_signal": has_signal("interaction_feedback_requested"),
	}
