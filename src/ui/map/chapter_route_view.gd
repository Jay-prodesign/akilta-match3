class_name Match3ChapterRouteView
extends Control

signal level_requested(level_number: int)
signal locked_level_requested(level_number: int)

const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")
const BONE := Color("#F1E8DD")
const PLUM := Color("#241A27")
const CYAN := Color("#9BBED0")
const ROSE := Color("#C98BA8")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")

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
var _lock_inspectors: Dictionary = {}
var _frontier_level: int = -1
var _frontier_focus: TextureRect
var _frontier_label: Label

func _ready() -> void:
	_build_route()
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

func get_level_lock_inspector(level_number: int) -> Button:
	return _lock_inspectors.get(level_number) as Button

func get_level_state(level_number: int) -> String:
	return String(_level_states.get(level_number, "locked"))

func get_frontier_level() -> int:
	return _frontier_level

func _build_route() -> void:
	for child in get_children():
		child.queue_free()
	_level_buttons.clear()
	_level_labels.clear()
	_centers.clear()
	_level_states.clear()
	_lock_inspectors.clear()

	var content_height := 1500.0
	custom_minimum_size = Vector2(route_width, content_height)
	size = custom_minimum_size

	var future_caption := Label.new()
	future_caption.name = "FutureCabinetsCaption"
	future_caption.position = Vector2(route_width * 0.12, 24.0)
	future_caption.size = Vector2(route_width * 0.76, 44.0)
	future_caption.text = "UPPER CABINETS · SEALED FOR LATER"
	future_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	future_caption.add_theme_font_size_override("font_size", 19)
	future_caption.add_theme_color_override("font_color", Color("#D7B9D8"))
	future_caption.add_theme_color_override("font_outline_color", Color("#090711", 0.92))
	future_caption.add_theme_constant_override("outline_size", 3)
	add_child(future_caption)

	_frontier_focus = TextureRect.new()
	_frontier_focus.name = "FrontierFocus"
	_frontier_focus.texture = PieceAssetLoader.ornament("res://assets/pieces/moon_sigil.svg")
	_frontier_focus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frontier_focus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_frontier_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frontier_focus.size = Vector2(72, 72)
	_frontier_focus.modulate = Color(1.0, 0.94, 0.78, 1.0)
	_frontier_focus.visible = false
	add_child(_frontier_focus)

	_frontier_label = Label.new()
	_frontier_label.name = "FrontierFocusLabel"
	_frontier_label.text = "CURRENT RITUAL"
	_frontier_label.size = Vector2(190, 38)
	_frontier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frontier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_frontier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frontier_label.add_theme_font_size_override("font_size", 18)
	_frontier_label.add_theme_color_override("font_color", Color("#FFF0B8"))
	_frontier_label.add_theme_color_override("font_outline_color", Color("#080710", 0.96))
	_frontier_label.add_theme_constant_override("outline_size", 4)
	_frontier_label.visible = false
	add_child(_frontier_label)

	for level_number in range(1, visible_route_levels + 1):
		var center := _center_for(level_number, content_height)
		_centers[level_number] = center

		var button := Button.new()
		button.name = "Level%d" % level_number
		var diameter := 160.0 if level_number == 1 else (148.0 if level_number <= 3 else 52.0)
		button.position = center - Vector2.ONE * diameter * 0.5
		button.size = Vector2.ONE * diameter
		button.focus_mode = Control.FOCUS_ALL
		button.tooltip_text = _tooltip_for(level_number)
		button.pressed.connect(func(n := level_number): _request(n))
		add_child(button)
		_level_buttons[level_number] = button

		var inspector := Button.new()
		inspector.name = "LockedInfo%d" % level_number
		var hit_diameter := maxf(diameter, 72.0)
		inspector.position = center - Vector2.ONE * hit_diameter * 0.5
		inspector.size = Vector2.ONE * hit_diameter
		inspector.text = ""
		inspector.tooltip_text = "Why is cabinet %d sealed?" % level_number
		inspector.focus_mode = Control.FOCUS_ALL
		inspector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var inspect_normal := StyleBoxFlat.new()
		inspect_normal.bg_color = Color(0, 0, 0, 0)
		inspect_normal.border_color = Color(0, 0, 0, 0)
		inspect_normal.set_corner_radius_all(int(hit_diameter * 0.5))
		var inspect_hover := inspect_normal.duplicate() as StyleBoxFlat
		inspect_hover.bg_color = Color("#A68CAB", 0.08)
		inspect_hover.border_color = Color("#D5AD70", 0.42)
		inspect_hover.set_border_width_all(2)
		inspector.add_theme_stylebox_override("normal", inspect_normal)
		inspector.add_theme_stylebox_override("hover", inspect_hover)
		inspector.add_theme_stylebox_override("pressed", inspect_hover)
		inspector.add_theme_stylebox_override("focus", inspect_hover)
		inspector.pressed.connect(func(n := level_number): locked_level_requested.emit(n))
		add_child(inspector)
		_lock_inspectors[level_number] = inspector

		var label := Label.new()
		label.name = "Label%d" % level_number
		label.size = Vector2(280.0, 88.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 25 if level_number == 1 else 23)
		label.add_theme_color_override("font_color", BONE if level_number == 1 else Color("#E0D2E2"))
		label.add_theme_color_override("font_outline_color", Color("#07060B", 0.94))
		label.add_theme_constant_override("outline_size", 3)
		var label_plate := StyleBoxFlat.new()
		label_plate.bg_color = Color("#100B16", 0.82)
		label_plate.border_color = Color(GOLD, 0.30)
		label_plate.set_border_width_all(1)
		label_plate.set_corner_radius_all(10)
		label_plate.content_margin_left = 12
		label_plate.content_margin_right = 12
		label.add_theme_stylebox_override("normal", label_plate)
		label.visible = level_number <= 3
		var on_right := center.x < route_width * 0.50
		if on_right:
			label.position = Vector2(center.x + diameter * 0.60, center.y - 44.0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			label.position = Vector2(center.x - diameter * 0.60 - label.size.x, center.y - 44.0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(label)
		_level_labels[level_number] = label
		if level_number <= 3:
			_add_relic_art(level_number, center, diameter, on_right)

	queue_redraw()

func _center_for(level_number: int, content_height: float) -> Vector2:
	var base_y := content_height - bottom_margin
	match level_number:
		1:
			return Vector2(route_width * 0.50, base_y)
		2:
			return Vector2(route_width * 0.34, base_y - 370.0)
		3:
			return Vector2(route_width * 0.66, base_y - 720.0)
		_:
			# Future Levels 4–10 stay visible as one compact sealed cabinet cluster.
			var future_index := level_number - 4
			if future_index < 4:
				return Vector2(route_width * (0.20 + float(future_index) * 0.20), 158.0)
			return Vector2(route_width * (0.30 + float(future_index - 4) * 0.20), 250.0)

func _add_relic_art(level_number: int, center: Vector2, diameter: float, label_on_right: bool) -> void:
	var paths := {
		1: "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg",
		2: "res://assets/curios/ch01_curio_moth_reliquary.svg",
		3: "res://assets/curios/ch01_curio_thorned_locket.svg",
	}
	var art := TextureRect.new()
	art.name = "RelicArt%d" % level_number
	art.texture = PieceAssetLoader.ornament(String(paths.get(level_number, "")))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(108, 108)
	art.size = Vector2(108, 108)
	var side := -1.0 if label_on_right else 1.0
	art.position = center + Vector2(side * (diameter * 0.5 + 82.0), -54.0) - Vector2(54, 0)
	art.modulate = Color(1, 1, 1, 0.94)
	add_child(art)
	move_child(art, max(0, get_child_count() - 3))

func _request(level_number: int) -> void:
	if level_number <= canonical_level_cap and (progress == null or level_number <= int(progress.highest_level_unlocked)):
		level_requested.emit(level_number)

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
		button.disabled = not open
		var inspector := _lock_inspectors.get(level_number) as Button
		if inspector != null:
			inspector.visible = not open
			inspector.disabled = open
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
	var box := StyleBoxFlat.new()
	var level_number := int(button.name.trim_prefix("Level"))
	var radius := 80 if level_number == 1 else (74 if level_number <= 3 else 26)
	var open := state in ["current", "available", "completed"]
	box.set_corner_radius_all(radius)
	box.set_border_width_all(5 if state == "current" else (4 if level_number <= 3 else 1))
	box.shadow_color = Color(0, 0, 0, 0.52)
	box.shadow_size = 24 if state == "current" else (18 if open else 5)
	match state:
		"completed":
			box.bg_color = Color("#3B2742")
			box.border_color = GOLD
		"current":
			box.bg_color = Color("#33203D")
			box.border_color = Color("#F6DA92")
		"available":
			box.bg_color = Color("#2E2036")
			box.border_color = LILAC
		_:
			if level_number <= 3:
				box.bg_color = Color("#1D1722")
				box.border_color = Color("#65596D")
			else:
				box.bg_color = Color("#151218")
				box.border_color = Color("#4E4355")
	button.add_theme_stylebox_override("normal", box)
	var hover_style := box.duplicate() as StyleBoxFlat
	hover_style.border_color = Color("#FFF0B8") if open else box.border_color
	hover_style.shadow_size = 28 if state == "current" else (22 if open else 5)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_stylebox_override("disabled", box)
	button.add_theme_color_override("font_color", Color("#FFF4D8") if state == "current" else (BONE if open else Color("#9A8D9E")))
	button.add_theme_color_override("font_disabled_color", Color("#776D7B"))
	button.add_theme_font_size_override("font_size", 48 if state == "current" else (46 if level_number == 1 else (40 if level_number <= 3 else 15)))

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
