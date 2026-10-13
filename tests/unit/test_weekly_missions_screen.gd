extends SceneTree

const WeeklyScene = preload("res://src/ui/missions/weekly_missions_screen.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = WeeklyScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.configure({"completed_count": 3, "opening_cap": 3}), "Weekly Rituals must configure from progression state")
	var contract: Dictionary = screen.screen_contract()
	_expect(String(contract.get("route", "")) == "missions", "Weekly Rituals must own the missions route contract")
	_expect(bool(contract.get("world_art_loaded", false)), "Weekly Rituals must load authored world art")
	_expect(bool(contract.get("reward_art_loaded", false)), "Weekly Rituals must load production reward art")
	_expect(String(contract.get("offline_contract", "")) == "truthful_empty_state", "Weekly Rituals must identify truthful offline state")
	_expect(String(contract.get("reward_asset_path", "")).ends_with(".webp"), "Weekly Rituals must use raster Curio art")
	_expect(bool(contract.get("sealed_offline_art", false)), "Offline Weekly Rituals must use the sealed Curio state, not awakened reward art")
	_expect(not bool(contract.get("code_built_panels", true)), "Weekly Rituals must not return to bootstrap-built panels")
	_expect(bool(contract.get("north_star_title_hierarchy", false)), "Weekly Rituals must retain a strong North Star page title")
	_expect(bool(contract.get("north_star_altar_stack", false)), "Weekly Rituals empty state must use a compact vertical altar composition")
	_expect(bool(contract.get("asset_backed_altar_chrome", false)), "Weekly Rituals altar must use asset-backed production chrome")
	_expect(bool(contract.get("header_readability_scrim", false)), "Weekly Rituals must retain a dedicated header readability scrim over world art")
	_expect(bool(contract.get("production_return_actions", false)), "Weekly Rituals returns must use the verified production action chrome family")

	var timer := screen.get_node_or_null("MissionLayout/MissionTimer") as Label
	var empty := screen.get_node_or_null("MissionLayout/MissionEmptyState") as PanelContainer
	var truth := screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/AltarCopy/MissionEmptyStateTruth") as Label
	var availability := screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/AltarCopy/MissionAvailability") as Label
	var art := screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/MissionRewardArt") as TextureRect
	var record := screen.get_node_or_null("MissionLayout/MissionOpeningRecord") as Label
	_expect(timer != null and timer.text.contains("OFFLINE"), "Weekly Rituals must disclose unavailable reset timing")
	_expect(empty != null and empty.custom_minimum_size.y >= 500.0 and empty.custom_minimum_size.y <= 520.0, "Weekly altar must keep a bounded hero stage without becoming an empty full-height slab")
	_expect(truth != null and truth.text.contains("NOTHING TO CLAIM"), "Weekly Rituals must not fabricate claimable rewards")
	_expect(availability != null and availability.text.contains("ONLY WHEN A MISSION FEED IS CONNECTED"), "Weekly Rituals must explain live-feed dependency")
	_expect(art != null and art.texture != null and art.custom_minimum_size.x >= 320.0 and String(art.get_meta("asset_path", "")).contains("_sealed_"), "Weekly altar must retain a hero-scale sealed raster Curio")
	_expect(record != null and record.text.contains("3 / 3 DISPLAYS AWAKENED"), "Weekly Rituals must reflect opening cabinet record")

	var event_signal := {"hit": false}
	screen.return_events_requested.connect(func(): event_signal["hit"] = true)
	(screen.get_node("MissionLayout/ReturnToEvents") as Button).emit_signal("pressed")
	_expect(bool(event_signal["hit"]), "Weekly Rituals must expose Event Center return")

	var house_signal := {"hit": false}
	screen.return_house_requested.connect(func(): house_signal["hit"] = true)
	(screen.get_node("MissionLayout/ReturnToHouse") as Button).emit_signal("pressed")
	_expect(bool(house_signal["hit"]), "Weekly Rituals must expose House return")

	screen.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored Weekly Rituals screen")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
