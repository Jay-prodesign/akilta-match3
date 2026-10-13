extends Control

signal close_requested

const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

@onready var veil: ColorRect = $Veil
@onready var card: PanelContainer = $Card
@onready var art: TextureRect = $Card/Content/KeeperArt
@onready var close: Button = $Card/Content/Close
@onready var no_cost: Label = $Card/Content/TruthRow/NoCost/Label
@onready var board_safe: Label = $Card/Content/TruthRow/BoardSafe/Label
@onready var moves_safe: Label = $Card/Content/TruthRow/MovesSafe/Label

var _reduced_motion := false
var _transition_tween: Tween
var _closing := false

func _ready() -> void:
	ProductionChrome.apply_primary(card)
	card.set_meta("production_chrome_kind", "keeper_familiar_card")
	ProductionChrome.apply_action_button(close, "utility", "keeper_return")
	close.pivot_offset = close.size * 0.5
	close.button_down.connect(func(): _animate_close_scale(Vector2(0.97, 0.97), 0.05))
	close.button_up.connect(func(): _animate_close_scale(Vector2.ONE, 0.09))
	close.pressed.connect(_dismiss)

func configure(texture: Texture2D, reduced_motion := false) -> bool:
	if texture == null:
		return false
	art.texture = texture
	_reduced_motion = bool(reduced_motion)
	_present()
	return true

func _present() -> void:
	if card == null or veil == null:
		return
	card.pivot_offset = card.size * 0.5
	if _reduced_motion:
		veil.modulate = Color.WHITE
		card.modulate = Color.WHITE
		card.scale = Vector2.ONE
		return
	veil.modulate = Color(1, 1, 1, 0)
	card.modulate = Color(1, 1, 1, 0)
	card.scale = Vector2(0.93, 0.93)
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(veil, "modulate", Color.WHITE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(card, "modulate", Color.WHITE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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

func keeper_contract() -> Dictionary:
	return {
		"authored_scene": true,
		"art_loaded": art != null and art.texture != null,
		"role": "non_mutating_legal_move_guide",
		"spends_resources": false,
		"changes_board": false,
		"adds_moves": false,
		"truth_chips": no_cost != null and no_cost.text == "NO COST" and board_safe != null and board_safe.text == "BOARD SAFE" and moves_safe != null and moves_safe.text == "NO +MOVES",
		"production_card_chrome": card != null and card.get_theme_stylebox("panel") is StyleBoxTexture and String(card.get_meta("production_chrome_kind", "")) == "keeper_familiar_card",
		"production_return_chrome": close != null and close.get_theme_stylebox("normal") is StyleBoxTexture,
		"modal_choreography": true,
		"reduced_motion_supported": true,
	}
