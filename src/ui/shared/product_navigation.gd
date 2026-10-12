class_name Match3ProductNavigation
extends RefCounted

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const MobileSafeArea = preload("res://src/ui/shared/mobile_safe_area.gd")
const NavigationScene = preload("res://src/ui/shared/product_navigation.tscn")

const ITEMS := [
	{"label": "HOUSE", "id": "house", "node": "NavHouse", "icon": "res://assets/ui/nav_house.svg"},
	{"label": "CURIOS", "id": "curios", "node": "NavCurios", "icon": "res://assets/ui/nav_curios.svg"},
	{"label": "MAP", "id": "map", "node": "NavMap", "icon": "res://assets/ui/nav_map.svg"},
	{"label": "EVENTS", "id": "events", "node": "NavEvents", "icon": "res://assets/ui/nav_events.svg"},
	{"label": "SHOP", "id": "shop", "node": "NavShop", "icon": "res://assets/ui/nav_shop.svg"},
]

static func attach(screen: Control, active_section: String, handler: Callable, content_path: NodePath = NodePath("Layout")) -> PanelContainer:
	if screen == null:
		return null
	var existing := screen.get_node_or_null("ProductNavigation") as PanelContainer
	if existing != null:
		return existing

	var safe_insets := MobileSafeArea.current_insets(screen)
	var content := screen.get_node_or_null(content_path) as Control
	if content != null:
		if not bool(content.get_meta("product_nav_inset_applied", false)):
			content.set_meta("product_nav_inset_applied", true)
		MobileSafeArea.apply_content(screen, content_path)

	var panel := NavigationScene.instantiate() as PanelContainer
	if panel == null:
		push_error("Global ProductNavigation authored scene could not instantiate.")
		return null
	panel.offset_left = 6.0 + safe_insets.x
	panel.offset_right = -6.0 - safe_insets.z
	panel.offset_top = -90.0 - safe_insets.w
	panel.offset_bottom = -4.0 - safe_insets.w
	screen.add_child(panel)

	for item in ITEMS:
		var action := String(item["id"])
		var button := panel.get_node_or_null("Scroll/Items/%s" % String(item["node"])) as Button
		if button == null:
			push_error("Global ProductNavigation authored slot missing: %s" % action)
			continue
		var is_active := action == active_section
		button.set_meta("interaction_state", "selected" if is_active else "normal")
		button.disabled = is_active
		button.tooltip_text = action.capitalize()
		var icon := button.get_node_or_null("Content/Icon") as TextureRect
		var caption := button.get_node_or_null("Content/Label") as Label
		if icon != null:
			icon.texture = PieceAssetLoader.ornament(String(item["icon"]))
			icon.modulate = Color("#F0CE8A") if is_active else Color("#C9B5C8")
		if caption != null:
			caption.text = String(item["label"])
			caption.add_theme_color_override("font_color", Color("#F4E5D3") if is_active else Color("#CDBFC9"))
		if handler.is_valid() and not is_active:
			button.pressed.connect(handler.bind(action))
	return panel

static func authored_contract(panel: PanelContainer) -> Dictionary:
	if panel == null:
		return {
			"authored_scene": false,
			"all_slots_present": false,
			"icons_loaded": false,
			"touch_targets_ok": false,
			"runtime_ui_factory": false,
		}
	var all_slots_present := true
	var icons_loaded := true
	var touch_targets_ok := true
	var compact_house_bar := true
	for item in ITEMS:
		var button := panel.get_node_or_null("Scroll/Items/%s" % String(item["node"])) as Button
		all_slots_present = all_slots_present and button != null
		if button == null:
			icons_loaded = false
			touch_targets_ok = false
			continue
		var icon := button.get_node_or_null("Content/Icon") as TextureRect
		icons_loaded = icons_loaded and icon != null and icon.texture != null
		touch_targets_ok = touch_targets_ok and button.custom_minimum_size.y >= 56.0
		compact_house_bar = compact_house_bar and button.custom_minimum_size.y <= 80.0
	return {
		"authored_scene": true,
		"all_slots_present": all_slots_present,
		"icons_loaded": icons_loaded,
		"touch_targets_ok": touch_targets_ok,
		"compact_house_bar": compact_house_bar and absf(panel.offset_top) <= 96.0,
		"runtime_ui_factory": false,
	}
