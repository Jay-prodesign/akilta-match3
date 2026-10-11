class_name Match3HouseHome
extends Control

signal play_requested(level_number: int)
signal collection_requested
signal map_requested
signal settings_requested
signal events_requested
signal shop_requested

const HouseState = preload("res://src/world/house_state.gd")

@onready var room_view = $Layout/RoomView
@onready var headline: Label = $Layout/Headline
@onready var detail: Label = $Layout/Detail
@onready var curio_label: Label = $Layout/CurioChip/Label
@onready var collection_button: Button = $Layout/ActionDock/Actions/CollectionButton
@onready var settings_button: Button = $Layout/ActionDock/Actions/SettingsButton
@onready var play_button: Button = $Layout/PlayButton

var progress
var available_level_count: int = 1
var _dock_buttons: Dictionary = {}
var _chapter_status: Label

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	_build_resource_bar()
	_build_navigation_dock()
	collection_button.pressed.connect(func(): collection_requested.emit())
	settings_button.pressed.connect(func(): settings_requested.emit())

func set_available_level_count(value: int) -> void:
	available_level_count = max(0, value)
	if progress != null:
		_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

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
	if stage >= 3:
		curio_label.text = "3 CURIOS · FIRST CABINET SET"
	elif stage >= 2:
		curio_label.text = "2 CURIOS · MOON CAMEO + MOTH RELIQUARY"
	elif stage >= 1:
		curio_label.text = "CURIO 01 · MOON CAMEO AWAKENED"
	else:
		curio_label.text = "DORMANT DISPLAY"
	collection_button.text = "RELIQUARY · %d / 3" % owned_curios.size()
	if _chapter_status != null:
		var finished: int = mini(progress.completed_levels.size(), available_level_count) if progress != null else 0
		_chapter_status.text = "✦ %d / %d RITUALS" % [finished, available_level_count]
	var next_level := int(progress.highest_level_unlocked) if progress != null else 1
	var has_started: bool = progress != null and not progress.completed_levels.is_empty()
	var level1_completed: bool = progress != null and progress.completed_levels.has("ch01_level_001")
	play_button.disabled = available_level_count < 1
	if has_started and next_level > 1 and next_level <= available_level_count:
		play_button.text = "ENTER LEVEL %d" % next_level
	elif level1_completed and next_level > available_level_count:
		play_button.text = "REPLAY LEVEL 1"
	elif next_level > available_level_count:
		play_button.text = "MORE CURIOS STIR SOON"
	else:
		play_button.text = "OPEN CURIO MAP"

func _on_play_pressed() -> void:
	if available_level_count < 1:
		return
	var next_level := int(progress.highest_level_unlocked) if progress != null else 1
	var has_started: bool = progress != null and not progress.completed_levels.is_empty()
	if has_started and next_level > 1 and next_level <= available_level_count:
		play_requested.emit(next_level)
	else:
		map_requested.emit()

func _build_navigation_dock() -> void:
	# Touch-sized, gothic first-party navigation for the three-level internal review.
	var dock_scroll := ScrollContainer.new()
	dock_scroll.name = "BottomNavigationScroll"
	dock_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock_scroll.custom_minimum_size = Vector2(0, 64)
	dock_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	dock_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	$Layout.add_child(dock_scroll)
	var dock := HBoxContainer.new()
	dock.name = "BottomNavigation"
	dock.add_theme_constant_override("separation", 4)
	dock_scroll.add_child(dock)
	for entry in [
		{"title": "HOUSE", "action": "house"},
		{"title": "CURIOS", "action": "curios"},
		{"title": "MAP", "action": "map"},
		{"title": "EVENTS", "action": "events"},
		{"title": "SHOP", "action": "shop"},
		{"title": "PROFILE", "action": "profile"}
	]:
		var button := Button.new()
		button.text = String(entry["title"])
		button.name = "Dock" + String(entry["action"]).capitalize()
		button.custom_minimum_size = Vector2(92, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		button.tooltip_text = String(entry["title"])
		var action := String(entry["action"])
		button.pressed.connect(func(): _navigate_dock(action))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#211728")
		normal.border_color = Color("#9B7B91", 0.65)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(10)
		var active := normal.duplicate() as StyleBoxFlat
		active.bg_color = Color("#49304C")
		active.border_color = Color("#D5AD70")
		active.set_border_width_all(2)
		button.add_theme_stylebox_override("normal", active if action == "house" else normal)
		button.add_theme_stylebox_override("hover", active)
		button.add_theme_stylebox_override("pressed", active)
		button.add_theme_color_override("font_color", Color("#F4E5D3"))
		button.add_theme_color_override("font_hover_color", Color("#FFF1D9"))
		_dock_buttons[action] = button
		dock.add_child(button)

func _navigate_dock(action: String) -> void:
	match action:
		"curios": collection_requested.emit()
		"map": map_requested.emit()
		"events": events_requested.emit()
		"shop": shop_requested.emit()
		"profile": settings_requested.emit()
		"house": _refresh()

func _build_resource_bar() -> void:
	var panel := PanelContainer.new()
	panel.name = "ResourceBar"
	panel.anchor_left = 0.02
	panel.anchor_right = 0.98
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_top = 5.0
	panel.offset_bottom = 43.0
	panel.z_index = 10
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B0D17", 0.94)
	style.border_color = Color("#D5AD70", 0.68)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)
	for value in ["☾ CURIO HOUSE", "✦ CHAPTER ONE", "✧ 0 / 3 RITUALS"]:
		var label := Label.new()
		label.text = value
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#F4E5D3"))
		label.add_theme_font_size_override("font_size", 12)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if value.begins_with("✧"):
			_chapter_status = label
