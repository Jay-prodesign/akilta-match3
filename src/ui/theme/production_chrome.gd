class_name Match3ProductionChrome
extends RefCounted

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const PRIMARY_PANEL_PATH := "res://assets/ui/chrome/gbl_ui_ritual_panel_9s_base_v01.svg"

static var _primary_panel: StyleBoxTexture
static var _top_shell: StyleBoxTexture
static var _bottom_shell: StyleBoxTexture
static var _gameplay_shell: StyleBoxTexture
static var _secondary_panel: StyleBoxTexture

static func _style(content_margin: float, texture_margin: float = 64.0) -> StyleBoxTexture:
	var texture := PieceAssetLoader.ornament(PRIMARY_PANEL_PATH)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = texture_margin
	style.texture_margin_top = texture_margin
	style.texture_margin_right = texture_margin
	style.texture_margin_bottom = texture_margin
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style

static func primary_panel() -> StyleBoxTexture:
	if _primary_panel != null:
		return _primary_panel
	var style := _style(28.0)
	if style == null:
		return null
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	_primary_panel = style
	return _primary_panel

static func top_shell() -> StyleBoxTexture:
	if _top_shell == null:
		_top_shell = _style(8.0, 52.0)
	return _top_shell

static func bottom_shell() -> StyleBoxTexture:
	if _bottom_shell == null:
		_bottom_shell = _style(8.0, 52.0)
	return _bottom_shell

static func secondary_panel() -> StyleBoxTexture:
	if _secondary_panel == null:
		_secondary_panel = _style(16.0, 56.0)
	return _secondary_panel

static func apply_secondary(panel: Control, role: String) -> bool:
	if panel == null:
		return false
	var style := secondary_panel()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", PRIMARY_PANEL_PATH)
	panel.set_meta("production_chrome_kind", "secondary_" + role)
	return true

static func gameplay_shell() -> StyleBoxTexture:
	if _gameplay_shell == null:
		_gameplay_shell = _style(6.0, 48.0)
	return _gameplay_shell

static func apply_gameplay_shell(panel: Control, kind: String) -> bool:
	if panel == null:
		return false
	var style := gameplay_shell()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", PRIMARY_PANEL_PATH)
	panel.set_meta("production_chrome_kind", "gameplay_" + kind)
	return true

static func apply_shell(panel: Control, kind: String) -> bool:
	if panel == null:
		return false
	var style := top_shell() if kind == "top" else bottom_shell()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", PRIMARY_PANEL_PATH)
	panel.set_meta("production_chrome_kind", kind)
	return true

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
		"top_shell_asset_backed": top_shell() != null and top_shell().texture != null,
		"bottom_shell_asset_backed": bottom_shell() != null and bottom_shell().texture != null,
		"global_shell_family_verified": top_shell() != null and top_shell().texture != null and bottom_shell() != null and bottom_shell().texture != null,
		"gameplay_shell_asset_backed": gameplay_shell() != null and gameplay_shell().texture != null,
		"secondary_panel_asset_backed": secondary_panel() != null and secondary_panel().texture != null,
	}
