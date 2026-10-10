class_name Match3BoardView
extends Control

signal swap_requested(from: Vector2i, to: Vector2i)
signal trace_motion_finished

const PieceVisuals = preload("res://src/match3/presentation/piece_visuals.gd")
const KENNEY_FRAME = preload("res://assets/candidate/third_party/kenney/fantasy-ui-borders/frame-024.png")

const INK := Color("#100D12")
const VELVET := Color("#17131B")
const PLUM := Color("#241A27")
const GLASS := Color("#2E2432")
const RAISED := Color("#382C3D")
const BONE := Color("#F1E8DD")
const MIST := Color("#D9CDD5")
const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")

# Timings are an AKILTA-owned trace-driven adaptation of the permissive donor's
# animator-hook idea. The donor runtime and demo art are not dependencies.
const MOTION_PROFILE := {
	"source": "sempitern0/match3-board@11945ef6db1703ba3043b1d93563514930e2ab37",
	"license": "MIT",
	"adaptation": "trace_driven_owned_renderer",
	"total_duration": 0.82,
	"swap_end": 0.22,
	"clear_start": 0.14,
	"clear_end": 0.42,
	"gravity_start": 0.36,
	"gravity_end": 0.76,
	"spawn_start": 0.48,
	"spawn_end": 0.90
}

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
var _motion_tween: Tween
var _motion_clock: float = 1.0
var _motion_active: bool = false
var _motion_items: Array[Dictionary] = []
var _reveal_at: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	queue_redraw()

func set_board(board) -> void:
	board_state = board
	queue_redraw()

func visual_contract() -> Dictionary:
	return PieceVisuals.contract()

func motion_contract() -> Dictionary:
	return MOTION_PROFILE.duplicate(true)

func is_motion_active() -> bool:
	return _motion_active

func play_trace(trace) -> bool:
	if trace == null:
		return false
	var types: Array[String] = trace.event_types()
	if types.has("combo_triggered"):
		_pulse_feedback("combo", 0.72, 0.44)
	elif types.has("special_created") or types.has("special_triggered"):
		_pulse_feedback("special", 0.52, 0.34)
	elif bool(trace.accepted):
		_pulse_feedback("match", 0.26, 0.24)
	else:
		_pulse_feedback("reject", 0.32, 0.18)

	_build_motion(trace)
	if _motion_items.is_empty():
		return false
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_active = true
	_motion_clock = 0.0
	queue_redraw()
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_QUAD)
	_motion_tween.set_ease(Tween.EASE_OUT)
	_motion_tween.tween_method(_set_motion_clock, 0.0, 1.0, float(MOTION_PROFILE["total_duration"]))
	_motion_tween.finished.connect(_finish_motion)
	return true

func _build_motion(trace) -> void:
	_motion_items.clear()
	_reveal_at.clear()
	for event in trace.events:
		var event_type := String(event.get("type", ""))
		match event_type:
			"swap_accepted":
				var from := _parse_pos(event.get("from", ""))
				var to := _parse_pos(event.get("to", ""))
				var from_family := String(event.get("from_family", ""))
				var to_family := String(event.get("to_family", ""))
				if from_family != "":
					_motion_items.append({"type": "swap", "family": from_family, "from": from, "to": to})
				if to_family != "":
					_motion_items.append({"type": "swap", "family": to_family, "from": to, "to": from})
				_remember_reveal(from, float(MOTION_PROFILE["swap_end"]))
				_remember_reveal(to, float(MOTION_PROFILE["swap_end"]))
			"swap_rejected":
				var reject_from := _parse_pos(event.get("from", ""))
				var reject_to := _parse_pos(event.get("to", ""))
				var reject_from_family := String(event.get("from_family", ""))
				var reject_to_family := String(event.get("to_family", ""))
				if reject_from_family != "":
					_motion_items.append({"type": "reject_swap", "family": reject_from_family, "from": reject_from, "to": reject_to})
				if reject_to_family != "":
					_motion_items.append({"type": "reject_swap", "family": reject_to_family, "from": reject_to, "to": reject_from})
				_remember_reveal(reject_from, 0.30)
				_remember_reveal(reject_to, 0.30)
			"clear", "combo_clear":
				for piece in event.get("pieces", []):
					if not piece is Dictionary:
						continue
					var clear_pos := _parse_pos(piece.get("at", ""))
					var clear_family := String(piece.get("family", ""))
					if clear_family != "":
						_motion_items.append({"type": "clear", "family": clear_family, "at": clear_pos})
					_remember_reveal(clear_pos, 0.58)
			"special_triggered":
				_motion_items.append({
					"type": "special",
					"kind": String(event.get("kind", "")),
					"at": _parse_pos(event.get("at", ""))
				})
			"special_created":
				var created_pos := _parse_pos(event.get("at", ""))
				_motion_items.append({
					"type": "special_created",
					"kind": String(event.get("kind", "")),
					"at": created_pos
				})
				_remember_reveal(created_pos, 0.54)
			"combo_triggered":
				_motion_items.append({
					"type": "combo",
					"at": _parse_pos(event.get("to", ""))
				})
			"gravity":
				var gravity_to := _parse_pos(event.get("to", ""))
				var gravity_family := String(event.get("family", ""))
				if gravity_family != "":
					_motion_items.append({
						"type": "gravity",
						"family": gravity_family,
						"from": _parse_pos(event.get("from", "")),
						"to": gravity_to
					})
				_remember_reveal(gravity_to, float(MOTION_PROFILE["gravity_end"]))
			"spawn":
				var spawn_pos := _parse_pos(event.get("at", ""))
				var spawn_family := String(event.get("family", ""))
				if spawn_family != "":
					_motion_items.append({"type": "spawn", "family": spawn_family, "at": spawn_pos})
				_remember_reveal(spawn_pos, float(MOTION_PROFILE["spawn_end"]))
			"blocker_damaged", "blocker_cleared":
				_motion_items.append({
					"type": "blocker",
					"cleared": event_type == "blocker_cleared",
					"at": _parse_pos(event.get("at", ""))
				})
			"shuffle":
				_motion_items.append({"type": "shuffle"})
			_:
				pass

func _remember_reveal(pos: Vector2i, at_clock: float) -> void:
	if pos.x < 0:
		return
	_reveal_at[pos] = maxf(float(_reveal_at.get(pos, 0.0)), at_clock)

func _set_motion_clock(value: float) -> void:
	_motion_clock = value
	queue_redraw()

func _finish_motion() -> void:
	_motion_clock = 1.0
	_motion_active = false
	_motion_items.clear()
	_reveal_at.clear()
	queue_redraw()
	trace_motion_finished.emit()

func _parse_pos(value) -> Vector2i:
	var parts := String(value).split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))

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
	if board_state == null or _motion_active:
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
	_draw_motion()

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

	# CC0 frame geometry is used only as a candidate ornamental primitive;
	# Curio House color/material identity remains owned by this renderer.
	var ornament_tint := Color(GOLD)
	ornament_tint.a = 0.42
	draw_texture_rect(KENNEY_FRAME, rect.grow(10.0), false, ornament_tint)

func _draw_cell(rect: Rect2, pos: Vector2i) -> void:
	var radius := rect.size.x * 0.18
	draw_style_box(_cell_box(radius), rect)
	var inner := rect.grow(-rect.size.x * 0.055)
	var inner_line := Color(LILAC)
	inner_line.a = 0.07
	draw_rect(inner, inner_line, false, 1.0)
	var inset := rect.grow(-rect.size.x * 0.13)
	var family: String = String(board_state.get_cell(pos))
	var descriptor: Dictionary = PieceVisuals.descriptor(family)
	var reveal_clock := float(_reveal_at.get(pos, 0.0))
	var show_final := not _motion_active or _motion_clock >= reveal_clock
	if show_final:
		_draw_piece(inset, family, descriptor)

		var special: String = String(board_state.get_special(pos))
		if special != "":
			_draw_special_mark(rect, special)

		var blocker: Dictionary = board_state.get_blocker(pos)
		if not blocker.is_empty():
			_draw_wax_seal(rect, int(blocker.get("hp", 1)))

func _cell_box(radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#2A2230")
	box.border_color = Color(0.851, 0.71, 0.416, 0.12)
	box.set_border_width_all(1)
	box.set_corner_radius_all(int(maxf(6.0, radius * 0.52)))
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
			draw_circle(c + Vector2(r * 0.34, -r * 0.12), r * 0.86, Color("#2A2230"))
			draw_arc(c + Vector2(-r * 0.06, 0), r * 0.72, PI * 0.58, PI * 1.43, 28, Color(1,1,1,0.18), max(1.0, r * 0.05))
			draw_circle(c + Vector2(-r * 0.15, r * 0.05), r * 0.10, BONE)
		"rose":
			var points := PackedVector2Array()
			for i in range(8):
				var angle := TAU * float(i) / 8.0 - PI * 0.5
				var rr: float = r if i % 2 == 0 else r * 0.72
				points.append(c + Vector2(cos(angle), sin(angle)) * rr)
			draw_colored_polygon(points, color)
			draw_circle(c, r * 0.55, Color(color, 0.15), false, max(1.0, r * 0.05))
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
			draw_arc(c, r * 0.82, PI * 1.06, PI * 1.94, 18, Color(1,1,1,0.16), max(1.0, r * 0.04))
		"key":
			draw_circle(c + Vector2(0, -r * 0.34), r * 0.42, Color(color, 0.10))
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
			draw_arc(c, r * 0.84, PI * 0.78, PI * 1.26, 16, Color(1,1,1,0.12), max(1.0, r * 0.035))
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


func _phase_progress(start_clock: float, end_clock: float) -> float:
	if end_clock <= start_clock:
		return 1.0
	return clampf((_motion_clock - start_clock) / (end_clock - start_clock), 0.0, 1.0)

func _cell_center(pos: Vector2i) -> Vector2:
	var geometry := _board_geometry()
	var origin: Vector2 = geometry["origin"]
	var cell_size: float = geometry["cell_size"]
	var pitch := cell_size + cell_gap
	return origin + Vector2(pos.x, pos.y) * pitch + Vector2.ONE * cell_size * 0.5

func _piece_rect(center: Vector2, scale_factor: float = 1.0) -> Rect2:
	var cell_size: float = float(_board_geometry()["cell_size"])
	var piece_size := cell_size * 0.74 * scale_factor
	return Rect2(center - Vector2.ONE * piece_size * 0.5, Vector2.ONE * piece_size)

func _draw_motion() -> void:
	if not _motion_active or board_state == null:
		return
	for item in _motion_items:
		var kind := String(item.get("type", ""))
		match kind:
			"swap":
				var p := _phase_progress(0.0, float(MOTION_PROFILE["swap_end"]))
				if p >= 1.0:
					continue
				var start := _cell_center(item["from"])
				var finish := _cell_center(item["to"])
				var eased := 1.0 - pow(1.0 - p, 2.0)
				var center := start.lerp(finish, eased)
				var family := String(item["family"])
				_draw_motion_piece(center, family, 1.0 + sin(p * PI) * 0.05)
			"reject_swap":
				var rp := _phase_progress(0.0, 0.30)
				if rp >= 1.0:
					continue
				var rstart := _cell_center(item["from"])
				var rfinish := _cell_center(item["to"])
				var direction := rfinish - rstart
				var center := rstart + direction * (0.26 * sin(rp * PI))
				_draw_motion_piece(center, String(item["family"]), 1.0)
			"clear":
				var cp := _phase_progress(float(MOTION_PROFILE["clear_start"]), float(MOTION_PROFILE["clear_end"]))
				if cp <= 0.0 or cp >= 1.0:
					continue
				var ccenter := _cell_center(item["at"])
				_draw_motion_piece(ccenter, String(item["family"]), maxf(0.16, 1.0 - cp * 0.88))
				var clear_color := Color(GOLD)
				clear_color.a = 0.55 * (1.0 - cp)
				draw_arc(ccenter, float(_board_geometry()["cell_size"]) * (0.18 + cp * 0.34), 0.0, TAU, 28, clear_color, 2.0)
			"gravity":
				var gp := _phase_progress(float(MOTION_PROFILE["gravity_start"]), float(MOTION_PROFILE["gravity_end"]))
				if gp <= 0.0 or gp >= 1.0:
					continue
				var gstart := _cell_center(item["from"])
				var gfinish := _cell_center(item["to"])
				var geased := 1.0 - pow(1.0 - gp, 3.0)
				_draw_motion_piece(gstart.lerp(gfinish, geased), String(item["family"]), 1.0)
			"spawn":
				var sp := _phase_progress(float(MOTION_PROFILE["spawn_start"]), float(MOTION_PROFILE["spawn_end"]))
				if sp <= 0.0 or sp >= 1.0:
					continue
				var target := _cell_center(item["at"])
				var geometry := _board_geometry()
				var start_y := float(geometry["origin"].y) - float(geometry["cell_size"]) * 1.25
				var spawn_start := Vector2(target.x, start_y)
				var seased := 1.0 - pow(1.0 - sp, 3.0)
				_draw_motion_piece(spawn_start.lerp(target, seased), String(item["family"]), 0.82 + 0.18 * seased)
			"special":
				_draw_special_motion(item)
			"special_created":
				var create_p := _phase_progress(0.34, 0.62)
				if create_p > 0.0 and create_p < 1.0:
					var create_center := _cell_center(item["at"])
					var create_color := Color(GOLD)
					create_color.a = 0.80 * sin(create_p * PI)
					draw_arc(create_center, float(_board_geometry()["cell_size"]) * (0.16 + create_p * 0.34), 0.0, TAU, 36, create_color, 3.0)
			"combo":
				var combo_p := _phase_progress(0.08, 0.50)
				if combo_p > 0.0 and combo_p < 1.0:
					var combo_center := _cell_center(item["at"])
					var combo_color := Color(LILAC)
					combo_color.a = 0.70 * sin(combo_p * PI)
					for ring in range(3):
						draw_arc(combo_center, float(_board_geometry()["cell_size"]) * (0.22 + combo_p * (0.30 + ring * 0.12)), 0.0, TAU, 40, combo_color, 2.0)
			"blocker":
				var bp := _phase_progress(0.18, 0.48)
				if bp > 0.0 and bp < 1.0:
					var bcenter := _cell_center(item["at"])
					var wax := Color("#C7728F")
					wax.a = 0.78 * (1.0 - bp)
					draw_arc(bcenter, float(_board_geometry()["cell_size"]) * (0.20 + bp * 0.30), 0.0, TAU, 28, wax, 3.0)
			"shuffle":
				var shuffle_p := _phase_progress(0.0, 0.62)
				if shuffle_p > 0.0 and shuffle_p < 1.0:
					var frame := Rect2(Vector2.ZERO, size).grow(-14.0)
					var shuffle_color := Color(LILAC)
					shuffle_color.a = 0.34 * sin(shuffle_p * PI)
					draw_rect(frame, shuffle_color, false, 4.0)
			_:
				pass

func _draw_motion_piece(center: Vector2, family: String, scale_factor: float) -> void:
	var descriptor := PieceVisuals.descriptor(family)
	if descriptor.is_empty():
		return
	var glow := Color(descriptor["color"])
	glow.a = 0.16
	draw_circle(center, float(_board_geometry()["cell_size"]) * 0.34 * scale_factor, glow)
	_draw_piece(_piece_rect(center, scale_factor), family, descriptor)

func _draw_special_motion(item: Dictionary) -> void:
	var p := _phase_progress(0.10, 0.48)
	if p <= 0.0 or p >= 1.0:
		return
	var pos: Vector2i = item["at"]
	var center := _cell_center(pos)
	var kind := String(item.get("kind", ""))
	var geometry := _board_geometry()
	var origin: Vector2 = geometry["origin"]
	var cell_size: float = geometry["cell_size"]
	var pitch := cell_size + cell_gap
	var board_extent := Vector2(
		cell_size * board_state.width + cell_gap * (board_state.width - 1),
		cell_size * board_state.height + cell_gap * (board_state.height - 1)
	)
	var energy := Color(GOLD)
	energy.a = 0.82 * sin(p * PI)
	match kind:
		"line_h":
			draw_line(Vector2(origin.x, center.y), Vector2(origin.x + board_extent.x, center.y), energy, 5.0 + 5.0 * sin(p * PI))
		"line_v":
			draw_line(Vector2(center.x, origin.y), Vector2(center.x, origin.y + board_extent.y), energy, 5.0 + 5.0 * sin(p * PI))
		"area":
			for ring in range(2):
				draw_arc(center, cell_size * (0.22 + p * (0.72 + ring * 0.24)), 0.0, TAU, 40, energy, 3.0)
		"smart":
			draw_arc(center, cell_size * (0.34 + p * 0.28), PI * 0.08, PI * 0.92, 28, energy, 3.0)
			draw_arc(center, cell_size * (0.34 + p * 0.28), PI * 1.08, PI * 1.92, 28, energy, 3.0)
			draw_circle(center, cell_size * 0.08 * (1.0 + p), energy)
		"global":
			var radius := cell_size * (0.30 + p * 1.30)
			draw_arc(center, radius, 0.0, TAU, 56, energy, 4.0)
			for angle in range(0, 8):
				var a := TAU * float(angle) / 8.0
				var direction := Vector2(cos(a), sin(a))
				draw_line(center + direction * radius * 0.55, center + direction * radius, energy, 2.0)
		_:
			draw_arc(center, cell_size * (0.22 + p * 0.44), 0.0, TAU, 32, energy, 3.0)
