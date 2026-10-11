class_name Match3ChapterRouteView
extends Control

signal level_requested(level_number: int)

const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")
const BONE := Color("#F1E8DD")
const PLUM := Color("#241A27")

@export var canonical_level_cap: int = 1
@export var visible_route_levels: int = 10
@export var route_width: float = 460.0
@export var top_margin: float = 120.0
@export var bottom_margin: float = 92.0

var progress
var _level_buttons: Dictionary = {}
var _level_labels: Dictionary = {}
var _centers: Dictionary = {}

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

func _build_route() -> void:
	for child in get_children():
		child.queue_free()
	_level_buttons.clear()
	_level_labels.clear()
	_centers.clear()

	var content_height := 820.0
	custom_minimum_size = Vector2(route_width, content_height)
	size = custom_minimum_size

	var future_caption := Label.new()
	future_caption.name = "FutureCabinetsCaption"
	future_caption.position = Vector2(70.0, 28.0)
	future_caption.size = Vector2(route_width - 140.0, 34.0)
	future_caption.text = "UPPER CABINETS · SEALED FOR LATER"
	future_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	future_caption.add_theme_font_size_override("font_size", 14)
	future_caption.add_theme_color_override("font_color", Color("#A993AE"))
	add_child(future_caption)

	for level_number in range(1, visible_route_levels + 1):
		var center := _center_for(level_number, content_height)
		_centers[level_number] = center

		var button := Button.new()
		button.name = "Level%d" % level_number
		var diameter := 108.0 if level_number == 1 else (100.0 if level_number <= 3 else 36.0)
		button.position = center - Vector2.ONE * diameter * 0.5
		button.size = Vector2.ONE * diameter
		button.focus_mode = Control.FOCUS_ALL
		button.tooltip_text = _tooltip_for(level_number)
		button.pressed.connect(func(n := level_number): _request(n))
		add_child(button)
		_level_buttons[level_number] = button

		var label := Label.new()
		label.name = "Label%d" % level_number
		label.size = Vector2(156.0, 64.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 17 if level_number == 1 else 15)
		label.add_theme_color_override("font_color", BONE if level_number == 1 else Color("#D7CAD9"))
		label.visible = level_number <= 3
		var on_right := center.x < route_width * 0.50
		if on_right:
			label.position = Vector2(center.x + diameter * 0.60, center.y - 32.0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			label.position = Vector2(center.x - diameter * 0.60 - label.size.x, center.y - 32.0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(label)
		_level_labels[level_number] = label

	queue_redraw()

func _center_for(level_number: int, content_height: float) -> Vector2:
	var base_y := content_height - bottom_margin
	match level_number:
		1:
			return Vector2(route_width * 0.50, base_y)
		2:
			return Vector2(route_width * 0.36, base_y - 165.0)
		3:
			return Vector2(route_width * 0.63, base_y - 330.0)
		_:
			# Future Levels 4–10 remain present for progression contracts, but read as
			# one sealed upper-cabinet cluster rather than a second competing journey.
			var future_index := level_number - 4
			if future_index < 4:
				return Vector2(117.5 + float(future_index) * 75.0, 126.0)
			return Vector2(140.0 + float(future_index - 4) * 90.0, 182.0)

func _request(level_number: int) -> void:
	if level_number <= canonical_level_cap and (progress == null or level_number <= int(progress.highest_level_unlocked)):
		level_requested.emit(level_number)

func _refresh() -> void:
	if not is_node_ready() or _level_buttons.is_empty():
		return
	for raw_level in _level_buttons:
		var level_number := int(raw_level)
		var button := _level_buttons[level_number] as Button
		var label := _level_labels[level_number] as Label
		var level_id := "ch01_level_%03d" % level_number
		var completed: bool = progress != null and progress.completed_levels.has(level_id)
		var open: bool = level_number <= canonical_level_cap and (progress == null or level_number <= int(progress.highest_level_unlocked))
		button.disabled = not open
		button.text = "✓" if completed else str(level_number)
		button.tooltip_text = _tooltip_for(level_number)
		label.text = _caption(level_number, completed)
		_apply_node_style(button, completed, open)
	queue_redraw()

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

func _apply_node_style(button: Button, completed: bool, open: bool) -> void:
	var box := StyleBoxFlat.new()
	var level_number := int(button.name.trim_prefix("Level"))
	var radius := 54 if level_number == 1 else (50 if level_number <= 3 else 18)
	box.set_corner_radius_all(radius)
	box.set_border_width_all(3 if level_number <= 3 else 1)
	box.shadow_color = Color(0, 0, 0, 0.46)
	box.shadow_size = 12 if open else 4
	if completed:
		box.bg_color = Color("#3B2742")
		box.border_color = GOLD
	elif open:
		box.bg_color = Color("#2E2036")
		box.border_color = LILAC
	elif level_number <= 3:
		box.bg_color = Color("#251B2B")
		box.border_color = Color("#7F6C88")
	else:
		box.bg_color = Color("#17131B")
		box.border_color = Color("#584B60")
	button.add_theme_stylebox_override("normal", box)
	var hover_style := box.duplicate() as StyleBoxFlat
	hover_style.border_color = Color("#F4D995") if open else box.border_color
	hover_style.shadow_size = 16 if open else 4
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_stylebox_override("disabled", box)
	button.add_theme_color_override("font_color", BONE if open else Color("#B8A8BC"))
	button.add_theme_color_override("font_disabled_color", Color("#8D7F93"))
	button.add_theme_font_size_override("font_size", 34 if level_number == 1 else (29 if level_number <= 3 else 11))

func _draw() -> void:
	var content := Rect2(Vector2.ZERO, size)
	draw_rect(content, Color("#0D0A10"), true)

	var wall := Rect2(18.0, 22.0, maxf(0.0, size.x - 36.0), maxf(0.0, size.y - 44.0))
	draw_rect(wall, Color("#151019"), true)
	draw_rect(wall, Color(GOLD, 0.15), false, 2.0)

	var future_zone := Rect2(54.0, 72.0, size.x - 108.0, 150.0)
	draw_rect(future_zone, Color("#110E15", 0.72), true)
	draw_rect(future_zone, Color(LILAC, 0.13), false, 1.2)

	var moon_center := Vector2(size.x * 0.50, 150.0)
	draw_circle(moon_center, 46.0, Color(LILAC, 0.055))
	draw_arc(moon_center, 35.0, 0.0, TAU, 42, Color(GOLD, 0.20), 1.5)

	# The authored opening path gets the visual weight. Future content is a compact
	# sealed cluster, not seven more equally important steps.
	for level_number in range(1, 3):
		var a := get_level_center(level_number)
		var b := get_level_center(level_number + 1)
		draw_line(a, b, Color(GOLD, 0.46), 4.0, true)
		var p := a.lerp(b, 0.5)
		draw_circle(p, 8.0, PLUM)
		draw_arc(p, 8.0, 0.0, TAU, 18, Color(GOLD, 0.52), 1.2)

	var future_hub := Vector2(route_width * 0.50, 238.0)
	draw_line(get_level_center(3), future_hub, Color(GOLD, 0.16), 1.8, true)
	draw_circle(future_hub, 7.0, PLUM)
	draw_arc(future_hub, 7.0, 0.0, TAU, 18, Color(GOLD, 0.30), 1.2)
	for level_number in range(4, visible_route_levels + 1):
		draw_line(future_hub, get_level_center(level_number), Color(LILAC, 0.075), 1.0, true)

	for level_number in range(1, 4):
		var center := get_level_center(level_number)
		var alcove := Rect2(center.x - 170.0, center.y - 70.0, 340.0, 140.0)
		draw_rect(alcove, Color("#1C141F", 0.42), true)
		draw_rect(alcove, Color(GOLD, 0.12 if level_number > 1 else 0.20), false, 1.3)

	var first_center := get_level_center(1)
	var threshold := Rect2(size.x * 0.29, first_center.y + 82.0, size.x * 0.42, 30.0)
	draw_rect(threshold, Color("#211725"), true)
	draw_line(threshold.position, threshold.position + Vector2(threshold.size.x, 0), Color(GOLD, 0.30), 1.7)
