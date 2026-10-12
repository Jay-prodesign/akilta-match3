class_name Match3HouseHome
extends Control

signal play_requested(level_number: int)
signal collection_requested
signal map_requested
signal settings_requested
signal events_requested
signal shop_requested
signal profile_requested
signal restoration_finished

const HouseState = preload("res://src/world/house_state.gd")
const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

@onready var room_view = $Layout/RoomView
@onready var headline: Label = $Layout/Headline
@onready var detail: Label = $Layout/Detail
@onready var curio_label: Label = $Layout/CurioChip/Label
@onready var collection_button: Button = $Layout/ActionDock/Actions/CollectionButton
@onready var settings_button: Button = $Layout/ActionDock/Actions/SettingsButton
@onready var play_button: Button = $Layout/PlayButton

var progress
var available_level_count: int = 1
var _completion_banner: PanelContainer
var _completion_label: Label
var _resource_bar: PanelContainer
var _returning_player: bool = false
var _returning_banner: PanelContainer
var _returning_label: Label
var _reduced_motion: bool = false
var _hotspot_layer: Control
var _hotspot_buttons: Dictionary = {}
var _house_curio_overlay: Control
var _keeper_hotspot: Button
var _keeper_overlay: Control
const KEEPER_ART_PATH := "res://assets/pieces/black_cat.webp"

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	collection_button.pressed.connect(func(): collection_requested.emit())
	settings_button.pressed.connect(func(): settings_requested.emit())
	_resource_bar = TopResourceBar.attach(self, progress, Callable(self, "_open_profile"))
	ProductNavigation.attach(self, "house", Callable(self, "_navigate_dock"), NodePath("Layout"))
	_build_returning_banner()
	_build_completion_banner()
	_build_room_hotspots()
	_build_keeper_hotspot()

func set_available_level_count(value: int) -> void:
	available_level_count = max(0, value)
	if progress != null:
		_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func set_returning_player(value: bool) -> void:
	_returning_player = value
	_refresh()

func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))

func _refresh() -> void:
	var stage: int = 0
	var owned_curios: Array[String] = []
	if progress != null:
		stage = int(progress.house_stage)
		for curio in progress.curios:
			owned_curios.append(String(curio))

	var state: Dictionary = HouseState.descriptor(stage)
	headline.text = String(state.get("headline", "The Curio Boutique sleeps."))
	detail.text = String(state.get("detail", ""))
	room_view.set_house_state(stage, owned_curios)
	TopResourceBar.refresh(_resource_bar, progress)
	_refresh_room_hotspots()

	if stage >= 3:
		curio_label.text = "FIRST CABINET SET · 3 / 3 CURIOS"
	elif stage >= 2:
		curio_label.text = "FIRST CABINET · 2 / 3 CURIOS"
	elif stage >= 1:
		curio_label.text = "MOON CAMEO · FIRST CURIO AWAKENED"
	else:
		curio_label.text = "THE HOUSE AWAITS · 0 / 3 CURIOS"

	collection_button.text = "RELIQUARY · %d / 3" % owned_curios.size()
	var finished: int = mini(progress.completed_levels.size(), available_level_count) if progress != null else 0
	var has_started: bool = progress != null and not progress.completed_levels.is_empty()
	var opening_complete := available_level_count > 0 and finished >= available_level_count and owned_curios.size() >= available_level_count and stage >= available_level_count
	if _returning_banner != null:
		_returning_banner.visible = _returning_player and has_started
	if _returning_label != null:
		if opening_complete:
			_returning_label.text = "WELCOME BACK · FIRST CABINET RESTORED"
		else:
			_returning_label.text = "WELCOME BACK · %d / %d CURIOS AWAKENED" % [owned_curios.size(), available_level_count]
	if _completion_banner != null:
		_completion_banner.visible = opening_complete and not _returning_player
	if _completion_label != null:
		_completion_label.text = "OPENING CABINET SET COMPLETE · %d / %d" % [finished, available_level_count]

	var next_level := int(progress.highest_level_unlocked) if progress != null else 1
	var level1_completed: bool = progress != null and progress.completed_levels.has("ch01_level_001")
	play_button.disabled = available_level_count < 1
	if has_started and next_level > 1 and next_level <= available_level_count:
		play_button.text = "CONTINUE CURIO BOUTIQUE"
	elif opening_complete:
		play_button.text = "REVISIT CURIO BOUTIQUE"
	elif level1_completed and next_level > available_level_count:
		play_button.text = "REVISIT CURIO BOUTIQUE"
	elif next_level > available_level_count:
		play_button.text = "MORE CURIOS STIR SOON"
	else:
		play_button.text = "ENTER CURIO BOUTIQUE"

func _on_play_pressed() -> void:
	if available_level_count < 1:
		return
	var next_level := int(progress.highest_level_unlocked) if progress != null else 1
	var has_started: bool = progress != null and not progress.completed_levels.is_empty()
	if has_started and next_level > 1 and next_level <= available_level_count:
		play_requested.emit(next_level)
	elif next_level == 1 and not has_started:
		play_requested.emit(1)
	else:
		map_requested.emit()

func _open_profile() -> void:
	profile_requested.emit()

func _navigate_dock(action: String) -> void:
	match action:
		"house":
			_refresh()
		"curios":
			collection_requested.emit()
		"map":
			map_requested.emit()
		"events":
			events_requested.emit()
		"shop":
			shop_requested.emit()

func _build_returning_banner() -> void:
	var panel := PanelContainer.new()
	panel.name = "ReturningPlayerBanner"
	panel.custom_minimum_size = Vector2(0, 42)
	panel.visible = false
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#17111F", 0.96)
	shell.border_color = Color("#BFA5D8", 0.72)
	shell.set_border_width_all(1)
	shell.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", shell)
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#F2D08B"))
	label.add_theme_font_size_override("font_size", 14)
	panel.add_child(label)
	$Layout.add_child(panel)
	$Layout.move_child(panel, $Layout/CurioChip.get_index() + 1)
	_returning_banner = panel
	_returning_label = label

func _build_completion_banner() -> void:
	var panel := PanelContainer.new()
	panel.name = "ChapterCompletionBanner"
	panel.custom_minimum_size = Vector2(0, 38)
	panel.visible = false
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#211426", 0.94)
	shell.border_color = Color("#D5AD70", 0.78)
	shell.set_border_width_all(1)
	shell.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", shell)
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#F2D08B"))
	label.add_theme_font_size_override("font_size", 14)
	panel.add_child(label)
	$Layout.add_child(panel)
	$Layout.move_child(panel, $Layout/CurioChip.get_index() + 1)
	_completion_banner = panel
	_completion_label = label

func _build_room_hotspots() -> void:
	if room_view == null or _hotspot_layer != null:
		return
	var layer := Control.new()
	layer.name = "CurioHotspots"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_view.add_child(layer)
	_hotspot_layer = layer
	for spec in [
		{"id":"moon_cameo", "name":"MoonHotspot", "x":0.93, "y":0.27},
		{"id":"moth_reliquary", "name":"MothHotspot", "x":0.93, "y":0.38},
		{"id":"thorned_locket", "name":"ThornHotspot", "x":0.93, "y":0.49}
	]:
		var button := Button.new()
		button.name = String(spec["name"])
		var x := float(spec["x"])
		var y := float(spec["y"])
		button.anchor_left = x
		button.anchor_right = x
		button.anchor_top = y
		button.anchor_bottom = y
		button.offset_left = -30
		button.offset_right = 30
		button.offset_top = -30
		button.offset_bottom = 30
		button.custom_minimum_size = Vector2(60, 60)
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "Inspect %s" % _curio_name(String(spec["id"])).capitalize()
		button.add_theme_font_size_override("font_size", 25)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#18111F", 0.22)
		normal.border_color = Color("#F0CE8A", 0.58)
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(30)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#3A2340", 0.72)
		hover.border_color = Color("#FFF1B6", 0.92)
		var disabled := normal.duplicate() as StyleBoxFlat
		disabled.bg_color = Color("#0D0A11", 0.12)
		disabled.border_color = Color("#7F7180", 0.24)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_stylebox_override("disabled", disabled)
		button.add_theme_color_override("font_color", Color("#FFF1B6", 0.86))
		button.add_theme_color_override("font_disabled_color", Color("#817783", 0.58))
		button.pressed.connect(_open_house_curio_inspect.bind(String(spec["id"])))
		layer.add_child(button)
		_hotspot_buttons[String(spec["id"])] = button
	_refresh_room_hotspots()

func _refresh_room_hotspots() -> void:
	if _hotspot_buttons.is_empty():
		return
	var owned: Array = progress.curios if progress != null else []
	for curio_id in _hotspot_buttons.keys():
		var button := _hotspot_buttons[curio_id] as Button
		if button == null:
			continue
		var awakened := owned.has(String(curio_id))
		button.disabled = not awakened
		button.text = "✦" if awakened else "◇"
		button.set_meta("curio_id", String(curio_id))
		button.set_meta("ownership_state", "owned" if awakened else "locked")

func house_hotspot_contract() -> Dictionary:
	var states := {}
	for curio_id in _hotspot_buttons.keys():
		var button := _hotspot_buttons[curio_id] as Button
		states[String(curio_id)] = {
			"disabled": button.disabled if button != null else true,
			"state": String(button.get_meta("ownership_state", "missing")) if button != null else "missing",
			"visible": button.visible if button != null else false,
		}
	return {
		"states": states,
		"owned_count": progress.curios.size() if progress != null else 0,
		"overlay_open": _house_curio_overlay != null and is_instance_valid(_house_curio_overlay),
	}

func _open_house_curio_inspect(curio_id: String) -> void:
	if progress == null or not progress.curios.has(curio_id):
		return
	_close_house_curio_inspect()
	var data := _house_curio_data(curio_id)
	if data.is_empty():
		return
	var overlay := Control.new()
	overlay.name = "HouseCurioInspect"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 140
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_house_curio_overlay = overlay

	var veil := ColorRect.new()
	veil.color = Color(0.012, 0.008, 0.018, 0.64)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(veil)

	var card := PanelContainer.new()
	card.name = "Card"
	card.anchor_left = 0.09
	card.anchor_right = 0.91
	card.anchor_top = 0.16
	card.anchor_bottom = 0.45
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#0D0912", 0.985)
	shell.border_color = Color("#D5AD70", 0.88)
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(20)
	shell.content_margin_left = 22
	shell.content_margin_right = 22
	shell.content_margin_top = 18
	shell.content_margin_bottom = 18
	shell.shadow_color = Color(0, 0, 0, 0.66)
	shell.shadow_size = 18
	card.add_theme_stylebox_override("panel", shell)
	overlay.add_child(card)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 7)
	card.add_child(content)

	var kicker := Label.new()
	kicker.text = "HOUSE · RESTORED CURIO"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_color_override("font_color", Color("#D5AD70"))
	kicker.add_theme_font_size_override("font_size", 18)
	content.add_child(kicker)

	var art := TextureRect.new()
	art.name = "HeroArt"
	art.custom_minimum_size = Vector2(0, 170)
	art.texture = _curio_texture(curio_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(art)

	var title := Label.new()
	title.name = "Name"
	title.text = _curio_name(curio_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var origin := Label.new()
	origin.name = "Origin"
	origin.text = String(data.get("origin", ""))
	origin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	origin.add_theme_color_override("font_color", Color("#BDAFC3"))
	origin.add_theme_font_size_override("font_size", 18)
	content.add_child(origin)

	var effect := Label.new()
	effect.name = "HouseEffect"
	effect.text = String(data.get("effect", ""))
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.add_theme_color_override("font_color", Color("#E7D9DF"))
	effect.add_theme_font_size_override("font_size", 20)
	content.add_child(effect)

	var close := Button.new()
	close.name = "Close"
	close.text = "RETURN TO HOUSE"
	close.custom_minimum_size = Vector2(0, 56)
	close.add_theme_font_size_override("font_size", 20)
	var close_box := StyleBoxFlat.new()
	close_box.bg_color = Color("#4A1A51")
	close_box.border_color = Color("#D5AD70")
	close_box.set_border_width_all(2)
	close_box.set_corner_radius_all(12)
	close.add_theme_stylebox_override("normal", close_box)
	close.add_theme_stylebox_override("hover", close_box)
	close.add_theme_stylebox_override("pressed", close_box)
	close.add_theme_color_override("font_color", Color("#FFF0D8"))
	content.add_child(close)
	close.pressed.connect(_close_house_curio_inspect)

func _close_house_curio_inspect() -> void:
	if _house_curio_overlay != null and is_instance_valid(_house_curio_overlay):
		_house_curio_overlay.queue_free()
	_house_curio_overlay = null

func _house_curio_data(curio_id: String) -> Dictionary:
	match curio_id:
		"moon_cameo":
			return {
				"origin": "RECOVERED FROM · MOONLIT CABINET · LEVEL 1",
				"effect": "Moonlight now remains visible in the first restored cabinet niche."
			}
		"moth_reliquary":
			return {
				"origin": "RECOVERED FROM · SEALED DISPLAY · LEVEL 2",
				"effect": "The side display stays open and the Moth Reliquary remains part of the House."
			}
		"thorned_locket":
			return {
				"origin": "RECOVERED FROM · THORNLIGHT ARRANGEMENT · LEVEL 3",
				"effect": "The third restored niche completes the opening cabinet set."
			}
		_:
			return {}

func _build_keeper_hotspot() -> void:
	if room_view == null or _keeper_hotspot != null:
		return
	if _hotspot_layer == null:
		_build_room_hotspots()
	var button := Button.new()
	button.name = "KeeperHotspot"
	button.anchor_left = 0.27
	button.anchor_right = 0.27
	button.anchor_top = 0.56
	button.anchor_bottom = 0.56
	button.offset_left = -34
	button.offset_right = 34
	button.offset_top = -34
	button.offset_bottom = 34
	button.custom_minimum_size = Vector2(68, 68)
	button.icon = PieceAssetLoader.ornament(KEEPER_ART_PATH)
	button.expand_icon = true
	button.tooltip_text = "Meet the Keeper"
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#0E0A14", 0.20)
	normal.border_color = Color("#D5AD70", 0.46)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(34)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#2C1A31", 0.72)
	hover.border_color = Color("#FFF1B6", 0.92)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.pressed.connect(_open_keeper_card)
	_hotspot_layer.add_child(button)
	_keeper_hotspot = button

func _open_keeper_card() -> void:
	_close_keeper_card()
	var overlay := Control.new()
	overlay.name = "KeeperRoleOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 150
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_keeper_overlay = overlay

	var veil := ColorRect.new()
	veil.color = Color(0.012, 0.008, 0.018, 0.64)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(veil)

	var card := PanelContainer.new()
	card.name = "Card"
	card.anchor_left = 0.10
	card.anchor_right = 0.90
	card.anchor_top = 0.17
	card.anchor_bottom = 0.50
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#0D0912", 0.985)
	shell.border_color = Color("#D5AD70", 0.86)
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(20)
	shell.content_margin_left = 22
	shell.content_margin_right = 22
	shell.content_margin_top = 18
	shell.content_margin_bottom = 18
	shell.shadow_color = Color(0, 0, 0, 0.66)
	shell.shadow_size = 18
	card.add_theme_stylebox_override("panel", shell)
	overlay.add_child(card)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 8)
	card.add_child(content)

	var kicker := Label.new()
	kicker.text = "HOUSE FAMILIAR"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_color_override("font_color", Color("#D5AD70"))
	kicker.add_theme_font_size_override("font_size", 18)
	content.add_child(kicker)

	var art := TextureRect.new()
	art.name = "KeeperArt"
	art.custom_minimum_size = Vector2(0, 170)
	art.texture = PieceAssetLoader.ornament(KEEPER_ART_PATH)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(art)

	var title := Label.new()
	title.name = "Name"
	title.text = "THE KEEPER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var role := Label.new()
	role.name = "Role"
	role.text = "PUZZLE GUIDE · NO COST · NO BOARD CHANGES"
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.add_theme_color_override("font_color", Color("#F0CE8A"))
	role.add_theme_font_size_override("font_size", 18)
	content.add_child(role)

	var body := Label.new()
	body.name = "Body"
	body.text = "In a puzzle, ASK KEEPER marks one legal adjacent swap. The Keeper never spends currency, changes the board, or adds moves."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("#E7D9DF"))
	body.add_theme_font_size_override("font_size", 20)
	content.add_child(body)

	var close := Button.new()
	close.name = "Close"
	close.text = "RETURN TO HOUSE"
	close.custom_minimum_size = Vector2(0, 56)
	close.add_theme_font_size_override("font_size", 20)
	var close_box := StyleBoxFlat.new()
	close_box.bg_color = Color("#4A1A51")
	close_box.border_color = Color("#D5AD70")
	close_box.set_border_width_all(2)
	close_box.set_corner_radius_all(12)
	close.add_theme_stylebox_override("normal", close_box)
	close.add_theme_stylebox_override("hover", close_box)
	close.add_theme_stylebox_override("pressed", close_box)
	close.add_theme_color_override("font_color", Color("#FFF0D8"))
	content.add_child(close)
	close.pressed.connect(_close_keeper_card)

func _close_keeper_card() -> void:
	if _keeper_overlay != null and is_instance_valid(_keeper_overlay):
		_keeper_overlay.queue_free()
	_keeper_overlay = null

func keeper_house_contract() -> Dictionary:
	return {
		"role": "non_mutating_legal_move_guide",
		"asset": KEEPER_ART_PATH,
		"raster_runtime": KEEPER_ART_PATH.ends_with(".webp") or KEEPER_ART_PATH.ends_with(".png"),
		"hotspot_visible": _keeper_hotspot != null and _keeper_hotspot.visible,
		"touch_target_ok": _keeper_hotspot != null and _keeper_hotspot.custom_minimum_size.x >= 56.0 and _keeper_hotspot.custom_minimum_size.y >= 56.0,
		"spends_resources": false,
		"changes_board": false,
		"adds_moves": false,
	}

func show_restoration_ceremony(curio_id: String, stage: int) -> void:
	if get_node_or_null("RestorationOverlay") != null:
		return
	var product_nav := get_node_or_null("ProductNavigation") as Control
	if product_nav != null:
		product_nav.visible = false
	play_button.visible = false
	curio_label.get_parent().visible = false
	headline.visible = false
	detail.visible = false
	if _completion_banner != null:
		_completion_banner.visible = false
	var current_curios: Array[String] = []
	if progress != null:
		for item in progress.curios:
			current_curios.append(String(item))
	var previous_curios := current_curios.duplicate()
	previous_curios.erase(curio_id)
	room_view.set_house_state(maxi(0, stage - 1), previous_curios)

	var overlay := Control.new()
	overlay.name = "RestorationOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 90
	add_child(overlay)

	var veil := ColorRect.new()
	veil.color = Color(0.02, 0.015, 0.03, 0.22)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(veil)

	var panel := PanelContainer.new()
	panel.name = "CeremonyCard"
	panel.anchor_left = 0.06
	panel.anchor_right = 0.94
	panel.anchor_top = 0.70
	panel.anchor_bottom = 0.82
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#09070D", 0.985)
	shell.border_color = Color("#D5AD70", 0.88)
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(14)
	shell.content_margin_left = 12
	shell.content_margin_right = 12
	shell.content_margin_top = 8
	shell.content_margin_bottom = 8
	shell.shadow_color = Color(0, 0, 0, 0.58)
	shell.shadow_size = 14
	panel.add_theme_stylebox_override("panel", shell)
	overlay.add_child(panel)

	var header := VBoxContainer.new()
	header.name = "RestorationHeader"
	header.anchor_left = 0.08
	header.anchor_right = 0.92
	header.anchor_top = 0.09
	header.anchor_bottom = 0.24
	header.add_theme_constant_override("separation", 4)
	overlay.add_child(header)
	var section := Label.new()
	section.text = "HOUSE RESTORATION"
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_theme_color_override("font_color", Color("#D5AD70"))
	section.add_theme_font_size_override("font_size", 18)
	header.add_child(section)
	var hero_title := Label.new()
	hero_title.name = "RestorationHeroTitle"
	hero_title.text = _curio_name(curio_id)
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_color_override("font_color", Color("#FFF0D8"))
	hero_title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03, 0.96))
	hero_title.add_theme_constant_override("outline_size", 5)
	hero_title.add_theme_font_size_override("font_size", 34)
	header.add_child(hero_title)
	var hero_copy := Label.new()
	hero_copy.text = "THE HOUSE REMEMBERS"
	hero_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_copy.add_theme_color_override("font_color", Color("#D9C5D0"))
	hero_copy.add_theme_font_size_override("font_size", 16)
	header.add_child(hero_copy)

	var hero_art := TextureRect.new()
	hero_art.name = "AwakeningMotif"
	hero_art.anchor_left = 0.32
	hero_art.anchor_right = 0.68
	hero_art.anchor_top = 0.27
	hero_art.anchor_bottom = 0.56
	hero_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_art.texture = _restoration_motif_texture(curio_id)
	hero_art.modulate = Color(1.0, 0.96, 0.88, 1.0)
	overlay.add_child(hero_art)

	var ceremony := VBoxContainer.new()
	ceremony.name = "CeremonyContent"
	ceremony.add_theme_constant_override("separation", 5)
	panel.add_child(ceremony)
	var row := HBoxContainer.new()
	row.name = "CeremonyRow"
	row.add_theme_constant_override("separation", 12)
	ceremony.add_child(row)

	var art := TextureRect.new()
	art.name = "RestoredCurioArt"
	art.custom_minimum_size = Vector2(82, 82)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _curio_texture(curio_id)
	row.add_child(art)

	var copy := VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 5)
	row.add_child(copy)

	var body := Label.new()
	body.text = _restoration_copy(stage)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("#DDCED6"))
	body.add_theme_font_size_override("font_size", 19)
	copy.add_child(body)

	var button := Button.new()
	button.name = "Continue"
	button.text = "CONTINUE"
	button.custom_minimum_size = Vector2(0, 58)
	button.add_theme_font_size_override("font_size", 21)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#4A1A51")
	normal.border_color = Color("#D5AD70")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color("#FFF0D8"))
	button.pressed.connect(func():
		overlay.queue_free()
		play_button.visible = true
		curio_label.get_parent().visible = true
		headline.visible = true
		detail.visible = true
		if product_nav != null:
			product_nav.visible = true
		_refresh()
		restoration_finished.emit()
	)
	copy.add_child(button)

	_animate_restoration_state(curio_id, stage, current_curios)

func _animate_restoration_state(curio_id: String, stage: int, current_curios: Array[String]) -> void:
	await get_tree().process_frame
	if not is_instance_valid(self):
		return
	room_view.set_house_state(stage, current_curios)
	room_view.modulate = Color.WHITE
	if _reduced_motion:
		return

	room_view.modulate = Color(0.70, 0.64, 0.82, 1)
	var restored_curio := room_view.get_node_or_null("MoonCameoOverlay") as Control
	if restored_curio != null and restored_curio.visible and stage == 1:
		restored_curio.pivot_offset = restored_curio.size * 0.5
		restored_curio.scale = Vector2(0.52, 0.52)
		restored_curio.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var awakening_echo: TextureRect
	if stage >= 2:
		awakening_echo = TextureRect.new()
		awakening_echo.name = "RestorationAwakeningEcho"
		awakening_echo.texture = _curio_texture(curio_id)
		awakening_echo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		awakening_echo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		awakening_echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		awakening_echo.z_index = 8
		var room_margin: float = float(room_view.size.x) * 0.035
		var world_room: Rect2 = Rect2(
			Vector2(room_margin, room_view.size.y * 0.025),
			Vector2(room_view.size.x - room_margin * 2.0, room_view.size.y * 0.93)
		)
		var side: float = world_room.size.x * 0.15
		awakening_echo.size = Vector2(side, side)
		var y_ratio: float = 0.38 if stage == 2 else 0.49
		var center: Vector2 = Vector2(
			world_room.position.x + world_room.size.x * 0.84,
			world_room.position.y + world_room.size.y * y_ratio
		)
		awakening_echo.position = center - awakening_echo.size * 0.5
		awakening_echo.pivot_offset = awakening_echo.size * 0.5
		awakening_echo.scale = Vector2(0.82, 0.82)
		awakening_echo.modulate = Color(1.0, 0.94, 0.78, 0.0)
		room_view.add_child(awakening_echo)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(room_view, "modulate", Color.WHITE, 0.55)
	if restored_curio != null and restored_curio.visible and stage == 1:
		tween.parallel().tween_property(restored_curio, "modulate", Color.WHITE, 0.34)
		tween.parallel().tween_property(restored_curio, "scale", Vector2.ONE, 0.56).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if awakening_echo != null:
		tween.parallel().tween_property(awakening_echo, "modulate", Color(1.0, 0.94, 0.78, 0.72), 0.28)
		tween.parallel().tween_property(awakening_echo, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(awakening_echo, "modulate", Color(1.0, 0.94, 0.78, 0.0), 0.26)
		tween.tween_callback(awakening_echo.queue_free)

func _restoration_motif_texture(curio_id: String) -> Texture2D:
	# The large transient awakening layer communicates each relic's motif using
	# the accepted production piece family. Exact Curio identity remains on the
	# item card and the persistent House niche; the motif is never a substitute
	# for ownership/progression truth.
	var path := "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp"
	if curio_id == "moth_reliquary":
		path = "res://assets/pieces/luna_moth.webp"
	elif curio_id == "thorned_locket":
		path = "res://assets/pieces/thorn_rose.webp"
	return PieceAssetLoader.ornament(path)

func _curio_texture(curio_id: String) -> Texture2D:
	var path := "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp"
	if curio_id == "moth_reliquary":
		path = "res://assets/curios/ch01_curio_moth_reliquary.png"
	elif curio_id == "thorned_locket":
		path = "res://assets/curios/ch01_curio_thorned_locket.png"
	return PieceAssetLoader.ornament(path)

func _curio_name(curio_id: String) -> String:
	match curio_id:
		"moth_reliquary": return "MOTH RELIQUARY"
		"thorned_locket": return "THORNED LOCKET"
		_: return "MOON CAMEO"

func _restoration_copy(stage: int) -> String:
	match stage:
		1: return "Moonlight returns to the first cabinet. The Moon Cameo now lives in the House."
		2: return "The side display opens for the Moth Reliquary."
		3: return "The Thorned Locket completes the opening cabinet set."
		_: return "A recovered Curio takes its place in the House."
