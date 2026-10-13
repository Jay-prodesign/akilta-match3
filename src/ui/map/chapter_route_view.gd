class_name Match3ChapterRouteView
extends Control

signal level_requested(level_number: int)
signal sealed_level_requested(level_number: int, kind: String)

const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")
const BONE := Color("#F1E8DD")
const PLUM := Color("#241A27")
const CYAN := Color("#9BBED0")
const ROSE := Color("#C98BA8")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")
const FRONTIER_ART_PATH := "res://assets/pieces/moon_sigil.webp"
const RELIC_ART_PATHS := {
	1: "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp",
	2: "res://assets/curios/ch01_curio_moth_reliquary.png",
	3: "res://assets/curios/ch01_curio_thorned_locket.png",
}

@export var canonical_level_cap: int = 1
@export var visible_route_levels: int = 10
@export var route_width: float = 940.0
@export var top_margin: float = 320.0
@export var bottom_margin: float = 170.0

var progress
var _level_buttons: Dictionary = {}
var _level_labels: Dictionary = {}
var _centers: Dictionary = {}
var _level_states: Dictionary = {}
var _frontier_level: int = -1
var _frontier_focus: TextureRect
var _frontier_label: Label

func _ready() -> void:
	_bind_authored_route()
	_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func set_canonical_level_cap(value: int) -> void:
	canonical_level_cap = max(1, value)
	_refresh()

func get_level_button(level_number: int) -> Button:
	return _level_buttons.get(level_number) as Button

func get_level_center(level_number: int) -> Vector2:
	return _centers.get(level_number, Vector2.ZERO) as Vector2

func get_level_state(level_number: int) -> String:
	return String(_level_states.get(level_number, "locked"))

func get_frontier_level() -> int:
	return _frontier_level

func _bind_authored_route() -> void:
	custom_minimum_size = Vector2(route_width, 1500.0)
	size = custom_minimum_size
	_level_buttons.clear()
	_level_labels.clear()
	_centers.clear()
	_level_states.clear()

	_frontier_focus = get_node_or_null("FrontierFocus") as TextureRect
	_frontier_label = get_node_or_null("FrontierFocusLabel") as Label
	if _frontier_focus != null:
		_frontier_focus.texture = PieceAssetLoader.ornament(FRONTIER_ART_PATH)

	for level_number in range(1, visible_route_levels + 1):
		var button := get_node_or_null("Level%d" % level_number) as Button
		var label := get_node_or_null("Label%d" % level_number) as Label
		if button == null or label == null:
			push_error("S03 authored route slot missing for level %d." % level_number)
			continue
		button.tooltip_text = _tooltip_for(level_number)
		button.pressed.connect(_request.bind(level_number))
		_level_buttons[level_number] = button
		_level_labels[level_number] = label
		_centers[level_number] = button.position + button.size * 0.5

	for level_number in RELIC_ART_PATHS:
		var art := get_node_or_null("RelicArt%d" % int(level_number)) as TextureRect
		if art != null:
			art.texture = PieceAssetLoader.ornament(String(RELIC_ART_PATHS[level_number]))

	queue_redraw()

func route_authored_contract() -> Dictionary:
	var raster_relics_loaded := true
	for level_number in RELIC_ART_PATHS:
		var path := String(RELIC_ART_PATHS[level_number])
		var art := get_node_or_null("RelicArt%d" % int(level_number)) as TextureRect
		raster_relics_loaded = raster_relics_loaded and (path.ends_with(".webp") or path.ends_with(".png")) and art != null and art.texture != null
	var opening_labels_readable := true
	for level_number in [1, 2, 3]:
		var label := _level_labels.get(level_number) as Label
		var plate := label.get_theme_stylebox("normal") if label != null else null
		opening_labels_readable = opening_labels_readable and label != null and label.get_theme_font_size("font_size") >= 25 and plate is StyleBoxFlat and (plate as StyleBoxFlat).bg_color.a >= 0.9
	var frontier_plate := _frontier_label.get_theme_stylebox("normal") if _frontier_label != null else null
	return {
		"authored_level_slots": _level_buttons.size() == visible_route_levels and _level_labels.size() == visible_route_levels,
		"authored_frontier_slots": _frontier_focus != null and _frontier_label != null,
		"frontier_raster_loaded": FRONTIER_ART_PATH.ends_with(".webp") and _frontier_focus != null and _frontier_focus.texture != null,
		"raster_relics_loaded": raster_relics_loaded,
		"opening_label_readability": opening_labels_readable,
		"frontier_label_readability": _frontier_label != null and _frontier_label.get_theme_font_size("font_size") >= 20 and frontier_plate is StyleBoxFlat,
		"runtime_node_factory": false,
		"asset_backed_level_chrome": _level_buttons.values().all(func(button): return button is Button and (button as Button).get_theme_stylebox("normal") is StyleBoxTexture and bool((button as Button).get_meta("production_route_chrome", false))),
		"runtime_flat_node_factory": false,
		"runtime_route_vfx_allowed": true,
	}

func _request(level_number: int) -> void:
	if level_number <= canonical_level_cap and (progress == null or level_number <= int(progress.highest_level_unlocked)):
		level_requested.emit(level_number)
		return
	var kind := "future_content" if level_number > canonical_level_cap else "progression_locked"
	sealed_level_requested.emit(level_number, kind)

func _refresh() -> void:
	if not is_node_ready() or _level_buttons.is_empty():
		return
	_frontier_level = _resolve_frontier_level()
	_level_states.clear()
	for raw_level in _level_buttons:
		var level_number := int(raw_level)
		var button := _level_buttons[level_number] as Button
		var label := _level_labels[level_number] as Label
		var level_id := "ch01_level_%03d" % level_number
		var completed: bool = progress != null and progress.completed_levels.has(level_id)
		var open: bool = level_number <= canonical_level_cap and (progress == null or level_number <= int(progress.highest_level_unlocked))
		var state := "locked"
		if completed:
			state = "completed"
		elif level_number == _frontier_level:
			state = "current"
		elif open:
			state = "available"
		_level_states[level_number] = state
		button.set_meta("level_state", state)
		button.set_meta("sealed_kind", "" if open else ("future_content" if level_number > canonical_level_cap else "progression_locked"))
		button.disabled = false
		button.text = "✓" if completed else str(level_number)
		button.tooltip_text = _tooltip_for(level_number)
		label.text = _caption(level_number, completed)
		_apply_node_style(button, state)
	_update_frontier_focus()
	queue_redraw()

func _resolve_frontier_level() -> int:
	if canonical_level_cap <= 0:
		return -1
	for level_number in range(1, canonical_level_cap + 1):
		var level_id := "ch01_level_%03d" % level_number
		var completed: bool = progress != null and bool(progress.completed_levels.has(level_id))
		var open: bool = progress == null or level_number <= int(progress.highest_level_unlocked)
		if open and not completed:
			return level_number
	return -1

func _update_frontier_focus() -> void:
	if _frontier_focus == null or _frontier_label == null:
		return
	var visible := _frontier_level > 0 and _centers.has(_frontier_level)
	_frontier_focus.visible = visible
	_frontier_label.visible = visible
	if not visible:
		return
	var center: Vector2 = _centers[_frontier_level]
	var diameter := 160.0 if _frontier_level == 1 else 148.0
	var icon_center := center + Vector2(diameter * 0.48, -diameter * 0.48)
	_frontier_focus.position = icon_center - _frontier_focus.size * 0.5
	_frontier_label.position = Vector2(center.x - _frontier_label.size.x * 0.5, center.y - diameter * 0.5 - 52.0)
	move_child(_frontier_focus, get_child_count() - 1)
	move_child(_frontier_label, get_child_count() - 1)

func _tooltip_for(level_number: int) -> String:
	match level_number:
		1: return "Moonlit Cabinet · Moon Cameo"
		2: return "Sealed Display · Wax Seals · Moth Reliquary"
		3: return "Thornlight Arrangement · Line Sigil · Thorned Locket"
		_: return "Upper cabinet %d · sealed for later" % level_number

func _caption(level_number: int, completed: bool) -> String:
	if level_number == 1:
		return "MOONLIT CABINET\n%s" % ("MOON CAMEO AWAKENED" if completed else "MOON CAMEO WAITS")
	if level_number == 2:
		return "SEALED DISPLAY\n%s" % ("MOTH RELIQUARY RECOVERED" if completed else "BREAK THE WAX SEALS")
	if level_number == 3:
		return "THORNLIGHT\n%s" % ("THORNED LOCKET RECOVERED" if completed else "FORM A MOON BEAM")
	return ""

func _apply_node_style(button: Button, state: String) -> void:
	var level_number := int(button.name.trim_prefix("Level"))
	var open := state in ["current", "available", "completed"]
	ProductionChrome.apply_interactive_button(button, state == "current", "chapter_route_node")
	var normal := button.get_theme_stylebox("normal")
	var hover := button.get_theme_stylebox("hover")
	if normal is StyleBoxTexture:
		var normal_style := (normal as StyleBoxTexture).duplicate() as StyleBoxTexture
		normal_style.modulate_color = _route_node_tint(level_number, state, false)
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("pressed", normal_style)
		button.add_theme_stylebox_override("disabled", normal_style)
	if hover is StyleBoxTexture:
		var hover_style := (hover as StyleBoxTexture).duplicate() as StyleBoxTexture
		hover_style.modulate_color = _route_node_tint(level_number, state, true)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("focus", hover_style)
	button.set_meta("production_route_chrome", true)
	button.add_theme_color_override("font_color", Color("#FFF4D8") if state == "current" else (BONE if open else Color("#9A8D9E")))
	button.add_theme_color_override("font_disabled_color", Color("#776D7B"))
	button.add_theme_font_size_override("font_size", 48 if state == "current" else (46 if level_number == 1 else (40 if level_number <= 3 else 15)))

func _route_node_tint(level_number: int, state: String, hover: bool) -> Color:
	var tint := Color(0.42, 0.36, 0.46, 0.66) if level_number <= 3 else Color(0.28, 0.24, 0.31, 0.54)
	match state:
		"completed":
			tint = Color(0.88, 0.72, 0.52, 0.94)
		"current":
			tint = Color(1.0, 0.94, 0.76, 1.0)
		"available":
			tint = Color(0.78, 0.68, 0.86, 0.90)
	if hover and state in ["current", "available", "completed"]:
		tint = tint.lightened(0.10)
	return tint

func _draw() -> void:
	# S03 owns route STRUCTURE only. Environment imagery belongs to the
	# chapter_route/environment slot and must be authored art, never a
	# procedurally illustrated cabinet/moon/room in this Control.
	var content := Rect2(Vector2.ZERO, size)
	var environment := ScreenArt.texture("chapter_route_curio_boutique")
	if environment != null:
		draw_texture_rect(environment, content, false)
	else:
		# Missing authored art must stay obvious; never reconstruct the world
		# with procedural illustration or an SVG fallback.
		draw_rect(content, Color("#090711"), true)
	draw_rect(content, Color("#090711", 0.20), true)

	# Opening route: live component geometry over authored environment art.
	for level_number in range(1, 3):
		var a := get_level_center(level_number)
		var b := get_level_center(level_number + 1)
		draw_line(a, b, Color("#160F1B", 0.88), 12.0, true)
		draw_line(a, b, Color(GOLD, 0.74), 4.0, true)
		for step in [0.33, 0.66]:
			var p := a.lerp(b, float(step))
			draw_circle(p, 12.0, Color("#130D18", 0.94))
			draw_arc(p, 12.0, 0.0, TAU, 24, Color(GOLD, 0.72), 2.0)
			draw_circle(p, 3.0, Color("#F1D8A2"))

	# Authored frontier marker owns semantic identity; these rings are runtime
	# focus VFX only and never substitute for the state asset.
	if _frontier_level > 0 and _centers.has(_frontier_level):
		var frontier_center: Vector2 = _centers[_frontier_level]
		var frontier_radius := 92.0 if _frontier_level == 1 else 86.0
		draw_circle(frontier_center, frontier_radius + 12.0, Color("#D8B56A", 0.09))
		draw_arc(frontier_center, frontier_radius + 8.0, 0.0, TAU, 48, Color("#F2D49A", 0.82), 4.0)
		draw_arc(frontier_center, frontier_radius + 18.0, 0.0, TAU, 48, Color("#BFA5D8", 0.34), 2.0)

	# Future levels remain visibly connected but subordinate to the opening
	# three-level journey. Their lock/state styling is owned by live buttons.
	var future_hub := Vector2(route_width * 0.50, 385.0)
	draw_line(get_level_center(3), future_hub, Color(GOLD, 0.24), 2.0, true)
	draw_circle(future_hub, 8.0, Color("#130D18", 0.90))
	draw_arc(future_hub, 8.0, 0.0, TAU, 18, Color(GOLD, 0.38), 1.5)
	for level_number in range(4, visible_route_levels + 1):
		draw_line(future_hub, get_level_center(level_number), Color(LILAC, 0.11), 1.2, true)
