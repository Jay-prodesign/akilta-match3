class_name Match3EventJournal
extends RefCounted

## Privacy-safe first-party observability boundary.
## No network transport, device/account identifier, wall-clock timestamp, raw
## navigation payload, free-form user text, or file path is stored by default.

const TRANSPORT_MODE := "local_only"
const MAX_EVENTS := 256

const SCHEMAS := {
	"session_boot": {"load_status": TYPE_STRING},
	"route_changed": {"from": TYPE_STRING, "to": TYPE_STRING},
	"level_started": {"level_number": TYPE_INT, "replay": TYPE_BOOL},
	"level_result": {"level_number": TYPE_INT, "result": TYPE_STRING},
	"reward_committed": {"level_number": TYPE_INT, "curio_id": TYPE_STRING, "restoration": TYPE_BOOL},
	"daily_practice_opened": {"level_number": TYPE_INT},
	"save_recovery": {"status": TYPE_STRING},
}

const ROUTES := [
	"boot", "house", "collection", "map", "prestart", "gameplay",
	"win_rewards", "restoration", "chapters", "missions", "events",
	"shop", "profile_settings"
]
const LOAD_STATUSES := [
	"primary", "backup_recovered", "default_after_invalid_primary",
	"future_schema", "default_new", "not_loaded"
]
const RESULTS := ["won", "failed"]
const CURIOS := ["moon_cameo", "moth_reliquary", "thorned_locket"]

var _events: Array[Dictionary] = []
var _sequence: int = 0
var _started_ms: int = 0
var _sink: Callable
var _rejected: int = 0

func _init() -> void:
	_started_ms = Time.get_ticks_msec()

func record(event_name: String, properties: Dictionary = {}) -> bool:
	if not SCHEMAS.has(event_name) or not _validate_properties(event_name, properties):
		_rejected += 1
		return false
	_sequence += 1
	var event := {
		"sequence": _sequence,
		"event": event_name,
		"elapsed_ms": maxi(0, Time.get_ticks_msec() - _started_ms),
		"properties": properties.duplicate(true),
	}
	_events.append(event)
	while _events.size() > MAX_EVENTS:
		_events.pop_front()
	if _sink.is_valid():
		_sink.call(event.duplicate(true))
	return true

func set_sink(sink: Callable) -> void:
	# A provider may be attached later behind the same validated schema.
	# The shipping app does not attach one while transport is LOCAL ONLY.
	_sink = sink

func snapshot() -> Array[Dictionary]:
	return _events.duplicate(true)

func count(event_name: String) -> int:
	var total := 0
	for event in _events:
		if String(event.get("event", "")) == event_name:
			total += 1
	return total

func last(event_name: String) -> Dictionary:
	for index in range(_events.size() - 1, -1, -1):
		var event: Dictionary = _events[index]
		if String(event.get("event", "")) == event_name:
			return event.duplicate(true)
	return {}

func diagnostics() -> Dictionary:
	return {
		"transport_mode": TRANSPORT_MODE,
		"network_transport_connected": false,
		"event_count": _events.size(),
		"rejected_count": _rejected,
		"capacity": MAX_EVENTS,
		"stores_device_id": false,
		"stores_account_id": false,
		"stores_wall_clock": false,
		"stores_free_form_text": false,
	}

func _validate_properties(event_name: String, properties: Dictionary) -> bool:
	var schema: Dictionary = SCHEMAS[event_name]
	for key in properties.keys():
		if not schema.has(key):
			return false
	for key in schema.keys():
		if not properties.has(key):
			return false
		if typeof(properties[key]) != int(schema[key]):
			return false
	return _validate_values(event_name, properties)

func _validate_values(event_name: String, properties: Dictionary) -> bool:
	match event_name:
		"session_boot":
			return LOAD_STATUSES.has(String(properties["load_status"]))
		"save_recovery":
			return String(properties["status"]) in ["backup_recovered", "default_after_invalid_primary", "future_schema"]
		"route_changed":
			return ROUTES.has(String(properties["from"])) and ROUTES.has(String(properties["to"]))
		"level_started", "daily_practice_opened":
			return int(properties["level_number"]) >= 1 and int(properties["level_number"]) <= 9999
		"level_result":
			return int(properties["level_number"]) >= 1 and RESULTS.has(String(properties["result"]))
		"reward_committed":
			return int(properties["level_number"]) >= 1 and CURIOS.has(String(properties["curio_id"]))
	return true
