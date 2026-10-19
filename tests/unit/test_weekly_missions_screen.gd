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
	await process_frame
	var contract: Dictionary = screen.screen_contract()
	var interaction: Dictionary = screen.weekly_interaction_contract()
	_expect(bool(interaction.get("reveal_choreography", false)), "Weekly Rituals must own staged destination reveal choreography")
	_expect(String(interaction.get("reveal_phase", "")) == "opening", "Weekly Rituals reveal must visibly enter before settling")
	_expect(bool(interaction.get("return_events_tactile", false)), "Weekly Rituals Events return must own tactile press/release craft")
	_expect(bool(interaction.get("reduced_motion_supported", false)), "Weekly Rituals interaction craft must support Reduced Motion")
	_expect(bool(interaction.get("feedback_signal", false)), "Weekly Rituals interactions must expose semantic feedback")
	_expect(bool(interaction.get("static_rows_noninteractive", false)), "Weekly Rituals offline status rows must remain static truth rather than fake actions")
	await create_timer(0.52).timeout
	interaction = screen.weekly_interaction_contract()
	_expect(String(interaction.get("reveal_phase", "")) == "idle", "Weekly Rituals staged reveal must settle cleanly")
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
	_expect(bool(contract.get("north_star_sealed_reward_panel", false)), "Weekly Rituals must give the locked board's reward zone a truthful sealed-state treatment")
	_expect(bool(contract.get("scene_authored_altar_material", false)), "Weekly Rituals altar must preserve its clean authored scene material")
	_expect(bool(contract.get("header_readability_scrim", false)), "Weekly Rituals must retain a dedicated header readability scrim over world art")
	_expect(bool(contract.get("production_return_actions", false)), "Weekly Rituals compact Events return must use verified utility chrome")
	_expect(bool(contract.get("scene_authored_status_rows", false)), "Weekly Rituals truthful offline rows must preserve seam-free scene-authored material")
	_expect(bool(contract.get("seam_free_weekly_material", false)), "Weekly Rituals must not stretch shared 9-slice chrome across its altar and mission rows")
	_expect(bool(contract.get("truthful_status_rows", false)), "Weekly Rituals status rows must expose only connected/offline/claim truth")
	_expect(bool(contract.get("raster_reward_stage", false)), "Weekly Rituals lower reward stage must use real raster Curio art")
	_expect(bool(contract.get("asset_backed_reward_stage", false)), "Weekly Rituals lower reward stage must use ornate production chrome")
	_expect(bool(contract.get("redundant_house_return_suppressed", false)), "Weekly Rituals must suppress redundant House return when product navigation already exposes House")
	_expect(bool(contract.get("compact_offline_copy", false)), "Weekly Rituals offline state must hide redundant live-feed copy from the visual stack")
	_expect(bool(contract.get("intentional_world_stage", false)), "Weekly Rituals must use only a compact authored gap rather than a large empty world corridor")
	_expect(bool(contract.get("scene_authored_opening_record", false)), "Weekly Rituals opening record must use clean authored scene material")
	_expect(bool(contract.get("world_art_not_overdimmed", false)), "Weekly Rituals must keep the authored Events world readable")
	_expect(bool(contract.get("visual_parity_gate_v2", false)), "Weekly Rituals must satisfy the final-direction visual parity gate")
	_expect(bool(contract.get("visual_parity_gate_v3", false)), "Weekly Rituals must satisfy the list-density parity gate")
	_expect(bool(contract.get("north_star_compact_reward_stage", false)), "Weekly Rituals reward stage must stay compact instead of becoming a large empty slab")

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
	var record := screen.get_node_or_null("MissionLayout/MissionOpeningRecord") as PanelContainer
	var reward_seal := screen.get_node_or_null("MissionLayout/MissionOpeningRecord/Content/RewardSeal") as TextureRect
	var reward_panel_state := screen.get_node_or_null("MissionLayout/MissionOpeningRecord/Content/State") as Label
	var reward_truth := screen.get_node_or_null("MissionLayout/MissionOpeningRecord/Content/Truth") as Label
	_expect(timer != null and timer.text.contains("OFFLINE"), "Weekly Rituals must disclose unavailable reset timing")
	_expect(empty != null and empty.custom_minimum_size.y >= 112.0 and empty.custom_minimum_size.y <= 128.0, "Weekly intro must stay compact so the locked-board mission rows own the screen")
	_expect(truth != null and truth.text.contains("NOTHING TO CLAIM"), "Weekly Rituals must not fabricate claimable rewards")
	_expect(availability != null and availability.text.contains("ONLY WHEN A MISSION FEED IS CONNECTED") and not availability.visible, "Weekly Rituals must retain live-feed truth without duplicating it visually")
	_expect(art != null and art.texture != null and art.custom_minimum_size.x >= 80.0 and art.custom_minimum_size.x <= 96.0 and art.custom_minimum_size.y >= 80.0 and art.custom_minimum_size.y <= 96.0 and String(art.get_meta("asset_path", "")).contains("_sealed_"), "Weekly intro must retain a compact sealed raster Curio anchor")
	_expect(feed_row != null and feed_row.custom_minimum_size.y >= 212.0 and feed_row.custom_minimum_size.y <= 228.0 and feed_row.size_flags_vertical != Control.SIZE_EXPAND_FILL and feed_row.get_theme_stylebox("panel") is StyleBoxFlat and feed_state != null and feed_state.text == "NOT CONNECTED", "Weekly Rituals live-feed row must stay dense, truthful and seam-free")
	_expect(progress_row != null and progress_row.custom_minimum_size.y >= 212.0 and progress_row.custom_minimum_size.y <= 228.0 and progress_row.size_flags_vertical != Control.SIZE_EXPAND_FILL and progress_row.get_theme_stylebox("panel") is StyleBoxFlat and progress_state != null and progress_state.text == "NOT TRACKED OFFLINE", "Weekly Rituals progress row must stay dense without fabricating offline progress")
	_expect(reward_row != null and reward_row.custom_minimum_size.y >= 212.0 and reward_row.custom_minimum_size.y <= 228.0 and reward_row.size_flags_vertical != Control.SIZE_EXPAND_FILL and reward_row.get_theme_stylebox("panel") is StyleBoxFlat and reward_state != null and reward_state.text == "NOTHING TO CLAIM", "Weekly Rituals reward row must stay dense without fabricating a claim")
	_expect(stage_spacer != null and stage_spacer.size_flags_vertical != Control.SIZE_EXPAND_FILL and stage_spacer.custom_minimum_size.y <= 2.0, "Weekly Rituals empty world corridor returned")
	_expect(record != null and record.visible and record.custom_minimum_size.y >= 350.0 and record.custom_minimum_size.y <= 370.0 and record.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Weekly Rituals reward zone must occupy the board's lower reward stage")
	_expect(record != null and record.get_theme_stylebox("panel") is StyleBoxTexture, "Weekly Rituals sealed reward zone must render with ornate production chrome")
	_expect(reward_seal != null and reward_seal.texture != null and String(reward_seal.get_meta("asset_path", "")).ends_with(".webp") and reward_panel_state != null and reward_panel_state.text == "SEALED · LIVE FEED REQUIRED" and reward_truth != null and reward_truth.text == "NOTHING TO CLAIM OFFLINE", "Weekly Rituals reward zone must remain explicit, raster-backed and truthful")

	var event_signal := {"hit": false}
	var feedback := {"count": 0}
	screen.return_events_requested.connect(func(): event_signal["hit"] = true)
	screen.interaction_feedback_requested.connect(func(_kind: String): feedback["count"] = int(feedback["count"]) + 1)
	var events_return := screen.get_node("MissionLayout/ReturnToEvents") as Button
	_expect(events_return.visible and events_return.custom_minimum_size.y <= 80.0, "Weekly Rituals Events return must stay compact and subordinate")
	events_return.emit_signal("button_down")
	await create_timer(0.08).timeout
	_expect(events_return.scale.x < 0.98, "Weekly Rituals Events return must visibly compress on press")
	_expect(int(feedback["count"]) == 1, "Weekly Rituals Events return press must emit one semantic feedback request")
	events_return.emit_signal("button_up")
	await create_timer(0.18).timeout
	_expect(absf(events_return.scale.x - 1.0) < 0.01, "Weekly Rituals Events return must spring cleanly back on release")
	screen.apply_presentation_settings({"reduced_motion": true})
	events_return.emit_signal("button_down")
	await process_frame
	_expect(absf(events_return.scale.x - 1.0) < 0.01, "Reduced Motion must suppress decorative Weekly Rituals press scaling")
	events_return.emit_signal("button_up")
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
