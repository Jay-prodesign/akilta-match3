class_name Match3ChapterRouteView
extends Control

signal level_requested(level_number: int)

const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")
const BONE := Color("#F1E8DD")
const MIST := Color("#D9CDD5")
const VELVET := Color("#17131B")
const PLUM := Color("#241A27")
const INK := Color("#100D12")

@export var canonical_level_cap: int = 1
@export var visible_route_levels: int = 10
@export var route_width: float = 960.0
@export var vertical_spacing: float = 126.0
@export var top_margin: float = 150.0
@export var bottom_margin: float = 155.0

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

	var content_height := top_margin + bottom_margin + float(max(0, visible_route_levels - 1)) * vertical_spacing
	custom_minimum_size = Vector2(route_width, content_height)
	size = custom_minimum_size

	for level_number in range(1, visible_route_levels + 1):
		var center := _center_for(level_number, content_height)
		_centers[level_number] = center

		var button := Button.new()
		button.name = "Level%d" % level_number
		var diameter := 122.0 if level_number == 1 else (112.0 if level_number <= 3 else 88.0)
		button.position = center - Vector2.ONE * diameter * 0.5
		button.size = Vector2.ONE * diameter
		button.focus_mode = Control.FOCUS_ALL
		button.tooltip_text = _tooltip_for(level_number)
		button.pressed.connect(func(n := level_number): _request(n))
		add_child(button)
		_level_buttons[level_number] = button

		var label := Label.new()
		label.name = "Label%d" % level_number
		label.size = Vector2(270.0, 64.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 26 if level_number == 1 else (22 if level_number <= 3 else 20))
		label.add_theme_color_override("font_color", BONE if level_number == 1 else Color("#D2C4D7"))
		var on_right := center.x < route_width * 0.5
		if on_right:
			label.position = Vector2(center.x + diameter * 0.58, center.y - 32.0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			label.position = Vector2(center.x - diameter * 0.58 - label.size.x, center.y - 32.0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(label)
		_level_labels[level_number] = label

	queue_redraw()

func _center_for(level_number: int, content_height: float) -> Vector2:
	var index := float(level_number - 1)
	var wave := sin(index * 1.24) * 92.0
	var x := route_width * 0.5 + wave
	var y := content_height - bottom_margin - index * vertical_spacing
	return Vector2(x, y)

func _request(level_number: int) -> void:
	if level_number <= canonical_level_cap:
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
		var open: bool = level_number <= canonical_level_cap
		button.disabled = not open
		button.text = "✓" if completed else str(level_number)
		button.tooltip_text = _tooltip_for(level_number)
		label.text = _caption(level_number, completed, open)
		_apply_node_style(button, completed, open)
	queue_redraw()

func _tooltip_for(level_number: int) -> String:
	match level_number:
		1: return "Moonlit Cabinet · Moon Cameo"
		2: return "Sealed Display · Wax Seals"
		3: return "Thornlight Arrangement · Line Sigil"
		_: return "Sealed display · Level %d" % level_number

func _caption(level_number: int, completed: bool, open: bool) -> String:
	if level_number == 1:
		return "MOONLIT CABINET\n%s" % ("MOON CAMEO AWAKENED" if completed else "MOON CAMEO WAITS")
	if level_number == 2:
		return "SEALED DISPLAY\nWAX SEALS · LOCKED"
	if level_number == 3:
		return "THORNLIGHT\nLINE SIGIL · LOCKED"
	if not open:
		return "SEALED DISPLAY %02d" % level_number
	return "DISPLAY %02d · READY" % level_number

func _apply_node_style(button: Button, completed: bool, open: bool) -> void:
	var box := StyleBoxFlat.new()
	var level_number := int(button.name.trim_prefix("Level"))
	var radius := 61 if level_number == 1 else (53 if level_number <= 3 else 44)
	box.set_corner_radius_all(radius)
	box.set_border_width_all(3 if open else 2)
	box.shadow_color = Color(0, 0, 0, 0.42)
	box.shadow_size = 10 if open else 6
	if completed:
		box.bg_color = Color("#34223D")
		box.border_color = GOLD
	elif open:
		box.bg_color = Color("#2A1C32")
		box.border_color = LILAC
	else:
		box.bg_color = Color("#302538")
		box.border_color = Color("#9A83A0")
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", box)
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_stylebox_override("disabled", box)
	button.add_theme_color_override("font_color", BONE if open else Color("#D2C4D7"))
	button.add_theme_color_override("font_disabled_color", Color("#B6A6B9"))
	button.add_theme_font_size_override("font_size", 40 if button.name == "Level1" else (32 if int(button.name.trim_prefix("Level")) <= 3 else 27))

func _draw() -> void:
	var content := Rect2(Vector2.ZERO, size)
	draw_rect(content, Color("#0E0B11"), true)

	# Long cabinet architecture: world context behind the interaction layer.
	var wall := Rect2(22.0, 26.0, maxf(0.0, size.x - 44.0), maxf(0.0, size.y - 52.0))
	draw_rect(wall, Color("#151019"), true)
	var wall_line := Color(GOLD)
	wall_line.a = 0.14
	draw_rect(wall, wall_line, false, 2.0)

	# Moon window crowns the sealed route.
	var moon_center := Vector2(size.x * 0.50, 82.0)
	var moon_glow := Color(LILAC)
	moon_glow.a = 0.13
	draw_circle(moon_center, 58.0, moon_glow)
	draw_arc(moon_center, 44.0, 0.0, TAU, 48, Color(GOLD, 0.34), 2.0)
	draw_line(moon_center + Vector2(-38, 0), moon_center + Vector2(38, 0), Color(GOLD, 0.12), 1.0)
	draw_line(moon_center + Vector2(0, -38), moon_center + Vector2(0, 38), Color(GOLD, 0.12), 1.0)

	# Route rises from the House threshold through all ten numbered displays.
	var route_points := PackedVector2Array()
	for level_number in range(1, visible_route_levels + 1):
		route_points.append(get_level_center(level_number))
	var route_color := Color(GOLD)
	route_color.a = 0.28
	if route_points.size() > 1:
		draw_polyline(route_points, route_color, 4.0, true)

	# House-native route seals replace generic three-star/candy-map shorthand.
	for level_number in range(1, visible_route_levels):
		var a := get_level_center(level_number)
		var b := get_level_center(level_number + 1)
		var p := a.lerp(b, 0.5)
		draw_circle(p, 9.0, PLUM)
		draw_arc(p, 9.0, 0.0, TAU, 20, Color(GOLD, 0.46), 2.0)
		draw_line(p + Vector2(-4.5, 0), p + Vector2(4.5, 0), Color(GOLD, 0.34), 1.2)
		draw_line(p + Vector2(0, -4.5), p + Vector2(0, 4.5), Color(GOLD, 0.34), 1.2)

	# Narrow shelf/alcove hints prevent the scroll from feeling like an empty list.
	for shelf_index in range(5):
		var y := 220.0 + float(shelf_index) * 250.0
		var left := Rect2(42.0, y, 82.0, 44.0)
		var right := Rect2(size.x - 124.0, y + 92.0, 82.0, 44.0)
		draw_rect(left, Color("#201624"), true)
		draw_rect(right, Color("#201624"), true)
		draw_line(left.position + Vector2(0, left.size.y), left.end, Color(GOLD, 0.15), 1.5)
		draw_line(right.position + Vector2(0, right.size.y), right.end, Color(GOLD, 0.15), 1.5)

	# Entry threshold anchors Level 1 to the House below.
	var first_center := get_level_center(1)
	var threshold := Rect2(size.x * 0.35, first_center.y + 90.0, size.x * 0.30, 38.0)
	draw_rect(threshold, Color("#211725"), true)
	draw_line(threshold.position, threshold.position + Vector2(threshold.size.x, 0), Color(GOLD, 0.30), 2.0)
