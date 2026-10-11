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
	veil.color = Color(0.02, 0.015, 0.03, 0.30)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(veil)

	var panel := PanelContainer.new()
	panel.name = "CeremonyCard"
	panel.anchor_left = 0.10
	panel.anchor_right = 0.90
	panel.anchor_top = 0.57
	panel.anchor_bottom = 0.77
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#09070D", 0.985)
	shell.border_color = Color("#D5AD70", 0.88)
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(14)
	shell.content_margin_left = 16
	shell.content_margin_right = 16
	shell.content_margin_top = 12
	shell.content_margin_bottom = 12
	shell.shadow_color = Color(0, 0, 0, 0.58)
	shell.shadow_size = 14
	panel.add_theme_stylebox_override("panel", shell)
	overlay.add_child(panel)

	var ceremony := VBoxContainer.new()
	ceremony.name = "CeremonyContent"
	ceremony.add_theme_constant_override("separation", 7)
	panel.add_child(ceremony)
	var section := Label.new()
	section.text = "HOUSE RESTORATION"
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_theme_color_override("font_color", Color("#D5AD70"))
	section.add_theme_font_size_override("font_size", 14)
	ceremony.add_child(section)
	var divider := HSeparator.new()
	divider.modulate = Color("#D5AD70", 0.45)
	ceremony.add_child(divider)
	var row := HBoxContainer.new()
	row.name = "CeremonyRow"
	row.add_theme_constant_override("separation", 14)
	ceremony.add_child(row)

	var art := TextureRect.new()
	art.name = "RestoredCurioArt"
	art.custom_minimum_size = Vector2(124, 124)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _curio_texture(curio_id)
	row.add_child(art)

	var copy := VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 5)
	row.add_child(copy)

	var kicker := Label.new()
	kicker.text = "THE HOUSE REMEMBERS"
	kicker.add_theme_color_override("font_color", Color("#D5AD70"))
	kicker.add_theme_font_size_override("font_size", 14)
	copy.add_child(kicker)

	var title := Label.new()
	title.text = _curio_name(curio_id)
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_font_size_override("font_size", 27)
	copy.add_child(title)

	var body := Label.new()
	body.text = _restoration_copy(stage)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("#DDCED6"))
	body.add_theme_font_size_override("font_size", 15)
	copy.add_child(body)

	var button := Button.new()
	button.name = "Continue"
	button.text = "CONTINUE"
	button.custom_minimum_size = Vector2(0, 50)
	button.add_theme_font_size_override("font_size", 18)
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

	_animate_restoration_state(stage, current_curios)

func _animate_restoration_state(stage: int, current_curios: Array[String]) -> void:
	await get_tree().process_frame
	if not is_instance_valid(self):
		return
	room_view.modulate = Color(0.70, 0.64, 0.82, 1)
	room_view.set_house_state(stage, current_curios)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(room_view, "modulate", Color.WHITE, 0.55)

func _curio_texture(curio_id: String) -> Texture2D:
	var path := "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg"
	if curio_id == "moth_reliquary":
		path = "res://assets/curios/ch01_curio_moth_reliquary.svg"
	elif curio_id == "thorned_locket":
		path = "res://assets/curios/ch01_curio_thorned_locket.svg"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var image := Image.new()
	var err := image.load_svg_from_string(file.get_as_text(), 1.0)
	file.close()
	return ImageTexture.create_from_image(image) if err == OK and not image.is_empty() else null

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
