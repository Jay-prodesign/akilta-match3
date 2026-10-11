extends SceneTree

const Navigation = preload("res://src/app/navigation_controller.gd")
const Settings = preload("res://src/settings/user_settings.gd")
const BoardView = preload("res://src/match3/presentation/board_view.gd")
const SplashScene = preload("res://src/ui/splash/splash_screen.tscn")
const TEST_SETTINGS := "user://match3_first_party_shell_settings.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var nav = Navigation.new()
	_expect(nav.route_name() == "BOOT", "navigation starts at BOOT")
	_expect(nav.go(Navigation.Route.HOUSE), "BOOT -> HOUSE must be legal")
	_expect(not nav.go(Navigation.Route.GAMEPLAY), "HOUSE cannot bypass map/prestart")
	_expect(nav.open_settings(), "settings must open from HOUSE")
	_expect(nav.back() == "close_settings", "back closes House settings first")
	_expect(nav.go(Navigation.Route.MAP), "HOUSE -> MAP must be legal")
	_expect(nav.go(Navigation.Route.PRESTART, {"level": 1}), "MAP -> PRESTART must be legal")
	_expect(nav.go(Navigation.Route.GAMEPLAY, {"level": 1}), "PRESTART -> GAMEPLAY must be legal")
	_expect(nav.open_settings(), "paused gameplay must support the shared settings overlay")
	_expect(nav.back() == "close_settings" and nav.route_name() == "GAMEPLAY", "closing gameplay settings must preserve gameplay route")
	_expect(nav.go(Navigation.Route.HOUSE, {"reason": "win"}), "GAMEPLAY -> HOUSE must be legal")

	_cleanup()
	var settings = Settings.new()
	var state: Dictionary = settings.load_settings(TEST_SETTINGS)
	_expect(bool(state.get("haptics_enabled", false)), "haptics default on")
	_expect(not bool(state.get("reduced_motion", true)), "reduced motion default off")
	_expect(settings.set_value("reduced_motion", true), "reduced motion must persist")
	_expect(settings.set_value("high_contrast", true), "high contrast must persist")
	var reloaded = Settings.new()
	reloaded.load_settings(TEST_SETTINGS)
	_expect(bool(reloaded.get_value("reduced_motion", false)), "reduced motion must survive reload")
	_expect(bool(reloaded.get_value("high_contrast", false)), "high contrast must survive reload")

	var board = BoardView.new()
	board.apply_presentation_settings(reloaded.get_presentation_state())
	var presentation: Dictionary = board.presentation_settings_contract()
	_expect(bool(presentation.get("reduced_motion", false)), "reduced motion must reach gameplay presentation")
	_expect(bool(presentation.get("high_contrast", false)), "high contrast must reach gameplay presentation")
	_expect(bool(board.motion_contract().get("reduced_motion_supported", false)), "board motion contract must declare reduced-motion support")
	board.free()
	var splash = SplashScene.instantiate()
	root.add_child(splash)
	await process_frame
	var splash_art: TextureRect = splash.get_node_or_null("NorthStarSplashArt")
	_expect(splash_art != null and splash_art.texture != null, "splash must render original North Star castle illustration")
	_expect(splash.get_node_or_null("Layout/Enter") != null, "splash must provide a working enter control")
	splash.queue_free()
	await process_frame
	_cleanup()
	_finish()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: AKILTA first-party shell contracts")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
