extends SceneTree

const GAMEPLAY_SCENE := preload("res://src/ui/gameplay/gameplay_screen.tscn")
var failures: Array[String] = []
var feedback: Array[String] = []
var haptic_calls: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = GAMEPLAY_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.apply_presentation_settings({"reduced_motion": false, "high_contrast": false, "haptics_enabled": true})
	screen.feedback_requested.connect(func(kind: String): feedback.append(kind))
	screen.haptics.set_platform_sink(func(duration_ms: int, category: int): haptic_calls.append({"ms": duration_ms, "category": category}))

	var board = screen.board_state
	var before_signature := String(board.signature())
	var before_moves := int(board.moves_remaining)
	var rejected = screen.attempt_swap(Vector2i(0, 0), Vector2i(1, 0))
	_expect(rejected != null and not bool(rejected.accepted), "known adjacent non-match swap must be rejected")
	_expect(String(board.signature()) == before_signature, "rejected swap must restore exact board state")
	_expect(int(board.moves_remaining) == before_moves, "rejected swap must not consume a move")
	_expect(feedback.has("invalid"), "rejected swap must emit semantic invalid feedback")
	_expect(haptic_calls.size() == 1 and int(haptic_calls[0]["ms"]) == screen.haptics.INVALID_MS, "rejected swap must emit a short tactile rejection")
	var board_view = screen.get_node_or_null("Layout/BoardView")
	_expect(board_view != null and bool(board_view.is_motion_active()), "rejected swap must visibly return instead of snapping silently")
	if board_view != null and bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished

	board.moves_remaining = 3
	screen._refresh_hud()
	var warning: Dictionary = screen.gameplay_feel_contract()
	_expect(String(warning.get("moves_urgency_state", "")) == "warning", "three moves must enter warning urgency")
	_expect(String(warning.get("moves_copy", "")).contains("⚠"), "warning urgency must have a non-color cue")

	board.moves_remaining = 1
	screen._refresh_hud()
	var critical: Dictionary = screen.gameplay_feel_contract()
	_expect(String(critical.get("moves_urgency_state", "")) == "critical", "one move must enter critical urgency")
	_expect(String(critical.get("moves_copy", "")) == "LAST MOVE", "critical urgency must become unmistakable text")

	screen.apply_presentation_settings({"reduced_motion": true, "high_contrast": true, "haptics_enabled": false})
	var accessible: Dictionary = screen.gameplay_feel_contract()
	_expect(bool(accessible.get("reduced_motion", false)), "gameplay feel contract must preserve Reduced Motion")
	_expect(bool(accessible.get("high_contrast", false)), "gameplay feel contract must preserve High Contrast")
	_expect(bool(accessible.get("urgency_non_color_cue", false)), "urgency must remain understandable without color")

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("TEST_PASS: invalid-swap tactile return and low-move urgency")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
