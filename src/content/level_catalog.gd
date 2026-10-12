class_name Match3LevelCatalog
extends RefCounted

const DEFAULT_PATH := "res://content/levels/ch01/catalog.json"
const SUPPORTED_SCHEMA_VERSION := 1

var chapter_id: String = ""
var display_name: String = ""
var _entries: Array[Dictionary] = []
var _by_number: Dictionary = {}
var _by_id: Dictionary = {}

static func load_default():
	var catalog = Match3LevelCatalog.new()
	return catalog if catalog.load_path(DEFAULT_PATH) else null

func load_path(path: String) -> bool:
	_entries.clear()
	_by_number.clear()
	_by_id.clear()
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("schema_version", -1)) != SUPPORTED_SCHEMA_VERSION:
		return false
	chapter_id = String(parsed.get("chapter_id", ""))
	display_name = String(parsed.get("display_name", ""))
	var raw_entries = parsed.get("entries", [])
	if not raw_entries is Array:
		return false
	for raw_entry in raw_entries:
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry.duplicate(true)
			_entries.append(entry)
			_by_number[int(entry.get("number", 0))] = entry
			_by_id[String(entry.get("id", ""))] = entry
	_entries.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("number", 0)) < int(b.get("number", 0)))
	return not _entries.is_empty()

func count() -> int:
	return _entries.size()

func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _entries:
		result.append(entry.duplicate(true))
	return result

func entry(level_number: int) -> Dictionary:
	var value: Variant = _by_number.get(level_number, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}

func level_path(level_number: int) -> String:
	return String((_by_number.get(level_number, {}) as Dictionary).get("path", ""))

func level_id(level_number: int) -> String:
	return String((_by_number.get(level_number, {}) as Dictionary).get("id", ""))

func validate() -> Array[String]:
	var issues: Array[String] = []
	if chapter_id == "":
		issues.append("catalog: chapter_id is required")
	if display_name == "":
		issues.append("catalog: display_name is required")
	if _entries.is_empty():
		issues.append("catalog: at least one level is required")
		return issues
	var seen_ids: Dictionary = {}
	for index in range(_entries.size()):
		var entry: Dictionary = _entries[index]
		var expected_number := index + 1
		var number := int(entry.get("number", 0))
		var level_id_value := String(entry.get("id", ""))
		var path := String(entry.get("path", ""))
		if number != expected_number:
			issues.append("catalog: level numbers must be contiguous from 1; expected %d" % expected_number)
		if level_id_value == "" or seen_ids.has(level_id_value):
			issues.append("catalog: level id must be unique and non-empty at %d" % number)
		seen_ids[level_id_value] = true
		if path == "" or not FileAccess.file_exists(path):
			issues.append("%s: level path missing" % level_id_value)
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		var level_data = JSON.parse_string(file.get_as_text()) if file != null else null
		if file != null:
			file.close()
		if not level_data is Dictionary:
			issues.append("%s: level file must parse" % level_id_value)
			continue
		if String(level_data.get("id", "")) != level_id_value:
			issues.append("%s: catalog id does not match level file" % level_id_value)
		if String(level_data.get("reward_curio", "")) != String(entry.get("reward_curio", "")):
			issues.append("%s: catalog reward_curio mismatch" % level_id_value)
		if int(level_data.get("house_stage_reward", -1)) != int(entry.get("house_stage_reward", -2)):
			issues.append("%s: catalog house_stage_reward mismatch" % level_id_value)
		var route_art := String(entry.get("route_art", ""))
		if route_art == "" or not FileAccess.file_exists(route_art):
			issues.append("%s: route_art missing" % level_id_value)
		elif not (route_art.ends_with(".webp") or route_art.ends_with(".png")):
			issues.append("%s: route_art must be production raster" % level_id_value)
		for required in ["title", "route_caption", "route_open", "route_completed", "tooltip"]:
			if String(entry.get(required, "")).strip_edges() == "":
				issues.append("%s: %s is required" % [level_id_value, required])
	return issues
