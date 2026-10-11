class_name MoonCameoRitualView
extends Control

const GOLD := Color("#D8B56A")
const LILAC := Color("#BFA5D8")
const BONE := Color("#F1E8DD")
const INK := Color("#100D12")
const ROSE := Color("#C66A88")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const CAMEO_SEALED_PATH := "res://assets/curios/ch01_curio_moon_cameo_sealed_v01.svg"
const CAMEO_AWAKENED_PATH := "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg"
const RELIC_PATHS := {
	"moth_reliquary": "res://assets/curios/ch01_curio_moth_reliquary.svg",
	"thorned_locket": "res://assets/curios/ch01_curio_thorned_locket.svg"
}
var _textures: Dictionary = {}

@export var mode: String = "prestart"
@export var relic_id: String = "moon_cameo"
@export_range(0.0, 1.0, 0.05) var glow_strength: float = 0.55

func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var dormant := mode == "fail"
	var center := Vector2(size.x * 0.5, size.y * (0.50 if mode != "house" else 0.52))
	var short := minf(size.x, size.y)

	if mode != "house":
		var frame := Rect2(size.x * 0.10, size.y * 0.07, size.x * 0.80, size.y * 0.86)
		draw_style_box(_panel_box(), frame)
		var arch_center := Vector2(frame.get_center().x, frame.position.y + frame.size.y * 0.34)
		draw_arc(arch_center, frame.size.x * 0.29, PI, TAU, 48, Color(GOLD, 0.42), 2.0)
		draw_line(Vector2(frame.position.x + 12, frame.end.y - 28), Vector2(frame.end.x - 12, frame.end.y - 28), Color(GOLD, 0.18), 1.0)
		if not dormant:
			_draw_candle(Vector2(frame.position.x + 28, frame.end.y - 18), short * 0.045)
			_draw_candle(Vector2(frame.end.x - 28, frame.end.y - 18), short * 0.045)

	var glow := Color(LILAC)
	glow.a = glow_strength * (0.08 if dormant else 0.14)
	draw_circle(center, short * (0.20 if mode == "house" else 0.24), glow)

	var texture := _relic_texture(dormant)
	if texture != null:
		var extent := short * (0.62 if mode == "house" else 0.70)
		var rect := Rect2(center - Vector2.ONE * extent * 0.5, Vector2.ONE * extent)
		draw_texture_rect(texture, rect, false)

	if dormant:
		_draw_wax_seal(center, short * 0.10)
		draw_line(center - Vector2(short * 0.18, short * 0.18), center + Vector2(short * 0.18, short * 0.18), Color(ROSE, 0.52), 3.0)
		draw_line(center + Vector2(short * 0.18, -short * 0.18), center + Vector2(-short * 0.18, short * 0.18), Color(ROSE, 0.52), 3.0)
	elif mode == "result":
		_draw_wax_seal(Vector2(center.x, size.y * 0.82), short * 0.055)

func _relic_texture(dormant: bool) -> Texture2D:
	if relic_id == "moon_cameo":
		return _load_texture(CAMEO_SEALED_PATH if dormant or mode == "prestart" else CAMEO_AWAKENED_PATH)
	var path := String(RELIC_PATHS.get(relic_id, ""))
	return _load_texture(path) if path != "" else null

func _panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#0E0B13", 0.88)
	box.border_color = Color(GOLD, 0.44)
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.shadow_color = Color(0, 0, 0, 0.42)
	box.shadow_size = 8
	return box

func _draw_candle(base: Vector2, scale: float) -> void:
	var body := Rect2(base.x - scale * 0.34, base.y - scale * 1.55, scale * 0.68, scale * 1.55)
	draw_rect(body, Color("#DCCFB9"), true)
	var flame_center := Vector2(base.x, body.position.y - scale * 0.30)
	draw_circle(flame_center, scale * 0.22, Color("#F0B95D"))
	draw_circle(flame_center, scale * 0.08, Color("#FFF1C5"))

func _draw_wax_seal(center: Vector2, r: float) -> void:
	draw_circle(center, r, Color(ROSE, 0.92))
	draw_arc(center, r, 0.0, TAU, 30, Color(GOLD, 0.56), 1.5)
	draw_line(center + Vector2(-r * 0.42, 0), center + Vector2(r * 0.42, 0), Color(BONE, 0.62), 1.2)
	draw_line(center + Vector2(0, -r * 0.42), center + Vector2(0, r * 0.42), Color(BONE, 0.62), 1.2)

func _load_texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var source := file.get_as_text()
	file.close()
	var image := Image.new()
	if image.load_svg_from_string(source, 1.0) != OK or image.is_empty():
		return null
	var texture := ImageTexture.create_from_image(image)
	_textures[path] = texture
	return texture
