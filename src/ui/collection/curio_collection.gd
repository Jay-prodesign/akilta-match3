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
@onready var slot2_number: Label = $Layout/Cards/Slot2/Content/Number
@onready var slot2_name: Label = $Layout/Cards/Slot2/Content/Copy/Name
@onready var slot2_hint: Label = $Layout/Cards/Slot2/Content/Copy/Hint
@onready var slot2_state: Label = $Layout/Cards/Slot2/Content/Copy/State
@onready var slot2_origin: Label = $Layout/Cards/Slot2/Content/Copy/Origin
@onready var slot3_number: Label = $Layout/Cards/Slot3/Content/Number
@onready var slot3_name: Label = $Layout/Cards/Slot3/Content/Copy/Name
@onready var slot3_hint: Label = $Layout/Cards/Slot3/Content/Copy/Hint
@onready var slot3_state: Label = $Layout/Cards/Slot3/Content/Copy/State
@onready var slot3_origin: Label = $Layout/Cards/Slot3/Content/Copy/Origin
@onready var slot2_card: PanelContainer = $Layout/Cards/Slot2
@onready var slot3_card: PanelContainer = $Layout/Cards/Slot3

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

const MOON_SEALED_PATH := "res://assets/curios/ch01_curio_moon_cameo_sealed_v01.svg"
const MOON_AWAKENED_PATH := "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg"
var _moon_textures: Dictionary = {}

var progress
var _moon_art: TextureRect

func _ready() -> void:
	back_button.pressed.connect(func(): back_requested.emit())
	_install_moon_art()
	_install_reward_art(slot2_number, "res://assets/curios/ch01_curio_moth_reliquary.svg")
	_install_reward_art(slot3_number, "res://assets/curios/ch01_curio_thorned_locket.svg")
	_install_collection_atmosphere()
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
	var has_moth := curios.has("moth_reliquary")
	var has_locket := curios.has("thorned_locket")
	slot2_name.text = "MOTH RELIQUARY" if has_moth else "SEALED · MOTH RELIQUARY"
	slot2_hint.text = "Recovered from the sealed side cabinet." if has_moth else "Clear both wax seals in Level 2."
	slot2_state.text = "AWAKENED · RELIC 02" if has_moth else "DORMANT · RELIC 02"
	slot2_origin.text = "RECOVERED FROM · SEALED DISPLAY" if has_moth else "SEALED BEHIND · WAX DISPLAY"
	slot2_number.modulate = Color.WHITE if has_moth else Color(0.55, 0.51, 0.60, 0.72)
	slot2_card.modulate = Color.WHITE if has_moth else Color(0.66, 0.62, 0.72, 0.82)
	_apply_reward_card_style(slot2_card, has_moth, Color("#9BBED0"))
	slot3_name.text = "THORNED LOCKET" if has_locket else "SEALED · THORNED LOCKET"
	slot3_hint.text = "A moon-beam sigil opened its thorned clasp." if has_locket else "Create and trigger a line special in Level 3."
	slot3_state.text = "AWAKENED · RELIC 03" if has_locket else "DORMANT · RELIC 03"
	slot3_origin.text = "RECOVERED FROM · THORNLIGHT ARRANGEMENT" if has_locket else "SEALED BEHIND · THORNLIGHT"
	slot3_number.modulate = Color.WHITE if has_locket else Color(0.55, 0.51, 0.60, 0.72)
	slot3_card.modulate = Color.WHITE if has_locket else Color(0.66, 0.62, 0.72, 0.82)
	_apply_reward_card_style(slot3_card, has_locket, Color("#C98BA8"))
	if _moon_art != null:
		_moon_art.texture = _load_moon_texture(MOON_AWAKENED_PATH if has_moon else MOON_SEALED_PATH)
		_moon_art.modulate = Color.WHITE if has_moon else Color(0.75, 0.70, 0.81, 0.78)
	if moon_ritual != null:
		moon_ritual.set("glow_strength", 0.82 if has_moon else 0.18)
		moon_ritual.queue_redraw()

func _apply_reward_card_style(card: PanelContainer, awakened: bool, accent: Color) -> void:
	if card == null:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#151019", 0.98) if awakened else Color("#100D14", 0.96)
	box.border_color = Color(accent.r, accent.g, accent.b, 0.76 if awakened else 0.28)
	box.set_border_width_all(2 if awakened else 1)
	box.set_corner_radius_all(18)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", box)

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

func _load_moon_texture(path: String) -> Texture2D:
	if _moon_textures.has(path):
		return _moon_textures[path]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var svg := file.get_as_text()
	file.close()
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK or image.is_empty():
		return null
	var texture := ImageTexture.create_from_image(image)
	_moon_textures[path] = texture
	return texture

func _install_reward_art(label: Label, path: String) -> void:
	if label == null:
		return
	label.text = ""
	var art := TextureRect.new()
	art.texture = PieceAssetLoader.ornament(path)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_child(art)

func _install_collection_atmosphere() -> void:
	var backdrop := TextureRect.new()
	backdrop.name = "ReliquaryMoonlitBackdrop"
	backdrop.texture = PieceAssetLoader.ornament("res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.modulate = Color(0.72, 0.64, 0.79, 0.18)
	add_child(backdrop)
	move_child(backdrop, 1)
	var action := StyleBoxFlat.new()
	action.bg_color = Color("#35213B")
	action.border_color = Color("#D5AD70")
	action.set_border_width_all(2)
	action.set_corner_radius_all(12)
	var hover := action.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#56305A")
	back_button.add_theme_stylebox_override("normal", action)
	back_button.add_theme_stylebox_override("hover", hover)
	back_button.add_theme_stylebox_override("pressed", hover)
	back_button.add_theme_color_override("font_color", Color("#F4E5D3"))
	back_button.add_theme_color_override("font_hover_color", Color("#F4E5D3"))
	back_button.custom_minimum_size.y = maxf(back_button.custom_minimum_size.y, 56.0)
