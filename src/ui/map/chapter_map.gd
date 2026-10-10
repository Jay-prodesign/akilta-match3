class_name Match3ChapterMap
extends Control

signal back_requested
signal level_requested(level_number: int)

@export var canonical_level_cap: int = 1
@export var visible_route_levels: int = 10

@onready var chapter_progress: Label = $Layout/Progress
@onready var scroll: ScrollContainer = $Layout/RoutePanel/Scroll
@onready var route_content: Control = $Layout/RoutePanel/Scroll/RouteContent
@onready var back_button: Button = $Layout/Back

var progress
var _level_buttons: Dictionary = {}
var _route_line: Line2D

func _ready() -> void:
	back_button.pressed.connect(func(): back_requested.emit())
	_build_route()
	_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func get_level_button(level_number: int) -> Button:
	return _level_buttons.get(level_number) as Button

func _build_route() -> void:
	for child in route_content.get_children():
		child.queue_free()
	_level_buttons.clear()

	_route_line = Line2D.new()
	_route_line.name = "RouteLine"
	_route_line.width = 4.0
	_route_line.default_color = Color(0.851, 0.71, 0.416, 0.34)
	_route_line.antialiased = true
	route_content.add_child(_route_line)

	var points := PackedVector2Array()
	var content_height := 180.0 + float(visible_route_levels - 1) * 126.0
	route_content.custom_minimum_size = Vector2(450.0, content_height + 120.0)
	route_content.size = route_content.custom_minimum_size

	for level_number in range(1, visible_route_levels + 1):
		var x := 225.0 + sin(float(level_number - 1) * 1.28) * 105.0
		var y := 110.0 + float(level_number - 1) * 126.0
		var center := Vector2(x, y)
		points.append(center)

		var button := Button.new()
		button.name = "Level%d" % level_number
		button.position = center - Vector2(55.0, 44.0)
		button.size = Vector2(110.0, 88.0)
		button.add_theme_font_size_override("font_size", 26)
		button.add_theme_color_override("font_color", Color("#F1E8DD"))
		button.add_theme_color_override("font_disabled_color", Color(0.49, 0.44, 0.52, 0.55))
		button.add_theme_stylebox_override("normal", _node_style(false, false))
		button.add_theme_stylebox_override("hover", _node_style(false, true))
		button.add_theme_stylebox_override("disabled", _node_style(true, false))
		button.pressed.connect(func(n := level_number): _request_level(n))
		route_content.add_child(button)
		_level_buttons[level_number] = button

	_route_line.points = points
	call_deferred("_focus_frontier")

func _node_style(disabled: bool, hover: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#17131B") if disabled else (Color("#35273C") if hover else Color("#2B2030"))
	box.border_color = Color(0.749, 0.647, 0.847, 0.24) if disabled else Color(0.851, 0.71, 0.416, 0.78)
	box.set_border_width_all(1 if disabled else 2)
	box.set_corner_radius_all(42)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 8
	return box

func _refresh() -> void:
	if not is_node_ready() or _level_buttons.is_empty():
		return
	var completed: int = int(progress.completed_levels.size()) if progress != null else 0
	chapter_progress.text = "CURIO BOUTIQUE · %d AWAKENING%s" % [completed, "" if completed == 1 else "S"]
	for level_number in _level_buttons:
		_configure_button(_level_buttons[level_number], int(level_number))

func _configure_button(button: Button, level_number: int) -> void:
	var level_id := "ch01_level_%03d" % level_number
	var completed: bool = progress != null and progress.completed_levels.has(level_id)
	var within_gate: bool = level_number <= canonical_level_cap
	button.disabled = not within_gate
	button.text = "✓ %d" % level_number if completed else str(level_number)
	if completed and level_number == 1:
		button.tooltip_text = "MOON CAMEO · AWAKENED"
	elif level_number == 1:
		button.tooltip_text = "LEVEL 1 · MOON CAMEO"
	else:
		button.tooltip_text = "SEALED · FUTURE LEVEL"

func _request_level(level_number: int) -> void:
	if level_number <= canonical_level_cap:
		level_requested.emit(level_number)

func _focus_frontier() -> void:
	if scroll != null:
		scroll.scroll_vertical = 0
