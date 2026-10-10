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

@onready var level1: Button = $Level1
@onready var level2: Button = $Level2
@onready var level3: Button = $Level3
@onready var label1: Label = $Label1
@onready var label2: Label = $Label2
@onready var label3: Label = $Label3

var progress
var canonical_level_cap: int = 1

func _ready() -> void:
	resized.connect(_layout_nodes)
	level1.pressed.connect(func(): _request(1))
	level2.pressed.connect(func(): _request(2))
	level3.pressed.connect(func(): _request(3))
	_layout_nodes()
	_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func set_canonical_level_cap(value: int) -> void:
	canonical_level_cap = max(1, value)
	_refresh()

func _request(level_number: int) -> void:
	if level_number <= canonical_level_cap:
		level_requested.emit(level_number)

func _node_centers() -> Array[Vector2]:
	return [
		Vector2(size.x * 0.33, size.y * 0.73),
		Vector2(size.x * 0.69, size.y * 0.51),
		Vector2(size.x * 0.40, size.y * 0.27),
	]

func _layout_nodes() -> void:
	if not is_node_ready():
		return
	var centers := _node_centers()
	var buttons: Array[Button] = [level1, level2, level3]
	var labels: Array[Label] = [label1, label2, label3]
	for i in range(3):
		var button_size := Vector2(126.0, 126.0) if i == 0 else Vector2(104.0, 104.0)
		buttons[i].size = button_size
		buttons[i].position = centers[i] - button_size * 0.5
		var label_size := Vector2(350.0, 58.0)
		labels[i].size = label_size
		var x := centers[i].x + (82.0 if i != 1 else -432.0)
		labels[i].position = Vector2(x, centers[i].y - 29.0)
	queue_redraw()

func _refresh() -> void:
	if not is_node_ready():
		return
	for i in range(3):
		var level_number := i + 1
		var button: Button = [level1, level2, level3][i]
		var label: Label = [label1, label2, label3][i]
		var level_id := "ch01_level_%03d" % level_number
		var completed: bool = progress != null and progress.completed_levels.has(level_id)
		var open: bool = level_number <= canonical_level_cap
		button.disabled = not open
		button.text = str(level_number)
		label.text = _caption(level_number, completed, open)
		_apply_node_style(button, completed, open)
	queue_redraw()

func _caption(level_number: int, completed: bool, open: bool) -> String:
	if level_number == 1:
		return "MOONLIT CABINET\n%s" % ("AWAKENED" if completed else "MOON CAMEO WAITS")
	if not open:
		return "SEALED DISPLAY\nTHE HOUSE KEEPS ITS SECRET"
	return "DISPLAY %02d\nREADY" % level_number

func _apply_node_style(button: Button, completed: bool, open: bool) -> void:
	var box := StyleBoxFlat.new()
	box.corner_radius_top_left = 63
	box.corner_radius_top_right = 63
	box.corner_radius_bottom_left = 63
	box.corner_radius_bottom_right = 63
	box.border_width_left = 3
	box.border_width_top = 3
	box.border_width_right = 3
	box.border_width_bottom = 3
	if completed:
		box.bg_color = Color("#33213D")
		box.border_color = GOLD
	elif open:
		box.bg_color = Color("#2A1C32")
		box.border_color = LILAC
	else:
		box.bg_color = Color("#151218")
		box.border_color = Color(0.45, 0.40, 0.48, 0.32)
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("disabled", box)
	button.add_theme_color_override("font_color", BONE if open else Color(0.55,0.51,0.57,1))
	button.add_theme_color_override("font_disabled_color", Color(0.55,0.51,0.57,1))
	button.add_theme_font_size_override("font_size", 34 if open else 28)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0E0B11"), true)

	# Cabinet-like architectural silhouette makes the map feel like a room/world,
	# while route and node state remain the only interaction authority.
	var arch := Rect2(size.x * 0.08, size.y * 0.06, size.x * 0.84, size.y * 0.86)
	draw_rect(arch, Color("#151019"), true)
	var arch_line := Color(GOLD); arch_line.a = 0.18
	draw_rect(arch, arch_line, false, 2.0)
	draw_arc(Vector2(size.x * 0.50, size.y * 0.16), size.x * 0.34, PI, TAU, 64, arch_line, 3.0)

	# Moon/window cue: world flavor only, deliberately not a gameplay piece.
	var moon_center := Vector2(size.x * 0.50, size.y * 0.13)
	var moon := Color(LILAC); moon.a = 0.16
	draw_circle(moon_center, 54.0, moon)
	draw_arc(moon_center, 42.0, 0.0, TAU, 48, Color(GOLD, 0.35), 2.0)

	var centers := _node_centers()
	var route_points: PackedVector2Array = PackedVector2Array()
	for segment in range(2):
		var a: Vector2 = centers[segment]
		var b: Vector2 = centers[segment + 1]
		var control := Vector2((a.x + b.x) * 0.5 + (80.0 if segment == 0 else -70.0), (a.y + b.y) * 0.5)
		for step in range(21):
			var t := float(step) / 20.0
			var p := a * pow(1.0 - t, 2.0) + control * 2.0 * (1.0 - t) * t + b * t * t
			route_points.append(p)
	var route_color := Color(GOLD); route_color.a = 0.24
	if route_points.size() > 1:
		draw_polyline(route_points, route_color, 4.0, true)

	# Small occult route seals replace generic map stars.
	for p in [Vector2(size.x*0.50,size.y*0.63), Vector2(size.x*0.58,size.y*0.39)]:
		draw_circle(p, 10.0, Color("#241A27"))
		draw_arc(p, 10.0, 0.0, TAU, 20, Color(GOLD,0.46), 2.0)
		draw_line(p + Vector2(-5,0), p + Vector2(5,0), Color(GOLD,0.40), 1.5)
		draw_line(p + Vector2(0,-5), p + Vector2(0,5), Color(GOLD,0.40), 1.5)

	# Entry threshold at the bottom.
	var threshold := Rect2(size.x*0.36, size.y*0.86, size.x*0.28, 46.0)
	draw_rect(threshold, Color("#211725"), true)
	draw_line(threshold.position, threshold.position + Vector2(threshold.size.x,0), Color(GOLD,0.32), 2.0)
