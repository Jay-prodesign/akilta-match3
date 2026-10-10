class_name Match3CurioBoutiqueView
extends Control

const INK := Color("#100D12")
const VELVET := Color("#17131B")
const PLUM := Color("#241A27")
const GLASS := Color("#2E2432")
const BONE := Color("#F1E8DD")
const LILAC := Color("#BFA5D8")
const GOLD := Color("#D8B56A")
const ROSE := Color("#C7728F")

var house_stage: int = 0
var curios: Array[String] = []

func set_house_state(stage: int, owned_curios: Array[String]) -> void:
	house_stage = stage
	curios = owned_curios.duplicate()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK, true)
	var margin: float = size.x * 0.07
	var room := Rect2(Vector2(margin, size.y * 0.08), Vector2(size.x - margin * 2.0, size.y * 0.78))
	draw_rect(room, VELVET, true)
	_draw_arch(room)
	_draw_cabinet(room)
	_draw_floor(room)

func _draw_arch(room: Rect2) -> void:
	var center := Vector2(room.get_center().x, room.position.y + room.size.y * 0.27)
	var radius: float = room.size.x * 0.42
	draw_arc(center, radius, PI, TAU, 72, Color("#382C3D"), 10.0)
	draw_line(Vector2(center.x - radius, center.y), Vector2(center.x - radius, room.end.y), Color("#382C3D"), 10.0)
	draw_line(Vector2(center.x + radius, center.y), Vector2(center.x + radius, room.end.y), Color("#382C3D"), 10.0)

func _draw_cabinet(room: Rect2) -> void:
	var cabinet := Rect2(
		Vector2(room.position.x + room.size.x * 0.18, room.position.y + room.size.y * 0.34),
		Vector2(room.size.x * 0.64, room.size.y * 0.46)
	)
	draw_rect(cabinet, PLUM, true)
	draw_rect(cabinet, Color("#6E626F"), false, 4.0)
	var shelf_y: float = cabinet.position.y + cabinet.size.y * 0.58
	draw_line(Vector2(cabinet.position.x, shelf_y), Vector2(cabinet.end.x, shelf_y), Color("#6E626F"), 4.0)
	var glow_center := cabinet.get_center() - Vector2(0, cabinet.size.y * 0.08)
	if house_stage >= 1:
		draw_circle(glow_center, cabinet.size.x * 0.29, Color(0.749, 0.647, 0.847, 0.08))
		draw_circle(glow_center, cabinet.size.x * 0.18, Color(0.749, 0.647, 0.847, 0.10))
		_draw_moon_cameo(glow_center)
	else:
		draw_circle(glow_center, cabinet.size.x * 0.08, GLASS)
		draw_arc(glow_center, cabinet.size.x * 0.07, 0.0, TAU, 32, Color("#6E626F"), 3.0)

func _draw_moon_cameo(center: Vector2) -> void:
	var radius: float = size.x * 0.075
	draw_circle(center, radius * 1.32, Color("#382C3D"))
	draw_arc(center, radius * 1.18, 0.0, TAU, 48, GOLD, 4.0)
	draw_circle(center, radius * 0.74, LILAC)
	draw_circle(center + Vector2(radius * 0.28, -radius * 0.12), radius * 0.63, PLUM)
	draw_circle(center + Vector2(-radius * 0.18, radius * 0.02), radius * 0.08, BONE)
	draw_circle(center + Vector2(0, radius * 1.62), radius * 0.12, ROSE)

func _draw_floor(room: Rect2) -> void:
	var y: float = room.end.y
	draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), GOLD, 2.0)
	for i in range(1, 5):
		var t: float = float(i) / 5.0
		draw_line(Vector2(room.position.x, lerpf(y, size.y, t)), Vector2(room.end.x, lerpf(y, size.y, t)), Color(0.851, 0.71, 0.416, 0.09), 1.0)
