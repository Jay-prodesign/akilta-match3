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
const ChapterSelectScene = preload("res://src/ui/map/chapter_select.tscn")
const PrestartScene = preload("res://src/ui/prestart/level_prestart.tscn")
const SettingsScene = preload("res://src/ui/settings/settings_panel.tscn")
const SplashScene = preload("res://src/ui/splash/splash_screen.tscn")
const AudioDirectorScript = preload("res://src/feedback/audio_director.gd")
const Typography = preload("res://src/ui/theme/typography.gd")
const CurioMaterials = preload("res://src/ui/theme/curio_materials.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

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
## Founder-authorized internal review exposes three provisional levels.
## This does not confer D-024B/D-027 shipping or final-art approval.
const INTERNAL_REVIEW_LEVEL_COUNT := 3

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
	screen.set("canonical_level_cap", INTERNAL_REVIEW_LEVEL_COUNT)
	_show_screen(screen)
	screen.set_progress(progress)
	screen.back_requested.connect(_on_map_back)
	screen.level_requested.connect(show_prestart)
	return true

func show_prestart(level_number: int) -> bool:
	if level_number < 1 or level_number > INTERNAL_REVIEW_LEVEL_COUNT or level_number > int(progress.highest_level_unlocked) or navigation.current() != NavigationScript.Route.MAP:
		return false
	# Validate authored content before mutating route or replacing the visible map.
	if not FileAccess.file_exists(_level_path(level_number)):
		return false
	var screen: Node = PrestartScene.instantiate()
	if not screen.configure_level(level_number):
		screen.free()
		return false
	if not navigation.go(NavigationScript.Route.PRESTART, {"level": level_number}):
		screen.free()
		return false
	_show_screen(screen)
	_pending_level_number = level_number
	screen.back_requested.connect(_on_prestart_back)
	screen.start_requested.connect(_on_prestart_start)
	return true

func start_level(level_number: int = 1) -> bool:
	if level_number < 1 or level_number > INTERNAL_REVIEW_LEVEL_COUNT or level_number > int(progress.highest_level_unlocked) or navigation.current() != NavigationScript.Route.PRESTART:
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
	# First-party, non-monetized preview: all controls are navigable, purchases remain disabled.
	if navigation == null or navigation.current() != NavigationScript.Route.HOUSE:
		return false
	# Reopening Events or Shop must replace the existing preview, not stack
	# opaque full-screen overlays and strand earlier back buttons.
	for existing in screen_host.get_children():
		if existing.name == "FeaturePreview":
			screen_host.remove_child(existing)
			existing.queue_free()
	var overlay := Control.new()
	overlay.name = "FeaturePreview"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_host.add_child(overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0A0C16")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)
	var layout := VBoxContainer.new()
	layout.name = "FeatureLayout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 18
	layout.offset_top = 24
	layout.offset_right = -18
	layout.offset_bottom = -20
	layout.add_theme_constant_override("separation", 16)
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	overlay.add_child(layout)
	var world_art := TextureRect.new()
	world_art.name = "WorldBackdrop"
	world_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_art.texture = PieceAssetLoader.ornament("res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg")
	world_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	world_art.modulate = Color(0.88, 0.80, 0.88, 0.30)
	overlay.add_child(world_art)
	overlay.move_child(world_art, 1)
	var eyebrow := Label.new()
	eyebrow.text = "THE HOUSE OF CURIOS  ·  AKILTA"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("#D5AD70"))
	eyebrow.add_theme_font_size_override("font_size", 13)
	layout.add_child(eyebrow)
	var title := Label.new()
	title.name = "FeatureTitle"
	title.text = "WEEKLY RITUALS" if feature.to_lower() == "events" else "THE CURIO EMPORIUM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#F4E5D3"))
	title.add_theme_font_size_override("font_size", 30)
	layout.add_child(title)
	var detail := Label.new()
	detail.text = "A new moonlit challenge arrives each week." if feature.to_lower() == "events" else "Spend no real money in this preview build."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", Color("#D8C6C3"))
	detail.add_theme_font_size_override("font_size", 17)
	layout.add_child(detail)
	var card_scroll := ScrollContainer.new()
	card_scroll.name = "FeatureCardScroll"
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(card_scroll)
	var cards := VBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 10)
	card_scroll.add_child(cards)
	var entries: Array[Dictionary]
	if feature.to_lower() == "events":
		entries = [
			{"icon":"☾", "art":"res://assets/pieces/moon_sigil.svg", "title":"MOONLIGHT MARKET", "body":"Play levels to gather moon sigils.", "status":"COMING SOON · EVENT RULES NOT ACTIVE"},
			{"icon":"♜", "art":"res://assets/pieces/crow.svg", "title":"THE LOST RELICS", "body":"A raven has spotted a sealed cabinet.", "status":"LOCKED · COMPLETE THE OPENING CHAPTER"},
			{"icon":"✧", "art":"res://assets/pieces/pentagram.svg", "title":"WEEKLY RITUALS", "body":"Your weekly ritual streak will live here.", "status":"PREVIEW · NO CLAIMABLE REWARDS"}
		]
	else:
		entries = [
			{"icon":"◉", "art":"res://assets/pieces/pentagram.svg", "title":"COIN SATCHEL", "body":"Soft currency for future House restoration.", "status":"NOT FOR SALE · ECONOMY PREVIEW"},
			{"icon":"◇", "art":"res://assets/pieces/potion.svg", "title":"MOONSTONE GEMS", "body":"Premium currency concept; no payment flow.", "status":"NOT FOR SALE · NO REAL-MONEY PURCHASES"},
			{"icon":"✦", "art":"res://assets/curios/ch01_curio_moth_reliquary.svg", "title":"STARTER RELIQUARY", "body":"A future bundle of curios and boosters.", "status":"LOCKED · STORE NOT CONNECTED"}
		]
	for entry in entries:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 158)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color("#171321")
		panel_style.border_color = Color("#D5AD70", 0.58)
		panel_style.set_border_width_all(1)
		panel_style.set_corner_radius_all(10)
		panel_style.content_margin_left = 14
		panel_style.content_margin_right = 14
		panel_style.content_margin_top = 10
		panel_style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", panel_style)
		cards.add_child(card)
		var row := HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var art_frame := PanelContainer.new()
		art_frame.custom_minimum_size = Vector2(76, 76)
		var art_style := StyleBoxFlat.new()
		art_style.bg_color = Color("#0E0D19")
		art_style.border_color = Color("#D5AD70", 0.40)
		art_style.set_border_width_all(1)
		art_style.set_corner_radius_all(10)
		art_frame.add_theme_stylebox_override("panel", art_style)
		row.add_child(art_frame)
		var art := TextureRect.new()
		art.name = "FeatureArtwork"
		art.custom_minimum_size = Vector2(68, 68)
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture = PieceAssetLoader.ornament(String(entry.get("art", "")))
		art_frame.add_child(art)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		copy.add_theme_constant_override("separation", 5)
		row.add_child(copy)
		var card_title := Label.new()
		card_title.text = String(entry["title"])
		card_title.add_theme_color_override("font_color", Color("#F4E5D3"))
		card_title.add_theme_font_size_override("font_size", 19)
		copy.add_child(card_title)
		var card_body := Label.new()
		card_body.text = String(entry["body"])
		card_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_body.add_theme_color_override("font_color", Color("#D8C6C3"))
		card_body.add_theme_font_size_override("font_size", 16)
		copy.add_child(card_body)
		var status := Label.new()
		status.text = String(entry["status"])
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.add_theme_color_override("font_color", Color("#BFA5D8"))
		status.add_theme_font_size_override("font_size", 14)
		copy.add_child(status)
	var back := Button.new()
	back.name = "BackToHouse"
	back.text = "RETURN TO THE HOUSE"
	back.custom_minimum_size = Vector2(0, 48)
	back.add_theme_color_override("font_color", Color("#F4E5D3"))
	back.add_theme_font_size_override("font_size", 22)
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color("#38233A")
	back_style.border_color = Color("#D5AD70")
	back_style.set_border_width_all(1)
	back_style.set_corner_radius_all(8)
	back.add_theme_stylebox_override("normal", back_style)
	back.add_theme_stylebox_override("hover", back_style)
	layout.add_child(back)
	back.pressed.connect(func():
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	# Explicit card typography is intentionally retained; applying the global theme
	# after construction would shrink these feature panels below mobile reading size.
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
	screen.set_available_level_count(INTERNAL_REVIEW_LEVEL_COUNT)
	screen.set_progress(progress)
	screen.collection_requested.connect(show_collection)
	screen.map_requested.connect(show_chapters)
	screen.play_requested.connect(_on_house_play_requested)
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
		show_chapters()

func _on_prestart_back() -> void:
	if navigation.go(NavigationScript.Route.MAP, {"via": "prestart_back"}):
		var screen: Node = MapScene.instantiate()
		screen.set("canonical_level_cap", INTERNAL_REVIEW_LEVEL_COUNT)
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
			show_chapters()
		"events":
			show_feature_preview("Events")
		"shop":
			show_feature_preview("Shop")
		"profile":
			show_settings()

func _install_north_star_backdrop(screen: Node) -> void:
	if screen == null or not screen is Control:
		return
	if screen.has_node("NorthStarBackdrop"):
		return
	var art_path := "res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg"
	var file := FileAccess.open(art_path, FileAccess.READ)
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
	backdrop.modulate = Color(0.72, 0.76, 0.95, 0.28 if screen.name == "GameplayScreen" else 0.52)
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

func _on_house_play_requested(level_number: int) -> void:
	if navigation.current() != NavigationScript.Route.HOUSE:
		return
	if show_map():
		show_prestart(level_number)

func show_chapters() -> bool:
	if navigation == null or navigation.current() != NavigationScript.Route.HOUSE:
		return false
	var screen: Node = ChapterSelectScene.instantiate()
	_show_screen(screen)
	screen.chapter_requested.connect(_on_chapter_selected)
	screen.back_requested.connect(show_house)
	return true

func _on_chapter_selected(chapter_id: String) -> void:
	if chapter_id == "curio_boutique":
		show_map()
