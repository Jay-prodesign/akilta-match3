class_name AppBootstrap
extends Node

const ProgressScript = preload("res://src/progression/player_progress.gd")
const SaveStoreScript = preload("res://src/save/save_store.gd")
const NavigationScript = preload("res://src/app/navigation_controller.gd")
const UserSettingsScript = preload("res://src/settings/user_settings.gd")
const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")
const HouseScene = preload("res://src/ui/home/house_home.tscn")
const CollectionScene = preload("res://src/ui/collection/curio_collection.tscn")
const MapScene = preload("res://src/ui/map/chapter_map.tscn")
const PrestartScene = preload("res://src/ui/prestart/level_prestart.tscn")
const SettingsScene = preload("res://src/ui/settings/settings_panel.tscn")
const SplashScene = preload("res://src/ui/splash/splash_screen.tscn")
const AudioDirectorScript = preload("res://src/feedback/audio_director.gd")
const Typography = preload("res://src/ui/theme/typography.gd")
const CurioMaterials = preload("res://src/ui/theme/curio_materials.gd")

@export var environment: String = "development"
@export var save_path_override: String = ""
@export var settings_path_override: String = ""

var progress
var navigation
var user_settings
var audio_director
var _store
var _current_screen: Node
var _settings_screen: Node
var _pending_level_number: int = 0
const TEST_LEVEL_COUNT := 3

@onready var screen_host: Node = $ScreenHost

func _ready() -> void:
	var path: String = save_path_override if save_path_override != "" else SaveStoreScript.DEFAULT_PATH
	_store = SaveStoreScript.new(path)
	progress = ProgressScript.from_dict(_store.load_or_default())
	navigation = NavigationScript.new()
	user_settings = UserSettingsScript.new()
	var settings_path := settings_path_override if settings_path_override != "" else UserSettingsScript.DEFAULT_PATH
	user_settings.load_settings(settings_path)
	user_settings.presentation_changed.connect(_on_presentation_settings_changed)
	audio_director = AudioDirectorScript.new()
	audio_director.name = "AudioDirector"
	add_child(audio_director)
	navigation.go(NavigationScript.Route.HOUSE, {"reason": "boot"})
	if OS.has_feature("web"):
		_render_splash()
	else:
		_render_house()

func current_route_name() -> String:
	return navigation.route_name().to_lower() if navigation != null else ""

func current_screen() -> Node:
	return _current_screen

func show_house() -> bool:
	if navigation.current() != NavigationScript.Route.HOUSE:
		if not navigation.go(NavigationScript.Route.HOUSE, {"reason": "return"}):
			return false
	_render_house()
	return true

func show_collection() -> bool:
	if not navigation.go(NavigationScript.Route.COLLECTION):
		return false
	var screen: Node = CollectionScene.instantiate()
	_show_screen(screen)
	screen.set_progress(progress)
	screen.back_requested.connect(_on_collection_back)
	return true

func show_map() -> bool:
	if not navigation.go(NavigationScript.Route.MAP):
		return false
	var screen: Node = MapScene.instantiate()
	screen.set("canonical_level_cap", TEST_LEVEL_COUNT)
	_show_screen(screen)
	screen.set_progress(progress)
	screen.back_requested.connect(_on_map_back)
	screen.level_requested.connect(show_prestart)
	return true

func show_prestart(level_number: int) -> bool:
	if level_number < 1 or level_number > TEST_LEVEL_COUNT or navigation.current() != NavigationScript.Route.MAP:
		return false
	if not navigation.go(NavigationScript.Route.PRESTART, {"level": level_number}):
		return false
	var screen: Node = PrestartScene.instantiate()
	_show_screen(screen)
	if not screen.configure_level(level_number):
		return false
	_pending_level_number = level_number
	screen.back_requested.connect(_on_prestart_back)
	screen.start_requested.connect(_on_prestart_start)
	return true

func start_level(level_number: int = 1) -> bool:
	if level_number < 1 or level_number > TEST_LEVEL_COUNT or navigation.current() != NavigationScript.Route.PRESTART:
		return false
	var level_path: String = _level_path(level_number)
	if not FileAccess.file_exists(level_path):
		return false
	if not navigation.go(NavigationScript.Route.GAMEPLAY, {"level": level_number}):
		return false
	var screen: Node = GameplayScene.instantiate()
	screen.set("default_level_path", level_path)
	screen.set("default_seed", 1000 + level_number)
	_show_screen(screen)
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	screen.level_won.connect(_on_level_won)
	if screen.has_signal("navigation_requested"):
		screen.navigation_requested.connect(_on_gameplay_navigation_requested)
	if screen.has_signal("level_exit_requested"):
		screen.level_exit_requested.connect(_on_level_exit_requested)
	if screen.has_signal("feedback_requested"):
		screen.feedback_requested.connect(_on_gameplay_feedback_requested)
	return true

func complete_level_win(transaction_id: String, level_id: String, curio_id: String = "moon_cameo", house_stage_reward: int = -1) -> bool:
	if progress == null:
		progress = ProgressScript.new()
	var candidate = ProgressScript.from_dict(progress.to_dict())
	var applied: bool = bool(candidate.apply_level_win(transaction_id, level_id, curio_id, house_stage_reward))
	if not applied:
		return false
	if not _store.save(candidate.to_dict()):
		return false
	progress = candidate
	return show_house()

func show_feature_preview(feature: String) -> bool:
	# Accessible non-monetized preview while first-party Events and Shop systems are built.
	if navigation == null or navigation.current() != NavigationScript.Route.HOUSE:
		return false
	var overlay := ColorRect.new()
	overlay.name = "FeaturePreview"
	overlay.color = Color("#100D19")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_host.add_child(overlay)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 24)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.offset_left = 28
	column.offset_right = -28
	overlay.add_child(column)
	var title := Label.new()
	title.text = feature.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	column.add_child(title)
	var detail := Label.new()
	detail.text = "THE HOUSE IS PREPARING THIS WING.\nNo purchases or live events are available in this test build."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	var back := Button.new()
	back.text = "RETURN TO THE HOUSE"
	column.add_child(back)
	back.pressed.connect(func(): overlay.queue_free())
	Typography.apply(overlay)
	CurioMaterials.apply(overlay)
	return true

func show_settings() -> bool:
	if navigation == null or not navigation.open_settings():
		return false
	_settings_screen = SettingsScene.instantiate()
	screen_host.add_child(_settings_screen)
	Typography.apply(_settings_screen)
	CurioMaterials.apply(_settings_screen)
	_settings_screen.bind_settings(user_settings)
	_settings_screen.close_requested.connect(close_settings)
	return true

func close_settings() -> bool:
	if navigation == null or not navigation.close_settings():
		return false
	if _settings_screen != null and is_instance_valid(_settings_screen):
		_settings_screen.queue_free()
	_settings_screen = null
	return true

func _render_house() -> void:
	var screen: Node = HouseScene.instantiate()
	_show_screen(screen)
	screen.set_available_level_count(TEST_LEVEL_COUNT)
	screen.set_progress(progress)
	screen.collection_requested.connect(show_collection)
	screen.map_requested.connect(show_map)
	screen.settings_requested.connect(show_settings)
	if screen.has_signal("events_requested"):
		screen.events_requested.connect(func(): show_feature_preview("Events"))
	if screen.has_signal("shop_requested"):
		screen.shop_requested.connect(func(): show_feature_preview("Shop"))

func _on_collection_back() -> void:
	if navigation.go(NavigationScript.Route.HOUSE, {"via": "collection_back"}):
		_render_house()

func _on_map_back() -> void:
	if navigation.go(NavigationScript.Route.HOUSE, {"via": "map_back"}):
		_render_house()

func _on_prestart_back() -> void:
	if navigation.go(NavigationScript.Route.MAP, {"via": "prestart_back"}):
		var screen: Node = MapScene.instantiate()
		screen.set("canonical_level_cap", TEST_LEVEL_COUNT)
		_show_screen(screen)
		screen.set_progress(progress)
		screen.back_requested.connect(_on_map_back)
		screen.level_requested.connect(show_prestart)

func _on_prestart_start(level_number: int) -> void:
	if level_number == _pending_level_number:
		start_level(level_number)

func _on_level_exit_requested() -> void:
	show_house()

func _on_level_won(level_id: String, curio_id: String, house_stage_reward: int) -> void:
	var transaction_id := "win:%s:%d" % [level_id, progress.processed_transactions.size() + 1]
	complete_level_win(transaction_id, level_id, curio_id, house_stage_reward)

func _on_gameplay_feedback_requested(kind: String) -> void:
	if audio_director != null:
		audio_director.request_feedback(kind)

func _on_presentation_settings_changed(state: Dictionary) -> void:
	if _current_screen != null and is_instance_valid(_current_screen) and _current_screen.has_method("apply_presentation_settings"):
		_current_screen.apply_presentation_settings(state)

func _level_path(level_number: int) -> String:
	return "res://content/levels/ch01/level_%03d.json" % level_number

func _show_screen(screen: Node) -> void:
	if _current_screen != null and is_instance_valid(_current_screen):
		screen_host.remove_child(_current_screen)
		_current_screen.queue_free()
	_current_screen = screen
	screen_host.add_child(screen)
	_install_north_star_backdrop(screen)
	Typography.apply(screen)
	CurioMaterials.apply(screen)

func _on_gameplay_navigation_requested(section: String) -> void:
	if navigation.current() == NavigationScript.Route.GAMEPLAY:
		show_house()
	match section:
		"house":
			return
		"curios":
			show_collection()
		"map":
			show_map()
		"events":
			show_feature_preview("Events")
		"shop":
			show_feature_preview("Shop")

func _install_north_star_backdrop(screen: Node) -> void:
	if screen == null or not screen is Control:
		return
	if screen.has_node("NorthStarBackdrop"):
		return
	const ART_PATH := "res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg"
	var file := FileAccess.open(ART_PATH, FileAccess.READ)
	if file == null:
		return
	var image := Image.new()
	var error := image.load_svg_from_string(file.get_as_text(), 1.0)
	file.close()
	if error != OK or image.is_empty():
		return
	var backdrop := TextureRect.new()
	backdrop.name = "NorthStarBackdrop"
	backdrop.texture = ImageTexture.create_from_image(image)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.modulate = Color(0.72, 0.76, 0.95, 0.52)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_index = -100
	(screen as Control).add_child(backdrop)
	(screen as Control).move_child(backdrop, 0)
	var flat := screen.get_node_or_null("Backdrop")
	if flat is ColorRect:
		(flat as ColorRect).color.a = 0.48

func _render_splash() -> void:
	var screen: Node = SplashScene.instantiate()
	_show_screen(screen)
	screen.continue_requested.connect(_on_splash_continue)

func _on_splash_continue() -> void:
	_render_house()
