extends SceneTree

const GAMEPLAY_SCENE := preload("res://src/ui/gameplay/gameplay_screen.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = GAMEPLAY_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen.apply_presentation_settings({"reduced_motion": false, "high_contrast": false, "haptics_enabled": false})

	var board_view = screen.get_node_or_null("Layout/BoardView")
	_expect(board_view != null, "touch session requires the real BoardView")
	if board_view == null:
		return _finish(screen)

	var initial_moves := int(screen.board_state.moves_remaining)
	var invalid_from: Vector2 = board_view._cell_center(Vector2i(0, 0))
	var invalid_to: Vector2 = board_view._cell_center(Vector2i(1, 0))
	_send_touch_press(board_view, invalid_from)
	_send_touch_drag(board_view, invalid_to, invalid_to - invalid_from)
	_expect(screen.last_trace != null and not bool(screen.last_trace.accepted), "real touch drag must reach the rejected-swap resolver path")
	_expect(int(screen.board_state.moves_remaining) == initial_moves, "rejected touch swipe must not spend a move")
	_expect(not bool(board_view.pointer_feedback_contract().get("tracking", true)), "threshold-crossing touch swipe must commit without waiting for finger release")
	_send_touch_release(board_view, invalid_to)
	_expect(int(screen.board_state.moves_remaining) == initial_moves, "release after committed rejected swipe must not duplicate the move")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished

	var from: Vector2 = board_view._cell_center(Vector2i(2, 0))
	var to: Vector2 = board_view._cell_center(Vector2i(3, 0))
	_send_touch_press(board_view, from)
	var preview := from.lerp(to, 0.55)
	_send_touch_drag(board_view, preview, preview - from)
	var preview_contract: Dictionary = board_view.pointer_feedback_contract()
	_expect(bool(preview_contract.get("tracking", false)), "sub-threshold touch drag must remain in preview state")
	_expect(preview_contract.get("intent_target", Vector2i(-1, -1)) == Vector2i(3, 0), "touch preview must communicate the intended adjacent target before commit")
	_expect(screen.last_trace != null and not bool(screen.last_trace.accepted), "sub-threshold preview must not resolve a new move")

	_send_touch_drag(board_view, to, to - preview)
	_expect(screen.last_trace != null and bool(screen.last_trace.accepted), "real touch swipe must resolve the authored Level 1 move")
	_expect(int(screen.board_state.moves_remaining) == initial_moves - 1, "accepted touch swipe must spend exactly one move at threshold crossing")
	_expect(not bool(board_view.pointer_feedback_contract().get("tracking", true)), "accepted swipe must clear pointer tracking immediately after commit")
	var moves_after_drag := int(screen.board_state.moves_remaining)
	_send_touch_release(board_view, to)
	_expect(int(screen.board_state.moves_remaining) == moves_after_drag, "finger release after committed swipe must never double-submit")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished

	_expect(int(screen.board_state.objective_progress) >= 3, "touch-driven accepted move must advance the real Moon objective")
	_expect(not bool(board_view.teaching_contract().get("active", true)), "first real touch swipe must dismiss the authored teaching cue")

	_finish(screen)

func _send_touch_press(board_view: Control, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = position
	event.pressed = true
	board_view._gui_input(event)

func _send_touch_drag(board_view: Control, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = position
	event.relative = relative
	board_view._gui_input(event)

func _send_touch_release(board_view: Control, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = position
	event.pressed = false
	board_view._gui_input(event)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish(screen: Node) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("TEST_PASS: real touch drag commits one Match-3 move at threshold")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
