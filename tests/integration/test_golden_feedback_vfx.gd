extends SceneTree

const GAMEPLAY_SCENE := preload("res://src/ui/gameplay/gameplay_screen.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _verify_animated_feedback()
	await _verify_reduced_motion_feedback()

	if failures.is_empty():
		print("TEST_PASS: Golden Loop match-clear and reward-reveal VFX contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _verify_animated_feedback() -> void:
	var screen = GAMEPLAY_SCENE.instantiate()
	root.add_child(screen)
	await _frames(2)
	screen.apply_presentation_settings({"reduced_motion": false, "high_contrast": false, "haptics_enabled": false})
	var board_view = screen.get_node_or_null("Layout/BoardView")
	_expect(board_view != null, "Animated VFX test requires BoardView")

	var setup_moves: Array = [[2, 0, 3, 0], [2, 2, 3, 2], [2, 4, 3, 4]]
	for raw_move in setup_moves:
		var setup_trace = screen.attempt_swap(
			Vector2i(int(raw_move[0]), int(raw_move[1])),
			Vector2i(int(raw_move[2]), int(raw_move[3]))
		)
		_expect(setup_trace != null and bool(setup_trace.accepted) and String(setup_trace.result) == "playing", "Level 1 setup moves must remain non-terminal for feedback proof")
		if board_view != null and board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
			await board_view.trace_motion_finished
		await _frames(1)
	var trace = screen.attempt_swap(Vector2i(2, 6), Vector2i(3, 6))
	_expect(trace != null and bool(trace.accepted) and String(trace.result) == "won", "Fourth authored Level 1 move must win for feedback proof")
	var early: Dictionary = screen.feedback_vfx_contract()
	var clear_contract: Dictionary = early.get("match_clear", {})
	_expect(str(clear_contract.get("slot", "")) == "S05/match_board/board_fx", "Match clear VFX must own canonical S05 board_fx slot")
	_expect(int(clear_contract.get("last_clear_fx_count", 0)) > 0, "Winning move must schedule visible match-clear bursts")
	_expect(bool(clear_contract.get("reduced_motion_supported", false)), "Match-clear VFX must support Reduced Motion")

	if board_view != null and board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished
	await _frames(1)
	var reward: Dictionary = screen.feedback_vfx_contract().get("reward_reveal", {})
	_expect(screen.result_overlay.visible, "Winning feedback must resolve into S06 result")
	_expect(str(reward.get("slot", "")) == "S06/result_panel/reward_fx", "Reward reveal VFX must own canonical S06 reward_fx slot")
	_expect(int(reward.get("play_count", 0)) == 1, "First-time win must play reward reveal exactly once")
	_expect(not bool(reward.get("last_reduced_motion", true)), "Normal presentation must use animated reward reveal")
	screen.queue_free()
	await _frames(2)

func _verify_reduced_motion_feedback() -> void:
	var screen = GAMEPLAY_SCENE.instantiate()
	root.add_child(screen)
	await _frames(2)
	screen.apply_presentation_settings({"reduced_motion": true, "high_contrast": false, "haptics_enabled": false})
	var board_view = screen.get_node_or_null("Layout/BoardView")
	for raw_move in [[2, 0, 3, 0], [2, 2, 3, 2], [2, 4, 3, 4]]:
		var setup_trace = screen.attempt_swap(
			Vector2i(int(raw_move[0]), int(raw_move[1])),
			Vector2i(int(raw_move[2]), int(raw_move[3]))
		)
		_expect(setup_trace != null and bool(setup_trace.accepted) and String(setup_trace.result) == "playing", "Reduced Motion setup moves must remain non-terminal")
	var trace = screen.attempt_swap(Vector2i(2, 6), Vector2i(3, 6))
	_expect(trace != null and bool(trace.accepted) and String(trace.result) == "won", "Reduced Motion fourth move must preserve gameplay result")
	var contract: Dictionary = screen.feedback_vfx_contract()
	var clear_contract: Dictionary = contract.get("match_clear", {})
	var reward: Dictionary = contract.get("reward_reveal", {})
	_expect(board_view != null and not bool(board_view.is_motion_active()), "Reduced Motion must skip board motion animation")
	_expect(bool(clear_contract.get("reduced_motion", false)), "S05 board_fx contract must report Reduced Motion")
	_expect(int(clear_contract.get("last_clear_fx_count", 0)) > 0, "Reduced Motion keeps semantic clear count without animating it")
	_expect(screen.result_overlay.visible, "Reduced Motion must resolve directly to S06 result")
	_expect(int(reward.get("play_count", 0)) == 1, "Reduced Motion reward state must still be registered")
	_expect(bool(reward.get("last_reduced_motion", false)), "S06 reward_fx must report Reduced Motion")
	_expect(not bool(reward.get("active", true)), "Reduced Motion must not leave decorative reward animation active")
	screen.queue_free()
	await _frames(2)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
