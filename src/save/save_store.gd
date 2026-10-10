class_name Match3SaveStore
extends RefCounted

const DEFAULT_PATH := "user://player_progress.json"

var save_path: String

func _init(path: String = DEFAULT_PATH) -> void:
	save_path = path

func save(data: Dictionary) -> bool:
	var temp_path := save_path + ".tmp"
	var backup_path := save_path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

	var absolute_main := ProjectSettings.globalize_path(save_path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)

	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(absolute_backup)
		var copy_error: int = int(DirAccess.copy_absolute(absolute_main, absolute_backup))
		if copy_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return false
		DirAccess.remove_absolute(absolute_main)

	var rename_error: int = int(DirAccess.rename_absolute(absolute_temp, absolute_main))
	if rename_error != OK:
		if FileAccess.file_exists(backup_path) and not FileAccess.file_exists(save_path):
			DirAccess.copy_absolute(absolute_backup, absolute_main)
		return false
	return true

func load_or_default() -> Dictionary:
	var primary: Dictionary = _read_valid(save_path)
	if not primary.is_empty():
		return primary
	var backup: Dictionary = _read_valid(save_path + ".bak")
	if not backup.is_empty():
		return backup
	return {}

func _read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed
	return {}
