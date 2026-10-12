extends SceneTree

const AnalyticsScript = preload("res://src/analytics/product_analytics.gd")
const TEST_PATH := "user://product_analytics_unit_test.json"

var failures: Array[String] = []
var delivered: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	var analytics = AnalyticsScript.new(TEST_PATH)
	var status: Dictionary = analytics.status_contract()
	_expect(bool(status.get("local_queue", false)), "analytics must use a durable local queue")
	_expect(not bool(status.get("transport_connected", true)), "analytics transport must start disconnected")
	_expect(not bool(status.get("persistent_user_id", true)) and not bool(status.get("advertising_id", true)), "analytics must not create persistent or advertising identifiers")
	_expect(not bool(status.get("pii_allowed", true)), "analytics contract must prohibit PII")

	_expect(analytics.start_session({"environment": "test", "returning": false}, "test-session"), "session start must persist")
	_expect(analytics.track("screen_view", {"route": "house", "from": "boot", "via": "test"}), "allowed screen event must persist")
	var before_sensitive := analytics.event_count()
	_expect(not analytics.track("screen_view", {"route": "house", "email": "forbidden@example.invalid"}), "sensitive payload keys must be rejected")
	_expect(analytics.event_count() == before_sensitive, "rejected sensitive event must not enter the queue")
	_expect(not analytics.track("unknown_event", {}), "unknown analytics events must be rejected")

	var reloaded = AnalyticsScript.new(TEST_PATH)
	_expect(reloaded.event_count() == 2, "analytics queue must survive a new local instance")
	reloaded.set_transport_sink(Callable(self, "_sink"))
	_expect(bool(reloaded.status_contract().get("transport_connected", false)), "injected transport must be explicitly connected")
	_expect(reloaded.flush_to_transport(), "connected transport must flush queued events")
	_expect(delivered.size() == 2, "transport must receive the durable queue exactly once")
	_expect(reloaded.event_count() == 0, "successful transport flush must clear the local queue")
	var after_flush = AnalyticsScript.new(TEST_PATH)
	_expect(after_flush.event_count() == 0, "cleared queue state must persist")

	_cleanup()
	if failures.is_empty():
		print("TEST_PASS: privacy-safe durable product analytics queue")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _sink(batch: Array) -> bool:
	delivered = batch.duplicate(true)
	return true

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
