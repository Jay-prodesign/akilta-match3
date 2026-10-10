class_name Match3BoardView
extends Control

signal swap_requested(from: Vector2i, to: Vector2i)

const PieceVisuals = preload("res://src/match3/presentation/piece_visuals.gd")

const INK := Color("#100D12")
const VELVET := Color("#17131B")
const PLUM := Color("#241A27")
const GLASS := Color("#2E2432")
const RAISED := Color("#382C3D")
const BONE := Color("#F1E8DD")
const MIST := Color("#D9CDD5")
const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")

@export var cell_gap: float = 8.0
@export var board_frame_padding: float = 14.0
@export var swipe_threshold: float = 24.0

var board_state
var _press_position := Vector2.ZERO
var _pressed_cell := Vector2i(-1, -1)
var _tracking := false
var _feedback_strength: float = 0.0
var _feedback_mode: String = ""
var _feedback_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	queue_redraw()

func set_board(board) -> void:
	board_state = board
	queue_redraw()

func visual_contract() -> Dictionary:
	return PieceVisuals.contract()

func play_trace(trace) -> void:
	if trace == null:
		return
	var types: Array[String] = trace.event_types()
	if types.has("combo_triggered"):
		_pulse_feedback("combo", 0.72, 0.44)
	elif types.has("special_created") or types.has("special_triggered"):
		_pulse_feedback("special", 0.52, 0.34)
	elif bool(trace.accepted):
		_pulse_feedback("match", 0.26, 0.24)
	else:
		_pulse_feedback("reject", 0.32, 0.18)

func _pulse_feedback(mode: String, strength: float, duration: float) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_mode = mode
	_feedback_strength = strength
	queue_redraw()
	_feedback_tween = create_tween()
	_feedback_tween.set_trans(Tween.TRANS_QUAD)
	_feedback_tween.set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_method(_set_feedback_strength, strength, 0.0, duration)

func _set_feedback_strength(value: float) -> void:
	_feedback_strength = value
	queue_redraw()

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
	var board_size := Vector2(
		cell_size * board_state.width + cell_gap * (board_state.width - 1),
		cell_size * board_state.height + cell_gap * (board_state.height - 1)
	)
	_draw_board_frame(Rect2(origin, board_size).grow(board_frame_padding))

	for y in range(board_state.height):
		for x in range(board_state.width):
			var pos := Vector2i(x, y)
			if board_state.is_hole(pos):
				continue
			var rect := Rect2(origin + Vector2(x, y) * pitch, Vector2.ONE * cell_size)
			_draw_cell(rect, pos)

	_draw_feedback()

func _draw_feedback() -> void:
	if _feedback_strength <= 0.001:
		return
	var color := Color("#BFA5D8")
	if _feedback_mode == "combo":
		color = Color("#D8B56A")
	elif _feedback_mode == "reject":
		color = Color("#C7728F")
	elif _feedback_mode == "match":
		color = Color("#A9C6C8")
	color.a = 0.12 * _feedback_strength
	draw_rect(Rect2(Vector2.ZERO, size), color, true)
	var edge := color
	edge.a = 0.9 * _feedback_strength
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), edge, false, 2.0 + 5.0 * _feedback_strength)
	if _feedback_mode == "combo" or _feedback_mode == "special":
		var center := size * 0.5
		draw_arc(center, minf(size.x, size.y) * (0.10 + 0.05 * _feedback_strength), 0.0, TAU, 48, edge, 2.0 + 3.0 * _feedback_strength)

func _draw_empty_state() -> void:
	var center := size * 0.5
	draw_circle(center, min(size.x, size.y) * 0.12, PLUM)
	draw_arc(center, min(size.x, size.y) * 0.08, 0.0, TAU, 48, Color("#BFA5D8"), 4.0)

func _board_geometry() -> Dictionary:
	if board_state == null or board_state.width <= 0 or board_state.height <= 0:
		return {"origin": Vector2.ZERO, "cell_size": 1.0}
	var available: Vector2 = Vector2(maxf(1.0, size.x - 28.0), maxf(1.0, size.y - 28.0))
	var by_width: float = (available.x - cell_gap * float(board_state.width - 1)) / float(board_state.width)
	var by_height: float = (available.y - cell_gap * float(board_state.height - 1)) / float(board_state.height)
	var cell_size: float = maxf(8.0, minf(by_width, by_height))
	var total: Vector2 = Vector2(
		cell_size * board_state.width + cell_gap * (board_state.width - 1),
		cell_size * board_state.height + cell_gap * (board_state.height - 1)
	)
	var origin_x := (size.x - total.x) * 0.5
	var origin_y := maxf(8.0, (size.y - total.y) * 0.18)
	return {"origin": Vector2(origin_x, origin_y), "cell_size": cell_size}

func _draw_board_frame(rect: Rect2) -> void:
	var shadow := rect.grow(7.0)
	draw_rect(shadow, Color(0.02, 0.015, 0.025, 0.72), true)
	draw_rect(rect, Color("#18131C"), true)
	var outer := Color(GOLD)
	outer.a = 0.34
	draw_rect(rect, outer, false, 2.0)
	var inner := Color(LILAC)
	inner.a = 0.13
	draw_rect(rect.grow(-5.0), inner, false, 1.0)
	var mark_color := Color(GOLD)
	mark_color.a = 0.5
	var mark := minf(rect.size.x, rect.size.y) * 0.035
	for corner in [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		Vector2(rect.position.x, rect.end.y),
		rect.end
	]:
		var sx: float = 1.0 if corner.x == rect.position.x else -1.0
		var sy: float = 1.0 if corner.y == rect.position.y else -1.0
		draw_line(corner, corner + Vector2(mark * sx, 0), mark_color, 2.0)
		draw_line(corner, corner + Vector2(0, mark * sy), mark_color, 2.0)

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
	var glow := Color(color)
	glow.a = 0.10
	draw_circle(c, r * 1.12, glow)

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
				c + Vector2(r * 0.68, -r * 0.28),
				c + Vector2(r * 0.50, r * 0.34),
				c + Vector2(0, r),
				c + Vector2(-r * 0.50, r * 0.34),
				c + Vector2(-r * 0.68, -r * 0.28)
			])
			draw_colored_polygon(leaf, color)
			draw_line(c + Vector2(0, -r * 0.72), c + Vector2(0, r * 0.72), BONE, max(1.5, r * 0.07))
			draw_line(c + Vector2(0, -r * 0.10), c + Vector2(r * 0.34, -r * 0.34), BONE, max(1.0, r * 0.045))
			draw_line(c + Vector2(0, r * 0.12), c + Vector2(-r * 0.32, r * 0.34), BONE, max(1.0, r * 0.045))

func _draw_special_mark(rect: Rect2, kind: String) -> void:
	var center := rect.get_center()
	var full_r := rect.size.x * 0.39
	var halo := Color(GOLD)
	halo.a = 0.20
	if kind == "global":
		draw_circle(center, full_r * 1.04, halo, false, max(2.0, rect.size.x * 0.035))
		draw_arc(center, full_r * 0.88, 0.0, TAU, 40, GOLD, max(2.0, rect.size.x * 0.025))
		for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
			var direction := Vector2(cos(angle), sin(angle))
			draw_line(center + direction * full_r * 0.88, center + direction * full_r * 1.16, GOLD, max(2.0, rect.size.x * 0.025))
		return
	if kind == "line_h":
		draw_line(center + Vector2(-full_r, 0), center + Vector2(full_r, 0), GOLD, max(3.0, rect.size.x * 0.055))
		draw_line(center + Vector2(-full_r, -rect.size.y * 0.08), center + Vector2(full_r, -rect.size.y * 0.08), Color(1,1,1,0.35), 1.5)
		return
	if kind == "line_v":
		draw_line(center + Vector2(0, -full_r), center + Vector2(0, full_r), GOLD, max(3.0, rect.size.x * 0.055))
		draw_line(center + Vector2(rect.size.x * 0.08, -full_r), center + Vector2(rect.size.x * 0.08, full_r), Color(1,1,1,0.35), 1.5)
		return
	if kind == "area":
		draw_arc(center, full_r * 0.74, 0.0, TAU, 32, GOLD, max(2.0, rect.size.x * 0.035))
		for angle in [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]:
			var direction := Vector2(cos(angle), sin(angle))
			draw_line(center + direction * full_r * 0.40, center + direction * full_r * 0.96, GOLD, 2.0)
		return
	if kind == "smart":
		draw_arc(center, full_r * 0.70, PI * 0.10, PI * 0.90, 24, GOLD, 2.5)
		draw_arc(center, full_r * 0.70, PI * 1.10, PI * 1.90, 24, GOLD, 2.5)
		draw_circle(center, full_r * 0.15, GOLD)

func _draw_wax_seal(rect: Rect2, hp: int) -> void:
	var c := rect.position + Vector2(rect.size.x * 0.22, rect.size.y * 0.78)
	var r := rect.size.x * 0.12
	draw_circle(c, r * 1.15, Color("#7D3048"))
	draw_circle(c, r * 0.68, Color("#C7728F"))
	for i in range(max(1, hp)):
		var y := c.y + (float(i) - float(hp - 1) * 0.5) * 4.0
		draw_line(Vector2(c.x - r * 0.38, y), Vector2(c.x + r * 0.38, y), INK, 1.5)
