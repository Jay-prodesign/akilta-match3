class_name Match3LiveOpsConfig
extends RefCounted

const DEFAULT_PATH := "res://content/liveops/defaults.json"
const SCHEMA_VERSION := 1

const FLAG_DEFAULTS := {
	"daily_house_ritual_enabled": true,
	"weekly_rituals_surface_enabled": true,
	"seasonal_events_enabled": false,
	"commerce_enabled": false,
	"keeper_guidance_enabled": true,
	"fail_plus3_recovery_enabled": true,
	"analytics_transport_enabled": false,
}

var defaults_path: String
var _bundled_flags: Dictionary = FLAG_DEFAULTS.duplicate(true)
var _flags: Dictionary = FLAG_DEFAULTS.duplicate(true)
var _revision: String = "builtin-fallback"
var _source: String = "builtin_fallback"
var _remote_connected := false
var _provider_id: String = ""

func _init(path: String = DEFAULT_PATH) -> void:
	defaults_path = path
	_load_bundled()

func flag(name: String) -> bool:
	if not FLAG_DEFAULTS.has(name):
		return false
	return bool(_flags.get(name, FLAG_DEFAULTS[name]))

func flags_snapshot() -> Dictionary:
	return _flags.duplicate(true)

func apply_remote_snapshot(snapshot: Dictionary, provider_id: String) -> bool:
	if provider_id.strip_edges() == "":
		return false
	var parsed := _validate_snapshot(snapshot)
	if parsed.is_empty():
		return false
	_flags = (parsed["flags"] as Dictionary).duplicate(true)
	_revision = String(parsed["revision"])
	_source = "remote_snapshot"
	_remote_connected = true
	_provider_id = provider_id.substr(0, mini(provider_id.length(), 64))
	return true

func disconnect_remote() -> void:
	_flags = _bundled_flags.duplicate(true)
	_revision = _bundled_revision()
	_source = "bundled"
	_remote_connected = false
	_provider_id = ""

func status_contract() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"source": _source,
		"revision": _revision,
		"remote_connected": _remote_connected,
		"provider_id": _provider_id,
		"network_client_built_in": false,
		"flags": flags_snapshot(),
	}

func _load_bundled() -> void:
	var file := FileAccess.open(defaults_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var validated := _validate_snapshot(parsed)
	if validated.is_empty():
		return
	_bundled_flags = (validated["flags"] as Dictionary).duplicate(true)
	_flags = _bundled_flags.duplicate(true)
	_revision = String(validated["revision"])
	_source = "bundled"

func _bundled_revision() -> String:
	if _source == "bundled":
		return _revision
	var file := FileAccess.open(defaults_path, FileAccess.READ)
	if file == null:
		return "builtin-fallback"
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return String((parsed as Dictionary).get("revision", "builtin-fallback"))
	return "builtin-fallback"

func _validate_snapshot(snapshot: Dictionary) -> Dictionary:
	if int(snapshot.get("schema_version", 0)) != SCHEMA_VERSION:
		return {}
	var revision := String(snapshot.get("revision", "")).strip_edges()
	if revision == "":
		return {}
	var incoming = snapshot.get("flags", null)
	if not incoming is Dictionary:
		return {}
	var incoming_flags: Dictionary = incoming
	if incoming_flags.size() != FLAG_DEFAULTS.size():
		return {}
	var validated := {}
	for flag_name in FLAG_DEFAULTS.keys():
		if not incoming_flags.has(flag_name) or typeof(incoming_flags[flag_name]) != TYPE_BOOL:
			return {}
		validated[flag_name] = bool(incoming_flags[flag_name])
	for flag_name in incoming_flags.keys():
		if not FLAG_DEFAULTS.has(String(flag_name)):
			return {}
	return {
		"revision": revision,
		"flags": validated,
	}
