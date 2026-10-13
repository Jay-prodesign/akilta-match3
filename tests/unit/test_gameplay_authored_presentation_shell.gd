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
		"north_star_resource_strip", "north_star_objective_strip", "north_star_booster_tray",
		"truthful_sealed_slots", "authored_target_moves_hierarchy", "authored_board_frame",
		"asset_backed_gameplay_chrome", "board_frame_asset_owner", "north_star_gameplay_geometry",
		"gameplay_header_clearance", "compact_resource_chips", "asset_backed_resource_chips",
		"level_badge_separated", "hint_booster_clearance", "booster_label_readability",
		"north_star_booster_family", "utility_separated_from_boosters", "north_star_board_object",
		"north_star_header_hierarchy", "booster_frame_family", "visual_parity_gate_v2",
	]:
		_expect(bool(contract.get(key, false)), "Gameplay North Star parity contract failed: %s" % key)
	_expect(int(contract.get("visible_booster_count", 0)) == 3, "Exactly three gameplay boosters must be visible")
	_expect(float(contract.get("resource_bar_height", 0.0)) == 80.0, "Resource strip height drifted")
	_expect(float(contract.get("hud_plate_height", 0.0)) >= 136.0, "Target/moves hierarchy collapsed")
	_expect(float(contract.get("booster_tray_height", 0.0)) >= 200.0, "Booster tray is too shallow")

	var title := screen.get_node_or_null("Layout/Title") as Label
	var objective := screen.get_node_or_null("Layout/HUDPlate/HUD/Objective") as Label
	var moves := screen.get_node_or_null("Layout/HUDPlate/HUD/Moves") as Label
	var objective_icon := screen.get_node_or_null("Layout/HUDPlate/HUD/ObjectiveIcon") as TextureRect
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

	_expect(title != null and title.get_theme_font_size("font_size") >= 36, "Title must retain hero hierarchy")
	_expect(objective != null and objective.text.contains("SIGILS"), "Objective must remain explicit")
	_expect(objective_icon != null and objective_icon.texture != null and objective_icon.custom_minimum_size.x >= 70.0, "Objective art must be visually dominant")
	_expect(moves != null and moves.custom_minimum_size.x >= 220.0 and moves.get_theme_font_size("font_size") >= 36, "Moves must be a dominant counter")
	_expect(board != null and board.custom_minimum_size.y >= 980.0, "Board must remain the dominant gameplay object")
	_expect(hint_band != null and tray != null and tray.global_position.y >= hint_band.global_position.y + hint_band.size.y + 20.0, "Hint and booster tray collide")
	_expect(tray != null and is_equal_approx(tray.anchor_left, 0.12) and is_equal_approx(tray.anchor_right, 0.88), "Booster tray became navigation-width chrome")
	_expect(keeper_slot != null and not keeper_slot.visible and settings_slot != null and not settings_slot.visible, "Utilities leaked into booster family")
	_expect(shuffle != null and shuffle.disabled and shuffle.icon != null and shuffle.custom_minimum_size.y >= 108.0, "Shuffle booster truth/scale failed")
	_expect(hand != null and hand.disabled and hand.icon != null and hand.custom_minimum_size.y >= 108.0, "Hand booster truth/scale failed")
	_expect(magic != null and magic.disabled and magic.icon != null and magic.custom_minimum_size.y >= 108.0, "Magic booster truth/scale failed")
	_expect(shuffle_label != null and shuffle_label.text == "SHUFFLE", "Shuffle identity drifted")
	_expect(hand_label != null and hand_label.text == "HAND", "Hand identity drifted")
	_expect(magic_label != null and magic_label.text == "MAGIC", "Magic identity drifted")

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
