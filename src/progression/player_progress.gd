class_name Match3PlayerProgress
extends RefCounted

const SCHEMA_VERSION := 2
const FIRST_CLEAR_COIN_REWARD := 120
const FIRST_CLEAR_GEM_REWARD := 1
const PURCHASES_CONNECTED := false
const SPENDING_CONNECTED := false
const LIFE_ECONOMY_CONNECTED := false

var schema_version: int = SCHEMA_VERSION
var highest_level_unlocked: int = 1
var house_stage: int = 0
var lives: int = 5
var coins: int = 0
var gems: int = 0
var completed_levels: Array[String] = []
var curios: Array[String] = []
var processed_transactions: Array[String] = []

static func from_dict(data: Dictionary):
	var progress = new()
	var source_schema := int(data.get("schema_version", 1))
	progress.schema_version = SCHEMA_VERSION
	progress.highest_level_unlocked = max(1, int(data.get("highest_level_unlocked", 1)))
	progress.house_stage = max(0, int(data.get("house_stage", 0)))
	progress.lives = clampi(int(data.get("lives", 5)), 0, 5)
	for level_id in data.get("completed_levels", []):
		_append_unique(progress.completed_levels, String(level_id))
	for curio_id in data.get("curios", []):
		_append_unique(progress.curios, String(curio_id))
	for transaction_id in data.get("processed_transactions", []):
		_append_unique(progress.processed_transactions, String(transaction_id))

	if source_schema < 2:
		progress.coins = progress.completed_levels.size() * FIRST_CLEAR_COIN_REWARD
		progress.gems = progress.completed_levels.size() * FIRST_CLEAR_GEM_REWARD
	else:
		progress.coins = max(0, int(data.get("coins", 0)))
		progress.gems = max(0, int(data.get("gems", 0)))
	return progress

func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"highest_level_unlocked": highest_level_unlocked,
		"house_stage": house_stage,
		"lives": lives,
		"coins": coins,
		"gems": gems,
		"completed_levels": completed_levels.duplicate(),
		"curios": curios.duplicate(),
		"processed_transactions": processed_transactions.duplicate()
	}

func economy_contract() -> Dictionary:
	return {
		"currency_earning": "first_clear_only",
		"coin_reward_per_first_clear": FIRST_CLEAR_COIN_REWARD,
		"gem_reward_per_first_clear": FIRST_CLEAR_GEM_REWARD,
		"purchases_connected": PURCHASES_CONNECTED,
		"spending_connected": SPENDING_CONNECTED,
		"life_economy_connected": LIFE_ECONOMY_CONNECTED,
	}

func apply_level_win(transaction_id: String, level_id: String, curio_id: String = "", house_stage_reward: int = -1) -> bool:
	if transaction_id == "" or level_id == "" or processed_transactions.has(transaction_id) or completed_levels.has(level_id):
		return false
	processed_transactions.append(transaction_id)
	_append_unique(completed_levels, level_id)
	if curio_id != "":
		_append_unique(curios, curio_id)
	var level_number: int = _level_number(level_id)
	var stage_reward: int = house_stage_reward if house_stage_reward >= 0 else level_number
	house_stage = max(house_stage, stage_reward)
	highest_level_unlocked = max(highest_level_unlocked, level_number + 1)
	coins += FIRST_CLEAR_COIN_REWARD
	gems += FIRST_CLEAR_GEM_REWARD
	return true

static func _append_unique(values: Array[String], value: String) -> void:
	if value != "" and not values.has(value):
		values.append(value)

static func _level_number(level_id: String) -> int:
	var parts: PackedStringArray = level_id.split("_")
	if parts.is_empty():
		return 1
	return max(1, int(parts[parts.size() - 1]))
