extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.apply_presentation_settings({"reduced_motion": true, "high_contrast": true, "haptics_enabled": false})
	var trace = screen.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	_expect(trace != null and bool(trace.accepted) and String(trace.result) == "won", "reduced-motion fixture must win")
	var terminal: Dictionary = screen.terminal_result_contract()
	_expect(String(terminal.get("state", "")) == "won", "reduced-motion result must identify win")
	_expect(String(terminal.get("transition", "")) == "reduced_motion_immediate", "Reduced Motion must skip terminal animation")
	_expect(String(terminal.get("objective_summary", "")).contains("6 / 6 MOON SIGILS"), "Reduced Motion must preserve objective completion copy")
	_expect(String(terminal.get("action", "")) == "CONTINUE", "win CTA must remain actionable")
	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("TEST_PASS: terminal result hierarchy and reduced-motion transition")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
