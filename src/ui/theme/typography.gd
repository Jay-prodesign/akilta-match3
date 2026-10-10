class_name Match3Typography
extends RefCounted

const DISPLAY_FONT_PATH := "res://assets/fonts/CormorantGaramond-Variable.ttf"
const DISPLAY_NODE_NAMES := ["Title", "Headline"]

static var _display_font: Font

static func apply(root: Node) -> void:
	if root == null:
		return
	var font := _get_display_font()
	if font == null:
		return
	_apply_recursive(root, font)

static func contract() -> Dictionary:
	return {
		"display_font_path": DISPLAY_FONT_PATH,
		"display_font_loaded": _get_display_font() != null,
		"display_nodes": DISPLAY_NODE_NAMES.duplicate(),
		"ui_font_path": "res://assets/fonts/Manrope-Variable.ttf",
		"license": "SIL Open Font License 1.1",
	}

static func _get_display_font() -> Font:
	if _display_font != null:
		return _display_font
	if not ResourceLoader.exists(DISPLAY_FONT_PATH):
		return null
	_display_font = load(DISPLAY_FONT_PATH) as Font
	return _display_font

static func _apply_recursive(node: Node, font: Font) -> void:
	if node is Label and DISPLAY_NODE_NAMES.has(String(node.name)):
		(node as Label).add_theme_font_override("font", font)
	for child in node.get_children():
		_apply_recursive(child, font)
