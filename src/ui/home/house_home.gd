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

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
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
	play_button.disabled = available_level_count < 1
	play_button.text = "OPEN CURIO MAP" if available_level_count >= 1 else "THE MAP IS SEALED"

func _on_play_pressed() -> void:
	if available_level_count >= 1:
		map_requested.emit()

func _build_navigation_dock() -> void:
	# Persistent, touch-sized first-party navigation for the playable three-level preview.
	var dock := HBoxContainer.new()
	dock.name = "BottomNavigation"
	dock.add_theme_constant_override("separation", 4)
	$Layout.add_child(dock)
	for entry in [
		{"title": "HOUSE", "action": "house"},
		{"title": "CURIOS", "action": "curios"},
		{"title": "MAP", "action": "map"},
		{"title": "EVENTS", "action": "events"},
		{"title": "SHOP", "action": "shop"}
	]:
		var button := Button.new()
		button.text = String(entry["title"])
		button.custom_minimum_size = Vector2(0, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		var action := String(entry["action"])
		button.pressed.connect(func(): _navigate_dock(action))
		dock.add_child(button)

func _navigate_dock(action: String) -> void:
	match action:
		"curios": collection_requested.emit()
		"map": map_requested.emit()
		"events": events_requested.emit()
		"shop": shop_requested.emit()
		"house": _refresh()
