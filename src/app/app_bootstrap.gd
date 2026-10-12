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
const HapticsControllerScript = preload("res://src/feedback/haptics_controller.gd")
const Typography = preload("res://src/ui/theme/typography.gd")
const CurioMaterials = preload("res://src/ui/theme/curio_materials.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const MobileSafeArea = preload("res://src/ui/shared/mobile_safe_area.gd")
const EventJournalScript = preload("res://src/analytics/event_journal.gd")

@export var environment: String = "development"
@export var save_path_override: String = ""
@export var settings_path_override: String = ""

var progress
var navigation
var user_settings
var audio_director
var ui_haptics
var analytics
var _store
var _save_load_status: String = "not_loaded"
var _save_write_blocked_reason: String = ""
var _current_screen: Node
var _settings_screen: Node
var _pending_level_number: int = 0
var _active_level_number: int = 0
var _returning_player_entry: bool = false
var _shell_navigation_locked: bool = false
## Founder-authorized internal review exposes three provisional levels.
## This does not confer D-024B/D-027 shipping or final-art approval.
const INTERNAL_REVIEW_LEVEL_COUNT := 3

@onready var screen_host: Node = $ScreenHost

func _ready() -> void:
	# S00 must be a real boot state, not a decorative gate shown after loading.
	# Navigation exists immediately so the player is truthfully on BOOT while the
	# first rendered frame exposes the canonical loading state.
	navigation = NavigationScript.new()
	_render_splash()
	call_deferred("_complete_bootstrap")

func _complete_bootstrap() -> void:
	var path: String = save_path_override if save_path_override != "" else SaveStoreScript.DEFAULT_PATH
	_store = SaveStoreScript.new(path)
	var loaded: Dictionary = _store.load_or_default()
	_save_load_status = String(_store.load_status())
	_save_write_blocked_reason = String(_store.write_blocked_reason)
	progress = ProgressScript.from_dict(loaded)
	_returning_player_entry = _has_durable_progress(progress)

	analytics = EventJournalScript.new()
	navigation.route_changed.connect(_on_analytics_route_changed)
	analytics.record("session_boot", {"load_status": _save_load_status})
	if _save_load_status in ["backup_recovered", "default_after_invalid_primary", "future_schema"]:
		analytics.record("save_recovery", {"status": _save_load_status})

	user_settings = UserSettingsScript.new()
	var settings_path := settings_path_override if settings_path_override != "" else UserSettingsScript.DEFAULT_PATH
	user_settings.load_settings(settings_path)
	user_settings.presentation_changed.connect(_on_presentation_settings_changed)

	audio_director = AudioDirectorScript.new()
	audio_director.name = "AudioDirector"
	add_child(audio_director)
	ui_haptics = HapticsControllerScript.new()
	ui_haptics.apply_settings(user_settings.get_presentation_state())

	var splash := _current_screen
	if splash == null or not splash.has_method("set_boot_state"):
		return
	var load_status := _save_load_status
	match load_status:
		"backup_recovered":
			splash.set_boot_state("recoverable_error", "The primary House record could not be used. The last known good backup was restored.", true)
		"default_after_invalid_primary":
			splash.set_boot_state("recoverable_error", "The local House record was unreadable. A safe new record was prepared; the damaged file was not treated as progress.", true)
		"future_schema":
			splash.set_boot_state("recoverable_error", "This House record was created by a newer build. Update the game before entering so that record is not overwritten.", false)
		_:
			splash.set_boot_state("ready")

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
	if screen.has_signal("house_inspect_requested"):
		screen.house_inspect_requested.connect(_on_collection_house_inspect_requested)
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
	if not navigation.go(NavigationScript.Route.PRESTART, {"level": level_number}):
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
	screen.back_button.text = "BACK TO MAP"
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
	var replay_mode: bool = progress.completed_levels.has(level_id)
	screen.set("replay_mode", replay_mode)
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
	_active_level_number = level_number
	if analytics != null:
		analytics.record("level_started", {"level_number": level_number, "replay": replay_mode})
	return true

func complete_level_win(transaction_id: String, level_id: String, curio_id: String = "moon_cameo", house_stage_reward: int = -1) -> bool:
	# Reward acknowledgement is only valid from the visible win/rewards route.
	# Never persist a transaction first and reject its navigation afterwards:
	# that strands an already-claimed Curio without the restoration ceremony.
	if navigation == null or navigation.current() != NavigationScript.Route.WIN_REWARDS:
		return false
	if _store == null:
		return false
	if progress == null:
		progress = ProgressScript.new()
	var curio_was_owned: bool = progress.curios.has(curio_id)
	var previous_house_stage: int = int(progress.house_stage)
	var candidate = ProgressScript.from_dict(progress.to_dict())
	var applied: bool = bool(candidate.apply_level_win(transaction_id, level_id, curio_id, house_stage_reward))
	if not applied:
		return false
	var restoration_needed := not curio_was_owned or int(candidate.house_stage) > previous_house_stage
	var destination := NavigationScript.Route.RESTORATION if restoration_needed else NavigationScript.Route.HOUSE
	if not navigation.can_go(destination):
		return false
	if not _store.save(candidate.to_dict()):
		return false
	if _save_load_status != "backup_recovered":
		_save_load_status = "primary"
	_save_write_blocked_reason = ""
	progress = candidate
	if analytics != null:
		analytics.record("reward_committed", {
			"level_number": _level_number_from_id(level_id),
			"curio_id": curio_id,
			"restoration": restoration_needed,
		})
	if restoration_needed:
		if not navigation.go(NavigationScript.Route.RESTORATION, {"reason": "level_reward_restoration"}):
			return false
		_render_house(true, curio_id, int(candidate.house_stage))
	else:
		if not navigation.go(NavigationScript.Route.HOUSE, {"reason": "level_replay_complete"}):
			return false
		_render_house(false, "", int(candidate.house_stage))
	_active_level_number = 0
	return true

func show_weekly_missions() -> bool:
	if navigation == null:
		return false
	if navigation.current() == NavigationScript.Route.HOUSE:
		if not navigation.go(NavigationScript.Route.MISSIONS, {"via": "house_entry_point"}):
			return false
	elif navigation.current() == NavigationScript.Route.EVENTS:
		if not navigation.go(NavigationScript.Route.MISSIONS, {"via": "event_center"}):
			return false
	elif navigation.current() != NavigationScript.Route.MISSIONS:
		return false
	var screen := Control.new()
	screen.name = "WeeklyMissionsScreen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_show_screen(screen)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#090A13")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(backdrop)
	var world_art := TextureRect.new()
	world_art.name = "MissionWorldArt"
	world_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_art.texture = ScreenArt.texture("events_bg_curio_house")
	world_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	world_art.modulate = Color(0.58, 0.52, 0.70, 0.52)
	world_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(world_art)
	var layout := VBoxContainer.new()
	layout.name = "MissionLayout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 22
	layout.offset_top = 52
	layout.offset_right = -22
	layout.offset_bottom = -22
	layout.add_theme_constant_override("separation", 12)
	screen.add_child(layout)
	var eyebrow := Label.new()
	eyebrow.text = "THE HOUSE OF CURIOS · WEEKLY ALTAR"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("#D5AD70"))
	eyebrow.add_theme_font_size_override("font_size", 15)
	layout.add_child(eyebrow)
	var title := Label.new()
	title.name = "MissionTitle"
	title.text = "WEEKLY RITUALS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_color_override("font_outline_color", Color("#080710", 0.92))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_size_override("font_size", 38)
	layout.add_child(title)
	var timer := Label.new()
	timer.name = "MissionTimer"
	timer.text = "OFFLINE · LIVE RESET TIME UNAVAILABLE"
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer.add_theme_color_override("font_color", Color("#BFA5D8"))
	timer.add_theme_font_size_override("font_size", 16)
	layout.add_child(timer)
	var empty := PanelContainer.new()
	empty.name = "MissionEmptyState"
	empty.custom_minimum_size = Vector2(0, 520)
	empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	empty.set_meta("offline_contract", "truthful_empty_state")
	var empty_style := StyleBoxFlat.new()
	empty_style.bg_color = Color("#100C16", 0.68)
	empty_style.border_color = Color("#B88AB8", 0.72)
	empty_style.set_border_width_all(2)
	empty_style.set_corner_radius_all(18)
	empty_style.content_margin_left = 22
	empty_style.content_margin_right = 22
	empty_style.content_margin_top = 26
	empty_style.content_margin_bottom = 26
	empty_style.shadow_color = Color(0, 0, 0, 0.48)
	empty_style.shadow_size = 18
	empty.add_theme_stylebox_override("panel", empty_style)
	layout.add_child(empty)
	var empty_content := VBoxContainer.new()
	empty_content.name = "EmptyContent"
	empty_content.alignment = BoxContainer.ALIGNMENT_CENTER
	empty_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	empty_content.add_theme_constant_override("separation", 10)
	empty.add_child(empty_content)
	var emblem := TextureRect.new()
	emblem.name = "MissionRewardArt"
	emblem.custom_minimum_size = Vector2(0, 360)
	var weekly_art_path := "res://assets/curios/ch01_curio_moon_cameo_sealed_v01.webp"
	emblem.texture = PieceAssetLoader.ornament(weekly_art_path)
	emblem.set_meta("asset_path", weekly_art_path)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_content.add_child(emblem)
	var empty_title := Label.new()
	empty_title.text = "THE WEEKLY ALTAR IS QUIET"
	empty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_title.add_theme_color_override("font_color", Color("#F4E5D3"))
	empty_title.add_theme_font_size_override("font_size", 34)
	empty_content.add_child(empty_title)
	var empty_body := Label.new()
	empty_body.text = "No live weekly mission feed is connected. Mission timers, progress and rewards are intentionally not fabricated."
	empty_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_body.add_theme_color_override("font_color", Color("#D8C6C3"))
	empty_body.add_theme_font_size_override("font_size", 19)
	empty_content.add_child(empty_body)
	var availability := Label.new()
	availability.name = "MissionAvailability"
	availability.text = "LIVE RITUALS WILL APPEAR HERE ONLY WHEN A MISSION FEED IS CONNECTED"
	availability.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	availability.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	availability.add_theme_color_override("font_color", Color("#BFA5D8"))
	availability.add_theme_font_size_override("font_size", 15)
	empty_content.add_child(availability)
	var empty_state := Label.new()
	empty_state.name = "MissionEmptyStateTruth"
	empty_state.text = "RESET / OFFLINE STATE · NOTHING TO CLAIM"
	empty_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_state.add_theme_color_override("font_color", Color("#D5AD70"))
	empty_state.add_theme_font_size_override("font_size", 15)
	empty_content.add_child(empty_state)
	var record := Label.new()
	var completed_count := mini(int(progress.completed_levels.size()) if progress != null else 0, INTERNAL_REVIEW_LEVEL_COUNT)
	record.name = "MissionOpeningRecord"
	record.text = "OPENING CABINET RECORD · %d / %d DISPLAYS AWAKENED" % [completed_count, INTERNAL_REVIEW_LEVEL_COUNT]
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record.add_theme_color_override("font_color", Color("#BFA5D8"))
	record.add_theme_font_size_override("font_size", 16)
	layout.add_child(record)
	var events_button := Button.new()
	events_button.name = "ReturnToEvents"
	events_button.text = "RETURN TO EVENT CENTER"
	events_button.custom_minimum_size.y = 62
	_style_meta_action(events_button, true)
	layout.add_child(events_button)
	events_button.pressed.connect(_on_missions_back)
	var house_button := Button.new()
	house_button.name = "ReturnToHouse"
	house_button.text = "RETURN TO HOUSE"
	house_button.custom_minimum_size.y = 56
	_style_meta_action(house_button, false)
	layout.add_child(house_button)
	house_button.pressed.connect(_on_missions_house)
	return true

func _style_meta_action(button: Button, primary: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#4A2848") if primary else Color("#211827")
	normal.border_color = Color("#D5AD70") if primary else Color("#8D7694")
	normal.set_border_width_all(2 if primary else 1)
	normal.set_corner_radius_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#61385B") if primary else Color("#34263D")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("#FFF0D8"))
	button.add_theme_color_override("font_disabled_color", Color("#CFC0CF"))
	button.add_theme_font_size_override("font_size", 19)

func _on_missions_back() -> void:
	if navigation != null and navigation.current() == NavigationScript.Route.MISSIONS and navigation.go(NavigationScript.Route.EVENTS, {"via": "missions_back"}):
		show_feature_preview("Events")

func _on_missions_house() -> void:
	if navigation != null and navigation.current() == NavigationScript.Route.MISSIONS and navigation.go(NavigationScript.Route.HOUSE, {"via": "missions_house"}):
		_render_house()

func _completed_opening_levels() -> Array[int]:
	var levels: Array[int] = []
	if progress == null:
		return levels
	for level_number in range(1, INTERNAL_REVIEW_LEVEL_COUNT + 1):
		var level_id := "ch01_level_%03d" % level_number
		if progress.completed_levels.has(level_id):
			levels.append(level_number)
	return levels

func _daily_practice_level() -> int:
	var levels := _completed_opening_levels()
	if levels.is_empty():
		return 0
	var local_date := Time.get_datetime_dict_from_system()
	var ordinal := int(local_date.get("year", 2000)) * 372 + int(local_date.get("month", 1)) * 31 + int(local_date.get("day", 1))
	return int(levels[posmod(ordinal, levels.size())])

func _open_daily_practice(level_number: int) -> void:
	var level_id := "ch01_level_%03d" % level_number
	if navigation == null or navigation.current() != NavigationScript.Route.EVENTS or progress == null or not progress.completed_levels.has(level_id):
		return
	_emit_shell_feedback()
	if not navigation.go(NavigationScript.Route.HOUSE, {"via":"daily_house_ritual", "level":level_number}):
		return
	_render_house()
	if not show_map():
		return
	if show_prestart(level_number) and analytics != null:
		analytics.record("daily_practice_opened", {"level_number": level_number})

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
	title.text = "THE KEEPER" if is_profile else ("EVENT CENTER" if is_events else "THE CURIO EMPORIUM")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_color_override("font_outline_color", Color("#080710", 0.94))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_font_size_override("font_size", 38)
	layout.add_child(title)
	var detail := Label.new()
	detail.text = "Your restored curios, House progress and preferences." if is_profile else ("Seasonal events gather here; Weekly Rituals has its own truthful mission state." if is_events else "A sealed preview of the House economy. Nothing here can charge you.")
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", Color("#D8C6C3"))
	detail.add_theme_color_override("font_outline_color", Color("#080710", 0.82))
	detail.add_theme_constant_override("outline_size", 2)
	detail.add_theme_font_size_override("font_size", 18)
	layout.add_child(detail)
	if not is_profile and not is_events:
		var currency_summary := Label.new()
		currency_summary.name = "ShopCurrencySummary"
		currency_summary.text = "HOUSE COINS  %d  ·  MOONSTONES  %d" % [int(progress.coins) if progress != null else 0, int(progress.gems) if progress != null else 0]
		currency_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		currency_summary.add_theme_color_override("font_color", Color("#F2D08B"))
		currency_summary.add_theme_color_override("font_outline_color", Color("#080710", 0.86))
		currency_summary.add_theme_constant_override("outline_size", 2)
		currency_summary.add_theme_font_size_override("font_size", 17)
		layout.add_child(currency_summary)
		var currency_truth := Label.new()
		currency_truth.name = "ShopCurrencyTruth"
		currency_truth.text = "LOCAL REVIEW BALANCES · NOT PURCHASABLE"
		currency_truth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		currency_truth.add_theme_color_override("font_color", Color("#BFA5D8"))
		currency_truth.add_theme_font_size_override("font_size", 13)
		layout.add_child(currency_truth)

	var hero := PanelContainer.new()
	hero.name = "FeatureHero"
	hero.custom_minimum_size = Vector2(0, 190) if is_events else Vector2(0, 150)
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
	if is_events:
		var event_hero_art := TextureRect.new()
		event_hero_art.name = "EventHeroArt"
		event_hero_art.custom_minimum_size = Vector2(190, 160)
		event_hero_art.texture = PieceAssetLoader.ornament("res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg")
		event_hero_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		event_hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		event_hero_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero_row.add_child(event_hero_art)
	elif not is_profile:
		var shop_hero_art := TextureRect.new()
		shop_hero_art.name = "ShopFeaturedOfferArt"
		shop_hero_art.custom_minimum_size = Vector2(190, 160)
		shop_hero_art.texture = PieceAssetLoader.ornament("res://assets/curios/ch01_curio_moth_reliquary.svg")
		shop_hero_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shop_hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shop_hero_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero_row.add_child(shop_hero_art)
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
	if not is_profile and not is_events:
		var disabled_action := Button.new()
		disabled_action.name = "ShopDisabledAction"
		disabled_action.text = "COMMERCE NOT CONNECTED"
		disabled_action.custom_minimum_size.y = 52
		_style_meta_action(disabled_action, false)
		disabled_action.disabled = true
		hero_copy.add_child(disabled_action)

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
		var daily_level := _daily_practice_level()
		var daily_card := PanelContainer.new()
		daily_card.name = "DailyPracticeCard"
		daily_card.custom_minimum_size = Vector2(0, 126)
		var daily_style := StyleBoxFlat.new()
		daily_style.bg_color = Color("#15101D", 0.96)
		daily_style.border_color = Color("#D5AD70", 0.74)
		daily_style.set_border_width_all(1)
		daily_style.set_corner_radius_all(14)
		daily_style.content_margin_left = 14
		daily_style.content_margin_right = 14
		daily_style.content_margin_top = 10
		daily_style.content_margin_bottom = 10
		daily_card.add_theme_stylebox_override("panel", daily_style)
		layout.add_child(daily_card)
		var daily_content := VBoxContainer.new()
		daily_content.name = "DailyContent"
		daily_content.add_theme_constant_override("separation", 4)
		daily_card.add_child(daily_content)
		var daily_kicker := Label.new()
		daily_kicker.name = "DailyPracticeKicker"
		daily_kicker.text = "DEVICE-LOCAL DAILY PRACTICE"
		daily_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		daily_kicker.add_theme_color_override("font_color", Color("#BFA5D8"))
		daily_kicker.add_theme_font_size_override("font_size", 14)
		daily_content.add_child(daily_kicker)
		var daily_title := Label.new()
		daily_title.name = "DailyPracticeTitle"
		daily_title.text = "DAILY HOUSE RITUAL · LEVEL %d" % daily_level if daily_level > 0 else "DAILY HOUSE RITUAL · SEALED"
		daily_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		daily_title.add_theme_color_override("font_color", Color("#FFF0D8"))
		daily_title.add_theme_font_size_override("font_size", 20)
		daily_content.add_child(daily_title)
		var daily_truth := Label.new()
		daily_truth.name = "DailyPracticeTruth"
		daily_truth.text = "REPLAY ONLY · NO BONUS REWARD · NO CURRENCY SPEND" if daily_level > 0 else "COMPLETE AN OPENING RITUAL TO UNLOCK LOCAL PRACTICE"
		daily_truth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		daily_truth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		daily_truth.add_theme_color_override("font_color", Color("#D5AD70"))
		daily_truth.add_theme_font_size_override("font_size", 13)
		daily_content.add_child(daily_truth)
		var daily_action := Button.new()
		daily_action.name = "DailyPracticeAction"
		daily_action.text = "PRACTICE LEVEL %d" % daily_level if daily_level > 0 else "RESTORE A DISPLAY TO UNLOCK"
		daily_action.custom_minimum_size.y = 50
		daily_action.disabled = daily_level <= 0
		daily_action.set_meta("daily_level", daily_level)
		daily_action.set_meta("retention_contract", "device_local_replay_no_bonus")
		_style_meta_action(daily_action, daily_level > 0)
		daily_content.add_child(daily_action)
		if daily_level > 0:
			daily_action.pressed.connect(_open_daily_practice.bind(daily_level))

		var weekly_button := Button.new()
		weekly_button.name = "WeeklyMissionsAction"
		weekly_button.text = "OPEN WEEKLY RITUALS"
		weekly_button.custom_minimum_size.y = 60
		_style_meta_action(weekly_button, true)
		layout.add_child(weekly_button)
		weekly_button.pressed.connect(show_weekly_missions)
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
			{"icon":"☾", "art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg", "title":"MOONLIGHT MARKET", "body":"The opening cabinet set is restored. The House is ready for a future moonlit event." if opening_complete else "Awaken the three opening displays to restore the Curio House.", "status":"OPENING CHAPTER COMPLETE · FUTURE MARKET EVENT REMAINS SEALED" if opening_complete else "CHAPTER PROGRESS TRACKED · MARKET EVENT NOT YET ACTIVE"},
			{"icon":"♜", "art":"res://assets/curios/ch01_curio_moth_reliquary.svg", "title":"THE LOST RELICS", "body":"A sealed reliquary marks a future cabinet journey.", "status":"UPPER CABINETS SEALED · FUTURE JOURNEY" if opening_complete else "LOCKED · COMPLETE THE OPENING CHAPTER"},
			{"icon":"✧", "art":"res://assets/curios/ch01_curio_thorned_locket.svg", "title":"WEEKLY RITUALS", "body":"Weekly ritual challenges will live here when a live mission feed exists.", "status":"FUTURE FEATURE · NO CLAIMABLE REWARDS"}
		]
	elif is_profile:
		entries = [
			{"icon":"☾", "art":"res://assets/pieces/moon_sigil.svg", "title":"CHAPTER PROGRESS", "body":"Opening chapter complete · %d of %d rituals." % [completed_count, INTERNAL_REVIEW_LEVEL_COUNT] if opening_complete else "%d of %d opening rituals completed." % [completed_count, INTERNAL_REVIEW_LEVEL_COUNT], "status":"FIRST CABINET SET RESTORED" if opening_complete else "YOUR SAVED JOURNEY"},
			{"icon":"✦", "art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg", "title":"RELIQUARY", "body":"%d of %d opening curios awakened." % [collected_count, INTERNAL_REVIEW_LEVEL_COUNT], "status":"OPENING SET COMPLETE" if opening_complete else "RELICS RECOVERED"},
			{"icon":"⌂", "art":"res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg", "title":"HOUSE RESTORATION", "body":"Restoration stage %d." % restored_stage, "status":"OPENING RESTORATION COMPLETE" if opening_complete else "PROGRESS SAVED ON THIS DEVICE"}
		]
	else:
		entries = [
			{"icon":"◉", "title":"CANDLELIGHT KIT", "body":"A future soft-currency cabinet for restoration supplies.", "status":"SEALED · ECONOMY PREVIEW ONLY"},
			{"icon":"◇", "title":"MOONSTONE CACHE", "body":"A future premium-currency cabinet. No price or payment flow is active.", "status":"SEALED · NO REAL-MONEY PURCHASES"},
			{"icon":"✦", "title":"RESTORER'S RELIQUARY", "body":"A future curated bundle surface for boosters and curios.", "status":"SEALED · STORE NOT CONNECTED"}
		]
	var card_index := 0
	for entry in entries:
		var card := PanelContainer.new()
		card_index += 1
		card.name = "FeatureCard%d" % card_index
		card.custom_minimum_size = Vector2(0, 210) if is_events else (Vector2(0, 170) if not is_profile else Vector2(0, 190))
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
		var art_path := String(entry.get("art", ""))
		if art_path != "":
			var card_art := TextureRect.new()
			card_art.name = "CardArt%d" % card_index
			card_art.custom_minimum_size = Vector2(116, 116) if is_events else Vector2(96, 96)
			card_art.texture = PieceAssetLoader.ornament(art_path)
			card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(card_art)
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
		_build_profile_save_health_card(layout)
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
	# Retention/meta destinations may use only contract-owned first-party content
	# art. Live event/economy truth remains unavailable, so visual richness must
	# never imply a claimable reward, price, countdown or active event.
	return true

func _build_profile_save_health_card(layout: VBoxContainer) -> void:
	if layout == null or layout.get_node_or_null("SaveHealthCard") != null:
		return
	var card := PanelContainer.new()
	card.name = "SaveHealthCard"
	card.custom_minimum_size = Vector2(0, 176)
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#11131D", 0.98)
	shell.border_color = Color("#8796C7", 0.74)
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(14)
	shell.content_margin_left = 16
	shell.content_margin_right = 16
	shell.content_margin_top = 12
	shell.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", shell)
	layout.add_child(card)

	var content := VBoxContainer.new()
	content.name = "SaveHealthContent"
	content.add_theme_constant_override("separation", 5)
	card.add_child(content)

	var kicker := Label.new()
	kicker.name = "SaveHealthKicker"
	kicker.text = "SAVE & ACCOUNT"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_color_override("font_color", Color("#D5AD70"))
	kicker.add_theme_font_size_override("font_size", 14)
	content.add_child(kicker)

	var local_status := Label.new()
	local_status.name = "LocalSaveStatus"
	local_status.text = _local_save_status_copy()
	local_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	local_status.add_theme_color_override("font_color", Color("#FFF0D8"))
	local_status.add_theme_font_size_override("font_size", 20)
	content.add_child(local_status)

	var local_detail := Label.new()
	local_detail.name = "LocalSaveDetail"
	local_detail.text = _local_save_detail_copy()
	local_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	local_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	local_detail.add_theme_color_override("font_color", Color("#D8C6C3"))
	local_detail.add_theme_font_size_override("font_size", 15)
	content.add_child(local_detail)

	var cloud_status := Label.new()
	cloud_status.name = "CloudSyncStatus"
	cloud_status.text = "CLOUD SYNC · NOT CONNECTED"
	cloud_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cloud_status.add_theme_color_override("font_color", Color("#BFA5D8"))
	cloud_status.add_theme_font_size_override("font_size", 16)
	content.add_child(cloud_status)

	var cloud_detail := Label.new()
	cloud_detail.name = "CloudSyncDetail"
	cloud_detail.text = "No account sign-in, remote backup, or cross-device restore is active in this build."
	cloud_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cloud_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cloud_detail.add_theme_color_override("font_color", Color("#B8AAB8"))
	cloud_detail.add_theme_font_size_override("font_size", 14)
	content.add_child(cloud_detail)

func _local_save_status_copy() -> String:
	match _save_load_status:
		"primary":
			return "LOCAL SAVE · HEALTHY"
		"backup_recovered":
			return "LOCAL SAVE · BACKUP RECOVERED"
		"default_after_invalid_primary":
			return "LOCAL SAVE · SAFE NEW RECORD"
		"future_schema":
			return "LOCAL SAVE · UPDATE REQUIRED"
		"default_new":
			return "LOCAL SAVE · NEW ON THIS DEVICE"
		_:
			return "LOCAL SAVE · DEVICE-LOCAL"

func _local_save_detail_copy() -> String:
	match _save_load_status:
		"backup_recovered":
			return "The primary record was unreadable; the last known good device backup restored your saved House state."
		"default_after_invalid_primary":
			return "The unreadable primary record could not be recovered; this build prepared a safe new local record."
		"future_schema":
			return "This record belongs to a newer build and is protected from overwrite. Update before continuing."
		"primary":
			return "Progress is stored transactionally on this device with a last-known-good local backup."
		"default_new":
			return "A new device-local House record is ready. No remote backup is active."
		_:
			return "Progress is device-local. Cloud backup is not active."

func save_health_contract() -> Dictionary:
	return {
		"load_status": _save_load_status,
		"write_blocked_reason": _save_write_blocked_reason,
		"local_status": _local_save_status_copy(),
		"cloud_sync_connected": false,
		"remote_backup_active": false,
		"cross_device_restore_active": false,
		"cloud_status": "CLOUD SYNC · NOT CONNECTED",
	}

func show_settings() -> bool:
	if navigation == null or not navigation.open_settings():
		return false
	_settings_screen = SettingsScene.instantiate()
	screen_host.add_child(_settings_screen)
	Typography.apply(_settings_screen)
	CurioMaterials.apply(_settings_screen)
	if _settings_screen.has_method("set_return_context"):
		_settings_screen.set_return_context(navigation.route_name().to_lower())
	_settings_screen.bind_settings(user_settings)
	if _settings_screen.has_signal("interaction_feedback_requested"):
		_settings_screen.interaction_feedback_requested.connect(_on_settings_feedback_requested)
	_settings_screen.close_requested.connect(close_settings)
	return true

func _on_settings_feedback_requested(_kind: String = "ui") -> void:
	_emit_shell_feedback()

func close_settings() -> bool:
	if navigation == null or not navigation.close_settings():
		return false
	if _settings_screen != null and is_instance_valid(_settings_screen):
		_settings_screen.queue_free()
	_settings_screen = null
	return true

func _render_house(restoration_mode: bool = false, curio_id: String = "", restoration_stage: int = 0, returning_player: bool = false) -> void:
	var screen: Node = HouseScene.instantiate()
	_show_screen(screen)
	screen.set_available_level_count(INTERNAL_REVIEW_LEVEL_COUNT)
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	screen.set_progress(progress)
	if screen.has_method("set_returning_player"):
		screen.set_returning_player(returning_player)
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
		# House is already rendered beneath the restoration ceremony.
		# Keep the next-level CTA available without forcing another route.

func _on_collection_house_inspect_requested(curio_id: String) -> void:
	if not show_house():
		return
	var house := current_screen()
	if house != null and house.has_method("open_curio_inspect"):
		house.open_curio_inspect(curio_id)

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
	if analytics != null and kind in ["won", "failed"] and _active_level_number > 0:
		analytics.record("level_result", {"level_number": _active_level_number, "result": kind})
	if kind == "won" and navigation.current() == NavigationScript.Route.GAMEPLAY:
		navigation.go(NavigationScript.Route.WIN_REWARDS, {"result": "won"})

func _on_level_won(level_id: String, curio_id: String, house_stage_reward: int) -> void:
	_pending_level_number = 0
	var transaction_id := "win:first:%s" % level_id
	if not complete_level_win(transaction_id, level_id, curio_id, house_stage_reward):
		# Keep the visible reward claim retryable when persistence fails.
		if _current_screen != null and is_instance_valid(_current_screen) and _current_screen.has_method("restore_reward_claim"):
			_current_screen.restore_reward_claim()

func _on_level_replay_finished(level_id: String) -> void:
	_pending_level_number = 0
	_active_level_number = 0
	if navigation.current() != NavigationScript.Route.WIN_REWARDS or progress == null or not progress.completed_levels.has(level_id):
		return
	if navigation.go(NavigationScript.Route.HOUSE, {"reason": "level_replay_complete", "level": level_id}):
		_render_house()

func _on_gameplay_feedback_requested(kind: String) -> void:
	if audio_director != null:
		audio_director.request_feedback(kind)

func _on_presentation_settings_changed(state: Dictionary) -> void:
	if ui_haptics != null:
		ui_haptics.apply_settings(state)
	if _current_screen != null and is_instance_valid(_current_screen) and _current_screen.has_method("apply_presentation_settings"):
		_current_screen.apply_presentation_settings(state)
	if _settings_screen != null and is_instance_valid(_settings_screen) and _settings_screen.has_method("apply_presentation_settings"):
		_settings_screen.apply_presentation_settings(state)

func _on_analytics_route_changed(from_route: int, to_route: int, _payload: Dictionary) -> void:
	if analytics == null or navigation == null:
		return
	analytics.record("route_changed", {
		"from": navigation.route_name(from_route).to_lower(),
		"to": navigation.route_name(to_route).to_lower(),
	})

func _level_number_from_id(level_id: String) -> int:
	var parts := level_id.split("_")
	if parts.is_empty():
		return maxi(1, _active_level_number)
	return maxi(1, int(parts[parts.size() - 1]))

func analytics_contract() -> Dictionary:
	if analytics == null:
		return {
			"transport_mode": "local_only",
			"network_transport_connected": false,
			"events": [],
		}
	var diagnostics: Dictionary = analytics.diagnostics()
	diagnostics["events"] = analytics.snapshot()
	return diagnostics

func _level_path(level_number: int) -> String:
	return "res://content/levels/ch01/level_%03d.json" % level_number

func _show_screen(screen: Node) -> void:
	if _current_screen != null and is_instance_valid(_current_screen):
		screen_host.remove_child(_current_screen)
		_current_screen.queue_free()
	_current_screen = screen
	screen_host.add_child(screen)
	if screen is Control:
		MobileSafeArea.apply_content(screen as Control)
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
	if _shell_navigation_locked or section == _active_shell_section():
		return
	_shell_navigation_locked = true
	_emit_shell_feedback()
	call_deferred("_release_shell_navigation_lock")
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

func _active_shell_section() -> String:
	match current_route_name():
		"house":
			return "house"
		"collection":
			return "curios"
		"map", "chapters":
			return "map"
		"events", "missions":
			return "events"
		"shop":
			return "shop"
		"profile_settings":
			return "profile"
		_:
			return ""

func _emit_shell_feedback() -> void:
	if audio_director != null:
		audio_director.request_feedback("ui")
	if ui_haptics != null:
		ui_haptics.request_ui()

func _release_shell_navigation_lock() -> void:
	_shell_navigation_locked = false

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
	if navigation == null or progress == null or user_settings == null:
		return
	if _store != null and _store.is_write_blocked():
		return
	if _current_screen != null and _current_screen.has_method("boot_state") and String(_current_screen.boot_state()) == "loading":
		return
	if navigation.current() == NavigationScript.Route.BOOT:
		if not navigation.go(NavigationScript.Route.HOUSE, {"reason": "splash_continue"}):
			return
	elif navigation.current() != NavigationScript.Route.HOUSE:
		return
	var returning_player := _returning_player_entry
	_returning_player_entry = false
	_render_house(false, "", 0, returning_player)

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


func _has_durable_progress(value) -> bool:
	if value == null:
		return false
	return int(value.house_stage) > 0 or not value.completed_levels.is_empty() or not value.curios.is_empty()
