extends SceneTree

const Navigation = preload("res://src/app/navigation_controller.gd")
const Settings = preload("res://src/settings/user_settings.gd")
const TEST_SETTINGS := "user://match3_first_party_shell_settings.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var nav = Navigation.new()
	_expect(nav.route_name() == "BOOT", "navigation starts at BOOT")
	_expect(nav.go(Navigation.Route.HOUSE), "BOOT -> HOUSE must be legal")
	_expect(not nav.go(Navigation.Route.GAMEPLAY), "HOUSE cannot bypass map/prestart")
	_expect(nav.open_settings(), "settings open only from HOUSE")
	_expect(nav.back() == "close_settings", "back closes settings first")
	_expect(nav.go(Navigation.Route.MAP), "HOUSE -> MAP must be legal")
	_expect(nav.go(Navigation.Route.PRESTART, {"level": 1}), "MAP -> PRESTART must be legal")
	_expect(nav.go(Navigation.Route.GAMEPLAY, {"level": 1}), "PRESTART -> GAMEPLAY must be legal")
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
