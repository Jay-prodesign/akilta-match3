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
var _detail_overlay: Control

func _ready() -> void:
	back_button.pressed.connect(func(): back_requested.emit())
	_install_moon_art()
	_install_reward_art(slot2_number, "res://assets/curios/ch01_curio_moth_reliquary.svg")
	_install_reward_art(slot3_number, "res://assets/curios/ch01_curio_thorned_locket.svg")
	_install_collection_atmosphere()
	_install_card_actions()
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


func _install_card_actions() -> void:
	_install_card_action(moon_card, "moon_cameo")
	_install_card_action(slot2_card, "moth_reliquary")
	_install_card_action(slot3_card, "thorned_locket")

func _install_card_action(card: PanelContainer, curio_id: String) -> void:
	if card == null or card.get_node_or_null("DetailActionLayer") != null:
		return
	var layer := Control.new()
	layer.name = "DetailActionLayer"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(layer)
	var button := Button.new()
	button.name = "InspectAction"
	button.text = "DETAILS"
	button.anchor_left = 0.73
	button.anchor_right = 0.97
	button.anchor_top = 0.78
	button.anchor_bottom = 0.96
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 12)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#24172A", 0.96)
	normal.border_color = Color("#D5AD70", 0.62)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#432348", 0.98)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("#F4E5D3"))
	layer.add_child(button)
	button.pressed.connect(func(): _open_curio_detail(curio_id))

func _open_curio_detail(curio_id: String) -> void:
	_close_curio_detail()
	var data := _curio_detail_data(curio_id)
	if data.is_empty():
		return
	var awakened := _is_curio_awakened(curio_id)
	var overlay := Control.new()
	overlay.name = "CurioDetailOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 120
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_detail_overlay = overlay

	var veil := ColorRect.new()
	veil.color = Color(0.015, 0.01, 0.025, 0.86)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(veil)

	var card := PanelContainer.new()
	card.name = "CurioDetailCard"
	card.anchor_left = 0.08
	card.anchor_right = 0.92
	card.anchor_top = 0.14
	card.anchor_bottom = 0.84
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#0D0912", 0.995)
	shell.border_color = Color("#D5AD70", 0.88 if awakened else 0.38)
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(20)
	shell.content_margin_left = 22
	shell.content_margin_right = 22
	shell.content_margin_top = 18
	shell.content_margin_bottom = 18
	shell.shadow_color = Color(0, 0, 0, 0.66)
	shell.shadow_size = 18
	card.add_theme_stylebox_override("panel", shell)
	overlay.add_child(card)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 9)
	card.add_child(content)

	var kicker := Label.new()
	kicker.text = "RELIQUARY · CURIO DETAIL"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_color_override("font_color", Color("#D5AD70"))
	kicker.add_theme_font_size_override("font_size", 13)
	content.add_child(kicker)

	var art := TextureRect.new()
	art.name = "HeroArt"
	art.custom_minimum_size = Vector2(0, 220)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _detail_texture(curio_id, awakened)
	art.modulate = Color.WHITE if awakened else Color(0.58, 0.54, 0.62, 0.62)
	content.add_child(art)

	var title := Label.new()
	title.name = "Name"
	title.text = String(data.get("name", "UNKNOWN CURIO"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#F4E5D3"))
	title.add_theme_font_size_override("font_size", 27)
	content.add_child(title)

	var state := Label.new()
	state.name = "State"
	state.text = "AWAKENED · OWNED" if awakened else "LOCKED · NOT YET RECOVERED"
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.add_theme_color_override("font_color", Color("#F2D08B") if awakened else Color("#A995B0"))
	state.add_theme_font_size_override("font_size", 15)
	content.add_child(state)

	var origin := Label.new()
	origin.name = "Origin"
	origin.text = String(data.get("origin_owned" if awakened else "origin_locked", ""))
	origin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	origin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	origin.add_theme_color_override("font_color", Color("#B4A2B7"))
	origin.add_theme_font_size_override("font_size", 13)
	content.add_child(origin)

	var lore := Label.new()
	lore.name = "Lore"
	lore.text = String(data.get("lore" if awakened else "requirement", ""))
	lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.add_theme_color_override("font_color", Color("#DDD0D7"))
	lore.add_theme_font_size_override("font_size", 15)
	content.add_child(lore)

	var close := Button.new()
	close.name = "Close"
	close.text = "RETURN TO RELIQUARY"
	close.custom_minimum_size = Vector2(0, 54)
	close.add_theme_font_size_override("font_size", 17)
	var close_box := StyleBoxFlat.new()
	close_box.bg_color = Color("#35213B")
	close_box.border_color = Color("#D5AD70")
	close_box.set_border_width_all(2)
	close_box.set_corner_radius_all(10)
	close.add_theme_stylebox_override("normal", close_box)
	close.add_theme_stylebox_override("hover", close_box)
	close.add_theme_stylebox_override("pressed", close_box)
	close.add_theme_color_override("font_color", Color("#FFF0D8"))
	content.add_child(close)
	close.pressed.connect(_close_curio_detail)

func _close_curio_detail() -> void:
	if _detail_overlay != null and is_instance_valid(_detail_overlay):
		_detail_overlay.queue_free()
	_detail_overlay = null

func _is_curio_awakened(curio_id: String) -> bool:
	return progress != null and progress.curios.has(curio_id)

func _detail_texture(curio_id: String, awakened: bool) -> Texture2D:
	match curio_id:
		"moon_cameo":
			return _load_moon_texture(MOON_AWAKENED_PATH if awakened else MOON_SEALED_PATH)
		"moth_reliquary":
			return PieceAssetLoader.ornament("res://assets/curios/ch01_curio_moth_reliquary.svg")
		"thorned_locket":
			return PieceAssetLoader.ornament("res://assets/curios/ch01_curio_thorned_locket.svg")
		_:
			return null

func _curio_detail_data(curio_id: String) -> Dictionary:
	match curio_id:
		"moon_cameo":
			return {
				"name": "MOON CAMEO",
				"origin_owned": "RECOVERED FROM · MOONLIT CABINET · LEVEL 1",
				"origin_locked": "SEALED BEHIND · MOONLIT CABINET",
				"lore": "The first recovered Curio. Its moonlit face now remains visible in the restored House.",
				"requirement": "Complete Level 1 to awaken the Moon Cameo and restore the first cabinet."
			}
		"moth_reliquary":
			return {
				"name": "MOTH RELIQUARY",
				"origin_owned": "RECOVERED FROM · SEALED DISPLAY · LEVEL 2",
				"origin_locked": "SEALED BEHIND · WAX DISPLAY",
				"lore": "A recovered side-cabinet relic. Its display stays restored after the Level 2 ritual.",
				"requirement": "Complete Level 2 by clearing both wax seals to recover the Moth Reliquary."
			}
		"thorned_locket":
			return {
				"name": "THORNED LOCKET",
				"origin_owned": "RECOVERED FROM · THORNLIGHT ARRANGEMENT · LEVEL 3",
				"origin_locked": "SEALED BEHIND · THORNLIGHT",
				"lore": "The third opening Curio. Its restored place completes the first cabinet set.",
				"requirement": "Complete Level 3 and its Moon Beam objective to recover the Thorned Locket."
			}
		_:
			return {}
