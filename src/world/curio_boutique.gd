class_name Match3CurioBoutiqueView
extends Control

const INK := Color("#100D12")
const VELVET := Color("#17131B")
const PLUM := Color("#241A27")
const GLASS := Color("#2E2432")
const RAISED := Color("#382C3D")
const BONE := Color("#F1E8DD")
const MIST := Color("#D9CDD5")
const LILAC := Color("#BFA5D8")
const CYAN := Color("#A9C6C8")
const GOLD := Color("#D8B56A")
const ROSE := Color("#C7728F")
const LEAF := Color("#8BAF7C")

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const BACKDROP_ASSET_ID := "hub_bg_grandhall"
var _backdrop: Texture2D
const CAT_PORTRAIT_PATH := "res://assets/pieces/black_cat.webp"
const MOTH_RELIQUARY_PATH := "res://assets/curios/ch01_curio_moth_reliquary.png"
const THORNED_LOCKET_PATH := "res://assets/curios/ch01_curio_thorned_locket.png"
var _cat_portrait: Texture2D
var _moth_reliquary: Texture2D
var _thorned_locket: Texture2D

func _ready() -> void:
	# Screen-first rule: the House environment is authored raster art. Never fall
	# back to a procedurally drawn room or an SVG environment when production art
	# is missing; missing art must remain visible as a production failure.
	_backdrop = ScreenArt.texture(BACKDROP_ASSET_ID)
	_cat_portrait = PieceAssetLoader.ornament(CAT_PORTRAIT_PATH)
	_moth_reliquary = PieceAssetLoader.ornament(MOTH_RELIQUARY_PATH)
	_thorned_locket = PieceAssetLoader.ornament(THORNED_LOCKET_PATH)
	queue_redraw()

var house_stage: int = 0
var curios: Array[String] = []
var _reduced_motion: bool = false
var _ambient_phase: float = 0.0
var _restoration_full_bleed: bool = false

func _process(delta: float) -> void:
	if _reduced_motion or house_stage <= 0:
		return
	_ambient_phase = fmod(_ambient_phase + delta * 1.15, TAU)
	queue_redraw()

func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	if _reduced_motion:
		_ambient_phase = 0.0
	queue_redraw()

func set_restoration_full_bleed(enabled: bool) -> void:
	_restoration_full_bleed = enabled
	queue_redraw()

func set_house_state(stage: int, owned_curios: Array[String]) -> void:
	house_stage = clampi(stage, 0, 3)
	curios = owned_curios.duplicate()
	var cameo_overlay := get_node_or_null("MoonCameoOverlay")
	if cameo_overlay != null:
		cameo_overlay.visible = house_stage >= 1 and curios.has("moon_cameo")
		cameo_overlay.queue_redraw()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK, true)
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var margin: float = size.x * 0.035
	var room_height_ratio := 0.975 if _restoration_full_bleed else 0.93
	var room := Rect2(
		Vector2(margin, size.y * 0.025),
		Vector2(size.x - margin * 2.0, size.y * room_height_ratio)
	)
	draw_rect(room, VELVET, true)
	if _backdrop != null:
		# The House screen owns one same-camera environment. Runtime layers add only
		# stateful light and restored Curios; they must not duplicate painted props.
		draw_texture_rect(_backdrop, room, false)
		_draw_authored_atmosphere(room)
		_draw_authored_restoration_curios(room)
	else:
		# Intentionally no illustrative fallback. A flat underlay is allowed only
		# so missing production art is obvious during review.
		draw_rect(room, INK, true)
	if house_stage >= 1:
		_draw_awakened_sparkles(room)


func _stage_veil_alpha() -> float:
	match house_stage:
		0:
			return 0.40
		1:
			return 0.27
		2:
			return 0.15
		_:
			return 0.06

func _ambient_tier() -> String:
	match house_stage:
		0:
			return "dormant"
		1:
			return "first_cabinet_awake"
		2:
			return "side_display_awake"
		_:
			return "opening_set_alive"

func _ambient_breath() -> float:
	if _reduced_motion or house_stage <= 0:
		return 1.0
	return 0.96 + sin(_ambient_phase) * 0.04

func _draw_authored_atmosphere(room: Rect2) -> void:
	# The environment itself is always the authored raster. These runtime layers
	# are lighting/color-response VFX only, so House progression changes the same
	# camera without redrawing furniture, architecture or painted props.
	var veil := Color("#090A17")
	veil.a = _stage_veil_alpha()
	draw_rect(room, veil, true)

	var breath := _ambient_breath()
	var moon_center := Vector2(room.get_center().x, room.position.y + room.size.y * 0.19)
	for i in range(4, 0, -1):
		var glow := Color(LILAC)
		glow.a = (0.006 + float(i) * 0.006) * breath
		draw_circle(moon_center, room.size.x * (0.10 + float(i) * 0.032), glow)

	if house_stage >= 1:
		var cabinet_center := Vector2(room.position.x + room.size.x * 0.84, room.position.y + room.size.y * 0.37)
		var stage_strength := 0.72 + float(house_stage) * 0.18
		for i in range(5, 0, -1):
			var warm := Color(GOLD)
			warm.a = (0.008 + float(i) * 0.008) * stage_strength * breath
			draw_circle(cabinet_center, room.size.x * (0.07 + float(i) * 0.028), warm)

	if house_stage >= 2:
		var hearth_center := Vector2(room.get_center().x, room.position.y + room.size.y * 0.57)
		for i in range(4, 0, -1):
			var hearth := Color("#E5A766")
			hearth.a = (0.005 + float(i) * 0.006) * breath
			draw_circle(hearth_center, room.size.x * (0.08 + float(i) * 0.035), hearth)

	if house_stage >= 3:
		var room_wake := Color(GOLD)
		room_wake.a = 0.022 * breath
		draw_rect(room, room_wake, true)

func living_house_contract() -> Dictionary:
	var restored := 0
	for curio_id in ["moon_cameo", "moth_reliquary", "thorned_locket"]:
		if curios.has(curio_id):
			restored += 1
	return {
		"stage": house_stage,
		"ambient_tier": _ambient_tier(),
		"stage_veil_alpha": _stage_veil_alpha(),
		"breathing_active": house_stage > 0 and not _reduced_motion,
		"reduced_motion": _reduced_motion,
		"authored_backdrop_id": BACKDROP_ASSET_ID,
		"authored_backdrop_loaded": _backdrop != null,
		"same_camera": true,
		"runtime_world_art": "authored_raster_plus_state_vfx",
		"restored_curio_count": restored,
		"procedural_environment_fallback": false,
		"restoration_full_bleed": _restoration_full_bleed,
	}

func restoration_contract() -> Dictionary:
	return {
		"stage": house_stage,
		"moth_reliquary_visible": house_stage >= 2 and curios.has("moth_reliquary") and _moth_reliquary != null,
		"thorned_locket_visible": house_stage >= 3 and curios.has("thorned_locket") and _thorned_locket != null,
	}

func _draw_authored_restoration_curios(room: Rect2) -> void:
	# The authored backdrop owns the room architecture. Progression must still read
	# as a persistent world change, so the restored cabinet becomes a luminous
	# display zone and each earned Curio occupies a real, readable niche.
	if house_stage >= 1:
		var cabinet_center := Vector2(room.position.x + room.size.x * 0.84, room.position.y + room.size.y * 0.37)
		var stage_strength := clampf(float(house_stage) / 3.0, 0.0, 1.0)
		for i in range(5, 0, -1):
			var cabinet_glow := Color(GOLD)
			cabinet_glow.a = (0.010 + float(i) * 0.008) * (0.72 + stage_strength * 0.58)
			draw_circle(cabinet_center, room.size.x * (0.075 + float(i) * 0.026), cabinet_glow)
	# Moon Cameo occupies the authored right-side cabinet niche; later reliquaries
	# use the remaining display niches without becoming floating UI tokens.
	if house_stage >= 1 and curios.has("moon_cameo"):
		var moon_niche := Vector2(room.position.x + room.size.x * 0.83, room.position.y + room.size.y * 0.27)
		for i in range(4, 0, -1):
			var moon_glow := Color(LILAC)
			moon_glow.a = 0.012 + float(i) * 0.010
			draw_circle(moon_niche, room.size.x * (0.055 + float(i) * 0.014), moon_glow)
		draw_circle(moon_niche, room.size.x * 0.047, Color(GOLD, 0.035))
	if house_stage >= 2 and curios.has("moth_reliquary") and _moth_reliquary != null:
		_draw_restored_relic(
			room,
			_moth_reliquary,
			Vector2(room.position.x + room.size.x * 0.84, room.position.y + room.size.y * 0.38),
			Color(CYAN, 0.32)
		)
	if house_stage >= 3 and curios.has("thorned_locket") and _thorned_locket != null:
		_draw_restored_relic(
			room,
			_thorned_locket,
			Vector2(room.position.x + room.size.x * 0.84, room.position.y + room.size.y * 0.49),
			Color(ROSE, 0.34)
		)

func _draw_restored_relic(room: Rect2, texture: Texture2D, center: Vector2, glow_color: Color) -> void:
	if texture == null:
		return
	# Keep later rewards embedded in the authored right-side cabinet stack instead
	# of reading as large floating UI tokens over furniture.
	var relic_size := room.size.x * 0.15
	var frame_size := Vector2(relic_size, relic_size)
	var frame := Rect2(center - frame_size * 0.5, frame_size)
	var glow := glow_color
	draw_circle(center, relic_size * 0.96, Color(glow.r, glow.g, glow.b, 0.090))
	draw_circle(center, relic_size * 0.72, Color(glow.r, glow.g, glow.b, 0.045))
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var max_size := frame_size * 0.96
	var fitted_scale: float = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var fitted_size := texture_size * fitted_scale
	var relic_rect := Rect2(center - fitted_size * 0.5, fitted_size)
	draw_texture_rect(texture, relic_rect, false)

func _draw_ambient_light(room: Rect2) -> void:
	var moon_center := Vector2(room.get_center().x, room.position.y + room.size.y * 0.18)
	for i in range(4, 0, -1):
		var moon_glow := Color(LILAC)
		moon_glow.a = 0.010 + 0.010 * float(i)
		draw_circle(moon_center, room.size.x * (0.09 + 0.035 * float(i)), moon_glow)
	if house_stage >= 1:
		var cabinet_glow_center := Vector2(room.get_center().x, room.position.y + room.size.y * 0.50)
		for i in range(5, 0, -1):
			var warm := Color(GOLD)
			warm.a = 0.008 + 0.009 * float(i)
			draw_circle(cabinet_glow_center, room.size.x * (0.12 + 0.045 * float(i)), warm)

func _draw_wall_panels(room: Rect2) -> void:
	var inset: float = room.size.x * 0.045
	var wall := room.grow(-inset)
	draw_rect(wall, Color("#1D1721"), true)
	var wash := Color("#3A2335")
	wash.a = 0.30
	draw_rect(wall, wash, true)
	draw_rect(wall, Color(0.749, 0.647, 0.847, 0.22), false, 2.0)

	# Large-scale wallpaper geometry keeps the room readable at portrait size.
	var motif := Color(GOLD)
	motif.a = 0.075
	var motif_step_x := wall.size.x / 6.0
	var motif_step_y := wall.size.y / 7.0
	for row in range(1, 7):
		for col in range(1, 6):
			var c := Vector2(wall.position.x + motif_step_x * float(col), wall.position.y + motif_step_y * float(row))
			var rx := motif_step_x * 0.20
			var ry := motif_step_y * 0.16
			var diamond := PackedVector2Array([
				c + Vector2(0, -ry),
				c + Vector2(rx, 0),
				c + Vector2(0, ry),
				c + Vector2(-rx, 0),
				c + Vector2(0, -ry)
			])
			draw_polyline(diamond, motif, 1.3)

	var panel_top: float = wall.position.y + wall.size.y * 0.18
	var panel_bottom: float = wall.position.y + wall.size.y * 0.70
	for x_ratio in [0.11, 0.34, 0.66, 0.89]:
		var x: float = lerpf(wall.position.x, wall.end.x, float(x_ratio))
		draw_line(Vector2(x, panel_top), Vector2(x, panel_bottom), Color(0.663, 0.6, 0.659, 0.10), 1.0)
	draw_line(
		Vector2(wall.position.x, panel_bottom),
		Vector2(wall.end.x, panel_bottom),
		Color(0.663, 0.6, 0.659, 0.12),
		2.0
	)

func _draw_arch(room: Rect2) -> void:
	var center := Vector2(room.get_center().x, room.position.y + room.size.y * 0.235)
	var radius: float = room.size.x * 0.445
	draw_arc(center, radius, PI, TAU, 72, RAISED, 18.0)
	draw_arc(center, radius - 10.0, PI, TAU, 72, Color(0.851, 0.71, 0.416, 0.32), 2.5)
	draw_line(Vector2(center.x - radius, center.y), Vector2(center.x - radius, room.end.y), RAISED, 18.0)
	draw_line(Vector2(center.x + radius, center.y), Vector2(center.x + radius, room.end.y), RAISED, 18.0)
	var arch_glow := Color(GOLD)
	arch_glow.a = 0.14
	draw_arc(center, radius - 18.0, PI, TAU, 72, arch_glow, 4.0)

	# Velvet curtain suggestions keep the room intimate without hiding the cabinet.
	var curtain_left := PackedVector2Array([
		Vector2(room.position.x + room.size.x * 0.06, room.position.y + room.size.y * 0.13),
		Vector2(room.position.x + room.size.x * 0.18, room.position.y + room.size.y * 0.20),
		Vector2(room.position.x + room.size.x * 0.13, room.position.y + room.size.y * 0.67),
		Vector2(room.position.x + room.size.x * 0.04, room.position.y + room.size.y * 0.73)
	])
	var curtain_right := PackedVector2Array([
		Vector2(room.end.x - room.size.x * 0.06, room.position.y + room.size.y * 0.13),
		Vector2(room.end.x - room.size.x * 0.18, room.position.y + room.size.y * 0.20),
		Vector2(room.end.x - room.size.x * 0.13, room.position.y + room.size.y * 0.67),
		Vector2(room.end.x - room.size.x * 0.04, room.position.y + room.size.y * 0.73)
	])
	draw_colored_polygon(curtain_left, Color("#451A3B"))
	draw_colored_polygon(curtain_right, Color("#451A3B"))
	draw_line(curtain_left[1], curtain_left[2], Color(0.78, 0.45, 0.56, 0.34), 4.0)
	draw_line(curtain_right[1], curtain_right[2], Color(0.78, 0.45, 0.56, 0.22), 3.0)

func _draw_moon_window(room: Rect2) -> void:
	var c := Vector2(room.get_center().x, room.position.y + room.size.y * 0.17)
	var r: float = room.size.x * 0.105
	draw_circle(c, r * 1.24, RAISED)
	draw_circle(c, r, Color("#1A2028"))
	draw_circle(c, r * 0.70, Color(0.663, 0.776, 0.784, 0.24))
	# Stained-glass crossbars keep the moon window architectural, not another gameplay piece.
	draw_line(c + Vector2(-r * 0.78, 0), c + Vector2(r * 0.78, 0), Color(0.851,0.71,0.416,0.18), 2.0)
	draw_line(c + Vector2(0, -r * 0.78), c + Vector2(0, r * 0.78), Color(0.851,0.71,0.416,0.18), 2.0)
	draw_circle(c - Vector2(r * 0.10, r * 0.04), r * 0.54, LILAC)
	draw_circle(c + Vector2(r * 0.24, -r * 0.10), r * 0.53, Color("#1A2028"))
	draw_arc(c, r * 1.02, 0.0, TAU, 48, GOLD, 2.0)

func _draw_wall_frames(room: Rect2) -> void:
	var top_y := room.position.y + room.size.y * 0.27
	var frame_w := room.size.x * 0.105
	var frame_h := room.size.y * 0.105
	for x_ratio in [0.16, 0.84]:
		var center := Vector2(lerpf(room.position.x, room.end.x, float(x_ratio)), top_y)
		var frame := Rect2(center - Vector2(frame_w, frame_h) * 0.5, Vector2(frame_w, frame_h))
		draw_rect(frame.grow(5.0), Color("#120F15"), true)
		draw_rect(frame, Color("#241A27"), true)
		draw_rect(frame, Color(GOLD, 0.34), false, 2.0)
		# Original House motifs: thorn rosette left, moth reliquary right.
		if float(x_ratio) < 0.5:
			_draw_rose_silhouette(center, minf(frame_w, frame_h) * 0.24)
		else:
			_draw_moth_frame(center, minf(frame_w, frame_h) * 0.24, house_stage >= 1)
	# Small sconces make the wall feel inhabited rather than diagrammatic.
	_draw_wall_sconce(Vector2(room.position.x + room.size.x * 0.28, top_y + frame_h * 0.18), house_stage >= 1)
	_draw_wall_sconce(Vector2(room.end.x - room.size.x * 0.28, top_y + frame_h * 0.18), house_stage >= 1)

func _draw_wall_sconce(center: Vector2, active: bool) -> void:
	var metal := GOLD.darkened(0.35)
	draw_line(center + Vector2(0, 14), center + Vector2(0, -9), metal, 3.0)
	draw_line(center, center + Vector2(13, 8), metal, 2.0)
	draw_line(center, center + Vector2(-13, 8), metal, 2.0)
	if active:
		var glow := Color(GOLD)
		glow.a = 0.08
		draw_circle(center - Vector2(0, 13), 22.0, glow)
		draw_circle(center - Vector2(0, 13), 6.0, GOLD)
	else:
		draw_circle(center - Vector2(0, 13), 5.0, Color("#665566"))

func _draw_side_shelves(room: Rect2) -> void:
	var shelf_y0: float = room.position.y + room.size.y * 0.42
	var shelf_gap: float = room.size.y * 0.115
	var left_x0: float = room.position.x + room.size.x * 0.075
	var left_x1: float = room.position.x + room.size.x * 0.255
	var right_x0: float = room.end.x - room.size.x * 0.255
	var right_x1: float = room.end.x - room.size.x * 0.075

	var left_alcove := Rect2(
		Vector2(left_x0 - room.size.x * 0.018, shelf_y0 - room.size.y * 0.075),
		Vector2((left_x1 - left_x0) + room.size.x * 0.036, shelf_gap * 2.72)
	)
	var right_alcove := Rect2(
		Vector2(right_x0 - room.size.x * 0.018, shelf_y0 - room.size.y * 0.075),
		Vector2((right_x1 - right_x0) + room.size.x * 0.036, shelf_gap * 2.72)
	)
	for alcove in [left_alcove, right_alcove]:
		draw_rect(alcove.grow(4.0), Color("#100D12"), true)
		draw_rect(alcove, Color("#18121B"), true)
		draw_rect(alcove, Color(0.851, 0.71, 0.416, 0.26), false, 2.0)

	for i in range(3):
		var y: float = shelf_y0 + shelf_gap * float(i)
		draw_line(Vector2(left_x0, y), Vector2(left_x1, y), Color(GOLD, 0.48), 3.5)
		draw_line(Vector2(right_x0, y), Vector2(right_x1, y), GOLD.darkened(0.45), 3.0)

	_draw_bottle(Vector2((left_x0 + left_x1) * 0.5, shelf_y0 - 14.0), CYAN, 0.95)
	_draw_candle(Vector2(left_x0 + 20.0, shelf_y0 + shelf_gap - 4.0), 1.05)
	_draw_bottle(Vector2(left_x1 - 18.0, shelf_y0 + shelf_gap - 8.0), ROSE, 0.66)
	_draw_rose_silhouette(Vector2(left_x0 + 34.0, shelf_y0 + shelf_gap * 2.0 - 12.0), 12.0)
	var locket_center := Vector2(left_x1 - 24.0, shelf_y0 + shelf_gap * 2.0 - 19.0)
	if house_stage >= 3:
		draw_circle(locket_center, 29.0, Color(0.78, 0.45, 0.56, 0.07))
		_draw_thorn_locket(locket_center, 20.0, true)
	else:
		_draw_thorn_locket(locket_center, 16.0, false)

	_draw_bottle(Vector2((right_x0 + right_x1) * 0.5, shelf_y0 - 14.0), LEAF, 0.88)
	_draw_candle(Vector2(right_x1 - 20.0, shelf_y0 + shelf_gap - 4.0), 1.05)
	_draw_bottle(Vector2(right_x0 + 20.0, shelf_y0 + shelf_gap - 8.0), LILAC, 0.66)
	_draw_rose_silhouette(Vector2(right_x1 - 34.0, shelf_y0 + shelf_gap * 2.0 - 12.0), 12.0)
	var moth_center := Vector2(right_x0 + 28.0, shelf_y0 + shelf_gap * 2.0 - 18.0)
	_draw_moth_frame(moth_center, 20.0 if house_stage >= 2 else 17.0, house_stage >= 2)

func _draw_rose_silhouette(center: Vector2, radius: float) -> void:
	var petals := PackedVector2Array()
	for i in range(10):
		var angle := TAU * float(i) / 10.0 - PI * 0.5
		var rr := radius if i % 2 == 0 else radius * 0.62
		petals.append(center + Vector2(cos(angle), sin(angle)) * rr)
	draw_colored_polygon(petals, Color("#7D3048"))
	draw_circle(center, radius * 0.26, Color("#C7728F"))

func _draw_central_cabinet(room: Rect2) -> void:
	var cabinet := Rect2(
		Vector2(room.position.x + room.size.x * 0.285, room.position.y + room.size.y * 0.34),
		Vector2(room.size.x * 0.43, room.size.y * 0.43)
	)
	draw_rect(cabinet.grow(14.0), Color(0, 0, 0, 0.30), true)
	draw_rect(cabinet.grow(9.0), Color("#120F15"), true)
	draw_rect(cabinet.grow(7.0), Color(GOLD, 0.48), false, 5.0)
	draw_rect(cabinet, Color("#291C2B"), true)
	# Cabinet crown / reliquary pediment.
	var crown_y := cabinet.position.y - 10.0
	draw_line(Vector2(cabinet.position.x + cabinet.size.x * 0.12, crown_y), Vector2(cabinet.end.x - cabinet.size.x * 0.12, crown_y), Color(GOLD, 0.52), 4.0)
	draw_arc(Vector2(cabinet.get_center().x, crown_y + 2.0), cabinet.size.x * 0.18, PI, TAU, 32, Color(GOLD, 0.42), 3.0)
	# Brass side columns improve object permanence at small scale.
	for x in [cabinet.position.x + 10.0, cabinet.end.x - 10.0]:
		draw_line(Vector2(x, cabinet.position.y + 14.0), Vector2(x, cabinet.end.y - 14.0), Color(GOLD, 0.34), 4.0)
		draw_circle(Vector2(x, cabinet.position.y + 12.0), 5.0, Color(GOLD, 0.44))
		draw_circle(Vector2(x, cabinet.end.y - 12.0), 5.0, Color(GOLD, 0.44))
	if house_stage >= 1:
		var velvet := Rect2(
			cabinet.position + Vector2(cabinet.size.x * 0.07, cabinet.size.y * 0.06),
			Vector2(cabinet.size.x * 0.86, cabinet.size.y * 0.57)
		)
		draw_rect(velvet, Color("#321A30"), true)
		draw_rect(velvet, Color(0.78, 0.45, 0.56, 0.24), false, 1.5)
		# Glass reflections give the display depth without covering the Curio.
		var glass := Color("#A9C6C8")
		glass.a = 0.07
		draw_line(velvet.position + Vector2(velvet.size.x * 0.12, 4.0), velvet.position + Vector2(velvet.size.x * 0.34, velvet.size.y - 6.0), glass, 4.0)
		draw_line(velvet.position + Vector2(velvet.size.x * 0.62, 4.0), velvet.position + Vector2(velvet.size.x * 0.78, velvet.size.y * 0.56), glass, 2.0)
	draw_rect(cabinet, Color(0.851, 0.71, 0.416, 0.34), false, 2.0)

	var shelf_y: float = cabinet.position.y + cabinet.size.y * 0.68
	draw_line(Vector2(cabinet.position.x, shelf_y), Vector2(cabinet.end.x, shelf_y), GOLD.darkened(0.5), 3.0)

	var glow_center := cabinet.get_center() - Vector2(0, cabinet.size.y * 0.10)
	if house_stage >= 1:
		draw_circle(glow_center, cabinet.size.x * 0.39, Color(0.749, 0.647, 0.847, 0.055))
		draw_circle(glow_center, cabinet.size.x * 0.29, Color(0.749, 0.647, 0.847, 0.085))
		draw_circle(glow_center, cabinet.size.x * 0.20, Color(0.851, 0.71, 0.416, 0.05))
		_draw_candle(Vector2(cabinet.position.x + cabinet.size.x * 0.18, shelf_y - 5.0), 0.66)
		_draw_candle(Vector2(cabinet.end.x - cabinet.size.x * 0.18, shelf_y - 5.0), 0.66)
	else:
		# Dormant display is visibly sealed, not merely empty.
		draw_circle(glow_center, cabinet.size.x * 0.16, Color("#151219"))
		draw_arc(glow_center, cabinet.size.x * 0.145, 0.0, TAU, 36, Color("#6E626F"), 3.0)
		var seal := Color("#7D3048")
		draw_circle(glow_center, cabinet.size.x * 0.075, seal.darkened(0.18))
		draw_arc(glow_center, cabinet.size.x * 0.075, 0.0, TAU, 30, ROSE.darkened(0.18), 2.0)
		for angle in [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]:
			var d := Vector2(cos(angle), sin(angle))
			draw_line(glow_center + d * cabinet.size.x * 0.08, glow_center + d * cabinet.size.x * 0.14, Color("#6E626F"), 2.0)

	# Drawer / hardware gives the display physical permanence.
	var drawer := Rect2(
		Vector2(cabinet.position.x + cabinet.size.x * 0.16, cabinet.end.y - cabinet.size.y * 0.19),
		Vector2(cabinet.size.x * 0.68, cabinet.size.y * 0.11)
	)
	draw_rect(drawer, Color("#1C151F"), true)
	draw_rect(drawer, Color(0.851, 0.71, 0.416, 0.22), false, 1.0)
	draw_circle(drawer.get_center(), 3.5, GOLD)

func _draw_bottle(base: Vector2, color: Color, scale: float) -> void:
	var w: float = 14.0 * scale
	var h: float = 30.0 * scale
	var body := Rect2(base - Vector2(w * 0.5, h), Vector2(w, h))
	draw_rect(body, color.darkened(0.24), true)
	draw_rect(body, color.lightened(0.18), false, 1.5)
	var neck := Rect2(Vector2(base.x - w * 0.22, base.y - h - 8.0 * scale), Vector2(w * 0.44, 9.0 * scale))
	draw_rect(neck, color, true)
	draw_circle(Vector2(base.x, base.y - h * 0.48), 2.4 * scale, BONE)

func _draw_candle(base: Vector2, scale: float) -> void:
	var w: float = 9.0 * scale
	var h: float = 27.0 * scale
	draw_rect(Rect2(base - Vector2(w * 0.5, h), Vector2(w, h)), BONE.darkened(0.15), true)
	var flame := PackedVector2Array([
		base - Vector2(0, h + 12.0 * scale),
		base + Vector2(5.0 * scale, -h - 3.0 * scale),
		base + Vector2(0, -h + 1.0 * scale),
		base + Vector2(-5.0 * scale, -h - 3.0 * scale)
	])
	draw_colored_polygon(flame, GOLD)
	draw_circle(base - Vector2(0, h + 4.0 * scale), 13.0 * scale, Color(0.851, 0.71, 0.416, 0.035))

func _draw_thorn_locket(center: Vector2, radius: float, active: bool) -> void:
	var metal: Color = ROSE if active else Color("#5D4C58")
	var rim: Color = GOLD if active else Color("#4D4450")
	draw_circle(center, radius * 1.08, Color("#151219"))
	draw_arc(center, radius, 0.0, TAU, 36, rim, 2.0)
	draw_circle(center, radius * 0.58, metal.darkened(0.28))
	draw_arc(center, radius * 0.58, 0.0, TAU, 30, metal, 2.0)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * radius * 0.68, center + direction * radius * 0.98, metal, 2.0)

func _draw_moth_frame(center: Vector2, radius: float, active: bool = true) -> void:
	draw_circle(center, radius * 1.15, Color("#151219"))
	var rim: Color = GOLD.darkened(0.25) if active else Color("#4D4450")
	var wings: Color = CYAN if active else Color("#536066")
	draw_arc(center, radius, 0.0, TAU, 36, rim, 2.0)
	var left := PackedVector2Array([
		center + Vector2(-2, -1),
		center + Vector2(-radius * 0.65, -radius * 0.35),
		center + Vector2(-radius * 0.50, radius * 0.48)
	])
	var right := PackedVector2Array([
		center + Vector2(2, -1),
		center + Vector2(radius * 0.65, -radius * 0.35),
		center + Vector2(radius * 0.50, radius * 0.48)
	])
	draw_colored_polygon(left, wings)
	draw_colored_polygon(right, wings)

func _draw_floor(room: Rect2) -> void:
	var horizon_y: float = room.position.y + room.size.y * 0.79
	draw_rect(
		Rect2(Vector2(room.position.x, horizon_y), Vector2(room.size.x, room.end.y - horizon_y)),
		Color("#120F15"),
		true
	)
	draw_line(Vector2(room.position.x, horizon_y), Vector2(room.end.x, horizon_y), GOLD.darkened(0.45), 2.0)
	for i in range(1, 5):
		var t: float = float(i) / 5.0
		var y: float = lerpf(horizon_y, room.end.y, t)
		draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color(0.851, 0.71, 0.416, 0.07), 1.0)
	var runner := PackedVector2Array([
		Vector2(room.get_center().x - room.size.x * 0.14, horizon_y),
		Vector2(room.get_center().x + room.size.x * 0.14, horizon_y),
		Vector2(room.get_center().x + room.size.x * 0.24, room.end.y),
		Vector2(room.get_center().x - room.size.x * 0.24, room.end.y)
	])
	draw_colored_polygon(runner, Color("#2A1728"))
	draw_polyline(PackedVector2Array([runner[0], runner[1], runner[2], runner[3], runner[0]]), Color(0.851, 0.71, 0.416, 0.24), 2.0)
	# Subtle runner medallions survive the small mobile render better than fine texture.
	for i in range(3):
		var t := 0.32 + float(i) * 0.20
		var c := Vector2(room.get_center().x, lerpf(horizon_y, room.end.y, t))
		var rr := lerpf(room.size.x * 0.025, room.size.x * 0.055, t)
		draw_arc(c, rr, 0.0, TAU, 28, Color(GOLD, 0.16), 2.0)
		draw_line(c - Vector2(rr * 0.6, 0), c + Vector2(rr * 0.6, 0), Color(GOLD, 0.10), 1.0)
	var center_x: float = room.get_center().x
	for x_ratio in [0.18, 0.34, 0.66, 0.82]:
		var x: float = lerpf(room.position.x, room.end.x, float(x_ratio))
		draw_line(Vector2(center_x, horizon_y), Vector2(x, room.end.y), Color(0.851, 0.71, 0.416, 0.05), 1.0)

func _draw_awakened_sparkles(room: Rect2) -> void:
	var points: Array[Vector2] = [
		Vector2(room.position.x + room.size.x * 0.24, room.position.y + room.size.y * 0.29),
		Vector2(room.end.x - room.size.x * 0.22, room.position.y + room.size.y * 0.32),
		Vector2(room.position.x + room.size.x * 0.19, room.position.y + room.size.y * 0.58),
		Vector2(room.end.x - room.size.x * 0.18, room.position.y + room.size.y * 0.54)
	]
	for p in points:
		draw_circle(p, 14.0, Color(0.851, 0.71, 0.416, 0.025))
		draw_line(p - Vector2(7, 0), p + Vector2(7, 0), Color(0.945, 0.91, 0.866, 0.62), 1.4)
		draw_line(p - Vector2(0, 7), p + Vector2(0, 7), Color(0.945, 0.91, 0.866, 0.62), 1.4)

func _draw_cat_portrait(room: Rect2) -> void:
	if _cat_portrait == null:
		return
	# First-party black-cat portrait is part of the House scene, not only the board.
	var portrait_size := Vector2(room.size.x * 0.18, room.size.y * 0.19)
	var center := Vector2(room.get_center().x, room.position.y + room.size.y * 0.77)
	var portrait := Rect2(center - portrait_size * 0.5, portrait_size)
	draw_rect(portrait.grow(5.0), Color("#100B15"), true)
	draw_rect(portrait.grow(3.0), Color(GOLD, 0.72), false, 2.0)
	draw_texture_rect(_cat_portrait, portrait, false)

func _draw_candle_props(room: Rect2) -> void:
	var candle := PieceAssetLoader.ornament("res://assets/pieces/candle.svg")
	if candle == null:
		return
	var prop_size := Vector2(room.size.x * 0.125, room.size.y * 0.155)
	for side in [-1.0, 1.0]:
		var center := Vector2(room.get_center().x + side * room.size.x * 0.405, room.position.y + room.size.y * 0.76)
		draw_texture_rect(candle, Rect2(center - prop_size * 0.5, prop_size), false)
