extends SceneTree

const HouseScene := preload("res://src/ui/home/house_home.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var reduced = HouseScene.instantiate()
	root.add_child(reduced)
	await _frames(2)
	reduced.set_available_level_count(3)
	reduced.apply_presentation_settings({"reduced_motion": true})
	var p2 = _progress_with_wins(2)
	reduced.set_progress(p2)
	reduced.show_restoration_ceremony("moth_reliquary", 2)
	await _frames(3)
	var reduced_room = reduced.get_node_or_null("Layout/RoomView")
	var reduced_card: PanelContainer = reduced.get_node_or_null("RestorationOverlay/CeremonyCard") as PanelContainer
	_expect(reduced_room != null, "Reduced Motion restoration room missing")
	if reduced_room != null:
		var contract: Dictionary = reduced_room.restoration_contract()
		_expect(int(contract.get("stage", -1)) == 2, "Reduced Motion must resolve immediately to restoration stage 2")
		_expect(bool(contract.get("moth_reliquary_visible", false)), "Reduced Motion must retain the restored Moth Reliquary")
		_expect(reduced_room.modulate == Color.WHITE, "Reduced Motion must not leave the House in a transitional tint")
		_expect(reduced_room.get_node_or_null("RestorationAwakeningEcho") == null, "Reduced Motion must skip scale/tween awakening echo")
	_expect(reduced_card != null and reduced_card.size.y <= reduced.size.y * 0.18, "Restoration ceremony card must fit its real content")
	reduced.queue_free()
	await _frames(2)

	var animated = HouseScene.instantiate()
	root.add_child(animated)
	await _frames(2)
	animated.set_available_level_count(3)
	animated.apply_presentation_settings({"reduced_motion": false})
	var p3 = _progress_with_wins(3)
	animated.set_progress(p3)
	animated.show_restoration_ceremony("thorned_locket", 3)
	await _frames(3)
	var animated_room = animated.get_node_or_null("Layout/RoomView")
	var animated_card: PanelContainer = animated.get_node_or_null("RestorationOverlay/CeremonyCard") as PanelContainer
	_expect(animated_room != null, "Animated restoration room missing")
	if animated_room != null:
		var contract: Dictionary = animated_room.restoration_contract()
		_expect(int(contract.get("stage", -1)) == 3, "Animated restoration must reach stage 3")
		_expect(bool(contract.get("thorned_locket_visible", false)), "Animated restoration must retain the Thorned Locket")
		var echo: TextureRect = animated_room.get_node_or_null("RestorationAwakeningEcho") as TextureRect
		_expect(echo != null and echo.texture != null, "Stage 3 must render the contract-owned Curio awakening echo")
	_expect(animated_card != null and animated_card.size.y <= animated.size.y * 0.18, "Animated ceremony card must fit its real content")
	animated.queue_free()
	await _frames(2)

	if failures.is_empty():
		print("TEST_PASS: S07 restoration presentation and reduced-motion contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _progress_with_wins(count: int):
	var progress = ProgressScript.new()
	if count >= 1:
		progress.apply_level_win("restoration-l1", "ch01_level_001", "moon_cameo", 1)
	if count >= 2:
		progress.apply_level_win("restoration-l2", "ch01_level_002", "moth_reliquary", 2)
	if count >= 3:
		progress.apply_level_win("restoration-l3", "ch01_level_003", "thorned_locket", 3)
	return progress

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
