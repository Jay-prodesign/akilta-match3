class_name Match3BoardView
extends Control

signal swap_requested(from: Vector2i, to: Vector2i)

const PieceVisuals = preload("res://src/match3/presentation/piece_visuals.gd")

const INK := Color("#100D12")
const VELVET := Color("#17131B")
const PLUM := Color("#241A27")
const GLASS := Color("#2E2432")
const BONE := Color("#F1E8DD")
const GOLD := Color("#D8B56A")

@export var cell_gap: float = 8.0
@export var swipe_threshold: float = 24.0

var board_state
var _press_position := Vector2.ZERO
var _pressed_cell := Vector2i(-1, -1)
var _tracking := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	queue_redraw()

func set_board(board) -> void:
	board_state = board
	queue_redraw()

func visual_contract() -> Dictionary:
	return PieceVisuals.contract()

func _gui_input(event: InputEvent) -> void:
	if board_state == null:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_pointer(event.position)
		else:
			_finish_pointer(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_pointer(event.position)
		else:
			_finish_pointer(event.position)
		accept_event()

func _begin_pointer(position: Vector2) -> void:
	_press_position = position
	_pressed_cell = cell_at_local(position)
	_tracking = _pressed_cell.x >= 0

func _finish_pointer(position: Vector2) -> void:
	if not _tracking:
		return
	_tracking = false
	var delta := position - _press_position
	if delta.length() < swipe_threshold:
		return
	var step := Vector2i.ZERO
	if abs(delta.x) > abs(delta.y):
		step = Vector2i(1 if delta.x > 0.0 else -1, 0)
	else:
		step = Vector2i(0, 1 if delta.y > 0.0 else -1)
	var target := _pressed_cell + step
	if board_state.in_bounds(target) and not board_state.is_hole(target):
		swap_requested.emit(_pressed_cell, target)

func cell_at_local(position: Vector2) -> Vector2i:
	if board_state == null:
		return Vector2i(-1, -1)
	var geometry := _board_geometry()
	var origin: Vector2 = geometry["origin"]
	var cell_size: float = geometry["cell_size"]
	var pitch := cell_size + cell_gap
	var local := position - origin
	if local.x < 0.0 or local.y < 0.0:
		return Vector2i(-1, -1)
	var x := int(floor(local.x / pitch))
	var y := int(floor(local.y / pitch))
	var pos := Vector2i(x, y)
	if not board_state.in_bounds(pos):
		return Vector2i(-1, -1)
	return pos

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK, true)
	if board_state == null:
		_draw_empty_state()
		return
	var geometry := _board_geometry()
	var origin: Vector2 = geometry["origin"]
	var cell_size: float = geometry["cell_size"]
	var pitch := cell_size + cell_gap

	for y in range(board_state.height):
		for x in range(board_state.width):
			var pos := Vector2i(x, y)
			if board_state.is_hole(pos):
				continue
			var rect := Rect2(origin + Vector2(x, y) * pitch, Vector2.ONE * cell_size)
			_draw_cell(rect, pos)

func _draw_empty_state() -> void:
	var center := size * 0.5
	draw_circle(center, min(size.x, size.y) * 0.12, PLUM)
	draw_arc(center, min(size.x, size.y) * 0.08, 0.0, TAU, 48, Color("#BFA5D8"), 4.0)

func _board_geometry() -> Dictionary:
	if board_state == null or board_state.width <= 0 or board_state.height <= 0:
		return {"origin": Vector2.ZERO, "cell_size": 1.0}
	var available := Vector2(max(1.0, size.x - 28.0), max(1.0, size.y - 28.0))
	var by_width := (available.x - cell_gap * float(board_state.width - 1)) / float(board_state.width)
	var by_height := (available.y - cell_gap * float(board_state.height - 1)) / float(board_state.height)
	var cell_size := max(8.0, min(by_width, by_height))
	var total := Vector2(
		cell_size * board_state.width + cell_gap * (board_state.width - 1),
		cell_size * board_state.height + cell_gap * (board_state.height - 1)
	)
	return {"origin": (size - total) * 0.5, "cell_size": cell_size}

func _draw_cell(rect: Rect2, pos: Vector2i) -> void:
	var radius := rect.size.x * 0.18
	draw_style_box(_cell_box(radius), rect)
	var inset := rect.grow(-rect.size.x * 0.10)
	var family: String = String(board_state.get_cell(pos))
	var descriptor: Dictionary = PieceVisuals.descriptor(family)
	_draw_piece(inset, family, descriptor)

	var special: String = String(board_state.get_special(pos))
	if special != "":
		_draw_special_mark(rect, special)

	var blocker: Dictionary = board_state.get_blocker(pos)
	if not blocker.is_empty():
		_draw_wax_seal(rect, int(blocker.get("hp", 1)))

func _cell_box(radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = GLASS
	box.border_color = Color(1.0, 1.0, 1.0, 0.055)
	box.set_border_width_all(1)
	box.set_corner_radius_all(int(radius))
	return box

func _draw_piece(rect: Rect2, family: String, descriptor: Dictionary) -> void:
	if descriptor.is_empty():
		return
	var color: Color = descriptor["color"]
	var c := rect.get_center()
	var r: float = minf(rect.size.x, rect.size.y) * 0.38

	match family:
		"moon":
			draw_circle(c, r, color)
			draw_circle(c + Vector2(r * 0.34, -r * 0.12), r * 0.86, GLASS)
			draw_circle(c + Vector2(-r * 0.15, r * 0.05), r * 0.10, BONE)
		"rose":
			var points := PackedVector2Array()
			for i in range(8):
				var angle := TAU * float(i) / 8.0 - PI * 0.5
				var rr: float = r if i % 2 == 0 else r * 0.72
				points.append(c + Vector2(cos(angle), sin(angle)) * rr)
			draw_colored_polygon(points, color)
			draw_arc(c, r * 0.43, 0.0, TAU * 1.6, 32, BONE, max(1.5, r * 0.08))
		"moth":
			draw_circle(c, r * 0.16, BONE)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.10, -r * 0.12),
				c + Vector2(-r, -r * 0.52),
				c + Vector2(-r * 0.72, r * 0.58),
				c + Vector2(-r * 0.08, r * 0.18)
			]), color)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(r * 0.10, -r * 0.12),
				c + Vector2(r, -r * 0.52),
				c + Vector2(r * 0.72, r * 0.58),
				c + Vector2(r * 0.08, r * 0.18)
			]), color)
			draw_circle(c + Vector2(-r * 0.52, -r * 0.04), r * 0.12, INK)
			draw_circle(c + Vector2(r * 0.52, -r * 0.04), r * 0.12, INK)
		"key":
			draw_arc(c + Vector2(0, -r * 0.34), r * 0.30, 0.0, TAU, 32, color, r * 0.18)
			draw_line(c + Vector2(0, -r * 0.04), c + Vector2(0, r * 0.76), color, r * 0.18)
			draw_line(c + Vector2(0, r * 0.52), c + Vector2(r * 0.34, r * 0.52), color, r * 0.14)
			draw_line(c + Vector2(0, r * 0.70), c + Vector2(r * 0.24, r * 0.70), color, r * 0.14)
		"leaf":
			var leaf := PackedVector2Array([
				c + Vector2(0, -r),
				c + Vector2(r * 0.82, -r * 0.10),
				c + Vector2(0, r),
				c + Vector2(-r * 0.82, -r * 0.10)
			])
			draw_colored_polygon(leaf, color)
			draw_line(c + Vector2(0, -r * 0.72), c + Vector2(0, r * 0.70), BONE, max(1.5, r * 0.07))

func _draw_special_mark(rect: Rect2, kind: String) -> void:
	var c := rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.22)
	var r := rect.size.x * 0.10
	draw_circle(c, r * 1.5, INK)
	draw_arc(c, r, 0.0, TAU, 24, GOLD, max(2.0, r * 0.33))
	if kind == "line_h":
		draw_line(c + Vector2(-r * 0.7, 0), c + Vector2(r * 0.7, 0), GOLD, 2.0)
	elif kind == "line_v":
		draw_line(c + Vector2(0, -r * 0.7), c + Vector2(0, r * 0.7), GOLD, 2.0)

func _draw_wax_seal(rect: Rect2, hp: int) -> void:
	var c := rect.position + Vector2(rect.size.x * 0.22, rect.size.y * 0.78)
	var r := rect.size.x * 0.12
	draw_circle(c, r * 1.15, Color("#7D3048"))
	draw_circle(c, r * 0.68, Color("#C7728F"))
	for i in range(max(1, hp)):
		var y := c.y + (float(i) - float(hp - 1) * 0.5) * 4.0
		draw_line(Vector2(c.x - r * 0.38, y), Vector2(c.x + r * 0.38, y), INK, 1.5)
