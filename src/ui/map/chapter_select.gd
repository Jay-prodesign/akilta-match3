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
var _locked_explanation: Control

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
	world_art.modulate = Color(0.96, 0.92, 1.0, 0.98)
	add_child(world_art)
	move_child(world_art, 0)

	var veil := ColorRect.new()
	veil.name = "ChapterWorldVeil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_index = 0
	veil.color = Color(0.025, 0.02, 0.05, 0.16)
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
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color("#D5AD70"))
	eyebrow.add_theme_color_override("font_outline_color", Color("#080710", 0.92))
	eyebrow.add_theme_constant_override("outline_size", 3)
	header_copy.add_child(eyebrow)

	var title := Label.new()
	title.text = "CHOOSE A WING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
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
	detail.add_theme_font_size_override("font_size", 20)
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
		button.add_theme_font_size_override("font_size", 27 if id == "curio_boutique" else 21)
		if id == "curio_boutique":
			button.icon = PieceAssetLoader.ornament("res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg")
			button.add_theme_constant_override("icon_max_width", 156)
			button.pressed.connect(func(): chapter_requested.emit("curio_boutique"))
		else:
			button.disabled = false
			button.text = "%s\nSEALED WING · DETAILS" % String(wing["name"])
			button.tooltip_text = "%s · inspect why this future chapter remains sealed" % String(wing["name"]).capitalize()
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.pressed.connect(_open_locked_explanation.bind(id, String(wing["name"])))
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
	lock_reason.add_theme_font_size_override("font_size", 17)
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
			button.add_theme_font_size_override("font_size", 27 if current else 21)
			button.add_theme_constant_override("icon_max_width", 156 if current else 0)

func _apply_current_style(button: Button, state: String) -> void:
	button.disabled = false
	button.add_theme_color_override("font_color", Color("#FFF7E9"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#25172C", 0.86)
	box.border_color = Color("#F2D49A", 0.98)
	if state == "current_partial":
		box.bg_color = Color("#30203A", 0.88)
	elif state == "current_complete":
		box.bg_color = Color("#1B2227", 0.88)
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
	button.add_theme_color_override("font_color", Color("#E1D4E2"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#0F1017", 0.72)
	box.border_color = Color("#A68CAB", 0.48)
	box.set_border_width_all(1)
	box.set_corner_radius_all(12)
	box.shadow_color = Color(0, 0, 0, 0.42)
	box.shadow_size = 7
	button.add_theme_stylebox_override("normal", box)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#1B1721", 0.90)
	hover.border_color = Color("#D5AD70", 0.72)
	hover.set_border_width_all(2)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)

func _open_locked_explanation(chapter_id: String, chapter_name: String) -> void:
	if chapter_id == "curio_boutique":
		return
	_close_locked_explanation()
	var overlay := Control.new()
	overlay.name = "LockedExplanation"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 120
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_locked_explanation = overlay

	var veil := ColorRect.new()
	veil.name = "Dim"
	veil.color = Color(0.015, 0.01, 0.025, 0.74)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(veil)

	var panel := PanelContainer.new()
	panel.name = "LockedPanel"
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.30
	panel.anchor_bottom = 0.66
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#0D0912", 0.985)
	shell.border_color = Color("#A68CAB", 0.82)
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(18)
	shell.content_margin_left = 24
	shell.content_margin_right = 24
	shell.content_margin_top = 20
	shell.content_margin_bottom = 20
	shell.shadow_color = Color(0, 0, 0, 0.68)
	shell.shadow_size = 18
	panel.add_theme_stylebox_override("panel", shell)
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var kicker := Label.new()
	kicker.name = "State"
	kicker.text = "SEALED HOUSE WING"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_color_override("font_color", Color("#D5AD70"))
	kicker.add_theme_font_size_override("font_size", 20)
	content.add_child(kicker)

	var title := Label.new()
	title.name = "Title"
	title.text = chapter_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_font_size_override("font_size", 34)
	content.add_child(title)

	var reason := Label.new()
	reason.name = "Reason"
	reason.text = "This wing belongs to a future chapter and is not available in the current playable House."
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason.add_theme_color_override("font_color", Color("#E0D1D8"))
	reason.add_theme_font_size_override("font_size", 21)
	content.add_child(reason)

	var requirement := Label.new()
	requirement.name = "Requirement"
	requirement.text = "Future chapter content must be released first. Curio Boutique progress does not unlock this wing."
	requirement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirement.add_theme_color_override("font_color", Color("#BFA5D8"))
	requirement.add_theme_font_size_override("font_size", 19)
	content.add_child(requirement)

	var close := Button.new()
	close.name = "Close"
	close.text = "RETURN TO CHAPTERS"
	close.custom_minimum_size = Vector2(0, 62)
	close.add_theme_font_size_override("font_size", 21)
	var close_box := StyleBoxFlat.new()
	close_box.bg_color = Color("#35213B")
	close_box.border_color = Color("#D5AD70")
	close_box.set_border_width_all(2)
	close_box.set_corner_radius_all(10)
	var close_hover := close_box.duplicate() as StyleBoxFlat
	close_hover.bg_color = Color("#56305A")
	close.add_theme_stylebox_override("normal", close_box)
	close.add_theme_stylebox_override("hover", close_hover)
	close.add_theme_stylebox_override("pressed", close_hover)
	close.add_theme_color_override("font_color", Color("#FFF0D8"))
	content.add_child(close)
	close.pressed.connect(_close_locked_explanation)

func _close_locked_explanation() -> void:
	if _locked_explanation != null and is_instance_valid(_locked_explanation):
		_locked_explanation.queue_free()
	_locked_explanation = null

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
