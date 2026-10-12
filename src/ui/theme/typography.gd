class_name Match3Typography
extends RefCounted

const DISPLAY_FONT_PATH := "res://assets/fonts/CormorantGaramond-Variable.ttf"
const UI_FONT_PATH := "res://assets/fonts/Manrope-Variable.ttf"
const DISPLAY_NODE_NAMES := ["Title", "Headline", "FeatureTitle", "FeatureHeroTitle"]
const LICENSE := "SIL Open Font License 1.1"
const PINNED_SOURCE := "google/fonts@bd8f81ddb5c74d5c8897b36ad88b440266245103"

static var _display_font: FontFile
static var _ui_font: FontFile

static func apply(root: Node) -> Dictionary:
	var stats := {"display": 0, "ui": 0}
	if root == null:
		return stats
	_ensure_fonts()
	_apply_recursive(root, stats)
	return stats

static func contract() -> Dictionary:
	_ensure_fonts()
	return {
		"display_font_path": DISPLAY_FONT_PATH,
		"ui_font_path": UI_FONT_PATH,
		"display_font_loaded": _display_font != null and _display_font.data.size() > 0,
		"ui_font_loaded": _ui_font != null and _ui_font.data.size() > 0,
		"display_nodes": DISPLAY_NODE_NAMES.duplicate(),
		"license": LICENSE,
		"source": PINNED_SOURCE,
		"loader": "runtime_fontfile_data",
	}

static func display_font() -> Font:
	_ensure_fonts()
	return _display_font

static func ui_font() -> Font:
	_ensure_fonts()
	return _ui_font

static func _ensure_fonts() -> void:
	if _display_font == null:
		_display_font = _font_from_bytes(DISPLAY_FONT_PATH)
	if _ui_font == null:
		_ui_font = _font_from_bytes(UI_FONT_PATH)

static func _font_from_bytes(path: String) -> FontFile:
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var font := FontFile.new()
	font.data = bytes
	if font.data.is_empty():
		return null
	return font

static func _apply_recursive(node: Node, stats: Dictionary) -> void:
	if node is Label:
		var label := node as Label
		if DISPLAY_NODE_NAMES.has(String(label.name)):
			if _display_font != null:
				label.add_theme_font_override("font", _display_font)
				stats["display"] = int(stats["display"]) + 1
		elif _ui_font != null:
			label.add_theme_font_override("font", _ui_font)
			stats["ui"] = int(stats["ui"]) + 1
	elif node is BaseButton and _ui_font != null:
		(node as BaseButton).add_theme_font_override("font", _ui_font)
		stats["ui"] = int(stats["ui"]) + 1
	for child in node.get_children():
		_apply_recursive(child, stats)
