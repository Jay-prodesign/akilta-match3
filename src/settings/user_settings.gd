class_name Match3UserSettings
extends RefCounted

## AKILTA first-party adaptation.
## Source: Sekiph82/Beach-Cocktails-Merge scripts/campaign/user_settings.gd
## Pinned source head: dd21439ac0b1fe982dba38705751b3bcdb3fc1e6

signal changed(key: String, value: Variant)
signal presentation_changed(state: Dictionary)

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://match3_user_settings.json"
const DEFAULTS := {
	"master_volume": 1.0,
	"master_muted": false,
	"music_volume": 1.0,
	"music_muted": false,
	"sfx_volume": 1.0,
	"sfx_muted": false,
	"haptics_enabled": true,
	"reduced_motion": false,
	"high_contrast": false,
}

var storage_path := DEFAULT_PATH
var _values: Dictionary = DEFAULTS.duplicate(true)

func load_settings(path: String = storage_path) -> Dictionary:
	storage_path = path
	_values = DEFAULTS.duplicate(true)
	if not FileAccess.file_exists(storage_path):
		apply_audio()
		return get_state()
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		apply_audio()
		return get_state()
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and int(parsed.get("schema_version", -1)) == SCHEMA_VERSION:
		for key in DEFAULTS:
			if parsed.has(key):
				_values[key] = _sanitize_value(key, parsed[key])
	apply_audio()
	return get_state()

func get_state() -> Dictionary:
	var state := {"schema_version": SCHEMA_VERSION}
	state.merge(_values.duplicate(true))
	return state

func get_value(key: String, fallback: Variant = null) -> Variant:
	return _values.get(key, fallback)

func set_value(key: String, value: Variant, persist := true) -> bool:
	if not DEFAULTS.has(key):
		return false
	var sanitized = _sanitize_value(key, value)
	if _values.get(key) == sanitized:
		return true
	_values[key] = sanitized
	if key.ends_with("_volume") or key.ends_with("_muted"):
		apply_audio()
	if key in ["haptics_enabled", "reduced_motion", "high_contrast"]:
		presentation_changed.emit(get_presentation_state())
	changed.emit(key, sanitized)
	return save_settings() if persist else true

func save_settings(path: String = storage_path) -> bool:
	storage_path = path
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(get_state(), "\t"))
	file.close()
	return true

func get_presentation_state() -> Dictionary:
	return {
		"reduced_motion": bool(_values["reduced_motion"]),
		"high_contrast": bool(_values["high_contrast"]),
		"haptics_enabled": bool(_values["haptics_enabled"]),
	}

func can_emit_haptics() -> bool:
	return bool(_values["haptics_enabled"])

func apply_audio() -> Dictionary:
	var report := {"Master": false, "Music": false, "SFX": false}
	report["Master"] = _apply_bus("Master", float(_values["master_volume"]), bool(_values["master_muted"]))
	report["Music"] = _apply_bus("Music", float(_values["music_volume"]), bool(_values["music_muted"]))
	report["SFX"] = _apply_bus("SFX", float(_values["sfx_volume"]), bool(_values["sfx_muted"]))
	return report

func _apply_bus(bus_name: String, volume: float, muted: bool) -> bool:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return false
	AudioServer.set_bus_mute(bus_index, muted)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(clampf(volume, 0.0, 1.0), 0.0001)))
	return true

func _sanitize_value(key: String, value: Variant) -> Variant:
	if key.ends_with("_volume"):
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			return float(DEFAULTS[key])
		return clampf(float(value), 0.0, 1.0)
	if typeof(DEFAULTS[key]) == TYPE_BOOL:
		return bool(value)
	return value
