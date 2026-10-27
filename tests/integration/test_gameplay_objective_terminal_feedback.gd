extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")
const BoardState = preload("res://src/match3/domain/board_state.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _verify_nonterminal_progress()
	await _verify_win_transition()
	await _verify_reduced_motion_fail_transition()
	if failures.is_empty():
		print("TEST_PASS: gameplay objective progress and terminal transition feel")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _verify_nonterminal_progress() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.load_level_path("res://content/levels/ch01/level_003.json", 1003), "Level 3 must load")
	var trace = screen.attempt_swap(Vector2i(2, 1), Vector2i(2, 0))
	_expect(trace != null and bool(trace.accepted), "Level 3 first move must resolve")
	var board_view = screen.get_node("Layout/BoardView")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished
	await process_frame
	var feel: Dictionary = screen.gameplay_feel_contract()
	_expect(int(feel.get("objective_delta", 0)) > 0, "successful non-terminal move must expose objective delta")
	_expect(int(feel.get("objective_progress", 0)) < int(feel.get("objective_target", 0)), "Level 3 first move must remain non-terminal")
	_expect(String(feel.get("objective_copy", "")).contains("THIS MOVE"), "non-terminal objective feedback must state this-move progress without relying on color")
	screen.queue_free()
	await process_frame

func _verify_win_transition() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.apply_presentation_settings({"reduced_motion": false, "high_contrast": false, "haptics_enabled": false})
	var authored_moves: Array = [[2, 0, 3, 0], [2, 2, 3, 2], [2, 4, 3, 4], [2, 6, 3, 6]]
	var trace
	var board_view = screen.get_node("Layout/BoardView")
	for move_index in range(authored_moves.size()):
		var raw_move: Array = authored_moves[move_index]
		trace = screen.attempt_swap(
			Vector2i(int(raw_move[0]), int(raw_move[1])),
			Vector2i(int(raw_move[2]), int(raw_move[3]))
		)
		_expect(trace != null and bool(trace.accepted), "Level 1 authored move %d must resolve" % (move_index + 1))
		if move_index < authored_moves.size() - 1:
			_expect(String(trace.result) == "playing", "Level 1 must not enter its terminal state before the fourth authored move")
		if board_view.is_motion_active():
			await board_view.trace_motion_finished
		await process_frame
	_expect(trace != null and String(trace.result) == "won", "Level 1 fourth authored move must win")
	var feel: Dictionary = screen.gameplay_feel_contract()
	var transition: Dictionary = screen.terminal_transition_contract()
	_expect(int(feel.get("objective_progress", 0)) >= int(feel.get("objective_target", 1)), "winning move must complete objective")
	_expect(String(feel.get("objective_copy", "")).contains("OBJECTIVE COMPLETE"), "winning objective must have explicit completion copy")
	_expect(String(transition.get("kind", "")) == "won" and bool(transition.get("overlay_visible", false)), "win must enter terminal overlay through transition contract")
	_expect(String(transition.get("mode", "")) == "subtle_card_settle", "win transition must use production settle mode")
	var polish: Dictionary = screen.terminal_result_polish_contract()
	_expect(bool(polish.get("asset_backed_result_chrome", false)), "win result must retain verified asset-backed production chrome")
	_expect(not bool(polish.get("runtime_result_style_factory", true)), "terminal result must not create flat StyleBox material at runtime")
	var win_dim_alpha := float(polish.get("result_dim_alpha", 0.0))
	_expect(win_dim_alpha >= 0.82 and win_dim_alpha <= 0.90, "win result must suppress gameplay chrome while preserving a trace of House context behind the reveal")
	screen.queue_free()
	await process_frame

func _verify_reduced_motion_fail_transition() -> void:
	var level_data := _read_level("res://content/levels/ch01/level_001.json")
	var failing := _find_failing_move(level_data)
	_expect(not failing.is_empty(), "deterministic fail move must exist")
	if failing.is_empty():
		return
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.apply_presentation_settings({"reduced_motion": true, "high_contrast": true, "haptics_enabled": false})
	screen.board_state.moves_remaining = 1
	screen._refresh_hud()
	var trace = screen.attempt_swap(failing["from"], failing["to"])
	_expect(trace != null and String(trace.result) == "failed", "one-move exhaustion must fail")
	await process_frame
	var transition: Dictionary = screen.terminal_transition_contract()
	_expect(String(transition.get("kind", "")) == "failed", "fail must own terminal transition kind")
	_expect(String(transition.get("mode", "")) == "readable_failure_settle", "fail transition must use the readable compact terminal mode")
	_expect(bool(transition.get("reduced_motion", false)), "fail transition must preserve Reduced Motion state")
	_expect(not bool(transition.get("active", true)), "Reduced Motion must skip decorative terminal tween")
	_expect(screen.result_action.text == "TRY AGAIN", "fail transition must preserve recovery CTA")
	_expect(screen.result_recovery_action.text == "FREE +3 MOVES", "failure rescue CTA must stay concise and truthful")
	var star_row := screen.get_node_or_null("ResultOverlay/Card/Content/StarRow") as HBoxContainer
	_expect(star_row != null and not star_row.visible, "failure result must not show win stars")
	var polish: Dictionary = screen.terminal_result_polish_contract()
	_expect(bool(polish.get("critical_result_copy_visible", false)), "failure title and retry action must remain readable at terminal state")
	_expect(screen.result_detail.text.contains("\n"), "failure guidance must use a compact two-line recovery hierarchy")
	_expect(bool(polish.get("failure_stars_hidden", false)), "failure polish contract must preserve semantic win/fail separation")
	_expect(bool(polish.get("failure_compact_layout", false)), "failure result must use the compact recovery composition instead of the tall win ceremony")
	_expect(not screen.result_objective_summary.visible, "failure result must avoid duplicating the objective gap below its recovery copy")
	screen.queue_free()
	await process_frame

func _read_level(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _find_failing_move(level_data: Dictionary) -> Dictionary:
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
