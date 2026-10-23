extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var contract: Dictionary = screen.gameplay_presentation_contract()
	for key in [
		"authored_hud_plate", "authored_resource_bar", "authored_booster_menu",
		"north_star_resource_strip", "north_star_objective_strip", "north_star_booster_tray", "tall_viewport_booster_attachment",
		"truthful_sealed_slots", "authored_target_moves_hierarchy", "authored_board_frame",
		"asset_backed_gameplay_chrome", "board_frame_asset_owner", "north_star_gameplay_geometry",
		"gameplay_header_clearance", "compact_resource_chips", "asset_backed_resource_chips",
		"level_badge_separated", "hint_booster_clearance", "booster_label_readability", "booster_labels_visible",
		"north_star_booster_family", "utility_separated_from_boosters", "north_star_board_object",
		"north_star_header_hierarchy", "booster_frame_family", "quiet_gameplay_shell_family", "clear_pause_control", "integrated_hint_surface", "integrated_hud_surface",
		"final_hint_readability", "final_booster_readability", "canonical_booster_art", "gothic_board_material", "objective_spacing_locked",
		"north_star_compact_gameplay_header", "north_star_compact_gameplay_geometry", "north_star_gameplay_hud_frame", "north_star_header_depth",
		"visual_parity_gate_v2", "visual_parity_gate_v3", "visual_parity_gate_v4", "visual_parity_gate_v5", "visual_parity_gate_v10", "visual_parity_gate_v11", "visual_parity_gate_v12", "visual_parity_gate_v13", "visual_parity_gate_v14", "visual_parity_gate_v15",
	]:
		_expect(bool(contract.get(key, false)), "Gameplay North Star parity contract failed: %s" % key)
	_expect(int(contract.get("visible_booster_count", 0)) == 3, "Exactly three gameplay boosters must be visible")
	_expect(float(contract.get("resource_bar_height", 0.0)) == 80.0, "Resource strip height drifted")
	_expect(float(contract.get("hud_plate_height", 0.0)) >= 184.0 and float(contract.get("hud_plate_height", 0.0)) <= 200.0, "Target/moves HUD depth drifted from North Star composition")
	_expect(float(contract.get("booster_tray_height", 0.0)) >= 210.0 and float(contract.get("booster_tray_height", 0.0)) <= 230.0, "Booster tray depth drifted")
	_expect(is_equal_approx(float(screen.booster_tray_target_top_for_board_bottom(1452.0)), 1488.0), "Baseline board-to-booster authored gap drifted")
	_expect(float(contract.get("board_to_booster_gap", -1.0)) >= 34.0 and float(contract.get("board_to_booster_gap", -1.0)) <= 38.0, "Gameplay boosters must stay attached to the rendered board across viewport expansion")

	var level_plaque := screen.get_node_or_null("Layout/LevelPlaque") as PanelContainer
	var eyebrow := screen.get_node_or_null("Layout/LevelPlaque/Eyebrow") as Label
	var title := screen.get_node_or_null("Layout/Title") as Label
	var objective_name := screen.get_node_or_null("Layout/HUDPlate/HUD/ObjectiveSlot/ObjectiveName") as Label
	var objective := screen.get_node_or_null("Layout/HUDPlate/HUD/ObjectiveSlot/Objective") as Label
	var moves := screen.get_node_or_null("Layout/HUDPlate/HUD/Moves") as Label
	var objective_icon := screen.get_node_or_null("Layout/HUDPlate/HUD/ObjectiveSlot/ObjectiveIcon") as TextureRect
	var pause := screen.get_node_or_null("Layout/HUDPlate/HUD/Pause") as Button
	var board := screen.get_node_or_null("Layout/BoardView") as Control
	var hint_band := screen.get_node_or_null("Layout/Hint") as Label
	var tray := screen.get_node_or_null("BoosterTray") as PanelContainer
	var keeper_slot := screen.get_node_or_null("BoosterTray/BoosterActions/HintSlot") as VBoxContainer
	var settings_slot := screen.get_node_or_null("BoosterTray/BoosterActions/SettingsSlot") as VBoxContainer
	var shuffle := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotA/SealedBoostA") as Button
	var hand := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotB/SealedBoostB") as Button
	var magic := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotC/SealedBoostC") as Button
	var shuffle_label := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotA/Label") as Label
	var hand_label := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotB/Label") as Label
	var magic_label := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotC/Label") as Label

	_expect(title != null and not title.visible, "Room title must not compete with the compact Level identity")
	_expect(level_plaque != null and level_plaque.custom_minimum_size.x >= 580.0 and level_plaque.get_theme_stylebox("panel") is StyleBoxTexture and eyebrow != null and eyebrow.text.begins_with("LEVEL ") and not eyebrow.text.contains("·") and eyebrow.get_theme_font_size("font_size") >= 40, "Authored Level plaque must anchor the gameplay header")
	_expect(objective_name != null and objective_name.text.contains("SIGILS") and objective_name.modulate.a > 0.95 and objective != null and objective.text.contains("/"), "Objective identity must remain explicit and visibly persistent")
	_expect(objective_icon != null and objective_icon.texture != null and objective_icon.custom_minimum_size.x >= 80.0, "Objective art must remain visually legible")
	_expect(moves != null and moves.custom_minimum_size.x >= 136.0 and moves.get_theme_font_size("font_size") >= 38 and moves.get_theme_font_size("font_size") <= 42, "Moves must remain a dominant counter")
	_expect(objective != null and objective.get_theme_font_size("font_size") >= 28 and objective.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Objective counter must remain readable and centered under its icon")
	_expect(objective != null and objective_icon != null and objective.global_position.y >= objective_icon.global_position.y + objective_icon.size.y - 8.0, "Objective counter must remain attached below its icon")
	_expect(pause != null and objective_icon != null and pause.global_position.x < objective_icon.global_position.x, "Pause must sit at the quiet left edge of the gameplay HUD")
	_expect(pause != null and pause.icon != null and pause.text == "" and pause.get_theme_stylebox("normal") is StyleBoxFlat and String(pause.get_meta("production_chrome_kind", "")) == "gameplay_pause_icon", "Pause must render as the clear authored icon rather than a clipped text glyph")
	_expect(board != null and board.custom_minimum_size.y >= 1020.0 and board.custom_minimum_size.y <= 1080.0, "Board must remain dominant without crowding the North Star header and booster bands")
	_expect(hint_band != null and not hint_band.visible, "Initial teaching must stay board-led instead of inserting a persistent hint band")
	_expect(tray != null and board != null and tray.global_position.y >= board.global_position.y + board.size.y - 4.0, "Booster tray must not cover the board")
	_expect(tray != null and is_equal_approx(tray.anchor_left, 0.045) and is_equal_approx(tray.anchor_right, 0.955), "Booster tray width drifted from the final gameplay family")
	await create_timer(0.35).timeout
	var native_layout: Dictionary = screen.gameplay_native_layout_contract()
	_expect(bool(native_layout.get("booster_visible", false)), "Gameplay booster tray must remain visible after layout")
	_expect(bool(native_layout.get("booster_inside_viewport", false)), "Gameplay booster tray must stay fully inside the rendered viewport")
	_expect(float(native_layout.get("board_to_booster_gap", -1.0)) >= 30.0 and float(native_layout.get("board_to_booster_gap", -1.0)) <= 42.0, "Native gameplay board-to-booster gap drifted")
	_expect(keeper_slot != null and not keeper_slot.visible and settings_slot != null and settings_slot.visible and settings_slot.custom_minimum_size.x < 100.0, "Gameplay utility must remain visually subordinate to the booster family")
	_expect(shuffle != null and shuffle.disabled and shuffle.icon != null and shuffle.custom_minimum_size.y >= 108.0, "Shuffle booster truth/scale failed")
	_expect(hand != null and hand.disabled and hand.icon != null and hand.custom_minimum_size.y >= 108.0, "Hand booster truth/scale failed")
	_expect(magic != null and magic.disabled and magic.icon != null and magic.custom_minimum_size.y >= 108.0, "Magic booster truth/scale failed")
	_expect(shuffle_label != null and shuffle_label.visible and shuffle_label.text == "SHUFFLE" and shuffle_label.get_theme_font_size("font_size") >= 18, "Shuffle identity/readability drifted")
	_expect(hand_label != null and hand_label.visible and hand_label.text == "HAND" and hand_label.get_theme_font_size("font_size") >= 18, "Hand identity/readability drifted")
	_expect(magic_label != null and magic_label.visible and magic_label.text == "MAGIC" and magic_label.get_theme_font_size("font_size") >= 18, "Magic identity/readability drifted")
	_expect(objective != null and objective_name != null and not objective.has_theme_stylebox_override("normal") and objective.text.contains("/") and objective_name.text != "", "Objective must read as a compact authored icon-and-counter slot rather than a detached text panel")
	_expect(hint_band != null and hint_band.custom_minimum_size.y >= 52.0 and hint_band.get_theme_font_size("font_size") >= 26, "Hint callout must remain readable without competing with the board")
	_expect(hint_band != null and hint_band.size_flags_horizontal == Control.SIZE_SHRINK_CENTER and hint_band.custom_minimum_size.x >= 660.0 and hint_band.custom_minimum_size.x <= 720.0, "Hint must remain a restrained centered gameplay callout")
	var hint_style := hint_band.get_theme_stylebox("normal") if hint_band != null else null
	_expect(hint_style is StyleBoxFlat and (hint_style as StyleBoxFlat).bg_color.a <= 0.10 and (hint_style as StyleBoxFlat).border_color.a <= 0.08 and (hint_style as StyleBoxFlat).shadow_color.a <= 0.08, "Hint must integrate into the world instead of reading as a detached UI strip")
	var resource_bar := screen.get_node_or_null("ResourceBar") as PanelContainer
	_expect(resource_bar != null and not resource_bar.visible, "Gameplay must not expose meta currency/level chrome above the final target-and-moves HUD")

	screen.set_player_resources(4, 1234, 7)
	await process_frame
	var coin := screen.get_node_or_null("ResourceBar/Resources/CoinChip/Content/CoinResource") as Label
	var gem := screen.get_node_or_null("ResourceBar/Resources/GemChip/Content/GemResource") as Label
	_expect(coin != null and coin.text == "1,234", "Coin truth binding failed")
	_expect(gem != null and gem.text == "7", "Gem truth binding failed")

	var result_action := screen.get_node_or_null("ResultOverlay/Card/Content/Action") as Button
	var result_objective := screen.get_node_or_null("ResultOverlay/Card/Content/ObjectiveSummary") as Label
	_expect(result_action != null and result_action.custom_minimum_size.y >= 82.0, "Result CTA scale regressed")
	_expect(result_objective != null and result_objective.get_theme_stylebox("normal") != null, "Result objective plate regressed")
	screen.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored gameplay presentation shell")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
