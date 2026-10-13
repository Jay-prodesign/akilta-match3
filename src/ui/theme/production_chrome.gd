class_name Match3ProductionChrome
extends RefCounted

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const PRIMARY_PANEL_PATH := "res://assets/ui/chrome/gbl_ui_ritual_panel_9s_base_v01.png"

static var _primary_panel: StyleBoxTexture

static func primary_panel() -> StyleBoxTexture:
	if _primary_panel != null:
		return _primary_panel
	var texture := PieceAssetLoader.ornament(PRIMARY_PANEL_PATH)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 64.0
	style.texture_margin_top = 64.0
	style.texture_margin_right = 64.0
	style.texture_margin_bottom = 64.0
	style.content_margin_left = 30.0
	style.content_margin_top = 28.0
	style.content_margin_right = 30.0
	style.content_margin_bottom = 28.0
	_primary_panel = style
	return _primary_panel

static func apply_primary(panel: Control) -> bool:
	if panel == null:
		return false
	var style := primary_panel()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", PRIMARY_PANEL_PATH)
	return true

static func contract() -> Dictionary:
	var style := primary_panel()
	return {
		"asset_backed": style != null and style.texture != null,
		"runtime_path": PieceAssetLoader.resolved_path(PRIMARY_PANEL_PATH),
		"nine_slice_margin": 64.0,
	}
