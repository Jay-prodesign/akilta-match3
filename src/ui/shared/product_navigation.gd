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
		content.offset_bottom -= 120.0
		content.set_meta("product_nav_inset_applied", true)

	var panel := PanelContainer.new()
	panel.name = "ProductNavigation"
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 12.0
	panel.offset_right = -12.0
	panel.offset_top = -114.0
	panel.offset_bottom = -10.0
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
		button.text = ""
		button.tooltip_text = action.capitalize()
		button.custom_minimum_size = Vector2(0, 94)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		var stack := VBoxContainer.new()
		stack.name = "Content"
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation", 3)
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(stack)
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(42, 42)
		icon.texture = PieceAssetLoader.ornament(String(item["icon"]))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.modulate = Color("#F0CE8A") if action == active_section else Color("#C9B5C8")
		stack.add_child(icon)
		var caption := Label.new()
		caption.name = "Label"
		caption.text = String(item["label"])
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 20)
		caption.add_theme_color_override("font_color", Color("#F4E5D3") if action == active_section else Color("#CDBFC9"))
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(caption)
		if handler.is_valid():
			button.pressed.connect(handler.bind(action))
		row.add_child(button)
	return panel
