class_name Match3HouseHome
extends Control

signal play_requested(level_number: int)
signal collection_requested
signal map_requested
signal settings_requested
signal events_requested
signal shop_requested
signal profile_requested

const HouseState = preload("res://src/world/house_state.gd")
const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")

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

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	collection_button.pressed.connect(func(): collection_requested.emit())
	settings_button.pressed.connect(func(): settings_requested.emit())
	_resource_bar = TopResourceBar.attach(self, progress, Callable(self, "_open_profile"))
	ProductNavigation.attach(self, "house", Callable(self, "_navigate_dock"), NodePath("Layout"))
	_build_completion_banner()

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
	TopResourceBar.refresh(_resource_bar, progress)

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
	var opening_complete := available_level_count > 0 and finished >= available_level_count and owned_curios.size() >= available_level_count and stage >= available_level_count
	if _completion_banner != null:
		_completion_banner.visible = opening_complete
	if _completion_label != null:
		_completion_label.text = "OPENING CABINET SET COMPLETE · %d / %d" % [finished, available_level_count]

	var next_level := int(progress.highest_level_unlocked) if progress != null else 1
	var has_started: bool = progress != null and not progress.completed_levels.is_empty()
	var level1_completed: bool = progress != null and progress.completed_levels.has("ch01_level_001")
	play_button.disabled = available_level_count < 1
	if has_started and next_level > 1 and next_level <= available_level_count:
		play_button.text = "PLAY LEVEL %d" % next_level
	elif opening_complete:
		play_button.text = "REVISIT CURIO BOUTIQUE"
	elif level1_completed and next_level > available_level_count:
		play_button.text = "REVISIT CURIO BOUTIQUE"
	elif next_level > available_level_count:
		play_button.text = "MORE CURIOS STIR SOON"
	else:
		play_button.text = "PLAY LEVEL 1"

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
