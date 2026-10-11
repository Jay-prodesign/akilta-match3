extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")

const READY_SAVE := "user://test_splash_boot_ready.json"
const READY_SETTINGS := "user://test_splash_boot_ready_settings.json"
const INVALID_SAVE := "user://test_splash_boot_invalid.json"
const INVALID_SETTINGS := "user://test_splash_boot_invalid_settings.json"
const FUTURE_SAVE := "user://test_splash_boot_future.json"
const FUTURE_SETTINGS := "user://test_splash_boot_future_settings.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in [READY_SAVE, READY_SETTINGS, INVALID_SAVE, INVALID_SETTINGS, FUTURE_SAVE, FUTURE_SETTINGS]:
		_remove(path)
		_remove(path + ".bak")
		_remove(path + ".tmp")

	await _verify_clean_ready()
	await _verify_recoverable_invalid_save()
	await _verify_future_save_protection()

	for path in [READY_SAVE, READY_SETTINGS, INVALID_SAVE, INVALID_SETTINGS, FUTURE_SAVE, FUTURE_SETTINGS]:
		_remove(path)
		_remove(path + ".bak")
		_remove(path + ".tmp")

	if failures.is_empty():
		print("TEST_PASS: S00 boot loading ready and recovery contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _verify_clean_ready() -> void:
	var app = APP_SCENE.instantiate()
	app.save_path_override = READY_SAVE
	app.settings_path_override = READY_SETTINGS
	root.add_child(app)
	var splash = app.current_screen()
	_expect(splash != null and splash.has_method("boot_state") and splash.boot_state() == "loading", "Cold boot must first expose S00 loading")
	var enter: Button = splash.get_node_or_null("Layout/Enter") as Button
	_expect(enter != null and (not enter.visible or enter.disabled), "S00 loading must not expose an active Enter action")
	await _frames(3)
	_expect(splash.boot_state() == "ready", "Clean boot must resolve S00 to ready")
	_expect(enter.visible and not enter.disabled and enter.text == "ENTER THE HOUSE", "Ready S00 must expose Enter the House")
	app.queue_free()
	await _frames(2)

func _verify_recoverable_invalid_save() -> void:
	_write(INVALID_SAVE, "{ not valid json")
	var app = APP_SCENE.instantiate()
	app.save_path_override = INVALID_SAVE
	app.settings_path_override = INVALID_SETTINGS
	root.add_child(app)
	var splash = app.current_screen()
	await _frames(3)
	_expect(splash != null and splash.boot_state() == "recoverable_error", "Unreadable local save must expose S00 recoverable_error")
	var recovery: Label = splash.get_node_or_null("Layout/BootState/StateContent/RecoveryMessage") as Label
	var enter: Button = splash.get_node_or_null("Layout/Enter") as Button
	_expect(recovery != null and recovery.visible and recovery.text.contains("unreadable"), "Recoverable S00 must explain the local save recovery")
	_expect(enter != null and enter.visible and not enter.disabled, "Recovered default session must remain enterable")
	if enter != null:
		enter.emit_signal("pressed")
	await _frames(3)
	_expect(String(app.current_route_name()) == "house", "Recovered S00 must enter the House safely")
	_expect(app.progress != null and int(app.progress.house_stage) == 0, "Recovered default boot must not invent progress")
	app.queue_free()
	await _frames(2)

func _verify_future_save_protection() -> void:
	_write(FUTURE_SAVE, JSON.stringify({
		"schema_version": 99,
		"highest_level_unlocked": 3,
		"house_stage": 2,
		"lives": 5,
		"coins": 999,
		"gems": 99,
		"completed_levels": ["ch01_level_001"],
		"curios": ["moon_cameo"],
		"processed_transactions": ["future"]
	}))
	var app = APP_SCENE.instantiate()
	app.save_path_override = FUTURE_SAVE
	app.settings_path_override = FUTURE_SETTINGS
	root.add_child(app)
	var splash = app.current_screen()
	await _frames(3)
	_expect(splash != null and splash.boot_state() == "recoverable_error", "Future-schema save must surface protected boot state")
	var enter: Button = splash.get_node_or_null("Layout/Enter") as Button
	_expect(enter != null and enter.visible and enter.disabled and enter.text == "UPDATE REQUIRED", "Future-schema record must not be entered or overwritten")
	_expect(String(app.current_route_name()) == "boot", "Future-schema protection must keep navigation on BOOT")
	app.queue_free()
	await _frames(2)

func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("Could not create boot fixture: %s" % path)
		return
	file.store_string(value)
	file.close()

func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
