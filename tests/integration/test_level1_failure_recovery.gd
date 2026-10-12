extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const BoardState := preload("res://src/match3/domain/board_state.gd")
const MoveResolver := preload("res://src/match3/domain/move_resolver.gd")
const LEVEL_PATH := "res://content/levels/ch01/level_001.json"
const SAVE_PATH := "user://level1_fail_retry_test.json"
const SETTINGS_PATH := "user://level1_fail_retry_settings.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	var level_data := _read_level()
	var failing_move := _find_failing_move(level_data)
	_expect(not failing_move.is_empty(), "Level 1 must have a reproducible accepted move that can exhaust the move budget without winning")
	if failing_move.is_empty():
		_finish()
		return

	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await process_frame
	await process_frame
	_expect(String(app.current_route_name()) == "boot", "failure recovery journey must begin on splash")
	var splash = app.current_screen()
	_expect(splash != null and splash.get_node_or_null("Layout/Enter") != null, "failure recovery splash must expose enter")
	splash.get_node("Layout/Enter").emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(String(app.current_route_name()) == "house", "failure recovery splash must enter House")
	_expect(app.show_map(), "House -> Map must open for failure recovery test")
	_expect(app.show_prestart(1), "Map -> Prestart must open for failure recovery test")
	_expect(app.start_level(1), "Prestart -> Level 1 must start for failure recovery test")
	await process_frame

	var gameplay = app.current_screen()
	gameplay.board_state.moves_remaining = 1
	gameplay._refresh_hud()
	var trace = gameplay.attempt_swap(failing_move["from"], failing_move["to"])
	_expect(trace != null and trace.accepted, "chosen exhaustion move must be accepted")
	_expect(trace != null and String(trace.result) == "failed", "last non-winning move must resolve to failed")
	var board_view = gameplay.get_node("Layout/BoardView")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished
	_expect(gameplay.result_overlay.visible, "failure must show a result overlay after resolution")
	_expect(gameplay.result_action.text == "TRY AGAIN", "failure result must offer Try Again")
	var recovery_action: Button = gameplay.get_node_or_null("ResultOverlay/Card/Content/RecoveryAction") as Button
	_expect(recovery_action != null and recovery_action.visible and not recovery_action.disabled, "unused +3 Moves recovery must be offered after failure")
	_expect(recovery_action != null and recovery_action.text.contains("+3 MOVES") and recovery_action.text.contains("FREE"), "failure recovery must truthfully label the free +3 Moves option")
	_expect(gameplay.result_detail.text.contains("Moon sigils"), "Level 1 failure must give authored Moon-sigil retry assistance")
	_expect(gameplay.has_method("terminal_result_polish_contract"), "failure result must expose terminal polish contract")
	if gameplay.has_method("terminal_result_polish_contract"):
		var terminal_polish: Dictionary = gameplay.terminal_result_polish_contract()
		_expect(String(terminal_polish.get("objective_summary", "")).begins_with("OBJECTIVE UNFINISHED"), "terminal polish contract must expose unfinished objective")
		_expect(bool(terminal_polish.get("distinct_result_material", false)), "failure result must use distinct terminal material")
	var fail_ritual: Control = gameplay.get_node("ResultOverlay/Card/Content/RewardRitual")
	_expect(String(fail_ritual.get("mode")) == "fail", "failure must keep Moon Cameo visually sealed rather than showing an awakened reward")
	_expect(int(app.progress.house_stage) == 0, "failure must not advance House")
	_expect(not app.progress.curios.has("moon_cameo"), "failure must not grant Moon Cameo")
	var failed_signature: String = String(gameplay.board_state.signature())
	var failed_objective_progress := int(gameplay.board_state.objective_progress)
	_expect(gameplay.has_method("terminal_result_polish_contract"), "failure must expose recovery polish contract")
	if gameplay.has_method("terminal_result_polish_contract"):
		var fail_polish: Dictionary = gameplay.terminal_result_polish_contract()
		_expect(String(fail_polish.get("failure_gap", "")).contains("remained"), "failure result must explain exact remaining objective gap")
		_expect(bool(fail_polish.get("plus_three_recovery_available", false)), "failure contract must expose +3 recovery availability")
	_expect(gameplay.recover_failed_attempt_with_plus_moves(), "unused +3 Moves must recover the failed board")
	_expect(not gameplay.result_overlay.visible, "successful +3 recovery must return to gameplay")
	_expect(int(gameplay.board_state.moves_remaining) == 3, "+3 recovery must restore exactly three moves")
	_expect(int(gameplay.board_state.objective_progress) == failed_objective_progress, "+3 recovery must preserve objective progress")
	var recovered_signature: String = String(gameplay.board_state.signature())
	_expect(failed_signature.get_slice("|moves=", 0) == recovered_signature.get_slice("|moves=", 0), "+3 recovery must preserve the settled board state")
	_expect(gameplay.hint_label.text.contains("RECOVERY") and gameplay.hint_label.text.contains("+3 MOVES"), "recovered gameplay must visibly confirm the continuation")
	_expect(not gameplay.recover_failed_attempt_with_plus_moves(), "+3 recovery must remain one-shot for the attempt")
	_expect(int(app.progress.house_stage) == 0 and not app.progress.curios.has("moon_cameo"), "recovery itself must not grant persistent progress")
	var retry_haptics: Array[Dictionary] = []
	gameplay.haptics.set_platform_sink(func(ms: int, category: int): retry_haptics.append({"ms": ms, "category": category}))
	_expect(gameplay.retry_current_level(), "clean retry must remain available after recovery and reload Level 1")
	_expect(not gameplay.result_overlay.visible, "retry must clear failure overlay")
	_expect(int(gameplay.board_state.moves_remaining) == int(level_data["moves"]), "retry must restore full authored move budget")
	_expect(String(gameplay.current_level_id) == "ch01_level_001", "retry must remain on canonical Level 1")
	_expect(String(app.current_route_name()) == "gameplay", "retry must remain inside gameplay route")
	_expect(gameplay.hint_label.text.contains("RITUAL RESET") and gameplay.hint_label.text.contains("MOVES RESTORED"), "retry must visibly confirm restored move budget")
	_expect(retry_haptics.any(func(call): return int(call["ms"]) == gameplay.haptics.RETRY_MS), "retry must emit a short tactile recovery cue")

	app.queue_free()
	await process_frame
	_cleanup()
	_finish()

func _read_level() -> Dictionary:
	var file := FileAccess.open(LEVEL_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _find_failing_move(level_data: Dictionary) -> Dictionary:
	if level_data.is_empty():
		return {}
	var width := int(level_data.get("width", 0))
	var height := int(level_data.get("height", 0))
	for y in range(height):
		for x in range(width):
			var from := Vector2i(x, y)
			for delta in [Vector2i.RIGHT, Vector2i.DOWN]:
				var to: Vector2i = from + Vector2i(delta)
				if to.x >= width or to.y >= height:
					continue
				var board = BoardState.from_level(level_data, 1001)
				board.moves_remaining = 1
				var trace = MoveResolver.try_swap(board, from, to)
				if trace.accepted and String(trace.result) == "failed":
					return {"from": from, "to": to}
	return {}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _cleanup() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: Level 1 fail retry recovery")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
