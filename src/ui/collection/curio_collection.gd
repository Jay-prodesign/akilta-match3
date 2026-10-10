class_name Match3CurioCollection
extends Control

signal back_requested

@onready var count_label: Label = $Layout/Count
@onready var moon_card: PanelContainer = $Layout/Cards/MoonCard
@onready var moon_state: Label = $Layout/Cards/MoonCard/Content/State
@onready var moon_detail: Label = $Layout/Cards/MoonCard/Content/Detail
@onready var back_button: Button = $Layout/Back

var progress

func _ready() -> void:
	back_button.pressed.connect(func(): back_requested.emit())
	_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	var curios: Array = progress.curios if progress != null else []
	count_label.text = "%d OF 3 DISPLAY RELICS AWAKENED" % curios.size()
	var has_moon := curios.has("moon_cameo")
	moon_state.text = "AWAKENED" if has_moon else "DORMANT"
	moon_detail.text = "Moonlight remembers your first victory." if has_moon else "Win Level 1 to wake the first relic."
	moon_card.modulate = Color.WHITE if has_moon else Color(0.58, 0.54, 0.62, 0.72)
