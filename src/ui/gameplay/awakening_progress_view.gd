class_name Match3AwakeningProgressView
extends Control

const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")
const BONE := Color("#F1E8DD")
const PLUM := Color("#241A27")
const INK := Color("#100D12")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

var _skull_texture: Texture2D

var progress: int = 0
var target: int = 6
var family: String = "moon"

func _ready() -> void:
	_skull_texture = PieceAssetLoader.ornament("res://assets/pieces/skull.svg")
	resized.connect(queue_redraw)
	queue_redraw()

func set_objective(value: int, target_value: int, family_value: String) -> void:
	progress = maxi(0, value)
	target = maxi(1, target_value)
	family = family_value
	queue_redraw()

func contract() -> Dictionary:
	return {
		"progress": progress,
		"target": target,
		"family": family,
		"language": "awakening_seals",
	}

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var panel := Rect2(Vector2.ZERO, size).grow(-2.0)
	draw_rect(panel, Color("#151019"), true)
	draw_rect(panel, Color(GOLD, 0.18), false, 2.0)

	var center_y := size.y * 0.56
	var left_x := size.x * 0.08
	var right_x := size.x * 0.72
	var usable := right_x - left_x
	var count := mini(target, 8)
	for i in range(count):
		var t := 0.0 if count <= 1 else float(i) / float(count - 1)
		var c := Vector2(lerpf(left_x, right_x, t), center_y)
		var active := i < progress
		if family == "wax_seal":
			_draw_wax_seal(c, size.y * 0.105, active)
		else:
			_draw_moon_seal(c, size.y * 0.105, active)

	var line := Color(GOLD)
	line.a = 0.16
	draw_line(Vector2(left_x, center_y), Vector2(right_x, center_y), line, 2.0)

	var cameo_center := Vector2(size.x * 0.88, center_y)
	var radius := size.y * 0.17
	for ring in range(3, 0, -1):
		draw_circle(cameo_center, radius * (1.0 + float(ring) * 0.28), Color(LILAC, 0.018 * float(ring)))
	draw_circle(cameo_center, radius * 0.78, Color("#182027"))
	draw_arc(cameo_center, radius * 0.78, 0.0, TAU, 36, Color(GOLD, 0.62), 2.0)
	if family == "wax_seal" and _skull_texture != null:
		draw_texture_rect(_skull_texture, Rect2(cameo_center - Vector2(radius * 0.82, radius * 0.82), Vector2(radius * 1.64, radius * 1.64)), false)
	else:
		var moon_c := cameo_center - Vector2(radius * 0.10, 0.0)
		draw_circle(moon_c, radius * 0.46, Color(LILAC, 0.92 if progress >= target else 0.48))
		draw_circle(moon_c + Vector2(radius * 0.18, -radius * 0.04), radius * 0.41, Color("#182027"))

func _draw_moon_seal(center: Vector2, radius: float, active: bool) -> void:
	var backing := Color(PLUM)
	draw_circle(center, radius * 1.36, backing)
	var rim := Color(GOLD)
	rim.a = 0.62 if active else 0.18
	draw_arc(center, radius * 1.34, 0.0, TAU, 24, rim, 1.6)
	var moon := Color(LILAC)
	moon.a = 0.92 if active else 0.24
	draw_circle(center - Vector2(radius * 0.10, 0.0), radius * 0.72, moon)
	draw_circle(center + Vector2(radius * 0.20, -radius * 0.03), radius * 0.68, backing)

func _draw_wax_seal(center: Vector2, radius: float, active: bool) -> void:
	var backing := Color("#4B1E35")
	draw_circle(center, radius * 1.36, backing)
	var rim := Color(GOLD)
	rim.a = 0.78 if active else 0.28
	draw_arc(center, radius * 1.34, 0.0, TAU, 24, rim, 1.6)
	if _skull_texture != null:
		draw_texture_rect(_skull_texture, Rect2(center - Vector2(radius * 0.92, radius * 0.92), Vector2(radius * 1.84, radius * 1.84)), false)
	else:
		draw_line(center + Vector2(-radius * 0.45, -radius * 0.2), center + Vector2(radius * 0.45, radius * 0.2), Color(BONE, 0.9), 1.5)
		draw_line(center + Vector2(radius * 0.45, -radius * 0.2), center + Vector2(-radius * 0.45, radius * 0.2), Color(BONE, 0.9), 1.5)
