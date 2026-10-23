extends SceneTree

const GAMEPLAY_SCENE := preload("res://src/ui/gameplay/gameplay_screen.tscn")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var screen = GAMEPLAY_SCENE.instantiate()
	root.add_child(screen)
	await _frames(2)
	screen.apply_presentation_settings({"reduced_motion": false, "high_contrast": false, "haptics_enabled": false})

	var board_view = screen.get_node_or_null("Layout/BoardView")
	var trace
	for raw_move in [[2, 0, 3, 0], [2, 2, 3, 2], [2, 4, 3, 4]]:
		var setup_trace = screen.attempt_swap(
			Vector2i(int(raw_move[0]), int(raw_move[1])),
			Vector2i(int(raw_move[2]), int(raw_move[3]))
		)
		if setup_trace == null or not bool(setup_trace.accepted) or String(setup_trace.result) != "playing":
			return _fail(screen, "Level 1 feedback setup move failed")
		if board_view != null and board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
			await board_view.trace_motion_finished
		await process_frame
	trace = screen.attempt_swap(Vector2i(2, 6), Vector2i(3, 6))
	if trace == null or not bool(trace.accepted) or String(trace.result) != "won":
		return _fail(screen, "authored Level 1 fourth move did not reach win")


	if board_view == null or not board_view.has_method("feedback_vfx_contract"):
		return _fail(screen, "S05 board feedback VFX contract missing")
	var clear_contract: Dictionary = board_view.feedback_vfx_contract()
	if int(clear_contract.get("last_clear_fx_count", 0)) <= 0:
		return _fail(screen, "winning move did not schedule match-clear VFX")

	# Observe the clear window while the actual piece art is still shrinking out.
	await create_timer(0.22).timeout
	if not await _save(screen, "feedback-01-match-clear.png"):
		return

	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished
	await process_frame
	if not screen.result_overlay.visible:
		return _fail(screen, "S06 result did not become visible after board motion")
	var reward: Dictionary = screen.feedback_vfx_contract().get("reward_reveal", {})
	if int(reward.get("play_count", 0)) != 1 or bool(reward.get("last_reduced_motion", true)):
		return _fail(screen, "S06 reward reveal VFX did not start")
	if not await _save(screen, "feedback-02-reward-reveal.png"):
		return

	print("CAPTURE_PASS: Golden Loop feedback VFX")
	screen.queue_free()
	await process_frame
	quit(0)

func _save(screen: Node, file_name: String) -> bool:
	var image: Image = screen.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return _fail(screen, "empty viewport for %s" % file_name)
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(file_name)
	if image.save_png(output_path) != OK:
		return _fail(screen, "save failed for %s" % file_name)
	print("CAPTURE_FRAME: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	return true

func _fail(screen: Node, message: String) -> bool:
	printerr("CAPTURE_FAIL: %s" % message)
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	quit(1)
	return false

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
