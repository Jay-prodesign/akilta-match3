class_name Match3ProductionChrome
extends RefCounted

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const PRIMARY_PANEL_PATH := "res://assets/ui/chrome/gbl_ui_ritual_panel_9s_base_v01.svg"
const QUIET_PANEL_PATH := "res://assets/ui/chrome/gbl_ui_ritual_panel_9s_quiet_v01.svg"
const PRIMARY_ACTION_PATH := "res://assets/ui/chrome/gbl_ui_action_primary_9s_v01.svg"
const UTILITY_ACTION_PATH := "res://assets/ui/chrome/gbl_ui_action_utility_9s_v01.svg"
const GAMEPLAY_FRAME_PATH := "res://assets/board/gbl_board_ritual_frame_9s_base_v01.png"
const GAMEPLAY_HUD_FRAME_PATH := "res://assets/ui/gameplay/hud_objective_frame_v01.svg"
const GAMEPLAY_PAUSE_FRAME_PATH := "res://assets/ui/gameplay/pause_modal_frame_v01.svg"
const GAMEPLAY_BOOSTER_TRAY_PATH := "res://assets/ui/gameplay/booster_tray_frame_v02.svg"
const GAMEPLAY_LEVEL_PLAQUE_PATH := "res://assets/ui/gameplay/level_plaque_v01.svg"

static var _primary_panel: StyleBoxTexture
static var _top_shell: StyleBoxTexture
static var _bottom_shell: StyleBoxTexture
static var _gameplay_shell: StyleBoxTexture
static var _gameplay_hud_frame: StyleBoxTexture
static var _gameplay_pause_frame: StyleBoxTexture
static var _secondary_panel: StyleBoxTexture
static var _gameplay_booster_tray: StyleBoxTexture
static var _gameplay_level_plaque: StyleBoxTexture
static var _compact_panel: StyleBoxTexture
static var _interactive_normal: StyleBoxTexture
static var _interactive_focus: StyleBoxTexture
static var _primary_action_normal: StyleBoxTexture
static var _primary_action_hover: StyleBoxTexture
static var _primary_action_pressed: StyleBoxTexture
static var _utility_action_normal: StyleBoxTexture
static var _utility_action_hover: StyleBoxTexture
static var _utility_action_pressed: StyleBoxTexture
static var _action_disabled: StyleBoxTexture

static func _style(content_margin: float, texture_margin: float = 64.0, asset_path: String = PRIMARY_PANEL_PATH) -> StyleBoxTexture:
	var texture := PieceAssetLoader.ornament(asset_path)
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

static func compact_panel() -> StyleBoxTexture:
	if _compact_panel == null:
		_compact_panel = _style(4.0, 52.0, QUIET_PANEL_PATH)
		if _compact_panel != null:
			_compact_panel.modulate_color = Color(0.84, 0.78, 0.88, 0.92)
	return _compact_panel

static func interactive_normal() -> StyleBoxTexture:
	if _interactive_normal == null:
		_interactive_normal = _style(4.0, 52.0, QUIET_PANEL_PATH)
		if _interactive_normal != null:
			_interactive_normal.modulate_color = Color(0.72, 0.64, 0.76, 0.78)
	return _interactive_normal

static func interactive_focus() -> StyleBoxTexture:
	if _interactive_focus == null:
		_interactive_focus = _style(4.0, 52.0, QUIET_PANEL_PATH)
		if _interactive_focus != null:
			_interactive_focus.modulate_color = Color(1.0, 0.98, 1.0, 1.0)
	return _interactive_focus

static func apply_compact_panel(panel: Control, role: String) -> bool:
	if panel == null:
		return false
	var style := compact_panel()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", QUIET_PANEL_PATH)
	panel.set_meta("production_chrome_kind", "compact_" + role)
	return true

static func apply_interactive_button(button: Button, selected: bool, role: String) -> bool:
	if button == null:
		return false
	var normal_style := interactive_normal()
	var focus_style := interactive_focus()
	if normal_style == null or focus_style == null:
		return false
	button.add_theme_stylebox_override("normal", focus_style if selected else normal_style)
	button.add_theme_stylebox_override("hover", focus_style)
	button.add_theme_stylebox_override("pressed", focus_style)
	button.add_theme_stylebox_override("focus", focus_style)
	button.add_theme_stylebox_override("disabled", focus_style if selected else normal_style)
	button.set_meta("production_chrome_asset", QUIET_PANEL_PATH)
	button.set_meta("production_chrome_kind", "interactive_" + role)
	return true

static func primary_action_normal() -> StyleBoxTexture:
	if _primary_action_normal == null:
		_primary_action_normal = _style(6.0, 20.0, PRIMARY_ACTION_PATH)
	return _primary_action_normal

static func primary_action_hover() -> StyleBoxTexture:
	if _primary_action_hover == null:
		_primary_action_hover = _style(6.0, 20.0, PRIMARY_ACTION_PATH)
		if _primary_action_hover != null:
			_primary_action_hover.modulate_color = Color(1.0, 0.96, 1.0, 1.0)
	return _primary_action_hover

static func primary_action_pressed() -> StyleBoxTexture:
	if _primary_action_pressed == null:
		_primary_action_pressed = _style(6.0, 20.0, PRIMARY_ACTION_PATH)
		if _primary_action_pressed != null:
			_primary_action_pressed.modulate_color = Color(0.80, 0.74, 0.84, 0.96)
	return _primary_action_pressed

static func utility_action_normal() -> StyleBoxTexture:
	if _utility_action_normal == null:
		_utility_action_normal = _style(6.0, 20.0, UTILITY_ACTION_PATH)
		if _utility_action_normal != null:
			_utility_action_normal.modulate_color = Color(0.72, 0.66, 0.76, 0.86)
	return _utility_action_normal

static func utility_action_hover() -> StyleBoxTexture:
	if _utility_action_hover == null:
		_utility_action_hover = _style(6.0, 20.0, UTILITY_ACTION_PATH)
		if _utility_action_hover != null:
			_utility_action_hover.modulate_color = Color(0.96, 0.92, 0.98, 1.0)
	return _utility_action_hover

static func utility_action_pressed() -> StyleBoxTexture:
	if _utility_action_pressed == null:
		_utility_action_pressed = _style(6.0, 20.0, UTILITY_ACTION_PATH)
		if _utility_action_pressed != null:
			_utility_action_pressed.modulate_color = Color(0.62, 0.56, 0.68, 0.92)
	return _utility_action_pressed

static func action_disabled() -> StyleBoxTexture:
	if _action_disabled == null:
		_action_disabled = _style(6.0, 20.0, UTILITY_ACTION_PATH)
		if _action_disabled != null:
			_action_disabled.modulate_color = Color(0.44, 0.40, 0.48, 0.62)
	return _action_disabled

static func apply_action_button(button: Button, hierarchy: String, role: String) -> bool:
	if button == null:
		return false
	var primary := hierarchy == "primary"
	var normal_style := primary_action_normal() if primary else utility_action_normal()
	var hover_style := primary_action_hover() if primary else utility_action_hover()
	var pressed_style := primary_action_pressed() if primary else utility_action_pressed()
	var disabled_style := action_disabled()
	if normal_style == null or hover_style == null or pressed_style == null or disabled_style == null:
		return false
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.set_meta("production_chrome_asset", PRIMARY_ACTION_PATH if primary else UTILITY_ACTION_PATH)
	button.set_meta("production_chrome_kind", "action_" + hierarchy + "_" + role)
	return true

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
		_gameplay_shell = _style(8.0, 52.0, QUIET_PANEL_PATH)
	return _gameplay_shell

static func gameplay_hud_frame() -> StyleBoxTexture:
	if _gameplay_hud_frame == null:
		_gameplay_hud_frame = _style(9.0, 64.0, GAMEPLAY_HUD_FRAME_PATH)
	return _gameplay_hud_frame

static func apply_gameplay_shell(panel: Control, kind: String) -> bool:
	if panel == null:
		return false
	var objective_frame := kind == "objective"
	var style := gameplay_hud_frame() if objective_frame else gameplay_shell()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", GAMEPLAY_HUD_FRAME_PATH if objective_frame else QUIET_PANEL_PATH)
	panel.set_meta("production_chrome_kind", "gameplay_objective_frame" if objective_frame else "gameplay_" + kind)
	return true

static func gameplay_booster_tray() -> StyleBoxTexture:
	if _gameplay_booster_tray == null:
		_gameplay_booster_tray = _style(14.0, 58.0, GAMEPLAY_BOOSTER_TRAY_PATH)
	return _gameplay_booster_tray

static func apply_gameplay_booster_tray(panel: Control) -> bool:
	if panel == null:
		return false
	var style := gameplay_booster_tray()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", GAMEPLAY_BOOSTER_TRAY_PATH)
	panel.set_meta("production_chrome_kind", "gameplay_booster_tray")
	return true

static func gameplay_level_plaque() -> StyleBoxTexture:
	if _gameplay_level_plaque == null:
		_gameplay_level_plaque = _style(8.0, 26.0, GAMEPLAY_LEVEL_PLAQUE_PATH)
		if _gameplay_level_plaque != null:
			_gameplay_level_plaque.modulate_color = Color(1.0, 0.97, 0.90, 1.0)
	return _gameplay_level_plaque

static func apply_gameplay_level_plaque(panel: Control) -> bool:
	if panel == null:
		return false
	var style := gameplay_level_plaque()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", GAMEPLAY_LEVEL_PLAQUE_PATH)
	panel.set_meta("production_chrome_kind", "gameplay_level_plaque")
	return true

static func gameplay_pause_frame() -> StyleBoxTexture:
	if _gameplay_pause_frame == null:
		_gameplay_pause_frame = _style(30.0, 78.0, GAMEPLAY_PAUSE_FRAME_PATH)
	return _gameplay_pause_frame

static func apply_gameplay_pause_modal(panel: Control) -> bool:
	if panel == null:
		return false
	var style := gameplay_pause_frame()
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("production_chrome_asset", GAMEPLAY_PAUSE_FRAME_PATH)
	panel.set_meta("production_chrome_kind", "gameplay_pause_modal")
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
		"gameplay_hud_frame_asset_backed": gameplay_hud_frame() != null and gameplay_hud_frame().texture != null,
		"gameplay_booster_tray_asset_backed": gameplay_booster_tray() != null and gameplay_booster_tray().texture != null,
		"secondary_panel_asset_backed": secondary_panel() != null and secondary_panel().texture != null,
		"secondary_hero_family_verified": secondary_panel() != null and secondary_panel().texture != null,
		"compact_panel_asset_backed": compact_panel() != null and compact_panel().texture != null,
		"interactive_button_asset_backed": interactive_normal() != null and interactive_normal().texture != null and interactive_focus() != null and interactive_focus().texture != null,
		"global_interactive_family_ready": compact_panel() != null and compact_panel().texture != null and interactive_normal() != null and interactive_normal().texture != null and interactive_focus() != null and interactive_focus().texture != null,
		"quiet_interactive_runtime_path": PieceAssetLoader.resolved_path(QUIET_PANEL_PATH),
		"primary_action_asset_backed": primary_action_normal() != null and primary_action_normal().texture != null and primary_action_hover() != null and primary_action_pressed() != null,
		"utility_action_asset_backed": utility_action_normal() != null and utility_action_normal().texture != null and utility_action_hover() != null and utility_action_pressed() != null,
		"action_family_ready": primary_action_normal() != null and primary_action_normal().texture != null and utility_action_normal() != null and utility_action_normal().texture != null and action_disabled() != null and action_disabled().texture != null,
		"primary_action_runtime_path": PieceAssetLoader.resolved_path(PRIMARY_ACTION_PATH),
		"utility_action_runtime_path": PieceAssetLoader.resolved_path(UTILITY_ACTION_PATH),
	}
