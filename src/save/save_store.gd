class_name Match3SaveStore
extends RefCounted

## Match-3-owned durable save boundary.
## Hardened with the AKILTA first-party transactional pattern evaluated in:
## Sekiph82/Scrubbots @ c2b1c3c7ae0a301cd43d95dd003f0ddf1373eed0
## The schema and progression truth remain Match-3-specific.

const DEFAULT_PATH := "user://player_progress.json"
const SCHEMA_VERSION := 1

var save_path: String
var write_blocked_reason: String = ""

func _init(path: String = DEFAULT_PATH) -> void:
	save_path = path

func save(data: Dictionary) -> bool:
	write_blocked_reason = ""
	if not _validate_candidate(data):
		return false

	var existing = _read_json(save_path)
	if existing is Dictionary and _is_future_schema(existing):
		write_blocked_reason = "future_schema"
		return false

	var temp_path := save_path + ".tmp"
	var backup_path := save_path + ".bak"
	_remove(temp_path)

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

	var temp_candidate = _read_json(temp_path)
	if not temp_candidate is Dictionary or not _validate_candidate(temp_candidate):
		_remove(temp_path)
		return false

	# Rotate backup only from a validated current primary. A corrupt primary must
	# never overwrite the last-known-good backup.
	if FileAccess.file_exists(save_path):
		if existing is Dictionary and _validate_candidate(existing):
			_remove(backup_path)
			if DirAccess.copy_absolute(
				ProjectSettings.globalize_path(save_path),
				ProjectSettings.globalize_path(backup_path)
			) != OK:
				_remove(temp_path)
				return false
		_remove(save_path)

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(save_path)
	)
	if rename_error != OK:
		# Best effort restore from LKG if the primary disappeared.
		if FileAccess.file_exists(backup_path) and not FileAccess.file_exists(save_path):
			DirAccess.copy_absolute(
				ProjectSettings.globalize_path(backup_path),
				ProjectSettings.globalize_path(save_path)
			)
		_remove(temp_path)
		return false
	return true

func load_or_default() -> Dictionary:
	write_blocked_reason = ""
	var primary = _read_json(save_path)
	if primary is Dictionary:
		if _is_future_schema(primary):
			write_blocked_reason = "future_schema"
		elif _validate_candidate(primary):
			return primary

	var backup = _read_json(save_path + ".bak")
	if backup is Dictionary and _validate_candidate(backup):
		return backup
	return {}

func is_write_blocked() -> bool:
	return write_blocked_reason != ""

func _validate_candidate(data: Dictionary) -> bool:
	var version = _exact_int(data.get("schema_version", null))
	if version == null or int(version) != SCHEMA_VERSION:
		return false
	var highest = _exact_int(data.get("highest_level_unlocked", null))
	var stage = _exact_int(data.get("house_stage", null))
	if highest == null or int(highest) < 1 or stage == null or int(stage) < 0:
		return false
	for key in ["completed_levels", "curios", "processed_transactions"]:
		var values = data.get(key, null)
		if not values is Array:
			return false
		for value in values:
			if typeof(value) != TYPE_STRING or String(value).is_empty():
				return false
	return true

func _is_future_schema(data: Dictionary) -> bool:
	var version = _exact_int(data.get("schema_version", null))
	return version != null and int(version) > SCHEMA_VERSION

func _exact_int(value):
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT and is_finite(float(value)) and is_equal_approx(float(value), float(int(value))):
		return int(value)
	return null

func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var raw := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		return null
	return parser.data

func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
