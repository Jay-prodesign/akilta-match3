class_name Match3ProductNavigation
extends RefCounted

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ITEMS := [
	{"label": "HOUSE", "id": "house", "icon": "res://assets/ui/nav_house.svg"},
	{"label": "CURIOS", "id": "curios", "icon": "res://assets/ui/nav_curios.svg"},
	{"label": "MAP", "id": "map", "icon": "res://assets/ui/nav_map.svg"},
	{"label": "EVENTS", "id": "events", "icon": "res://assets/ui/nav_events.svg"},
	{"label": "SHOP", "id": "shop", "icon": "res://assets/ui/nav_shop.svg"},
]

static func attach(screen: Control, active_section: String, handler: Callable, content_path: NodePath = NodePath("Layout")) -> PanelContainer:
	if screen == null:
		return null
	var existing := screen.get_node_or_null("ProductNavigation") as PanelContainer
	if existing != null:
		return existing

	var content := screen.get_node_or_null(content_path) as Control
	if content != null and not bool(content.get_meta("product_nav_inset_applied", false)):
		content.offset_bottom -= 78.0
		content.set_meta("product_nav_inset_applied", true)

	var panel := PanelContainer.new()
	panel.name = "ProductNavigation"
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 12.0
	panel.offset_right = -12.0
	panel.offset_top = -76.0
	panel.offset_bottom = -8.0
	panel.z_index = 40
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#090810", 0.985)
	shell.border_color = Color("#D5AD70", 0.82)
	shell.set_border_width_all(1)
	shell.set_corner_radius_all(12)
	shell.shadow_color = Color(0, 0, 0, 0.44)
	shell.shadow_size = 8
	panel.add_theme_stylebox_override("panel", shell)
	screen.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(scroll)

	var row := HBoxContainer.new()
	row.name = "Items"
	row.add_theme_constant_override("separation", 2)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)

	for item in ITEMS:
		var action := String(item["id"])
		var button := Button.new()
		button.name = "Nav" + action.capitalize()
		button.text = String(item["label"])
		button.icon = PieceAssetLoader.ornament(String(item["icon"]))
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 24)
		button.tooltip_text = action.capitalize()
		button.custom_minimum_size = Vector2(0, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", Color("#F4E5D3"))
		button.add_theme_color_override("font_hover_color", Color("#FFF1D9"))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#211728")
		normal.border_color = Color("#9B7B91", 0.54)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(7)
		var active := normal.duplicate() as StyleBoxFlat
		active.bg_color = Color("#49304C")
		active.border_color = Color("#D5AD70")
		active.set_border_width_all(2)
		button.add_theme_stylebox_override("normal", active if action == active_section else normal)
		button.add_theme_stylebox_override("hover", active)
		button.add_theme_stylebox_override("pressed", active)
		button.add_theme_stylebox_override("focus", active)
		if handler.is_valid():
			button.pressed.connect(handler.bind(action))
		row.add_child(button)
	return panel
