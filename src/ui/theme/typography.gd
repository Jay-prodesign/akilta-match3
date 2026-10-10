class_name Match3Typography
extends RefCounted

const DISPLAY_FONT_PATH := "res://assets/fonts/CormorantGaramond-Variable.ttf"
const UI_FONT_PATH := "res://assets/fonts/Manrope-Variable.ttf"
const DISPLAY_NODE_NAMES := ["Title", "Headline"]

static var _display_font: FontFile
static var _ui_font: FontFile

static func create_ui_theme() -> Theme:
	var theme := Theme.new()
	var font := _get_ui_font()
	if font != null:
		theme.default_font = font
		theme.default_font_size = 18
	return theme

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
		"ui_font_path": UI_FONT_PATH,
		"ui_font_loaded": _get_ui_font() != null,
		"display_nodes": DISPLAY_NODE_NAMES.duplicate(),
		"license": "SIL Open Font License 1.1",
		"load_mode": "direct_dynamic_font_source",
	}

static func _get_display_font() -> FontFile:
	if _display_font != null:
		return _display_font
	_display_font = _load_font_file(DISPLAY_FONT_PATH)
	return _display_font

static func _get_ui_font() -> FontFile:
	if _ui_font != null:
		return _ui_font
	_ui_font = _load_font_file(UI_FONT_PATH)
	return _ui_font

static func _load_font_file(path: String) -> FontFile:
	if not FileAccess.file_exists(path):
		return null
	var font := FontFile.new()
	if font.load_dynamic_font(path) != OK:
		return null
	return font

static func _apply_recursive(node: Node, font: Font) -> void:
	if node is Label and DISPLAY_NODE_NAMES.has(String(node.name)):
		(node as Label).add_theme_font_override("font", font)
	for child in node.get_children():
		_apply_recursive(child, font)
