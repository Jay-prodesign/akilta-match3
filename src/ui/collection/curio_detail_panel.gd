extends Control

signal close_requested
signal view_house_requested(curio_id: String)

var _curio_id: String = ""

@onready var card: PanelContainer = $CurioDetailCard
@onready var hero_art: TextureRect = $CurioDetailCard/Content/HeroArt
@onready var title: Label = $CurioDetailCard/Content/Name
@onready var state: Label = $CurioDetailCard/Content/State
@onready var origin: Label = $CurioDetailCard/Content/Origin
@onready var lore: Label = $CurioDetailCard/Content/Lore
@onready var view_house: Button = $CurioDetailCard/Content/ViewInHouse
@onready var close: Button = $CurioDetailCard/Content/Close

func _ready() -> void:
	close.pressed.connect(func(): close_requested.emit())
	view_house.pressed.connect(func(): view_house_requested.emit(_curio_id))

func configure(curio_id: String, data: Dictionary, awakened: bool, texture: Texture2D) -> bool:
	_curio_id = curio_id
	if data.is_empty() or texture == null:
		return false
	hero_art.texture = texture
	hero_art.modulate = Color.WHITE if awakened else Color(0.58, 0.54, 0.62, 0.62)
	title.text = String(data.get("name", "UNKNOWN CURIO"))
	state.text = "AWAKENED · OWNED" if awakened else "LOCKED · NOT YET RECOVERED"
	state.add_theme_color_override("font_color", Color("#F2D08B") if awakened else Color("#A995B0"))
	origin.text = String(data.get("origin_owned" if awakened else "origin_locked", ""))
	lore.text = String(data.get("lore" if awakened else "requirement", ""))
	view_house.visible = awakened
	card.set_meta("curio_id", curio_id)
	card.set_meta("ownership_state", "awakened" if awakened else "locked")
	return true

func detail_contract() -> Dictionary:
	return {
		"curio_id": _curio_id,
		"art_loaded": hero_art != null and hero_art.texture != null,
		"view_in_house_visible": view_house != null and view_house.visible,
		"authored_scene": true,
	}
