extends Control
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

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
	ProductionChrome.apply_primary(card)
	ProductionChrome.apply_action_button(view_house, "primary", "curio_view_house")
	ProductionChrome.apply_action_button(close, "utility", "curio_return_reliquary")
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
		"north_star_actions": view_house != null and view_house.custom_minimum_size.y >= 64.0 and close != null and close.custom_minimum_size.y >= 60.0,
		"asset_backed_actions": view_house != null and view_house.get_theme_stylebox("normal") is StyleBoxTexture and close != null and close.get_theme_stylebox("normal") is StyleBoxTexture and String(view_house.get_meta("production_chrome_kind", "")) == "action_primary_curio_view_house" and String(close.get_meta("production_chrome_kind", "")) == "action_utility_curio_return_reliquary",
		"content_bounded_card": card != null and card.anchor_bottom - card.anchor_top <= 0.57,
		"modal_veil_strength": ($Veil as ColorRect).color.a >= 0.74,
		"authored_scene": true,
	}
