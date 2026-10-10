class_name Match3CurioCollection
extends Control

signal back_requested

@onready var count_label: Label = $Layout/Count
@onready var moon_card: PanelContainer = $Layout/Cards/MoonCard
@onready var moon_ritual: Control = $Layout/Cards/MoonCard/Content/RitualArt
@onready var moon_state: Label = $Layout/Cards/MoonCard/Content/State
@onready var moon_detail: Label = $Layout/Cards/MoonCard/Content/Detail
@onready var moon_origin: Label = $Layout/Cards/MoonCard/Content/Origin
@onready var back_button: Button = $Layout/Back

const MOON_SEALED = preload("res://assets/curios/ch01_curio_moon_cameo_sealed_v01.svg")
const MOON_AWAKENED = preload("res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg")

var progress
var _moon_art: TextureRect

func _ready() -> void:
	back_button.pressed.connect(func(): back_requested.emit())
	_install_moon_art()
	_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	var curios: Array = progress.curios if progress != null else []
	count_label.text = "FIRST CABINET SET · %d / 3 AWAKENED" % curios.size()
	var has_moon := curios.has("moon_cameo")
	moon_state.text = "AWAKENED · RELIC 01" if has_moon else "DORMANT · RELIC 01"
	moon_detail.text = "Moonlight remembers your first victory." if has_moon else "Win Level 1 to wake the first relic."
	moon_origin.text = "RECOVERED FROM · MOONLIT CABINET" if has_moon else "SEALED BEHIND · MOONLIT CABINET"
	moon_card.modulate = Color.WHITE if has_moon else Color(0.58, 0.54, 0.62, 0.72)
	if _moon_art != null:
		_moon_art.texture = MOON_AWAKENED if has_moon else MOON_SEALED
		_moon_art.modulate = Color.WHITE if has_moon else Color(0.75, 0.70, 0.81, 0.78)
	if moon_ritual != null:
		moon_ritual.set("glow_strength", 0.82 if has_moon else 0.18)
		moon_ritual.queue_redraw()

func _install_moon_art() -> void:
	if moon_ritual == null:
		return
	_moon_art = TextureRect.new()
	_moon_art.name = "MoonCameoArt"
	_moon_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_moon_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_moon_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_moon_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon_ritual.add_child(_moon_art)
