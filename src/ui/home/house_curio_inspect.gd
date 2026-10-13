extends Control

signal close_requested

const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

@onready var veil: ColorRect = $Veil
@onready var card: PanelContainer = $Card
@onready var hero_art: TextureRect = $Card/Content/HeroArt
@onready var title: Label = $Card/Content/Name
@onready var origin: Label = $Card/Content/Origin
@onready var effect: Label = $Card/Content/HouseEffect
@onready var close: Button = $Card/Content/Close

var _reduced_motion := false
var _transition_tween: Tween
var _closing := false

func _ready() -> void:
	ProductionChrome.apply_primary(card)
	card.set_meta("production_chrome_kind", "house_curio_memory_card")
	ProductionChrome.apply_action_button(close, "utility", "house_curio_return")
	close.pivot_offset = close.size * 0.5
	close.button_down.connect(func(): _animate_close_scale(Vector2(0.97, 0.97), 0.05))
	close.button_up.connect(func(): _animate_close_scale(Vector2.ONE, 0.09))
	close.pressed.connect(_dismiss)

func configure(curio_id: String, curio_name: String, origin_copy: String, effect_copy: String, texture: Texture2D, reduced_motion := false) -> bool:
	if curio_id == "" or texture == null:
		return false
	title.text = curio_name
	origin.text = origin_copy
	effect.text = effect_copy
	hero_art.texture = texture
	_reduced_motion = bool(reduced_motion)
	set_meta("curio_id", curio_id)
	_present()
	return true

func _present() -> void:
	if card == null or veil == null or hero_art == null:
		return
	card.pivot_offset = card.size * 0.5
	hero_art.pivot_offset = hero_art.size * 0.5
	if _reduced_motion:
		veil.modulate = Color.WHITE
		card.modulate = Color.WHITE
		card.scale = Vector2.ONE
		hero_art.modulate = Color.WHITE
		hero_art.scale = Vector2.ONE
		return
	veil.modulate = Color(1, 1, 1, 0)
	card.modulate = Color(1, 1, 1, 0)
	card.scale = Vector2(0.96, 0.96)
	hero_art.modulate = Color(1.08, 1.02, 0.90, 0)
	hero_art.scale = Vector2(0.78, 0.78)
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(veil, "modulate", Color.WHITE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(card, "modulate", Color.WHITE, 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(hero_art, "modulate", Color.WHITE, 0.22).set_delay(0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(hero_art, "scale", Vector2.ONE, 0.32).set_delay(0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _dismiss() -> void:
	if _closing:
		return
	_closing = true
	if _reduced_motion:
		close_requested.emit()
		return
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(veil, "modulate", Color(1, 1, 1, 0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_transition_tween.tween_property(card, "modulate", Color(1, 1, 1, 0), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_transition_tween.tween_property(card, "scale", Vector2(0.97, 0.97), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_transition_tween.finished.connect(func(): close_requested.emit())

func _animate_close_scale(target: Vector2, duration: float) -> void:
	if close == null or _closing:
		return
	if _reduced_motion:
		close.scale = target
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(close, "scale", target, duration)

func inspect_contract() -> Dictionary:
	return {
		"authored_scene": true,
		"curio_id": String(get_meta("curio_id", "")),
		"art_loaded": hero_art != null and hero_art.texture != null,
		"hero_scale": hero_art != null and hero_art.custom_minimum_size.y >= 320.0,
		"memory_bands": origin != null and origin.has_theme_stylebox_override("normal") and effect != null and effect.has_theme_stylebox_override("normal"),
		"production_card_chrome": card != null and card.get_theme_stylebox("panel") is StyleBoxTexture and String(card.get_meta("production_chrome_kind", "")) == "house_curio_memory_card",
		"production_return_chrome": close != null and close.get_theme_stylebox("normal") is StyleBoxTexture,
		"modal_choreography": true,
		"reduced_motion_supported": true,
	}
