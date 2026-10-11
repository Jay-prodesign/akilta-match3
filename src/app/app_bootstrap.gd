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
const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")

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
	# Every platform enters through the authored first-impression surface.
	# Navigation stays at BOOT until the player explicitly enters the House.
	_render_splash()

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
	_install_product_navigation(screen, "curios")
	screen.back_requested.connect(_on_collection_back)
	return true

func show_map() -> bool:
	if not navigation.go(NavigationScript.Route.MAP):
		return false
	var screen: Node = MapScene.instantiate()
	screen.set("canonical_level_cap", INTERNAL_REVIEW_LEVEL_COUNT)
	_show_screen(screen)
	screen.set_progress(progress)
	_install_product_navigation(screen, "map")
	screen.back_requested.connect(_on_map_back)
	screen.level_requested.connect(show_prestart)
	return true

func show_prestart(level_number: int) -> bool:
	if level_number < 1 or level_number > INTERNAL_REVIEW_LEVEL_COUNT or level_number > int(progress.highest_level_unlocked) or navigation.current() != NavigationScript.Route.MAP:
		return false
	# Reject missing or malformed content while preserving the current map.
	var level_file := FileAccess.open(_level_path(level_number), FileAccess.READ)
	if level_file == null:
		return false
	var level_data: Variant = JSON.parse_string(level_file.get_as_text())
	level_file.close()
	if not level_data is Dictionary:
		return false
	var entry_route: int = navigation.current()
	if not navigation.go(NavigationScript.Route.PRESTART, {"level": level_number, "origin": entry_route}):
		return false
	var screen: Node = PrestartScene.instantiate()
	_show_screen(screen)
	var level_id := String((level_data as Dictionary).get("id", ""))
	var is_replay: bool = progress.completed_levels.has(level_id)
	if not screen.configure_level(level_number, is_replay):
		# Recover to House if prestart configuration fails.
		_ensure_house_route()
		return false
	_pending_level_number = level_number
	screen.back_button.text = "BACK TO MAP" if entry_route == NavigationScript.Route.MAP else "BACK TO HOUSE"
	screen.back_requested.connect(_on_prestart_back)
	screen.start_requested.connect(_on_prestart_start)
	return true

func start_level(level_number: int = 1) -> bool:
	if level_number < 1 or level_number > INTERNAL_REVIEW_LEVEL_COUNT or level_number > int(progress.highest_level_unlocked) or level_number != _pending_level_number or navigation.current() != NavigationScript.Route.PRESTART:
		return false
	var level_path: String = _level_path(level_number)
	if not FileAccess.file_exists(level_path):
		return false
	var level_file := FileAccess.open(level_path, FileAccess.READ)
	if level_file == null:
		return false
	var level_data: Variant = JSON.parse_string(level_file.get_as_text())
	level_file.close()
	if not level_data is Dictionary:
		return false
	if not navigation.go(NavigationScript.Route.GAMEPLAY, {"level": level_number}):
		return false
	var screen: Node = GameplayScene.instantiate()
	screen.set("default_level_path", level_path)
	screen.set("default_seed", 1000 + level_number)
	var level_id := String((level_data as Dictionary).get("id", ""))
	screen.set("replay_mode", progress.completed_levels.has(level_id))
	_show_screen(screen)
	if screen.has_method("set_player_resources"):
		screen.set_player_resources(int(progress.lives), int(progress.coins), int(progress.gems))
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	screen.level_won.connect(_on_level_won)
	if screen.has_signal("level_replay_finished"):
		screen.level_replay_finished.connect(_on_level_replay_finished)
	if screen.has_signal("navigation_requested"):
		screen.navigation_requested.connect(_on_gameplay_navigation_requested)
	if screen.has_signal("level_exit_requested"):
		screen.level_exit_requested.connect(_on_level_exit_requested)
	if screen.has_signal("feedback_requested"):
		screen.feedback_requested.connect(_on_gameplay_feedback_requested)
	if screen.has_signal("settings_requested"):
		screen.settings_requested.connect(show_settings)
	if screen.has_signal("result_state_changed"):
		screen.result_state_changed.connect(_on_gameplay_result_state_changed)
	return true

func complete_level_win(transaction_id: String, level_id: String, curio_id: String = "moon_cameo", house_stage_reward: int = -1) -> bool:
	if progress == null:
		progress = ProgressScript.new()
	var curio_was_owned: bool = progress.curios.has(curio_id)
	var previous_house_stage: int = int(progress.house_stage)
	var candidate = ProgressScript.from_dict(progress.to_dict())
	var applied: bool = bool(candidate.apply_level_win(transaction_id, level_id, curio_id, house_stage_reward))
	if not applied:
		return false
	if not _store.save(candidate.to_dict()):
		return false
	progress = candidate
	var restoration_needed := not curio_was_owned or int(candidate.house_stage) > previous_house_stage
	if restoration_needed:
		if navigation.current() != NavigationScript.Route.WIN_REWARDS:
			return false
		if not navigation.go(NavigationScript.Route.RESTORATION, {"reason": "level_reward_restoration"}):
			return false
		_render_house(true, curio_id, int(candidate.house_stage))
	else:
		if navigation.current() == NavigationScript.Route.WIN_REWARDS:
			if not navigation.go(NavigationScript.Route.HOUSE, {"reason": "level_replay_complete"}):
				return false
		elif navigation.current() != NavigationScript.Route.HOUSE:
			return false
		_render_house(false, "", int(candidate.house_stage))
	return true

func show_feature_preview(feature: String) -> bool:
	# Truthful internal-review destinations are real product routes/screens.
	# Events and Shop remain unavailable for live actions, but they are not
	# overlays pretending the player is still on the House route.
	if navigation == null:
		return false
	var feature_key := feature.to_lower()
	var target_route := -1
	var screen_name := ""
	match feature_key:
		"events":
			target_route = NavigationScript.Route.EVENTS
			screen_name = "EventsScreen"
		"shop":
			target_route = NavigationScript.Route.SHOP
			screen_name = "ShopScreen"
		"profile":
			target_route = NavigationScript.Route.PROFILE_SETTINGS
			screen_name = "ProfileSettingsScreen"
		_:
			return false
	if navigation.current() != NavigationScript.Route.HOUSE and navigation.current() != target_route:
		if not _ensure_house_route():
			return false
	if navigation.current() == NavigationScript.Route.HOUSE:
		if not navigation.go(target_route, {"via": "product_navigation", "screen": feature_key}):
			return false
	elif navigation.current() != target_route:
		return false
	var overlay := Control.new()
	overlay.name = screen_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_show_screen(overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0A0C16")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)
	var world_art := TextureRect.new()
	world_art.name = "FeatureWorldArt"
	world_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var world_art_id := "events_bg_curio_house" if feature_key == "events" else ("profile_bg_curio_house" if feature_key == "profile" else "shop_bg_curio_house")
	world_art.texture = ScreenArt.texture(world_art_id)
	world_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	world_art.modulate = Color(0.58, 0.52, 0.70, 0.42) if feature_key == "events" else (Color(0.68, 0.58, 0.50, 0.36) if feature_key == "shop" else Color(0.52, 0.60, 0.74, 0.38))
	overlay.add_child(world_art)
	var layout := VBoxContainer.new()
	layout.name = "FeatureLayout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 18
	layout.offset_top = 24
	layout.offset_right = -18
	layout.offset_bottom = -20
	layout.add_theme_constant_override("separation", 12)
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	overlay.add_child(layout)
	var is_events := feature_key == "events"
	var is_profile := feature_key == "profile"
	var completed_count := mini(int(progress.completed_levels.size()) if progress != null else 0, INTERNAL_REVIEW_LEVEL_COUNT)
	var collected_count := mini(int(progress.curios.size()) if progress != null else 0, INTERNAL_REVIEW_LEVEL_COUNT)
	var restored_stage := int(progress.house_stage) if progress != null else 0
	var opening_complete := completed_count >= INTERNAL_REVIEW_LEVEL_COUNT and collected_count >= INTERNAL_REVIEW_LEVEL_COUNT and restored_stage >= INTERNAL_REVIEW_LEVEL_COUNT

	var eyebrow := Label.new()
	eyebrow.text = "THE HOUSE OF CURIOS  ·  AKILTA"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("#D5AD70"))
	eyebrow.add_theme_color_override("font_outline_color", Color("#080710", 0.92))
	eyebrow.add_theme_constant_override("outline_size", 3)
	eyebrow.add_theme_font_size_override("font_size", 15)
	layout.add_child(eyebrow)
	var title := Label.new()
	title.name = "FeatureTitle"
	title.text = "THE KEEPER" if is_profile else ("WEEKLY RITUALS" if is_events else "THE CURIO EMPORIUM")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_color_override("font_outline_color", Color("#080710", 0.94))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_font_size_override("font_size", 38)
	layout.add_child(title)
	var detail := Label.new()
	detail.text = "Your restored curios, House progress and preferences." if is_profile else ("Seasonal rituals will gather here when the upper cabinets awaken." if is_events else "A sealed preview of the House economy. Nothing here can charge you.")
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", Color("#D8C6C3"))
	detail.add_theme_color_override("font_outline_color", Color("#080710", 0.82))
	detail.add_theme_constant_override("outline_size", 2)
	detail.add_theme_font_size_override("font_size", 18)
	layout.add_child(detail)

	var hero := PanelContainer.new()
	hero.name = "FeatureHero"
	hero.custom_minimum_size = Vector2(0, 150)
	var hero_style := StyleBoxFlat.new()
	hero_style.bg_color = Color("#171321", 0.96)
	hero_style.border_color = Color("#9B6FA6", 0.82) if is_events else (Color("#D5AD70", 0.86) if not is_profile else Color("#8796C7", 0.82))
	hero_style.set_border_width_all(2)
	hero_style.set_corner_radius_all(16)
	hero_style.content_margin_left = 18
	hero_style.content_margin_right = 18
	hero_style.content_margin_top = 14
	hero_style.content_margin_bottom = 14
	hero_style.shadow_color = Color(0, 0, 0, 0.48)
	hero_style.shadow_size = 12
	hero.add_theme_stylebox_override("panel", hero_style)
	layout.add_child(hero)
	var hero_row := HBoxContainer.new()
	hero_row.name = "HeroRow"
	hero_row.add_theme_constant_override("separation", 14)
	hero.add_child(hero_row)
	var hero_copy := VBoxContainer.new()
	hero_copy.name = "HeroCopy"
	hero_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_copy.add_theme_constant_override("separation", 4)
	hero_row.add_child(hero_copy)
	var hero_kicker := Label.new()
	hero_kicker.name = "FeatureHeroKicker"
	hero_kicker.text = ("OPENING RITUAL COMPLETE" if opening_complete else "OPENING RITUAL IN PROGRESS") if is_events else ("EMPORIUM PREVIEW · SEALED" if not is_profile else ("FIRST CABINET SET RESTORED" if opening_complete else "KEEPER RECORD"))
	hero_kicker.add_theme_color_override("font_color", Color("#D5AD70"))
	hero_kicker.add_theme_font_size_override("font_size", 15)
	hero_copy.add_child(hero_kicker)
	var hero_title := Label.new()
	hero_title.name = "FeatureHeroTitle"
	hero_title.text = ("%d / %d DISPLAYS AWAKENED" % [completed_count, INTERNAL_REVIEW_LEVEL_COUNT]) if is_events else ("NO PURCHASES ENABLED" if not is_profile else ("%d CURIOS · RESTORATION STAGE %d" % [collected_count, restored_stage]))
	hero_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_title.add_theme_color_override("font_color", Color("#FFF0D8"))
	hero_title.add_theme_color_override("font_outline_color", Color("#080710", 0.90))
	hero_title.add_theme_constant_override("outline_size", 3)
	hero_title.add_theme_font_size_override("font_size", 25)
	hero_copy.add_child(hero_title)
	var hero_body := Label.new()
	hero_body.name = "FeatureHeroBody"
	hero_body.text = ("The House remembers every completed display; future weekly events remain sealed." if is_events else ("Future offers will live in this cabinet only after economy and purchase systems are production-ready." if not is_profile else "Your opening journey is stored locally and reflected across the House, map and Reliquary."))
	hero_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_body.add_theme_color_override("font_color", Color("#CFC0CF"))
	hero_body.add_theme_font_size_override("font_size", 16)
	hero_copy.add_child(hero_body)

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
	if is_events:
		var progress_label := Label.new()
		progress_label.name = "ChapterRitualProgress"
		progress_label.text = ("OPENING RITUAL COMPLETE  ·  %d / %d DISPLAYS AWAKENED" if opening_complete else "OPENING RITUAL  ·  %d / %d DISPLAYS AWAKENED") % [completed_count, INTERNAL_REVIEW_LEVEL_COUNT]
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		progress_label.add_theme_color_override("font_color", Color("#D5AD70"))
		progress_label.add_theme_font_size_override("font_size", 16)
		layout.add_child(progress_label)
		var ritual_progress := ProgressBar.new()
		ritual_progress.name = "OpeningRitualProgressBar"
		ritual_progress.min_value = 0
		ritual_progress.max_value = INTERNAL_REVIEW_LEVEL_COUNT
		ritual_progress.value = completed_count
		ritual_progress.show_percentage = false
		ritual_progress.custom_minimum_size.y = 12
		var track := StyleBoxFlat.new()
		track.bg_color = Color("#211827")
		track.set_corner_radius_all(6)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("#D5AD70")
		fill.set_corner_radius_all(6)
		ritual_progress.add_theme_stylebox_override("background", track)
		ritual_progress.add_theme_stylebox_override("fill", fill)
		layout.add_child(ritual_progress)
	elif not is_profile:
		var shop_note := Label.new()
		shop_note.name = "NoPurchasesNotice"
		shop_note.text = "THE EMPORIUM IS SEALED  ·  NO PURCHASES OR PAYMENTS"
		shop_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shop_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		shop_note.add_theme_color_override("font_color", Color("#D5AD70"))
		shop_note.add_theme_font_size_override("font_size", 15)
		layout.add_child(shop_note)
	if is_events:
		entries = [
			{"icon":"☾", "art":"res://assets/pieces/moon_sigil.svg", "title":"MOONLIGHT MARKET", "body":"The opening cabinet set is restored. The House is ready for a future moonlit event." if opening_complete else "Awaken the three opening displays to restore the Curio House.", "status":"OPENING CHAPTER COMPLETE · FUTURE MARKET EVENT REMAINS SEALED" if opening_complete else "CHAPTER PROGRESS TRACKED · MARKET EVENT NOT YET ACTIVE"},
			{"icon":"♜", "art":"res://assets/pieces/crow.svg", "title":"THE LOST RELICS", "body":"A raven has spotted a sealed cabinet.", "status":"UPPER CABINETS SEALED · FUTURE JOURNEY" if opening_complete else "LOCKED · COMPLETE THE OPENING CHAPTER"},
			{"icon":"✧", "art":"res://assets/pieces/pentagram.svg", "title":"WEEKLY RITUALS", "body":"Weekly ritual challenges will live here.", "status":"FUTURE FEATURE · NO CLAIMABLE REWARDS"}
		]
	elif is_profile:
		entries = [
			{"icon":"☾", "art":"res://assets/pieces/moon_sigil.svg", "title":"CHAPTER PROGRESS", "body":"Opening chapter complete · %d of %d rituals." % [completed_count, INTERNAL_REVIEW_LEVEL_COUNT] if opening_complete else "%d of %d opening rituals completed." % [completed_count, INTERNAL_REVIEW_LEVEL_COUNT], "status":"FIRST CABINET SET RESTORED" if opening_complete else "YOUR SAVED JOURNEY"},
			{"icon":"✦", "art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg", "title":"RELIQUARY", "body":"%d of %d opening curios awakened." % [collected_count, INTERNAL_REVIEW_LEVEL_COUNT], "status":"OPENING SET COMPLETE" if opening_complete else "RELICS RECOVERED"},
			{"icon":"⌂", "art":"res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg", "title":"HOUSE RESTORATION", "body":"Restoration stage %d." % restored_stage, "status":"OPENING RESTORATION COMPLETE" if opening_complete else "PROGRESS SAVED ON THIS DEVICE"}
		]
	else:
		entries = [
			{"icon":"◉", "art":"res://assets/pieces/pentagram.svg", "title":"CANDLELIGHT KIT", "body":"A future soft-currency cabinet for restoration supplies.", "status":"SEALED · ECONOMY PREVIEW ONLY"},
			{"icon":"◇", "art":"res://assets/pieces/potion.svg", "title":"MOONSTONE CACHE", "body":"A future premium-currency cabinet. No price or payment flow is active.", "status":"SEALED · NO REAL-MONEY PURCHASES"},
			{"icon":"✦", "art":"res://assets/curios/ch01_curio_moth_reliquary.svg", "title":"RESTORER'S RELIQUARY", "body":"A future curated bundle surface for boosters and curios.", "status":"SEALED · STORE NOT CONNECTED"}
		]
	var card_index := 0
	for entry in entries:
		var card := PanelContainer.new()
		card_index += 1
		card.name = "FeatureCard%d" % card_index
		card.custom_minimum_size = Vector2(0, 190)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color("#171321")
		panel_style.border_color = Color("#9B6FA6", 0.58) if is_events else (Color("#D5AD70", 0.62) if not is_profile else Color("#8796C7", 0.58))
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(14)
		panel_style.content_margin_left = 16
		panel_style.content_margin_right = 16
		panel_style.content_margin_top = 14
		panel_style.content_margin_bottom = 14
		panel_style.shadow_color = Color(0, 0, 0, 0.34)
		panel_style.shadow_size = 8
		card.add_theme_stylebox_override("panel", panel_style)
		cards.add_child(card)
		var row := HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 18)
		card.add_child(row)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		copy.add_theme_constant_override("separation", 6)
		row.add_child(copy)
		var card_kicker := Label.new()
		card_kicker.name = "CardKicker%d" % card_index
		card_kicker.text = ("%s %02d" % ["RITUAL" if is_events else ("RECORD" if is_profile else "SEALED CABINET"), card_index])
		card_kicker.add_theme_color_override("font_color", Color("#D5AD70"))
		card_kicker.add_theme_font_size_override("font_size", 13)
		copy.add_child(card_kicker)
		var card_title := Label.new()
		card_title.text = String(entry["title"])
		card_title.add_theme_color_override("font_color", Color("#F4E5D3"))
		card_title.add_theme_color_override("font_outline_color", Color("#080710", 0.88))
		card_title.add_theme_constant_override("outline_size", 2)
		card_title.add_theme_font_size_override("font_size", 23)
		copy.add_child(card_title)
		var card_body := Label.new()
		card_body.text = String(entry["body"])
		card_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_body.add_theme_color_override("font_color", Color("#D8C6C3"))
		card_body.add_theme_font_size_override("font_size", 17)
		copy.add_child(card_body)
		var status := Label.new()
		status.text = String(entry["status"])
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.add_theme_color_override("font_color", Color("#BFA5D8"))
		status.add_theme_font_size_override("font_size", 14)
		copy.add_child(status)
	if is_profile:
		var preferences := Button.new()
		preferences.name = "ProfileSettings"
		preferences.text = "⚙  AUDIO & ACCESSIBILITY"
		preferences.custom_minimum_size.y = 60
		preferences.add_theme_color_override("font_color", Color("#F4E5D3"))
		preferences.add_theme_font_size_override("font_size", 18)
		var preferences_style := StyleBoxFlat.new()
		preferences_style.bg_color = Color("#211728", 0.98)
		preferences_style.border_color = Color("#8796C7", 0.82)
		preferences_style.set_border_width_all(1)
		preferences_style.set_corner_radius_all(8)
		var preferences_hover := preferences_style.duplicate() as StyleBoxFlat
		preferences_hover.bg_color = Color("#352A45")
		preferences_hover.border_color = Color("#D5AD70")
		preferences.add_theme_stylebox_override("normal", preferences_style)
		preferences.add_theme_stylebox_override("hover", preferences_hover)
		preferences.add_theme_stylebox_override("pressed", preferences_hover)
		layout.add_child(preferences)
		preferences.pressed.connect(func(): show_settings())
	var back := Button.new()
	back.name = "BackToHouse"
	back.text = "RETURN TO THE HOUSE"
	back.custom_minimum_size = Vector2(0, 58)
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
	back.pressed.connect(_dismiss_feature_preview)
	_install_product_navigation(overlay, feature.to_lower(), NodePath("FeatureLayout"))
	# Secondary destinations intentionally use only contract-owned structural UI
	# while their content art/economy/event assets are unavailable. Do not decorate
	# locked shells with unrelated world or piece artwork.
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

func _render_house(restoration_mode: bool = false, curio_id: String = "", restoration_stage: int = 0) -> void:
	var screen: Node = HouseScene.instantiate()
	_show_screen(screen)
	screen.set_available_level_count(INTERNAL_REVIEW_LEVEL_COUNT)
	screen.set_progress(progress)
	if restoration_mode and screen.has_method("show_restoration_ceremony"):
		screen.show_restoration_ceremony(curio_id, restoration_stage)
		if screen.has_signal("restoration_finished"):
			screen.restoration_finished.connect(_on_restoration_finished)
	screen.collection_requested.connect(show_collection)
	screen.map_requested.connect(show_chapters)
	screen.play_requested.connect(_on_house_play_requested)
	screen.settings_requested.connect(show_settings)
	screen.profile_requested.connect(func(): show_feature_preview("Profile"))
	if screen.has_signal("events_requested"):
		screen.events_requested.connect(func(): show_feature_preview("Events"))
	if screen.has_signal("shop_requested"):
		screen.shop_requested.connect(func(): show_feature_preview("Shop"))

func _on_restoration_finished() -> void:
	if navigation.current() == NavigationScript.Route.RESTORATION:
		navigation.go(NavigationScript.Route.HOUSE, {"reason": "restoration_complete"})

func _on_collection_back() -> void:
	if navigation.go(NavigationScript.Route.HOUSE, {"via": "collection_back"}):
		_render_house()

func _on_map_back() -> void:
	if navigation.go(NavigationScript.Route.CHAPTERS, {"via": "map_back"}):
		_render_chapters()

func _on_prestart_back() -> void:
	_pending_level_number = 0
	if navigation.go(NavigationScript.Route.MAP, {"via": "prestart_back"}):
		_render_map_from_prestart()

func _render_map_from_prestart() -> void:
	var screen: Node = MapScene.instantiate()
	screen.set("canonical_level_cap", INTERNAL_REVIEW_LEVEL_COUNT)
	_show_screen(screen)
	screen.set_progress(progress)
	_install_product_navigation(screen, "map")
	screen.back_requested.connect(_on_map_back)
	screen.level_requested.connect(show_prestart)

func _on_prestart_start(level_number: int) -> void:
	if level_number == _pending_level_number:
		start_level(level_number)

func _on_level_exit_requested() -> void:
	show_house()

func _on_gameplay_result_state_changed(kind: String) -> void:
	if kind == "won" and navigation.current() == NavigationScript.Route.GAMEPLAY:
		navigation.go(NavigationScript.Route.WIN_REWARDS, {"result": "won"})

func _on_level_won(level_id: String, curio_id: String, house_stage_reward: int) -> void:
	_pending_level_number = 0
	var transaction_id := "win:first:%s" % level_id
	complete_level_win(transaction_id, level_id, curio_id, house_stage_reward)

func _on_level_replay_finished(level_id: String) -> void:
	_pending_level_number = 0
	if navigation.current() != NavigationScript.Route.WIN_REWARDS or progress == null or not progress.completed_levels.has(level_id):
		return
	if navigation.go(NavigationScript.Route.HOUSE, {"reason": "level_replay_complete", "level": level_id}):
		_render_house()

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

func _install_product_navigation(screen: Node, active_section: String, content_path: NodePath = NodePath("Layout")) -> void:
	if screen is Control:
		ProductNavigation.attach(screen as Control, active_section, Callable(self, "_on_shell_navigation_requested"), content_path)

func _dismiss_feature_preview() -> void:
	if navigation == null:
		return
	if navigation.current() in [NavigationScript.Route.EVENTS, NavigationScript.Route.SHOP, NavigationScript.Route.PROFILE_SETTINGS]:
		if navigation.go(NavigationScript.Route.HOUSE, {"via": "feature_back"}):
			_render_house()
	elif navigation.current() == NavigationScript.Route.HOUSE:
		_render_house()

func _ensure_house_route() -> bool:
	if navigation == null:
		return false
	if navigation.current() == NavigationScript.Route.HOUSE:
		return true
	# Most shell routes can return directly. PRESTART is intentionally stricter
	# in NavigationController, so unwind one legal edge before entering HOUSE.
	if navigation.current() == NavigationScript.Route.PRESTART:
		if not navigation.go(NavigationScript.Route.MAP, {"via": "product_navigation"}):
			return false
	return show_house()

func _on_shell_navigation_requested(section: String) -> void:
	_dismiss_feature_preview()
	match section:
		"house":
			_ensure_house_route()
		"curios":
			if _ensure_house_route():
				show_collection()
		"map":
			if _ensure_house_route():
				show_chapters()
		"events":
			if _ensure_house_route():
				show_feature_preview("Events")
		"shop":
			if _ensure_house_route():
				show_feature_preview("Shop")
		"profile":
			if _ensure_house_route():
				show_feature_preview("Profile")

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
			show_feature_preview("Profile")

func _install_north_star_backdrop(_screen: Node) -> void:
	# Retired by the canonical screen/state architecture. World art may only be
	# loaded by the exact Screen -> Block -> Slot owner; no generic SVG wallpaper
	# is injected across unrelated screens.
	pass

func _render_splash() -> void:
	var screen: Node = SplashScene.instantiate()
	_show_screen(screen)
	screen.continue_requested.connect(_on_splash_continue)

func _on_splash_continue() -> void:
	if navigation == null:
		return
	if navigation.current() == NavigationScript.Route.BOOT:
		if not navigation.go(NavigationScript.Route.HOUSE, {"reason": "splash_continue"}):
			return
	elif navigation.current() != NavigationScript.Route.HOUSE:
		return
	_render_house()

func _on_house_play_requested(_level_number: int) -> void:
	if navigation.current() != NavigationScript.Route.HOUSE:
		return
	show_map()

func show_chapters() -> bool:
	if navigation == null or navigation.current() != NavigationScript.Route.HOUSE:
		return false
	if not navigation.go(NavigationScript.Route.CHAPTERS, {"via": "house"}):
		return false
	return _render_chapters()

func _render_chapters() -> bool:
	var screen: Node = ChapterSelectScene.instantiate()
	_show_screen(screen)
	if screen.has_method("set_progress"):
		screen.set_progress(progress)
	_install_product_navigation(screen, "map")
	screen.chapter_requested.connect(_on_chapter_selected)
	screen.back_requested.connect(show_house)
	return true

func _on_chapter_selected(chapter_id: String) -> void:
	if chapter_id == "curio_boutique":
		show_map()
