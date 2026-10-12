extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const SAVE_PATH := "user://analytics_journey_save.json"
const SETTINGS_PATH := "user://analytics_journey_settings.json"
const ANALYTICS_PATH := "user://analytics_journey_events.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	app.analytics_path_override = ANALYTICS_PATH
	root.add_child(app)
	await _frames(4)

	var status: Dictionary = app.analytics_status_contract()
	_expect(bool(status.get("local_queue", false)), "app analytics must expose a local queue")
	_expect(not bool(status.get("transport_connected", true)), "app analytics must not imply a connected backend")
	_expect(not bool(status.get("persistent_user_id", true)) and not bool(status.get("advertising_id", true)), "app analytics must remain identifier-free")

	var splash = app.current_screen()
	var enter: Button = splash.get_node_or_null("Layout/Enter") as Button if splash != null else null
	_expect(enter != null, "analytics journey requires the ready Splash action")
	if enter != null:
		enter.emit_signal("pressed")
		await _frames(3)
	_expect(String(app.current_route_name()) == "house", "analytics journey must enter House")

	_expect(app.show_map(), "analytics journey must open the current map")
	await _frames(2)
	_expect(app.show_prestart(1), "analytics journey must open Level 1 prestart")
	await _frames(2)
	_expect(app.start_level(1), "analytics journey must start Level 1")
	await _frames(3)

	var gameplay = app.current_screen()
	var trace = gameplay.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	_expect(trace != null and bool(trace.accepted) and String(trace.result) == "won", "analytics journey fixture must win Level 1")
	var board_view = gameplay.get_node_or_null("Layout/BoardView")
	if board_view != null and board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished
	await _frames(2)
	_expect(gameplay.result_overlay.visible, "analytics journey must expose win result")
	gameplay.result_action.emit_signal("pressed")
	await _frames(4)

	var events: Array[Dictionary] = app.analytics_events_snapshot()
	_expect(_has_event(events, "session_started"), "analytics must capture session start")
	_expect(_has_screen(events, "boot") and _has_screen(events, "house") and _has_screen(events, "map") and _has_screen(events, "prestart") and _has_screen(events, "gameplay") and _has_screen(events, "win_rewards"), "analytics must capture the canonical Level 1 route funnel")
	_expect(_has_event_with(events, "level_started", "level_id", "ch01_level_001"), "analytics must capture Level 1 start")
	_expect(_has_event_with(events, "level_result", "result", "won"), "analytics must capture Level 1 win")
	_expect(_has_event_with(events, "level_reward", "level_id", "ch01_level_001"), "analytics must capture persisted first-clear reward")
	_expect(_strict_sequence(events), "analytics event sequence must stay monotonic inside a session")
	var serialized := JSON.stringify(events).to_lower()
	for forbidden in ["email", "phone", "address", "device_id", "advertising_id", "user_id"]:
		_expect(not serialized.contains(""%s"" % forbidden), "analytics queue must not contain %s" % forbidden)

	app.queue_free()
	await process_frame
	_cleanup()
	if failures.is_empty():
		print("TEST_PASS: canonical product analytics journey")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _has_event(events: Array[Dictionary], name: String) -> bool:
	for event in events:
		if String(event.get("event", "")) == name:
			return true
	return false

func _has_event_with(events: Array[Dictionary], name: String, key: String, expected) -> bool:
	for event in events:
		if String(event.get("event", "")) != name:
			continue
		var payload: Dictionary = event.get("payload", {})
		if payload.get(key) == expected:
			return true
	return false

func _has_screen(events: Array[Dictionary], route: String) -> bool:
	return _has_event_with(events, "screen_view", "route", route)

func _strict_sequence(events: Array[Dictionary]) -> bool:
	var last := 0
	for event in events:
		var sequence := int(event.get("sequence", 0))
		if sequence <= last:
			return false
		last = sequence
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _cleanup() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH, ANALYTICS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
