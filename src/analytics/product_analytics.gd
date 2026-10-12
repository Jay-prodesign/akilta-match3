class_name Match3ProductAnalytics
extends RefCounted

const DEFAULT_PATH := "user://product_analytics_queue.json"
const SCHEMA_VERSION := 1
const MAX_QUEUE_SIZE := 500
const MAX_STRING_LENGTH := 96

const ALLOWED_EVENTS := {
	"session_started": true,
	"screen_view": true,
	"level_started": true,
	"level_result": true,
	"level_reward": true,
	"level_replay_complete": true,
	"recovery_used": true,
	"settings_opened": true,
	"settings_changed": true,
}

const SENSITIVE_KEYS := {
	"email": true,
	"name": true,
	"full_name": true,
	"phone": true,
	"address": true,
	"user_id": true,
	"device_id": true,
	"advertising_id": true,
	"idfa": true,
	"gaid": true,
	"ip": true,
	"ip_address": true,
}

var queue_path: String
var _session_id: String = ""
var _sequence: int = 0
var _events: Array[Dictionary] = []
var _transport_sink: Callable = Callable()

func _init(path: String = DEFAULT_PATH) -> void:
	queue_path = path
	_load_existing()

func start_session(context: Dictionary = {}, session_id_override: String = "") -> bool:
	if _contains_sensitive_key(context):
		return false
	_session_id = session_id_override if session_id_override != "" else "s-%d-%d" % [int(Time.get_unix_time_from_system()), int(Time.get_ticks_usec())]
	_sequence = 0
	return track("session_started", context)

func track(event_name: String, payload: Dictionary = {}) -> bool:
	if not ALLOWED_EVENTS.has(event_name) or _session_id == "" or _contains_sensitive_key(payload):
		return false
	_sequence += 1
	var event := {
		"schema_version": SCHEMA_VERSION,
		"event": event_name,
		"session_id": _session_id,
		"sequence": _sequence,
		"unix_time": int(Time.get_unix_time_from_system()),
		"payload": _sanitize_dictionary(payload),
	}
	_events.append(event)
	while _events.size() > MAX_QUEUE_SIZE:
		_events.pop_front()
	return _persist()

func set_transport_sink(sink: Callable) -> void:
	_transport_sink = sink

func flush_to_transport() -> bool:
	if not _transport_sink.is_valid() or _events.is_empty():
		return false
	var snapshot := events_snapshot()
	if not bool(_transport_sink.call(snapshot)):
		return false
	_events.clear()
	return _persist()

func events_snapshot() -> Array[Dictionary]:
	return _events.duplicate(true)

func event_count(event_name: String = "") -> int:
	if event_name == "":
		return _events.size()
	var count := 0
	for event in _events:
		if String(event.get("event", "")) == event_name:
			count += 1
	return count

func status_contract() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"queue_count": _events.size(),
		"local_queue": true,
		"transport_connected": _transport_sink.is_valid(),
		"persistent_user_id": false,
		"advertising_id": false,
		"pii_allowed": false,
	}

func _load_existing() -> void:
	_events.clear()
	if not FileAccess.file_exists(queue_path):
		return
	var file := FileAccess.open(queue_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return
	for raw in parsed:
		if not raw is Dictionary:
			continue
		var event: Dictionary = raw
		if int(event.get("schema_version", 0)) != SCHEMA_VERSION:
			continue
		if not ALLOWED_EVENTS.has(String(event.get("event", ""))):
			continue
		var payload = event.get("payload", {})
		if not payload is Dictionary or _contains_sensitive_key(payload):
			continue
		_events.append(event.duplicate(true))
	while _events.size() > MAX_QUEUE_SIZE:
		_events.pop_front()

func _persist() -> bool:
	var file := FileAccess.open(queue_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_events))
	file.flush()
	file.close()
	return true

func _contains_sensitive_key(value) -> bool:
	if value is Dictionary:
		for raw_key in value.keys():
			var key := String(raw_key).to_lower()
			if SENSITIVE_KEYS.has(key):
				return true
			if _contains_sensitive_key(value[raw_key]):
				return true
	elif value is Array:
		for item in value:
			if _contains_sensitive_key(item):
				return true
	return false

func _sanitize_dictionary(value: Dictionary) -> Dictionary:
	var out := {}
	for raw_key in value.keys():
		var key := String(raw_key)
		out[key] = _sanitize_value(value[raw_key])
	return out

func _sanitize_value(value):
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT:
			return value
		TYPE_STRING, TYPE_STRING_NAME:
			var text := String(value)
			return text.substr(0, mini(text.length(), MAX_STRING_LENGTH))
		TYPE_DICTIONARY:
			return _sanitize_dictionary(value)
		TYPE_ARRAY:
			var out: Array = []
			for item in value:
				out.append(_sanitize_value(item))
			return out
		_:
			return String(value).substr(0, MAX_STRING_LENGTH)
