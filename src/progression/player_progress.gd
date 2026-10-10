class_name Match3PlayerProgress
extends RefCounted

const SCHEMA_VERSION := 1

var schema_version: int = SCHEMA_VERSION
var highest_level_unlocked: int = 1
var house_stage: int = 0
var completed_levels: Array[String] = []
var curios: Array[String] = []
var processed_transactions: Array[String] = []

static func from_dict(data: Dictionary):
	var progress = new()
	progress.schema_version = int(data.get("schema_version", SCHEMA_VERSION))
	progress.highest_level_unlocked = max(1, int(data.get("highest_level_unlocked", 1)))
	progress.house_stage = max(0, int(data.get("house_stage", 0)))
	for level_id in data.get("completed_levels", []):
		_append_unique(progress.completed_levels, String(level_id))
	for curio_id in data.get("curios", []):
		_append_unique(progress.curios, String(curio_id))
	for transaction_id in data.get("processed_transactions", []):
		_append_unique(progress.processed_transactions, String(transaction_id))
	return progress

func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"highest_level_unlocked": highest_level_unlocked,
		"house_stage": house_stage,
		"completed_levels": completed_levels.duplicate(),
		"curios": curios.duplicate(),
		"processed_transactions": processed_transactions.duplicate()
	}

func apply_level_win(transaction_id: String, level_id: String, curio_id: String = "") -> bool:
	if transaction_id == "" or processed_transactions.has(transaction_id):
		return false
	processed_transactions.append(transaction_id)
	_append_unique(completed_levels, level_id)
	if curio_id != "":
		_append_unique(curios, curio_id)
	house_stage = max(house_stage, 1)
	highest_level_unlocked = max(highest_level_unlocked, _level_number(level_id) + 1)
	return true

static func _append_unique(values: Array[String], value: String) -> void:
	if value != "" and not values.has(value):
		values.append(value)

static func _level_number(level_id: String) -> int:
	var parts: PackedStringArray = level_id.split("_")
	if parts.is_empty():
		return 1
	return max(1, int(parts[parts.size() - 1]))
