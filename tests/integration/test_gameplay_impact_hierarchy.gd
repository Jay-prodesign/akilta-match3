extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")
const ResolutionTrace = preload("res://src/match3/domain/resolution_trace.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _verify_blocker_feedback()
	await _verify_special_feedback()
	await _verify_cascade_escalation()
	if failures.is_empty():
		print("TEST_PASS: gameplay blocker special and cascade impact hierarchy")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _verify_blocker_feedback() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.load_level_path("res://content/levels/ch01/level_002.json", 1002), "Level 2 must load")
	var feedback: Array[String] = []
	var haptic_calls: Array[Dictionary] = []
	screen.feedback_requested.connect(func(kind: String): feedback.append(kind))
	screen.haptics.set_platform_sink(func(ms: int, category: int): haptic_calls.append({"ms": ms, "category": category}))
	var trace = screen.attempt_swap(Vector2i(4, 2), Vector2i(4, 3))
	_expect(trace != null and bool(trace.accepted), "Level 2 teaching move must be accepted")
	_expect(trace.event_types().has("blocker_cleared"), "Level 2 teaching move must clear Wax Seals")
	_expect(feedback.has("blocker"), "blocker clear must emit distinct audio semantics")
	_expect(haptic_calls.any(func(call): return int(call["ms"]) == screen.haptics.BLOCKER_MS), "blocker clear must emit distinct impact haptic")
	var feel: Dictionary = screen.gameplay_feel_contract()
	_expect(String(feel.get("last_impact_feedback", "")) == "blocker_cleared", "gameplay contract must identify blocker clear")
	_expect(String(feel.get("impact_copy", "")).contains("WAX SEAL"), "blocker clear must have readable non-color copy")
	var fx: Dictionary = screen.get_node("Layout/BoardView").feedback_vfx_contract()
	_expect(int(fx.get("last_blocker_clear_fx_count", 0)) >= 2, "Level 2 must render both authored seal clears as clear-impact VFX")
	if screen.get_node("Layout/BoardView").is_motion_active():
		await screen.get_node("Layout/BoardView").trace_motion_finished
	screen.queue_free()
	await process_frame

func _verify_special_feedback() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.load_level_path("res://content/levels/ch01/level_003.json", 1003), "Level 3 must load")
	var feedback: Array[String] = []
	screen.feedback_requested.connect(func(kind: String): feedback.append(kind))
	var create_trace = screen.attempt_swap(Vector2i(2, 3), Vector2i(2, 4))
	_expect(create_trace != null and create_trace.event_types().has("special_created"), "Level 3 first move must create a Moon Beam")
	_expect(feedback.has("special_create"), "special creation must differ from special activation audio semantics")
	_expect(String(screen.gameplay_feel_contract().get("last_impact_feedback", "")) == "special_created", "special creation must own its impact state")
	if screen.get_node("Layout/BoardView").is_motion_active():
		await screen.get_node("Layout/BoardView").trace_motion_finished
	feedback.clear()
	var trigger_trace = screen.attempt_swap(Vector2i(3, 3), Vector2i(3, 4))
	_expect(trigger_trace != null and trigger_trace.event_types().has("special_triggered"), "Level 3 second move must trigger the Moon Beam")
	_expect(feedback.has("special"), "special activation must emit activation semantics")
	_expect(String(screen.gameplay_feel_contract().get("last_impact_feedback", "")) == "special_triggered", "special activation must own its impact state")
	screen.queue_free()
	await process_frame

func _verify_cascade_escalation() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	var board_view = screen.get_node("Layout/BoardView")
	board_view.snapshot_before_move()
	var family := String(screen.board_state.get_cell(Vector2i(0, 0)))
	var trace = ResolutionTrace.new()
	trace.accepted = true
	trace.add_event("clear", {"cascade": 2, "pieces": [{"at": "0,0", "family": family}]})
	_expect(board_view.play_trace(trace), "cascade escalation fixture must start trace-driven motion")
	var fx: Dictionary = board_view.feedback_vfx_contract()
	var motion: Dictionary = board_view.motion_contract()
	_expect(int(fx.get("last_cascade_depth", 1)) == 2, "board feedback contract must preserve cascade depth")
	_expect(String(motion.get("cascade_escalation", "")) == "depth_scaled_clear_burst", "cascade depth must scale visible clear impact")
	if board_view.is_motion_active():
		await board_view.trace_motion_finished
	screen.queue_free()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
