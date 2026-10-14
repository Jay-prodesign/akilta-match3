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
	_expect(bool(contract.get("north_star_altar_stack", false)), "Weekly Rituals must combine a compact truthful intro with stacked ritual rows")
	_expect(bool(contract.get("north_star_horizontal_mission_rows", false)), "Weekly Rituals must preserve the locked board's three horizontal mission-row scan path")
	_expect(bool(contract.get("scene_authored_altar_material", false)), "Weekly Rituals altar must preserve its clean authored scene material")
	_expect(bool(contract.get("header_readability_scrim", false)), "Weekly Rituals must retain a dedicated header readability scrim over world art")
	_expect(bool(contract.get("production_return_actions", false)), "Weekly Rituals compact Events return must use verified utility chrome")
	_expect(bool(contract.get("scene_authored_status_rows", false)), "Weekly Rituals truthful offline rows must preserve seam-free scene-authored material")
	_expect(bool(contract.get("seam_free_weekly_material", false)), "Weekly Rituals must not stretch shared 9-slice chrome across its altar and mission rows")
	_expect(bool(contract.get("truthful_status_rows", false)), "Weekly Rituals status rows must expose only connected/offline/claim truth")
	_expect(bool(contract.get("redundant_house_return_suppressed", false)), "Weekly Rituals must suppress redundant House return when product navigation already exposes House")
	_expect(bool(contract.get("compact_offline_copy", false)), "Weekly Rituals offline state must hide redundant live-feed copy from the visual stack")
	_expect(bool(contract.get("intentional_world_stage", false)), "Weekly Rituals must use only a compact authored gap rather than a large empty world corridor")
	_expect(bool(contract.get("scene_authored_opening_record", false)), "Weekly Rituals opening record must use clean authored scene material")
	_expect(bool(contract.get("world_art_not_overdimmed", false)), "Weekly Rituals must keep the authored Events world readable")
	_expect(bool(contract.get("visual_parity_gate_v2", false)), "Weekly Rituals must satisfy the final-direction visual parity gate")
	_expect(bool(contract.get("visual_parity_gate_v3", false)), "Weekly Rituals must satisfy the list-density parity gate")

	var timer := screen.get_node_or_null("MissionLayout/MissionTimer") as Label
	var empty := screen.get_node_or_null("MissionLayout/MissionEmptyState") as PanelContainer
	var truth := screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/AltarCopy/MissionEmptyStateTruth") as Label
	var availability := screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/AltarCopy/MissionAvailability") as Label
	var art := screen.get_node_or_null("MissionLayout/MissionEmptyState/EmptyContent/MissionRewardArt") as TextureRect
	var feed_row := screen.get_node_or_null("MissionLayout/MissionStatusStack/FeedStatus") as PanelContainer
	var feed_state := screen.get_node_or_null("MissionLayout/MissionStatusStack/FeedStatus/Content/State") as Label
	var progress_row := screen.get_node_or_null("MissionLayout/MissionStatusStack/ProgressStatus") as PanelContainer
	var progress_state := screen.get_node_or_null("MissionLayout/MissionStatusStack/ProgressStatus/Content/State") as Label
	var reward_row := screen.get_node_or_null("MissionLayout/MissionStatusStack/RewardStatus") as PanelContainer
	var reward_state := screen.get_node_or_null("MissionLayout/MissionStatusStack/RewardStatus/Content/State") as Label
	var stage_spacer := screen.get_node_or_null("MissionLayout/WorldStageSpacer") as Control
	var record := screen.get_node_or_null("MissionLayout/MissionOpeningRecord") as Label
	_expect(timer != null and timer.text.contains("OFFLINE"), "Weekly Rituals must disclose unavailable reset timing")
	_expect(empty != null and empty.custom_minimum_size.y >= 148.0 and empty.custom_minimum_size.y <= 164.0, "Weekly intro must stay compact so the locked-board mission rows own the screen")
	_expect(truth != null and truth.text.contains("NOTHING TO CLAIM"), "Weekly Rituals must not fabricate claimable rewards")
	_expect(availability != null and availability.text.contains("ONLY WHEN A MISSION FEED IS CONNECTED") and not availability.visible, "Weekly Rituals must retain live-feed truth without duplicating it visually")
	_expect(art != null and art.texture != null and art.custom_minimum_size.x >= 90.0 and art.custom_minimum_size.x <= 104.0 and art.custom_minimum_size.y >= 90.0 and art.custom_minimum_size.y <= 104.0 and String(art.get_meta("asset_path", "")).contains("_sealed_"), "Weekly intro must retain a compact sealed raster Curio anchor")
	_expect(feed_row != null and feed_row.get_theme_stylebox("panel") is StyleBoxFlat and feed_state != null and feed_state.text == "NOT CONNECTED", "Weekly Rituals live-feed row must stay truthful and seam-free")
	_expect(progress_row != null and progress_row.get_theme_stylebox("panel") is StyleBoxFlat and progress_state != null and progress_state.text == "NOT TRACKED OFFLINE", "Weekly Rituals progress row must not fabricate offline progress")
	_expect(reward_row != null and reward_row.get_theme_stylebox("panel") is StyleBoxFlat and reward_state != null and reward_state.text == "NOTHING TO CLAIM", "Weekly Rituals reward row must not fabricate a claim")
	_expect(stage_spacer != null and stage_spacer.size_flags_vertical != Control.SIZE_EXPAND_FILL and stage_spacer.custom_minimum_size.y <= 2.0, "Weekly Rituals empty world corridor returned")
	_expect(record != null and record.visible and record.custom_minimum_size.y >= 52.0 and record.custom_minimum_size.y <= 60.0 and record.text.contains("NOTHING TO CLAIM"), "Weekly Rituals footer must truthfully seal the unavailable reward area")
	_expect(record != null and record.get_theme_stylebox("normal") is StyleBoxFlat, "Weekly Rituals sealed reward footer must render on its seam-free authored material")

	var event_signal := {"hit": false}
	screen.return_events_requested.connect(func(): event_signal["hit"] = true)
	var events_return := screen.get_node("MissionLayout/ReturnToEvents") as Button
	_expect(events_return.visible and events_return.custom_minimum_size.y <= 64.0, "Weekly Rituals Events return must stay compact and subordinate")
	events_return.emit_signal("pressed")
	_expect(bool(event_signal["hit"]), "Weekly Rituals must expose Event Center return")

	var house_signal := {"hit": false}
	screen.return_house_requested.connect(func(): house_signal["hit"] = true)
	var house_button := screen.get_node("MissionLayout/ReturnToHouse") as Button
	_expect(not house_button.visible, "Weekly Rituals redundant House button must stay hidden behind product navigation")
	house_button.emit_signal("pressed")
	_expect(bool(house_signal["hit"]), "Weekly Rituals compatibility House return signal must remain intact")

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
