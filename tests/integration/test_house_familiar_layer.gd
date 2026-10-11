extends SceneTree

const HouseScene := preload("res://src/ui/home/house_home.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = HouseScene.instantiate()
	root.add_child(screen)
	await _frames(2)
	screen.set_available_level_count(3)

	var fresh = ProgressScript.new()
	screen.set_progress(fresh)
	await _frames(2)
	var room = screen.get_node_or_null("Layout/RoomView")
	_expect(room != null and room.has_method("familiar_contract"), "House must expose character_world_layer contract")
	if room != null and room.has_method("familiar_contract"):
		var fresh_contract: Dictionary = room.familiar_contract()
		_expect(bool(fresh_contract.get("loaded", false)), "Authored House familiar layer must decode")
		_expect(str(fresh_contract.get("slot", "")) == "character_world_layer", "Familiar must own canonical character_world_layer slot")
		_expect(str(fresh_contract.get("state", "")) == "attention", "Dormant House must use attention familiar state")
		_expect(not bool(fresh_contract.get("gameplay_piece_substitution", true)), "House familiar must never reuse Match-3 cat tile semantics")
		_expect(str(fresh_contract.get("path", "")).ends_with("ch01_house_black_cat_familiar_layer_v01.png"), "House familiar must resolve to authored transparent world layer")

	var restored = ProgressScript.new()
	restored.apply_level_win("cat-layer-l1", "ch01_level_001", "moon_cameo", 1)
	screen.set_progress(restored)
	await _frames(2)
	if room != null:
		_expect(str(room.familiar_contract().get("state", "")) == "idle", "Restored House must return familiar to idle")

	screen.apply_presentation_settings({"reduced_motion": true})
	screen.show_restoration_ceremony("moon_cameo", 1)
	await _frames(3)
	if room != null:
		_expect(str(room.familiar_contract().get("state", "")) == "celebrate", "Restoration ceremony must expose celebrate familiar state even with Reduced Motion")
	var continue_button: Button = screen.get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button
	if continue_button != null:
		continue_button.emit_signal("pressed")
		await _frames(3)
	if room != null:
		_expect(str(room.familiar_contract().get("state", "")) == "idle", "Familiar must return to idle after restoration ceremony")

	screen.queue_free()
	await _frames(2)
	if failures.is_empty():
		print("TEST_PASS: S01 S07 House familiar character-world contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
