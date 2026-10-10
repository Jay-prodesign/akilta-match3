class_name MoonCameoRitualView
extends Control

const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")
const BONE := Color("#F1E8DD")
const PLUM := Color("#2A1C32")
const INK := Color("#100D12")
const ROSE := Color("#C66A88")

@export var mode: String = "prestart"
@export_range(0.0, 1.0, 0.05) var glow_strength: float = 0.55

func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var center := Vector2(size.x * 0.5, size.y * 0.52)
	var min_dim := minf(size.x, size.y)
	var dormant := mode == "fail"
	if mode == "house":
		var house_radius := min_dim * 0.30
		_draw_cameo_identity(center, house_radius, false, true, true)
		return

	var radius := min_dim * (0.24 if mode == "prestart" else 0.28)

	# Reliquary/cabinet frame.
	var frame := Rect2(size.x * 0.17, size.y * 0.09, size.x * 0.66, size.y * 0.82)
	draw_style_box(_panel_box(), frame)
	var arch_color := Color(GOLD)
	arch_color.a = 0.12 if dormant else 0.28
	draw_arc(Vector2(center.x, frame.position.y + radius * 0.55), frame.size.x * 0.34, PI, TAU, 48, arch_color, 2.0)

	_draw_cameo_identity(center, radius, dormant, true, false)

	# Candle/relic accents establish the cabinet rather than generic modal chrome.
	if not dormant:
		_draw_candle(Vector2(frame.position.x + frame.size.x * 0.12, frame.end.y - 24.0), radius * 0.09)
		_draw_candle(Vector2(frame.end.x - frame.size.x * 0.12, frame.end.y - 24.0), radius * 0.09)
	if mode == "result":
		_draw_wax_seal(Vector2(center.x, frame.end.y - radius * 0.12), radius * 0.20)
	elif dormant:
		_draw_wax_seal(center, radius * 0.32)
		var seal_line := Color(ROSE)
		seal_line.a = 0.36
		draw_line(center + Vector2(-radius * 0.72, -radius * 0.72), center + Vector2(radius * 0.72, radius * 0.72), seal_line, 3.0)
		draw_line(center + Vector2(radius * 0.72, -radius * 0.72), center + Vector2(-radius * 0.72, radius * 0.72), seal_line, 3.0)

func _draw_cameo_identity(center: Vector2, radius: float, dormant: bool, show_orbit: bool, show_catalogue_drop: bool) -> void:
	# Soft occult glow and nested antique-metal seals.
	for i in range(4, 0, -1):
		var glow := Color(LILAC)
		glow.a = glow_strength * (0.012 if dormant else 0.035) * float(i)
		draw_circle(center, radius * (1.0 + float(i) * 0.22), glow)
	var ring := Color(GOLD)
	ring.a = 0.28 if dormant else 0.72
	draw_arc(center, radius * 1.10, 0.0, TAU, 64, ring, 2.5)
	draw_arc(center, radius * 0.86, 0.0, TAU, 64, Color(LILAC, 0.16 if dormant else 0.46), 1.8)

	# Smoked moonstone cameo.
	draw_circle(center + Vector2(radius * 0.025, radius * 0.045), radius * 0.76, Color(0, 0, 0, 0.34))
	draw_circle(center, radius * 0.72, Color("#182027"))
	draw_arc(center, radius * 0.72, 0.0, TAU, 64, Color(GOLD, 0.70), 2.0)
	var moon_center := center - Vector2(radius * 0.10, 0.0)
	draw_circle(moon_center, radius * 0.43, Color("#645D6B") if dormant else LILAC)
	draw_circle(moon_center + Vector2(radius * 0.17, -radius * 0.04), radius * 0.39, Color("#182027"))
	var highlight := Color(BONE)
	highlight.a = 0.18 if dormant else 0.50
	draw_arc(moon_center, radius * 0.36, PI * 0.72, PI * 1.42, 18, highlight, 2.0)

	# Small mineral inclusions make the physical Curio read as the same relic everywhere.
	if not dormant:
		for crater in [Vector2(-0.27, -0.12), Vector2(-0.18, 0.22), Vector2(-0.02, -0.31)]:
			var p: Vector2 = moon_center + crater * radius
			draw_circle(p, radius * 0.035, Color(1, 1, 1, 0.16))

	# Six learned moon-sigil echoes orbit the reward without becoming stars.
	if show_orbit:
		for i in range(6):
			var angle := -PI * 0.5 + TAU * float(i) / 6.0
			var p := center + Vector2(cos(angle), sin(angle)) * radius * 1.42
			_draw_small_moon(p, radius * 0.12, dormant)

	# Rose wax drop identifies the Curio as catalogued House property.
	if show_catalogue_drop and not dormant:
		var drop_center := center + Vector2(0, radius * 1.72)
		draw_circle(drop_center, radius * 0.12, ROSE.darkened(0.08))
		draw_arc(drop_center, radius * 0.12, 0.0, TAU, 22, Color(GOLD, 0.48), 1.3)

func _panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#151019")
	box.border_color = Color(GOLD, 0.22)
	box.set_border_width_all(2)
	box.set_corner_radius_all(22)
	return box

func _draw_small_moon(center: Vector2, r: float, dormant: bool = false) -> void:
	var backing := Color(PLUM)
	backing.a = 0.95
	draw_circle(center, r * 1.55, backing)
	draw_arc(center, r * 1.55, 0.0, TAU, 24, Color(GOLD, 0.12 if dormant else 0.30), 1.2)
	draw_circle(center - Vector2(r * 0.12, 0.0), r, Color("#5E5963") if dormant else Color(LILAC, 0.88))
	draw_circle(center + Vector2(r * 0.30, -r * 0.05), r * 0.92, backing)

func _draw_candle(base: Vector2, scale: float) -> void:
	var body := Rect2(base.x - scale * 0.40, base.y - scale * 1.7, scale * 0.8, scale * 1.7)
	draw_rect(body, Color("#D5C9B7"), true)
	draw_circle(Vector2(base.x, body.position.y - scale * 0.32), scale * 0.30, Color("#F0C86A"))
	draw_circle(Vector2(base.x, body.position.y - scale * 0.32), scale * 0.12, Color("#FFF1C5"))

func _draw_wax_seal(center: Vector2, r: float) -> void:
	draw_circle(center, r, Color(ROSE, 0.85))
	draw_arc(center, r, 0.0, TAU, 30, Color(GOLD, 0.45), 1.5)
	draw_line(center + Vector2(-r * 0.42, 0), center + Vector2(r * 0.42, 0), Color(BONE, 0.62), 1.2)
	draw_line(center + Vector2(0, -r * 0.42), center + Vector2(0, r * 0.42), Color(BONE, 0.62), 1.2)
