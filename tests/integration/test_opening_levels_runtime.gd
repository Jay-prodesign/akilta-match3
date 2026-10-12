extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")
const LEVELS := [
	{"number": 2, "path": "res://content/levels/ch01/level_002.json", "reward": "moth_reliquary", "relic_label": "RELIC · MOTH RELIQUARY"},
	{"number": 3, "path": "res://content/levels/ch01/level_003.json", "reward": "thorned_locket", "relic_label": "RELIC · THORNED LOCKET"}
]
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for entry in LEVELS:
		await _run_level(entry)
	if failures.is_empty():
		print("TEST_PASS: opening Levels 2 and 3 runtime gameplay and reward contracts")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _run_level(entry: Dictionary) -> void:
	var number := int(entry["number"])
	var path := String(entry["path"])
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Level %d content file must open" % number)
		return
	var level_data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not level_data is Dictionary:
		failures.append("Level %d content must parse" % number)
		return
	var retry_hint := String(level_data.get("retry_hint", ""))
	if retry_hint.length() < 24:
		failures.append("Level %d must define meaningful authored retry assistance" % number)
	if number == 2 and not retry_hint.contains("wax seal"):
		failures.append("Level 2 retry assistance must teach Wax Seal recovery")
	if number == 3 and not retry_hint.contains("Moon Beam"):
		failures.append("Level 3 retry assistance must teach Moon Beam recovery")

	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	if not screen.load_level_path(path, 1000 + number):
		failures.append("Level %d must load in the actual gameplay screen" % number)
		screen.queue_free()
		await process_frame
		return
	var level_badge: Label = screen.get_node_or_null("ResourceBar/Resources/LevelBadge")
	if level_badge == null or level_badge.text != "LEVEL %d" % number:
		failures.append("Level %d top resource bar must identify the active level" % number)

	var moves: Array = level_data.get("teaching_moves", [])
	if number == 3:
		if String(level_data.get("objective", "")) != "clear_blockers":
			failures.append("Level 3 puzzle-depth objective must be clear_blockers")
		if (level_data.get("holes", []) as Array).size() < 3:
			failures.append("Level 3 must use a shaped board with at least three holes")
		var initial_seal: Dictionary = screen.board_state.get_blocker(Vector2i(4, 4))
		if int(initial_seal.get("hp", 0)) != 2:
			failures.append("Level 3 deep Wax Seal must begin at 2 HP")
	for move_index in range(moves.size()):
		var raw_move = moves[move_index]
		if not raw_move is Array or raw_move.size() != 4:
			failures.append("Level %d teaching move must be four coordinates" % number)
			break
		var trace = screen.attempt_swap(
			Vector2i(int(raw_move[0]), int(raw_move[1])),
			Vector2i(int(raw_move[2]), int(raw_move[3]))
		)
		if trace == null or not bool(trace.accepted):
			failures.append("Level %d authored teaching move must be accepted by runtime" % number)
			break
		if number == 3 and move_index == 0:
			if not trace.event_types().has("special_created"):
				failures.append("Level 3 first move must form the Moon Beam")
			if not trace.event_types().has("blocker_damaged") or trace.event_types().has("blocker_cleared"):
				failures.append("Level 3 first move must crack but not clear the deep Wax Seal")
			if int(screen.board_state.get_blocker(Vector2i(4, 4)).get("hp", 0)) != 1:
				failures.append("Level 3 first move must reduce deep Wax Seal from 2 HP to 1 HP")
			if String(trace.result) != "playing":
				failures.append("Level 3 first move must leave the puzzle unresolved")
		if number == 3 and move_index == 1:
			if not trace.event_types().has("special_triggered"):
				failures.append("Level 3 second move must trigger the Moon Beam")
			if not trace.event_types().has("blocker_cleared"):
				failures.append("Level 3 second move must shatter the deep Wax Seal")
			if String(trace.result) != "won":
				failures.append("Level 3 second move must complete the shaped-board puzzle")
		var board_view = screen.get_node_or_null("Layout/BoardView")
		if board_view != null and board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
			if board_view.has_signal("trace_motion_finished"):
				await board_view.trace_motion_finished
		await process_frame
		if screen.result_overlay.visible:
			break

	if not bool(screen.result_overlay.visible):
		failures.append("Level %d scripted runtime journey must reach its win overlay" % number)
	else:
		if String(screen.current_reward_curio) != String(entry["reward"]):
			failures.append("Level %d must grant its authored relic" % number)
		if screen.result_title.text != String(level_data.get("win_title", "")):
			failures.append("Level %d win title must match authored content" % number)
		var reward_art = screen.get_node_or_null("ResultOverlay/Card/Content/RewardRitual")
		if reward_art == null or str(reward_art.get("relic_id")) != String(entry["reward"]):
			failures.append("Level %d win ritual must render its authored relic" % number)
		elif not reward_art.has_method("relic_asset_contract"):
			failures.append("Level %d reward ritual must expose its production Curio asset contract" % number)
		else:
			var reward_contract: Dictionary = reward_art.relic_asset_contract()
			if not bool(reward_contract.get("raster_runtime", false)) or not bool(reward_contract.get("loaded", false)):
				failures.append("Level %d reward Curio must load from production raster art" % number)
		var relic_label: Label = screen.get_node_or_null("Layout/Awakening/Content/Label")
		if relic_label == null or relic_label.text != String(entry["relic_label"]):
			failures.append("Level %d relic progress label must match its reward" % number)

	screen.queue_free()
	await process_frame
