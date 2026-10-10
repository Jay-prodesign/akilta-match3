extends SceneTree

const UserSettings = preload("res://src/settings/user_settings.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var master := AudioServer.get_bus_index("Master")
	var music := AudioServer.get_bus_index("Music")
	var sfx := AudioServer.get_bus_index("SFX")
	_expect(master >= 0 and music >= 0 and sfx >= 0, "Master/Music/SFX buses must exist")
	_expect(String(AudioServer.get_bus_send(music)) == "Master", "Music must route to Master")
	_expect(String(AudioServer.get_bus_send(sfx)) == "Master", "SFX must route to Master")

	var settings = UserSettings.new()
	settings.set_value("music_volume", 0.25, false)
	settings.set_value("sfx_volume", 0.75, false)
	settings.set_value("music_muted", true, false)
	_expect(AudioServer.is_bus_mute(music), "music mute must affect real Music bus")
	_expect(not AudioServer.is_bus_mute(sfx), "SFX must remain independently unmuted")
	_expect(absf(AudioServer.get_bus_volume_db(sfx) - linear_to_db(0.75)) < 0.01, "SFX volume must map to AudioServer dB")

	settings.set_value("music_muted", false, false)
	settings.set_value("music_volume", 1.0, false)
	settings.set_value("sfx_volume", 1.0, false)

	if failures.is_empty():
		print("TEST_PASS: first-party audio bus routing")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
