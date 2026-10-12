extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")
const SaveStoreScript = preload("res://src/save/save_store.gd")

const SAVE_PATH := "user://save_recovery_surface_test.json"
const SETTINGS_PATH := "user://save_recovery_surface_settings.json"
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	var progress = ProgressScript.new()
	var store = SaveStoreScript.new(SAVE_PATH)
	_expect(progress.apply_level_win("recovery-l1", "ch01_level_001", "moon_cameo", 1), "Level 1 recovery seed must apply")
	_expect(store.save(progress.to_dict()), "first recovery seed save must succeed")
	_expect(progress.apply_level_win("recovery-l2", "ch01_level_002", "moth_reliquary", 2), "Level 2 recovery seed must apply")
	_expect(store.save(progress.to_dict()), "second recovery seed save must create a last-known-good backup")

	var primary := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	_expect(primary != null, "test must be able to corrupt the primary save")
	if primary != null:
		primary.store_string("{ broken-primary")
		primary.close()

	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await _frames(4)

	_expect(app.has_method("save_health_contract"), "app must expose save-health truth")
	var health: Dictionary = app.save_health_contract() if app.has_method("save_health_contract") else {}
	_expect(String(health.get("load_status", "")) == "backup_recovered", "corrupt primary must report backup_recovered")
	_expect(not bool(health.get("cloud_sync_connected", true)), "cloud sync must remain explicitly disconnected")
	_expect(not bool(health.get("remote_backup_active", true)), "remote backup must not be implied")
	_expect(not bool(health.get("cross_device_restore_active", true)), "cross-device restore must not be implied")
	_expect(int(app.progress.house_stage) == 1 and app.progress.curios.has("moon_cameo"), "app must hydrate last-known-good backup rather than corrupt primary")

	var splash = app.current_screen()
	var enter: Button = splash.get_node_or_null("Layout/Enter") as Button if splash != null else null
	_expect(enter != null, "recovered Splash must retain a safe enter action")
	if enter != null:
		enter.emit_signal("pressed")
		await _frames(3)

	_expect(String(app.current_route_name()) == "house", "recovered save must enter House after acknowledgement")
	_expect(app.show_feature_preview("Profile"), "recovered House must open Profile")
	await _frames(3)
	var profile = app.current_screen()
	var local_status: Label = profile.get_node_or_null("FeatureLayout/SaveHealthCard/SaveHealthContent/LocalSaveStatus") as Label if profile != null else null
	var local_detail: Label = profile.get_node_or_null("FeatureLayout/SaveHealthCard/SaveHealthContent/LocalSaveDetail") as Label if profile != null else null
	var cloud_status: Label = profile.get_node_or_null("FeatureLayout/SaveHealthCard/SaveHealthContent/CloudSyncStatus") as Label if profile != null else null
	var cloud_detail: Label = profile.get_node_or_null("FeatureLayout/SaveHealthCard/SaveHealthContent/CloudSyncDetail") as Label if profile != null else null
	_expect(local_status != null and local_status.text.contains("BACKUP RECOVERED"), "Profile must surface backup recovery provenance")
	_expect(local_detail != null and local_detail.text.contains("last known good device backup"), "Profile must explain local backup recovery")
	_expect(cloud_status != null and cloud_status.text == "CLOUD SYNC · NOT CONNECTED", "Profile must state cloud sync truth")
	_expect(cloud_detail != null and cloud_detail.text.contains("No account sign-in") and cloud_detail.text.contains("cross-device restore"), "Profile must deny unavailable account/cloud capabilities")

	if profile != null:
		for node in profile.find_children("", "Button", true, false):
			var text := (node as Button).text.to_upper()
			_expect(not text.contains("SIGN IN") and not text.contains("SYNC NOW"), "Profile must not expose a fake account/cloud action")

	app.queue_free()
	await process_frame
	_cleanup()
	if failures.is_empty():
		print("TEST_PASS: local save recovery and cloud-sync truth")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _cleanup() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
