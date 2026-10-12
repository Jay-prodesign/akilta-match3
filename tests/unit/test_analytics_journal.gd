extends SceneTree

const Journal = preload("res://src/analytics/event_journal.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var journal = Journal.new()
	var sink_events: Array[Dictionary] = []
	journal.set_sink(func(event: Dictionary): sink_events.append(event))

	_expect(journal.record("session_boot", {"load_status":"default_new"}), "known boot event must record")
	_expect(journal.record("route_changed", {"from":"boot", "to":"house"}), "known route event must record")
	_expect(journal.record("level_started", {"level_number":1, "replay":false}), "known level start must record")
	_expect(not journal.record("unknown_event", {}), "unknown event must be rejected")
	_expect(not journal.record("level_started", {"level_number":1, "replay":false, "email":"player@example.com"}), "unknown/PII property must be rejected")
	_expect(not journal.record("route_changed", {"from":"boot", "to":"house", "payload":{"path":"user://secret"}}), "raw navigation payload must be rejected")
	_expect(not journal.record("level_result", {"level_number":1, "result":"maybe"}), "invalid enum value must be rejected")
	_expect(sink_events.size() == 3, "sink must receive validated events only")

	for index in range(Journal.MAX_EVENTS + 20):
		_expect(journal.record("level_started", {"level_number":(index % 3) + 1, "replay":true}), "bounded fixture event must record")
	var events := journal.snapshot()
	_expect(events.size() == Journal.MAX_EVENTS, "journal must remain bounded")
	_expect(int(events[0].get("sequence", 0)) > 1, "oldest events must be evicted when capacity is exceeded")

	var diag: Dictionary = journal.diagnostics()
	_expect(String(diag.get("transport_mode", "")) == "local_only", "default transport must remain local only")
	_expect(not bool(diag.get("network_transport_connected", true)), "journal must not imply a network provider")
	_expect(not bool(diag.get("stores_device_id", true)), "journal must not store device identifiers")
	_expect(not bool(diag.get("stores_account_id", true)), "journal must not store account identifiers")
	_expect(not bool(diag.get("stores_wall_clock", true)), "journal must not store wall-clock timestamps")
	_expect(not bool(diag.get("stores_free_form_text", true)), "journal must not store free-form user text")
	_expect(int(diag.get("rejected_count", 0)) >= 4, "privacy/schema rejection count must be observable")

	for event in events:
		_expect(event.has("sequence") and event.has("elapsed_ms"), "event envelope must use sequence and monotonic elapsed time")
		_expect(not event.has("device_id") and not event.has("account_id") and not event.has("timestamp"), "event envelope must contain no identity or wall-clock fields")

	if failures.is_empty():
		print("TEST_PASS: privacy-safe local analytics journal")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
