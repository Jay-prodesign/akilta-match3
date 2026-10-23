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
const MetaDestinationScene = preload("res://src/ui/meta/meta_destination_screen.tscn")
const WeeklyMissionsScene = preload("res://src/ui/missions/weekly_missions_screen.tscn")
const SplashScene = preload("res://src/ui/splash/splash_screen.tscn")
const AudioDirectorScript = preload("res://src/feedback/audio_director.gd")
const HapticsControllerScript = preload("res://src/feedback/haptics_controller.gd")
const AnalyticsScript = preload("res://src/analytics/product_analytics.gd")
const Typography = preload("res://src/ui/theme/typography.gd")
const CurioMaterials = preload("res://src/ui/theme/curio_materials.gd")
const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const MobileSafeArea = preload("res://src/ui/shared/mobile_safe_area.gd")
const NATIVE_RUNTIME_REVIEW_AUTO_ENTER_ARG := "--cat-coven-native-review-auto-enter"
const NATIVE_RUNTIME_REVIEW_ROUTE_PREFIX := "--cat-coven-native-review-route="
const ROUTE_TRANSITION_DURATION := 0.10

@export var environment: String = "development"
@export var save_path_override: String = ""
@export var settings_path_override: String = ""
@export var analytics_path_override: String = ""

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
var _settings_suspended_screen: CanvasItem
var _settings_suspended_process_mode: int = Node.PROCESS_MODE_INHERIT
var _pending_level_number: int = 0
var _returning_player_entry: bool = false
var _shell_navigation_locked: bool = false
var _route_transition_tween: Tween
var _route_transition_count: int = 0
var _last_route_transition_mode: String = "none"
## Founder-authorized internal review exposes three provisional levels.
## This does not confer D-024B/D-027 shipping or final-art approval.
const INTERNAL_REVIEW_LEVEL_COUNT := 3

@onready var screen_host: Node = $ScreenHost
@onready var route_transition_veil: ColorRect = $RouteTransitionVeil

func _ready() -> void:
	_ensure_android_immersive_mode()
	# S00 must be a real boot state, not a decorative gate shown after loading.
	# Navigation exists immediately so the player is truthfully on BOOT while the
	# first rendered frame exposes the canonical loading state.
	navigation = NavigationScript.new()
	_render_splash()
	call_deferred("_complete_bootstrap")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		call_deferred("_ensure_android_immersive_mode")

func _ensure_android_immersive_mode() -> void:
	if OS.get_name() != "Android":
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _complete_bootstrap() -> void:
	var path: String = save_path_override if save_path_override != "" else SaveStoreScript.DEFAULT_PATH
	_store = SaveStoreScript.new(path)
	var loaded: Dictionary = _store.load_or_default()
	_save_load_status = String(_store.load_status())
	_save_write_blocked_reason = String(_store.write_blocked_reason)
	progress = ProgressScript.from_dict(loaded)
	_returning_player_entry = _has_durable_progress(progress)

	var analytics_path := analytics_path_override if analytics_path_override != "" else AnalyticsScript.DEFAULT_PATH
	analytics = AnalyticsScript.new(analytics_path)
	analytics.start_session({
		"environment": environment,
		"returning": _returning_player_entry,
		"save_status": _save_load_status,
	})
	if not navigation.route_changed.is_connected(_on_navigation_route_changed):
		navigation.route_changed.connect(_on_navigation_route_changed)
	analytics.track("screen_view", {"route": "boot", "from": "", "via": "bootstrap"})

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
	if String(splash.boot_state()) == "ready":
		var native_review_route := _native_runtime_review_route_requested()
		if native_review_route != "":
			call_deferred("_run_native_runtime_review_route", native_review_route)
		elif _native_runtime_review_auto_enter_requested():
			call_deferred("_on_splash_continue")

func native_runtime_review_route_from_args(args: PackedStringArray) -> String:
	for raw_arg in args:
		var arg := String(raw_arg)
		if not arg.begins_with(NATIVE_RUNTIME_REVIEW_ROUTE_PREFIX):
			continue
		var route := arg.trim_prefix(NATIVE_RUNTIME_REVIEW_ROUTE_PREFIX).strip_edges().to_lower()
		if route in ["house", "map", "prestart", "gameplay", "reliquary", "events", "weekly", "shop", "profile", "settings", "secondary"]:
			return route
	return ""

func _native_runtime_review_route_requested() -> String:
	var route := native_runtime_review_route_from_args(OS.get_cmdline_args())
	if route != "":
		return route
	return native_runtime_review_route_from_args(OS.get_cmdline_user_args())

func _native_runtime_review_auto_enter_requested() -> bool:
	# Workflow-only proof hook. Normal player launches never receive this arg.
	return OS.get_cmdline_args().has(NATIVE_RUNTIME_REVIEW_AUTO_ENTER_ARG) or OS.get_cmdline_user_args().has(NATIVE_RUNTIME_REVIEW_AUTO_ENTER_ARG)

func _run_native_runtime_review_route(route: String) -> void:
	# Workflow-only deep review path. It deliberately traverses the same real
	# navigation methods a player uses; it never instantiates a fake review UI.
	_on_splash_continue()
	if navigation == null or navigation.current() != NavigationScript.Route.HOUSE:
		return
	match route:
		"house":
			_write_native_runtime_review_marker("house")
			print("NATIVE_RUNTIME_REVIEW_ROUTE_PASS: house")
		"map":
			if not show_map():
				return
			_write_native_runtime_review_marker("map")
			print("NATIVE_RUNTIME_REVIEW_ROUTE_PASS: map")
		"prestart":
			if not show_map():
				return
			if not show_prestart(1):
				return
			_write_native_runtime_review_marker("prestart")
			print("NATIVE_RUNTIME_REVIEW_ROUTE_PASS: prestart")
		"gameplay":
			if not show_map():
				return
			if not show_prestart(1):
				return
			if not start_level(1):
				return
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().create_timer(0.55).timeout
			if _current_screen == null or not _current_screen.has_method("gameplay_native_layout_contract"):
				push_error("Native gameplay review is missing its runtime layout contract.")
				return
			var gameplay_layout: Dictionary = _current_screen.gameplay_native_layout_contract()
			if not bool(gameplay_layout.get("booster_visible", false)) or not bool(gameplay_layout.get("booster_inside_viewport", false)):
				push_error("Native gameplay booster tray is outside the rendered viewport: %s" % gameplay_layout)
				return
			var native_gap := float(gameplay_layout.get("board_to_booster_gap", -1.0))
			if native_gap < 30.0 or native_gap > 42.0:
				push_error("Native gameplay board-to-booster gap drifted: %s" % gameplay_layout)
				return
			_write_native_runtime_review_marker("gameplay")
			print("NATIVE_RUNTIME_REVIEW_LAYOUT_PASS: %s" % gameplay_layout)
			print("NATIVE_RUNTIME_REVIEW_ROUTE_PASS: gameplay")
		"reliquary":
			if not show_collection():
				return
			await _settle_native_runtime_review_route("reliquary")
		"events":
			if not show_feature_preview("Events"):
				return
			await _settle_native_runtime_review_route("events")
		"weekly":
			if not show_weekly_missions():
				return
			await _settle_native_runtime_review_route("weekly")
		"shop":
			if not show_feature_preview("Shop"):
				return
			await _settle_native_runtime_review_route("shop")
		"profile":
			if not show_feature_preview("Profile"):
				return
			await _settle_native_runtime_review_route("profile")
		"settings":
			if not show_feature_preview("Profile"):
				return
			if not show_settings():
				return
			await _settle_native_runtime_review_route("settings")
		"secondary":
			await _run_native_secondary_review_sequence()

func _settle_native_runtime_review_route(route: String, hold_seconds: float = 0.0) -> void:
	# Review markers are emitted only after the real scene has had time to lay out
	# and its short authored route transition has completed.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	_write_native_runtime_review_marker(route)
	print("NATIVE_RUNTIME_REVIEW_ROUTE_PASS: %s" % route)
	if hold_seconds > 0.0:
		await get_tree().create_timer(hold_seconds).timeout

func _run_native_secondary_review_sequence() -> void:
	# One native launch walks the real secondary product destinations in player
	# navigation order. Each state is held long enough for CI to capture the
	# settled device frame; no review-only UI is created.
	if not show_collection():
		return
	await _settle_native_runtime_review_route("reliquary", 3.0)

	if not show_house():
		return
	if not show_feature_preview("Events"):
		return
	await _settle_native_runtime_review_route("events", 3.0)

	if not show_weekly_missions():
		return
	await _settle_native_runtime_review_route("weekly", 3.0)

	if not _ensure_house_route():
		return
	if not show_feature_preview("Shop"):
		return
	await _settle_native_runtime_review_route("shop", 3.0)

	if not show_feature_preview("Profile"):
		return
	await _settle_native_runtime_review_route("profile", 3.0)

	if not show_settings():
		return
	await _settle_native_runtime_review_route("settings")

func _write_native_runtime_review_marker(route: String) -> void:
	var marker := FileAccess.open("user://native-runtime-review-route.txt", FileAccess.WRITE)
	if marker == null:
		return
	marker.store_string(route)
	marker.close()

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
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	screen.set_progress(progress)
	_install_product_navigation(screen, "curios")
	screen.back_requested.connect(_on_collection_back)
	if screen.has_signal("house_inspect_requested"):
		screen.house_inspect_requested.connect(_on_collection_house_inspect_requested)
	if screen.has_signal("interaction_feedback_requested"):
		screen.interaction_feedback_requested.connect(_on_collection_interaction_feedback_requested)
	return true

func _on_collection_interaction_feedback_requested(_kind: String = "ui") -> void:
	_emit_shell_feedback()

func show_map() -> bool:
	if not navigation.go(NavigationScript.Route.MAP):
		return false
	var screen: Node = MapScene.instantiate()
	screen.set("canonical_level_cap", INTERNAL_REVIEW_LEVEL_COUNT)
	_show_screen(screen)
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	screen.set_progress(progress)
	_install_product_navigation(screen, "map")
	if screen.has_signal("interaction_feedback_requested"):
		screen.interaction_feedback_requested.connect(_on_chapter_interaction_feedback_requested)
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
	_track_analytics("level_started", {
		"level_id": level_id,
		"level_number": level_number,
		"replay": bool(screen.replay_mode),
	})
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
	_track_analytics("level_reward", {
		"level_id": level_id,
		"curio_id": curio_id,
		"first_clear": true,
		"house_stage": int(candidate.house_stage),
		"coins_awarded": int(ProgressScript.FIRST_CLEAR_COIN_REWARD),
		"gems_awarded": int(ProgressScript.FIRST_CLEAR_GEM_REWARD),
	})
	if restoration_needed:
		if not navigation.go(NavigationScript.Route.RESTORATION, {"reason": "level_reward_restoration"}):
			return false
		_render_house(true, curio_id, int(candidate.house_stage))
	else:
		if not navigation.go(NavigationScript.Route.HOUSE, {"reason": "level_replay_complete"}):
			return false
		_render_house(false, "", int(candidate.house_stage))
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

	var completed_count := mini(int(progress.completed_levels.size()) if progress != null else 0, INTERNAL_REVIEW_LEVEL_COUNT)
	var screen: Node = WeeklyMissionsScene.instantiate()
	_show_screen(screen)
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	TopResourceBar.attach(screen as Control, progress, Callable(self, "_on_shell_profile_requested"), NodePath("MissionLayout"))
	if screen.has_signal("interaction_feedback_requested"):
		screen.interaction_feedback_requested.connect(_on_meta_interaction_feedback_requested)
	if not bool(screen.configure({
		"completed_count": completed_count,
		"opening_cap": INTERNAL_REVIEW_LEVEL_COUNT,
	})):
		_on_missions_back()
		return false
	if screen.has_signal("return_events_requested"):
		screen.return_events_requested.connect(_on_missions_back)
	if screen.has_signal("return_house_requested"):
		screen.return_house_requested.connect(_on_missions_house)
	return true


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
	show_prestart(level_number)

func show_feature_preview(feature: String) -> bool:
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

	var completed_count := mini(int(progress.completed_levels.size()) if progress != null else 0, INTERNAL_REVIEW_LEVEL_COUNT)
	var collected_count := mini(int(progress.curios.size()) if progress != null else 0, INTERNAL_REVIEW_LEVEL_COUNT)
	var restored_stage := int(progress.house_stage) if progress != null else 0
	var opening_complete := completed_count >= INTERNAL_REVIEW_LEVEL_COUNT and collected_count >= INTERNAL_REVIEW_LEVEL_COUNT and restored_stage >= INTERNAL_REVIEW_LEVEL_COUNT
	var state := {
		"completed_count": completed_count,
		"collected_count": collected_count,
		"restored_stage": restored_stage,
		"opening_cap": INTERNAL_REVIEW_LEVEL_COUNT,
		"opening_complete": opening_complete,
		"coins": int(progress.coins) if progress != null else 0,
		"gems": int(progress.gems) if progress != null else 0,
		"daily_level": _daily_practice_level() if feature_key == "events" else 0,
		"save_status": _local_save_status_copy(),
		"save_detail": _local_save_detail_copy(),
	}
	var screen: Node = MetaDestinationScene.instantiate()
	screen.name = screen_name
	_show_screen(screen)
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	if not bool(screen.configure(feature_key, state)):
		_ensure_house_route()
		return false
	_install_product_navigation(screen, feature_key, NodePath("FeatureLayout"))
	if screen.has_signal("back_requested"):
		screen.back_requested.connect(_dismiss_feature_preview)
	if screen.has_signal("settings_requested"):
		screen.settings_requested.connect(show_settings)
	if screen.has_signal("weekly_requested"):
		screen.weekly_requested.connect(show_weekly_missions)
	if screen.has_signal("daily_practice_requested"):
		screen.daily_practice_requested.connect(_open_daily_practice)
	if screen.has_signal("interaction_feedback_requested"):
		screen.interaction_feedback_requested.connect(_on_meta_interaction_feedback_requested)
	return true

func _on_meta_interaction_feedback_requested(_kind: String = "ui") -> void:
	_emit_shell_feedback()


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
	_track_analytics("settings_opened", {"route": navigation.route_name().to_lower()})
	_suspend_current_screen_for_settings()
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

func _suspend_current_screen_for_settings() -> void:
	_settings_suspended_screen = null
	if _current_screen == null or not is_instance_valid(_current_screen) or not (_current_screen is CanvasItem):
		return
	_settings_suspended_screen = _current_screen as CanvasItem
	_settings_suspended_process_mode = _current_screen.process_mode
	_settings_suspended_screen.visible = false
	_current_screen.process_mode = Node.PROCESS_MODE_DISABLED

func _restore_current_screen_after_settings() -> void:
	if _settings_suspended_screen != null and is_instance_valid(_settings_suspended_screen):
		_settings_suspended_screen.visible = true
		_settings_suspended_screen.process_mode = _settings_suspended_process_mode
	_settings_suspended_screen = null
	_settings_suspended_process_mode = Node.PROCESS_MODE_INHERIT

func _dismiss_settings_surface_without_navigation() -> void:
	if _settings_screen != null and is_instance_valid(_settings_screen):
		_settings_screen.queue_free()
	_settings_screen = null
	_restore_current_screen_after_settings()

func settings_surface_contract() -> Dictionary:
	return {
		"open": _settings_screen != null and is_instance_valid(_settings_screen),
		"origin_suspended": _settings_suspended_screen != null and is_instance_valid(_settings_suspended_screen) and not _settings_suspended_screen.visible and _settings_suspended_screen.process_mode == Node.PROCESS_MODE_DISABLED,
		"origin_preserved": _settings_suspended_screen == _current_screen if _settings_suspended_screen != null else true,
		"standalone_surface": true,
	}

func _on_settings_feedback_requested(_kind: String = "ui") -> void:
	_emit_shell_feedback()

func close_settings() -> bool:
	if navigation == null or not navigation.close_settings():
		return false
	_dismiss_settings_surface_without_navigation()
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
	if screen.has_signal("interaction_feedback_requested"):
		screen.interaction_feedback_requested.connect(_on_house_interaction_feedback_requested)
	if screen.has_signal("events_requested"):
		screen.events_requested.connect(func(): show_feature_preview("Events"))
	if screen.has_signal("shop_requested"):
		screen.shop_requested.connect(func(): show_feature_preview("Shop"))

func _on_house_interaction_feedback_requested(_kind: String = "ui") -> void:
	_emit_shell_feedback()

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
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	screen.set_progress(progress)
	_install_product_navigation(screen, "map")
	if screen.has_signal("interaction_feedback_requested"):
		screen.interaction_feedback_requested.connect(_on_chapter_interaction_feedback_requested)
	screen.back_requested.connect(_on_map_back)
	screen.level_requested.connect(show_prestart)

func _on_prestart_start(level_number: int) -> void:
	if level_number == _pending_level_number:
		start_level(level_number)

func _on_level_exit_requested() -> void:
	show_house()

func _on_gameplay_result_state_changed(kind: String) -> void:
	var level_id := ""
	if _current_screen != null and is_instance_valid(_current_screen):
		level_id = String(_current_screen.get("current_level_id"))
	_track_analytics("level_result", {"level_id": level_id, "result": kind})
	if kind == "recovered":
		_track_analytics("recovery_used", {"level_id": level_id, "kind": "free_plus_3_moves"})
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
	_track_analytics("level_replay_complete", {"level_id": level_id})
	if navigation.current() != NavigationScript.Route.WIN_REWARDS or progress == null or not progress.completed_levels.has(level_id):
		return
	if navigation.go(NavigationScript.Route.HOUSE, {"reason": "level_replay_complete", "level": level_id}):
		_render_house()

func _on_gameplay_feedback_requested(kind: String) -> void:
	if audio_director != null:
		audio_director.request_feedback(kind)

func _on_presentation_settings_changed(state: Dictionary) -> void:
	_track_analytics("settings_changed", {
		"reduced_motion": bool(state.get("reduced_motion", false)),
		"high_contrast": bool(state.get("high_contrast", false)),
		"haptics_enabled": bool(state.get("haptics_enabled", true)),
	})
	if ui_haptics != null:
		ui_haptics.apply_settings(state)
	if _current_screen != null and is_instance_valid(_current_screen):
		if _current_screen is Control:
			var reduced_motion := bool(state.get("reduced_motion", false))
			(_current_screen as Control).set_meta("reduced_motion", reduced_motion)
			ProductNavigation.set_reduced_motion(_current_screen.get_node_or_null("ProductNavigation") as PanelContainer, reduced_motion)
			TopResourceBar.set_reduced_motion(_current_screen.get_node_or_null("ResourceBar") as PanelContainer, reduced_motion)
		if _current_screen.has_method("apply_presentation_settings"):
			_current_screen.apply_presentation_settings(state)
	if _settings_screen != null and is_instance_valid(_settings_screen) and _settings_screen.has_method("apply_presentation_settings"):
		_settings_screen.apply_presentation_settings(state)

func _level_path(level_number: int) -> String:
	return "res://content/levels/ch01/level_%03d.json" % level_number

func _on_navigation_route_changed(from_route: int, to_route: int, payload: Dictionary) -> void:
	if _settings_screen != null and is_instance_valid(_settings_screen) and navigation != null and not navigation.is_settings_open():
		_dismiss_settings_surface_without_navigation()
	var via := String(payload.get("via", payload.get("reason", "")))
	_track_analytics("screen_view", {
		"from": navigation.route_name(from_route).to_lower(),
		"route": navigation.route_name(to_route).to_lower(),
		"via": via,
		"level": int(payload.get("level", 0)),
	})

func _track_analytics(event_name: String, payload: Dictionary = {}) -> void:
	if analytics != null:
		analytics.track(event_name, payload)

func analytics_status_contract() -> Dictionary:
	if analytics == null:
		return {
			"local_queue": false,
			"transport_connected": false,
			"persistent_user_id": false,
			"advertising_id": false,
			"pii_allowed": false,
		}
	return analytics.status_contract()

func analytics_events_snapshot() -> Array[Dictionary]:
	return analytics.events_snapshot() if analytics != null else []

func _show_screen(screen: Node) -> void:
	var had_previous := _current_screen != null and is_instance_valid(_current_screen)
	if had_previous:
		screen_host.remove_child(_current_screen)
		_current_screen.queue_free()
	_current_screen = screen
	screen_host.add_child(screen)
	var reduced_motion := false
	if screen is Control:
		if user_settings != null:
			reduced_motion = bool(user_settings.get_presentation_state().get("reduced_motion", false))
		(screen as Control).set_meta("reduced_motion", reduced_motion)
		MobileSafeArea.apply_content(screen as Control)
	_install_north_star_backdrop(screen)
	Typography.apply(screen)
	CurioMaterials.apply(screen)
	if had_previous:
		_play_route_entry_transition(screen, reduced_motion)

func _play_route_entry_transition(screen: Node, reduced_motion: bool) -> void:
	_route_transition_count += 1
	_last_route_transition_mode = "instant_reduced_motion" if reduced_motion else "gothic_dissolve"
	if screen != null:
		screen.set_meta("route_transition_id", _route_transition_count)
		screen.set_meta("route_transition_mode", _last_route_transition_mode)
	if route_transition_veil == null:
		return
	if _route_transition_tween != null and _route_transition_tween.is_valid():
		_route_transition_tween.kill()
	route_transition_veil.visible = not reduced_motion
	route_transition_veil.modulate = Color.WHITE
	if reduced_motion:
		route_transition_veil.visible = false
		return
	_route_transition_tween = create_tween()
	_route_transition_tween.tween_property(route_transition_veil, "modulate:a", 0.0, ROUTE_TRANSITION_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_route_transition_tween.finished.connect(func():
		if route_transition_veil != null:
			route_transition_veil.visible = false
			route_transition_veil.modulate = Color.WHITE
	)

func route_transition_contract() -> Dictionary:
	return {
		"overlay_present": route_transition_veil != null,
		"mode": _last_route_transition_mode,
		"count": _route_transition_count,
		"active": route_transition_veil != null and route_transition_veil.visible,
		"duration_seconds": ROUTE_TRANSITION_DURATION,
		"blocks_input": route_transition_veil != null and route_transition_veil.mouse_filter != Control.MOUSE_FILTER_IGNORE,
		"screen_tagged": _current_screen != null and _current_screen.has_meta("route_transition_id"),
		"screen_mode": String(_current_screen.get_meta("route_transition_mode", "")) if _current_screen != null else "",
	}

func _install_product_navigation(screen: Node, active_section: String, content_path: NodePath = NodePath("Layout")) -> void:
	if screen is Control:
		TopResourceBar.attach(screen as Control, progress, Callable(self, "_on_shell_profile_requested"), content_path)
		ProductNavigation.attach(screen as Control, active_section, Callable(self, "_on_shell_navigation_requested"), content_path)

func _on_shell_profile_requested() -> void:
	_on_shell_navigation_requested("profile")

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
	if screen.has_method("apply_presentation_settings"):
		screen.apply_presentation_settings(user_settings.get_presentation_state())
	if screen.has_method("set_progress"):
		screen.set_progress(progress)
	_install_product_navigation(screen, "map")
	if screen.has_signal("interaction_feedback_requested"):
		screen.interaction_feedback_requested.connect(_on_chapter_interaction_feedback_requested)
	screen.chapter_requested.connect(_on_chapter_selected)
	screen.back_requested.connect(show_house)
	return true

func _on_chapter_interaction_feedback_requested(_kind: String = "ui") -> void:
	_emit_shell_feedback()

func _on_chapter_selected(chapter_id: String) -> void:
	if chapter_id == "curio_boutique":
		show_map()


func _has_durable_progress(value) -> bool:
	if value == null:
		return false
	return int(value.house_stage) > 0 or not value.completed_levels.is_empty() or not value.curios.is_empty()
