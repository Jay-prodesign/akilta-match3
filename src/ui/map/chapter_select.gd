class_name Match3ChapterSelect
extends Control

signal back_requested
signal chapter_requested(chapter_id: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const OPENING_LEVEL_COUNT := 3

const WINGS := [
	{"id":"curio_boutique","name":"CURIO BOUTIQUE","x":0.08,"y":0.04,"w":0.84,"h":0.20},
	{"id":"witch_atelier","name":"WITCH ATELIER","x":0.03,"y":0.32,"w":0.45,"h":0.14},
	{"id":"dark_vanity","name":"DARK VANITY","x":0.52,"y":0.32,"w":0.45,"h":0.14},
	{"id":"archive","name":"THE ARCHIVE","x":0.03,"y":0.51,"w":0.45,"h":0.14},
	{"id":"moon_conservatory","name":"MOON CONSERVATORY","x":0.52,"y":0.51,"w":0.45,"h":0.14},
	{"id":"cemetery_garden","name":"CEMETERY GARDEN","x":0.28,"y":0.70,"w":0.44,"h":0.14},
]

var progress
var _resource_bar: PanelContainer
var _chapter_summary: Label
var _lock_reason: Label
var _buttons: Dictionary = {}

func set_progress(value) -> void:
	progress = value
	TopResourceBar.refresh(_resource_bar, progress)
	_refresh_progress_state()

func get_chapter_button(chapter_id: String) -> Button:
	return _buttons.get(chapter_id) as Button

func chapter_state(chapter_id: String) -> String:
	var button := get_chapter_button(chapter_id)
	return String(button.get_meta("chapter_state", "")) if button != null else ""

func _ready() -> void:
	var world_art := TextureRect.new()
	world_art.name = "ChapterWorldBackdrop"
	world_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_art.z_index = -1
	world_art.texture = ScreenArt.texture("chapters_bg_curio_house")
	world_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	world_art.modulate = Color(0.88, 0.84, 0.96, 0.90)
	add_child(world_art)
	move_child(world_art, 0)

	var veil := ColorRect.new()
	veil.name = "ChapterWorldVeil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_index = 0
	veil.color = Color(0.025, 0.02, 0.05, 0.24)
	add_child(veil)

	_resource_bar = TopResourceBar.attach(self, progress)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 16
	layout.offset_right = -16
	layout.offset_top = 66
	layout.offset_bottom = -16
	layout.add_theme_constant_override("separation", 7)
	layout.z_index = 10
	add_child(layout)

	var header_row := HBoxContainer.new()
	header_row.name = "ChapterHeader"
	header_row.add_theme_constant_override("separation", 10)
	layout.add_child(header_row)

	var back := Button.new()
	back.name = "HeaderBack"
	back.text = "‹  HOUSE"
	back.custom_minimum_size = Vector2(122, 46)
	back.tooltip_text = "Return to the House"
	back.add_theme_font_size_override("font_size", 16)
	_style_header_back(back)
	back.pressed.connect(func(): back_requested.emit())
	header_row.add_child(back)

	var header_copy := VBoxContainer.new()
	header_copy.name = "HeaderCopy"
	header_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_copy.add_theme_constant_override("separation", 0)
	header_row.add_child(header_copy)

	var eyebrow := Label.new()
	eyebrow.text = "THE HOUSE AND ITS CHAPTERS"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", Color("#D5AD70"))
	eyebrow.add_theme_color_override("font_outline_color", Color("#080710", 0.92))
	eyebrow.add_theme_constant_override("outline_size", 3)
	header_copy.add_child(eyebrow)

	var title := Label.new()
	title.text = "CHOOSE A WING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_color_override("font_outline_color", Color("#080710", 0.94))
	title.add_theme_constant_override("outline_size", 4)
	header_copy.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(122, 1)
	header_row.add_child(spacer)

	var detail := Label.new()
	detail.name = "ChapterSummary"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 16)
	detail.add_theme_color_override("font_color", Color("#F0DCCB"))
	detail.add_theme_color_override("font_outline_color", Color("#080710", 0.86))
	detail.add_theme_constant_override("outline_size", 2)
	layout.add_child(detail)
	_chapter_summary = detail

	var grid := Control.new()
	grid.name = "ChapterGrid"
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.clip_contents = false
	layout.add_child(grid)

	var hotspot_buttons: Array[Button] = []
	for wing in WINGS:
		var id := String(wing["id"])
		var button := Button.new()
		button.name = "CurioBoutiqueButton" if id == "curio_boutique" else "Chapter_" + id
		button.set_meta("chapter_id", id)
		button.set_meta("map_x", float(wing["x"]))
		button.set_meta("map_y", float(wing["y"]))
		button.set_meta("map_w", float(wing["w"]))
		button.set_meta("map_h", float(wing["h"]))
		button.set_meta("chapter_state", "first_wing_open" if id == "curio_boutique" else "future_wings_locked")
		button.custom_minimum_size = Vector2.ZERO
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 20 if id == "curio_boutique" else 17)
		if id == "curio_boutique":
			button.icon = PieceAssetLoader.ornament("res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg")
			button.add_theme_constant_override("icon_max_width", 122)
			button.pressed.connect(func(): chapter_requested.emit("curio_boutique"))
		else:
			button.disabled = true
			button.text = "%s\nSEALED WING" % String(wing["name"])
			button.tooltip_text = "%s · future chapter remains sealed" % String(wing["name"]).capitalize()
		_apply_locked_style(button)
		grid.add_child(button)
		_buttons[id] = button
		hotspot_buttons.append(button)

	grid.resized.connect(func(): _layout_chapter_hotspots(grid, hotspot_buttons))
	call_deferred("_layout_chapter_hotspots", grid, hotspot_buttons)

	var lock_reason := Label.new()
	lock_reason.name = "LockReason"
	lock_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lock_reason.add_theme_font_size_override("font_size", 14)
	lock_reason.add_theme_color_override("font_color", Color("#BFA5D8"))
	lock_reason.add_theme_color_override("font_outline_color", Color("#080710", 0.82))
	lock_reason.add_theme_constant_override("outline_size", 2)
	layout.add_child(lock_reason)
	_lock_reason = lock_reason

	_refresh_progress_state()

func _refresh_progress_state() -> void:
	var current := get_chapter_button("curio_boutique")
	if current == null or _chapter_summary == null or _lock_reason == null:
		return
	var completed := 0
	var collected := 0
	var restored := 0
	if progress != null:
		completed = mini(int(progress.completed_levels.size()), OPENING_LEVEL_COUNT)
		collected = mini(int(progress.curios.size()), OPENING_LEVEL_COUNT)
		restored = int(progress.house_stage)
	var opening_complete := completed >= OPENING_LEVEL_COUNT and collected >= OPENING_LEVEL_COUNT and restored >= OPENING_LEVEL_COUNT
	var state := "first_wing_open"
	if opening_complete:
		state = "current_complete"
		current.text = "CURIO BOUTIQUE\nRESTORED · 3 / 3 · FIRST CABINET SET"
		current.tooltip_text = "Curio Boutique · first cabinet set restored · Levels 1–3 replayable"
		_chapter_summary.text = "The opening wing is restored. Revisit its rituals while the deeper House remains sealed."
		_lock_reason.text = "FIVE WINGS REMAIN SEALED · FUTURE CHAPTERS"
	elif completed > 0:
		state = "current_partial"
		current.text = "CURIO BOUTIQUE\n%d / %d DISPLAYS AWAKENED · CONTINUE" % [completed, OPENING_LEVEL_COUNT]
		current.tooltip_text = "Curio Boutique · %d / %d opening displays awakened" % [completed, OPENING_LEVEL_COUNT]
		_chapter_summary.text = "%d of %d displays are awake. Continue the Curio Boutique restoration." % [completed, OPENING_LEVEL_COUNT]
		_lock_reason.text = "RESTORE THE CURRENT WING · FUTURE WINGS STAY SEALED"
	else:
		current.text = "CURIO BOUTIQUE\nOPENING RITUALS · 0 / 3"
		current.tooltip_text = "Curio Boutique · opening rituals · Levels 1–3"
		_chapter_summary.text = "The Curio Boutique is the House's first open wing. Begin its three opening rituals."
		_lock_reason.text = "FUTURE WINGS ARE SEALED UNTIL LATER CHAPTERS"
	current.set_meta("chapter_state", state)
	_apply_current_style(current, state)
	for wing in WINGS:
		var id := String(wing["id"])
		if id == "curio_boutique":
			continue
		var locked := get_chapter_button(id)
		if locked != null:
			locked.set_meta("chapter_state", "future_wings_locked")

func _layout_chapter_hotspots(grid: Control, buttons: Array[Button]) -> void:
	var compact := grid.size.x < 680.0
	var count := buttons.size()
	for i in range(count):
		var button := buttons[i]
		if compact:
			var spacing := 6.0
			var card_height := maxf(52.0, (grid.size.y - spacing * float(count - 1)) / float(count))
			button.position = Vector2(0, float(i) * (card_height + spacing))
			button.size = Vector2(grid.size.x, card_height)
			button.add_theme_font_size_override("font_size", 14)
			button.add_theme_constant_override("icon_max_width", 56)
		else:
			button.position = Vector2(grid.size.x * float(button.get_meta("map_x")), grid.size.y * float(button.get_meta("map_y")))
			button.size = Vector2(grid.size.x * float(button.get_meta("map_w")), grid.size.y * float(button.get_meta("map_h")))
			var current := String(button.get_meta("chapter_id", "")) == "curio_boutique"
			button.add_theme_font_size_override("font_size", 22 if current else 17)
			button.add_theme_constant_override("icon_max_width", 126 if current else 0)

func _apply_current_style(button: Button, state: String) -> void:
	button.disabled = false
	button.add_theme_color_override("font_color", Color("#FFF7E9"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#25172C", 0.94)
	box.border_color = Color("#F2D49A", 0.98)
	if state == "current_partial":
		box.bg_color = Color("#30203A", 0.96)
	elif state == "current_complete":
		box.bg_color = Color("#1B2227", 0.96)
		box.border_color = Color("#E4C67F")
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.shadow_color = Color(0, 0, 0, 0.62)
	box.shadow_size = 12
	button.add_theme_stylebox_override("normal", box)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = box.bg_color.lightened(0.08)
	hover.border_color = Color("#FFF0B8")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)

func _apply_locked_style(button: Button) -> void:
	button.add_theme_color_override("font_disabled_color", Color("#C9BCCB"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#0F1017", 0.86)
	box.border_color = Color("#756779", 0.58)
	box.set_border_width_all(1)
	box.set_corner_radius_all(12)
	box.shadow_color = Color(0, 0, 0, 0.42)
	box.shadow_size = 7
	button.add_theme_stylebox_override("disabled", box)

func _style_header_back(button: Button) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#15111B", 0.94)
	box.border_color = Color("#D5AD70", 0.72)
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#35233B", 0.98)
	hover.border_color = Color("#F2D08B")
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color("#F4E5D3"))
