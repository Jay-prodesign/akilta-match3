extends SceneTree

const PrestartScene = preload("res://src/ui/prestart/level_prestart.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = PrestartScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	_expect(screen.configure_level(1, false), "Level 1 prestart must configure")
	await process_frame
	var contract: Dictionary = screen.aid_asset_contract()
	_expect(bool(contract.get("authored_world_backdrop", false)), "Prestart world backdrop must be authored and loaded")
	_expect(bool(contract.get("authored_level_artwork", false)), "Prestart level artwork must be authored and loaded")
	_expect(bool(contract.get("authored_ritual_aids", false)), "Ritual Help chips must be authored and loaded")
	_expect(not bool(contract.get("runtime_ui_factory", true)), "Prestart must not rebuild persistent presentation UI at runtime")
	_expect(bool(contract.get("north_star_readability", false)), "Prestart must retain a strong North Star title/objective/Play hierarchy")
	_expect(bool(contract.get("note_subordinate", false)), "Long explanatory copy must not compete with the primary prestart decision")
	_expect(bool(contract.get("raster_runtime", false)), "Prestart aid art must use raster runtime assets")

	var keeper := screen.get_node_or_null("Layout/Card/Content/RitualAids/Column/AidRow/KeeperChip/Content/Art") as TextureRect
	var recovery := screen.get_node_or_null("Layout/Card/Content/RitualAids/Column/AidRow/RecoveryChip/Content/Art") as TextureRect
	var start := screen.get_node_or_null("Layout/Card/Content/Start") as Button
	var back := screen.get_node_or_null("Layout/Back") as Button
	_expect(keeper != null and keeper.texture != null, "ASK KEEPER authored aid art missing")
	_expect(recovery != null and recovery.texture != null, "Fail recovery authored aid art missing")
	_expect(start != null and start.custom_minimum_size.y >= 84.0, "Prestart primary CTA must retain mobile touch target")
	_expect(back != null and back.custom_minimum_size.y >= 56.0, "Prestart back CTA must retain mobile touch target")

	var objective := screen.get_node_or_null("Layout/Card/Content/Objective") as Label
	var reward := screen.get_node_or_null("Layout/Card/Content/Reward") as Label
	_expect(objective != null and objective.text.contains("6 MOON SIGILS"), "Prestart must bind Level 1 objective truth")
	_expect(reward != null and reward.text.contains("MOON CAMEO"), "Prestart must bind Level 1 reward truth")

	_expect(screen.configure_level(1, true), "Level 1 replay prestart must configure")
	await process_frame
	_expect(reward.text.contains("OWNED CURIO"), "Replay prestart must not fabricate a second Curio reward")

	screen.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored prestart production screen")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
