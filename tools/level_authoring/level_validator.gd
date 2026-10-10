class_name Match3LevelValidator
extends RefCounted

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MatchDetector = preload("res://src/match3/domain/match_detector.gd")
const MoveFinder = preload("res://src/match3/domain/move_finder.gd")

const SUPPORTED_SCHEMA_VERSION := 1
const SUPPORTED_OBJECTIVES := ["collect_family", "clear_blockers"]
const SUPPORTED_SPECIALS := ["line_h", "line_v", "area", "smart", "global"]
const SUPPORTED_STATUSES := ["draft", "validated", "playtest", "approved", "staging", "production", "retired"]

static func load_level(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	return parser.data if parser.data is Dictionary else {}

static func validate(level: Dictionary) -> Array[String]:
	var issues: Array[String] = []
	var level_id: String = String(level.get("id", "<missing-id>"))

	if int(level.get("schema_version", -1)) != SUPPORTED_SCHEMA_VERSION:
		issues.append("%s: unsupported schema_version" % level_id)
	var status: String = String(level.get("content_status", ""))
	if not SUPPORTED_STATUSES.has(status):
		issues.append("%s: invalid content_status" % level_id)

	var width: int = int(level.get("width", 0))
	var height: int = int(level.get("height", 0))
	if width < 3 or width > 12 or height < 3 or height > 12:
		issues.append("%s: board dimensions must be within 3..12" % level_id)
	if int(level.get("moves", 0)) <= 0:
		issues.append("%s: moves must be positive" % level_id)

	var families: Array[String] = []
	for raw_family in level.get("families", []):
		var family: String = String(raw_family)
		if family != "" and not families.has(family):
			families.append(family)
	if families.size() < 3:
		issues.append("%s: at least three unique families are required" % level_id)

	var rows = level.get("initial_rows", [])
	if not rows is Array or rows.size() != height:
		issues.append("%s: initial_rows height mismatch" % level_id)
	else:
		for y in range(rows.size()):
			var row = rows[y]
			if not row is Array or row.size() != width:
				issues.append("%s: initial_rows width mismatch at row %d" % [level_id, y])
				continue
			for raw_cell in row:
				if not families.has(String(raw_cell)):
					issues.append("%s: initial_rows contains undeclared family" % level_id)

	var objective: String = String(level.get("objective", ""))
	if not SUPPORTED_OBJECTIVES.has(objective):
		issues.append("%s: unsupported objective" % level_id)
	elif objective == "collect_family":
		if not families.has(String(level.get("objective_family", ""))):
			issues.append("%s: collect_family objective_family must be declared" % level_id)
		if int(level.get("objective_target", 0)) <= 0:
			issues.append("%s: collect_family objective_target must be positive" % level_id)
	elif objective == "clear_blockers" and level.get("blockers", []).is_empty():
		issues.append("%s: clear_blockers requires blockers" % level_id)

	_validate_positions(level, width, height, issues)
	_validate_teaching_moves(level, width, height, issues)

	if issues.is_empty() and width > 0 and height > 0 and not families.is_empty():
		var seed_value: int = int(level.get("validation_seed", 1))
		var board = BoardState.from_level(level, seed_value)
		if not MatchDetector.find_match_cells(board).is_empty():
			issues.append("%s: authored board begins with an automatic match" % level_id)
		if not MoveFinder.has_legal_move(board):
			issues.append("%s: authored board has no legal opening move" % level_id)
	return issues

static func _validate_positions(level: Dictionary, width: int, height: int, issues: Array[String]) -> void:
	var level_id: String = String(level.get("id", "<missing-id>"))
	var occupied_specials: Dictionary = {}
	for raw_special in level.get("specials", []):
		if not raw_special is Dictionary:
			issues.append("%s: special entry must be an object" % level_id)
			continue
		var pos := Vector2i(int(raw_special.get("x", -1)), int(raw_special.get("y", -1)))
		if not _in_bounds(pos, width, height):
			issues.append("%s: special position out of bounds" % level_id)
		if not SUPPORTED_SPECIALS.has(String(raw_special.get("kind", ""))):
			issues.append("%s: unsupported special kind" % level_id)
		if occupied_specials.has(pos):
			issues.append("%s: duplicate special position" % level_id)
		occupied_specials[pos] = true

	var occupied_blockers: Dictionary = {}
	for raw_blocker in level.get("blockers", []):
		if not raw_blocker is Dictionary:
			issues.append("%s: blocker entry must be an object" % level_id)
			continue
		var pos := Vector2i(int(raw_blocker.get("x", -1)), int(raw_blocker.get("y", -1)))
		if not _in_bounds(pos, width, height):
			issues.append("%s: blocker position out of bounds" % level_id)
		if String(raw_blocker.get("type", "")) != "wax_seal":
			issues.append("%s: unsupported blocker type" % level_id)
		if int(raw_blocker.get("hp", 0)) <= 0:
			issues.append("%s: blocker hp must be positive" % level_id)
		if occupied_blockers.has(pos):
			issues.append("%s: duplicate blocker position" % level_id)
		occupied_blockers[pos] = true

func _validate_teaching_moves(level: Dictionary, width: int, height: int, issues: Array[String]) -> void:
	var level_id: String = String(level.get("id", "<missing-id>"))
	var moves = level.get("teaching_moves", [])
	if not moves is Array or moves.is_empty():
		issues.append("%s: opening content requires teaching_moves" % level_id)
		return
	for raw_move in moves:
		if not raw_move is Array or raw_move.size() != 4:
			issues.append("%s: teaching move must be [from_x,from_y,to_x,to_y]" % level_id)
			continue
		var from := Vector2i(int(raw_move[0]), int(raw_move[1]))
		var to := Vector2i(int(raw_move[2]), int(raw_move[3]))
		if not _in_bounds(from, width, height) or not _in_bounds(to, width, height):
			issues.append("%s: teaching move out of bounds" % level_id)
		elif (from - to).abs().x + (from - to).abs().y != 1:
			issues.append("%s: teaching move must be adjacent" % level_id)

static func _in_bounds(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height
