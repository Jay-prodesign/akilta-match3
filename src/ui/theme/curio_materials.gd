class_name Match3CurioMaterials
extends RefCounted

## Shared Curio House material language for player-facing UI.
## Product-owned: no donor visual identity or paid assets.

const INK := Color("#100D12")
const VELVET := Color("#17131B")
const PLUM := Color("#241A27")
const PLUM_RAISED := Color("#2E2135")
const BONE := Color("#F1E8DD")
const MIST := Color("#D9CDD5")
const LILAC := Color("#BFA5D8")
const GOLD := Color("#D8B56A")

const PRIMARY_BUTTONS := ["Start", "Action", "Close", "PlayButton", "Resume"]
const SECONDARY_BUTTONS := ["Back", "SettingsButton", "CollectionButton", "Retry", "Exit"]
const HERO_PANELS := ["Card", "MoonCard", "RoutePanel"]
const SEALED_PANELS := ["Slot2", "Slot3"]
const CHIP_PANELS := ["CurioChip", "Awakening"]

static func apply(root: Node) -> Dictionary:
	var stats := {"panels": 0, "buttons": 0, "labels": 0}
	if root == null:
		return stats
	_apply_recursive(root, stats)
	return stats

static func contract() -> Dictionary:
	return {
		"ink": INK.to_html(),
		"velvet": VELVET.to_html(),
		"plum": PLUM.to_html(),
		"bone": BONE.to_html(),
		"mist": MIST.to_html(),
		"lilac": LILAC.to_html(),
		"gold": GOLD.to_html(),
		"corner_radius": 18,
		"identity": "curio_house_product_owned",
	}

static func _apply_recursive(node: Node, stats: Dictionary) -> void:
	if node is PanelContainer:
		_style_panel(node as PanelContainer)
		stats["panels"] = int(stats["panels"]) + 1
	elif node is Button:
		_style_button(node as Button)
		stats["buttons"] = int(stats["buttons"]) + 1
	elif node is CheckButton:
		_style_toggle(node as CheckButton)
		stats["buttons"] = int(stats["buttons"]) + 1
	elif node is Label:
		_style_label(node as Label)
		stats["labels"] = int(stats["labels"]) + 1
	for child in node.get_children():
		_apply_recursive(child, stats)

static func _style_panel(panel: PanelContainer) -> void:
	var name := String(panel.name)
	if not (HERO_PANELS.has(name) or SEALED_PANELS.has(name) or CHIP_PANELS.has(name)):
		return
	var box := StyleBoxFlat.new()
	box.corner_radius_top_left = 22
	box.corner_radius_top_right = 22
	box.corner_radius_bottom_left = 22
	box.corner_radius_bottom_right = 22
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.shadow_color = Color(0, 0, 0, 0.36)
	box.shadow_size = 10
	if SEALED_PANELS.has(name):
		box.bg_color = Color(0.07, 0.052, 0.082, 0.97)
		box.border_color = Color(LILAC, 0.20)
	elif CHIP_PANELS.has(name):
		box.bg_color = Color(PLUM, 0.94)
		box.border_color = Color(GOLD, 0.26)
		box.corner_radius_top_left = 14
		box.corner_radius_top_right = 14
		box.corner_radius_bottom_left = 14
		box.corner_radius_bottom_right = 14
		box.shadow_size = 4
	else:
		box.bg_color = Color(0.09, 0.067, 0.105, 0.985)
		box.border_color = Color(GOLD, 0.38)
	panel.add_theme_stylebox_override("panel", box)

static func _style_button(button: Button) -> void:
	var name := String(button.name)
	if PRIMARY_BUTTONS.has(name):
		var normal := _button_box(Color("#BEA4D8"), Color(BONE, 0.24), 18)
		var hover := _button_box(Color("#CDB8E1"), Color(BONE, 0.42), 18)
		var pressed := _button_box(Color("#A98FC3"), Color(GOLD, 0.42), 18)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_color_override("font_color", INK)
		button.add_theme_color_override("font_hover_color", INK)
		button.add_theme_color_override("font_pressed_color", INK)
	elif SECONDARY_BUTTONS.has(name):
		var utility := _button_box(Color(0.105, 0.078, 0.12, 0.98), Color(LILAC, 0.24), 15)
		button.add_theme_stylebox_override("normal", utility)
		button.add_theme_stylebox_override("hover", utility)
		button.add_theme_stylebox_override("pressed", utility)
		button.add_theme_color_override("font_color", MIST)

static func _style_toggle(toggle: CheckButton) -> void:
	var box := _button_box(Color(0.075, 0.057, 0.088, 0.98), Color(LILAC, 0.18), 14)
	toggle.add_theme_stylebox_override("normal", box)
	toggle.add_theme_stylebox_override("hover", box)
	toggle.add_theme_stylebox_override("pressed", box)
	toggle.add_theme_color_override("font_color", MIST)

static func _style_label(label: Label) -> void:
	var name := String(label.name)
	if name in ["Title", "Headline"]:
		label.add_theme_color_override("font_color", BONE)
	elif name in ["Eyebrow", "Origin", "SavedNote"]:
		label.add_theme_color_override("font_color", Color(MIST, 0.58))
	elif name in ["Reward", "Count", "State", "AudioLabel", "ExperienceLabel", "Label"]:
		label.add_theme_color_override("font_color", GOLD)

static func _button_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = border
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box
