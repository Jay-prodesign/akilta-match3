extends SceneTree

const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")

var failures: Array[String] = []
var settings_requested := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = GameplayScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var contract: Dictionary = screen.gameplay_presentation_contract()
	_expect(bool(contract.get("authored_hud_plate", false)), "Gameplay HUD plate must be authored in the scene tree")
	_expect(bool(contract.get("authored_resource_bar", false)), "Gameplay resource bar must be authored")
	_expect(bool(contract.get("authored_keeper_tray", false)), "ASK KEEPER tray must be authored")
	_expect(bool(contract.get("authored_booster_menu", false)), "Gameplay must expose the five-slot North Star lower utility/booster bar")
	_expect(bool(contract.get("north_star_resource_strip", false)), "Gameplay top resource strip must use the locked 80 logical px compact geometry")
	_expect(bool(contract.get("north_star_objective_strip", false)), "Gameplay target/moves strip must retain the locked North Star hierarchy")
	_expect(bool(contract.get("north_star_booster_tray", false)), "Gameplay lower booster tray must use the locked 160 logical px family with 88 px touch targets")
	_expect(bool(contract.get("hint_booster_clearance", false)), "Gameplay hint band must remain fully visible above the booster tray")
	_expect(bool(contract.get("booster_label_readability", false)), "Gameplay booster labels must retain a dedicated readable band inside the ornamental tray edge")
	_expect(bool(contract.get("deterministic_gameplay_geometry", false)), "Gameplay tray geometry must be authored rather than positioned by runtime magic")
	_expect(bool(contract.get("truthful_sealed_slots", false)), "Unavailable boosters must remain visibly sealed rather than pretending to be usable")
	_expect(bool(contract.get("authored_target_moves_hierarchy", false)), "Gameplay target and moves hierarchy must use authored production plates")
	_expect(bool(contract.get("authored_board_frame", false)), "Gameplay board must sit inside an authored ornamental frame")
	_expect(bool(contract.get("asset_backed_gameplay_chrome", false)), "Gameplay resource/HUD/booster surfaces must use authored asset-backed chrome")
	_expect(bool(contract.get("board_frame_asset_owner", false)), "Gameplay board frame must be owned by the raster-backed BoardView rather than a second code-drawn panel border")
	_expect(bool(contract.get("north_star_gameplay_geometry", false)), "Gameplay resource bar, target/moves HUD and lower tray must retain canonical North Star proportions")
	_expect(bool(contract.get("gameplay_header_clearance", false)), "Gameplay level/title stack must clear the resource bar at real mobile scale")
	_expect(bool(contract.get("compact_resource_chips", false)), "Gameplay coin/gem chips must stay compact instead of stretching into oversized blocks")
	_expect(bool(contract.get("asset_backed_resource_chips", false)), "Gameplay coin/gem/level chips must use verified compact production chrome")
	_expect(bool(contract.get("level_badge_separated", false)), "Gameplay level badge must remain a distinct right-side status chip")
	_expect(float(contract.get("resource_bar_height", 0.0)) >= 76.0, "Gameplay resource strip must not collapse into a tiny utility row")
	_expect(float(contract.get("hud_plate_height", 0.0)) >= 108.0, "Gameplay target/moves plate must keep its authored vertical hierarchy")
	_expect(float(contract.get("booster_tray_height", 0.0)) >= 132.0, "Gameplay lower tray must keep the canonical booster-zone height")
	_expect(bool(contract.get("authored_result_values", false)), "Terminal reward values must be authored")
	_expect(bool(contract.get("authored_result_proclamation", false)), "Terminal House proclamation must be authored")
	_expect(bool(contract.get("north_star_result_hierarchy", false)), "Terminal reward must retain a strong North Star completion hierarchy")
	_expect(bool(contract.get("north_star_result_cta", false)), "Terminal reward CTA must match the large rounded North Star action family")
	_expect(bool(contract.get("asset_backed_result_chrome", false)), "Terminal reward card must use the verified asset-backed production chrome family")
	_expect(bool(contract.get("result_hero_scale", false)), "Terminal reward Curio reveal must retain hero-scale vertical space")
	_expect(bool(contract.get("result_frame_clearance", false)), "Terminal reward copy must clear the ornamental top frame before the eyebrow")
	_expect(not bool(contract.get("runtime_shell_factory", true)), "Gameplay must not rebuild persistent presentation shell at runtime")

	var objective := screen.get_node_or_null("Layout/HUDPlate/HUD/Objective") as Label
	var moves := screen.get_node_or_null("Layout/HUDPlate/HUD/Moves") as Label
	var objective_icon := screen.get_node_or_null("Layout/HUDPlate/HUD/ObjectiveIcon") as TextureRect
	var keeper := screen.get_node_or_null("BoosterTray/BoosterActions/HintSlot/HintBoost") as Button
	var sealed_a := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotA/SealedBoostA") as Button
	var sealed_b := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotB/SealedBoostB") as Button
	var sealed_c := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotC/SealedBoostC") as Button
	var settings := screen.get_node_or_null("BoosterTray/BoosterActions/SettingsSlot/SettingsShortcut") as Button
	var keeper_label := screen.get_node_or_null("BoosterTray/BoosterActions/HintSlot/Label") as Label
	var settings_label := screen.get_node_or_null("BoosterTray/BoosterActions/SettingsSlot/Label") as Label
	var sealed_label := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotA/Label") as Label
	var keeper_slot := screen.get_node_or_null("BoosterTray/BoosterActions/HintSlot") as VBoxContainer
	_expect(objective != null and moves != null, "Authored HUD objective/moves slots missing")
	_expect(objective_icon != null and objective_icon.texture != null, "Authored objective plate must expose production objective art")
	_expect(objective != null and objective.text.begins_with("TARGET ·"), "Objective copy must read as a clear top target block")
	_expect(moves != null and moves.custom_minimum_size.x >= 240.0 and moves.custom_minimum_size.y >= 88.0, "Moves must retain a distinct right-side counter block")
	var resource_bar := screen.get_node_or_null("ResourceBar") as PanelContainer
	var coin_chip := screen.get_node_or_null("ResourceBar/Resources/CoinChip") as PanelContainer
	var gem_chip := screen.get_node_or_null("ResourceBar/Resources/GemChip") as PanelContainer
	var level_badge_plate := screen.get_node_or_null("ResourceBar/Resources/LevelBadgePlate") as PanelContainer
	var hud_plate := screen.get_node_or_null("Layout/HUDPlate") as PanelContainer
	var booster_tray := screen.get_node_or_null("BoosterTray") as PanelContainer
	_expect(resource_bar != null and resource_bar.offset_bottom - resource_bar.offset_top == 80.0, "Gameplay resource strip height drifted")
	var gameplay_layout := screen.get_node_or_null("Layout") as VBoxContainer
	_expect(gameplay_layout != null and gameplay_layout.offset_top - resource_bar.offset_bottom >= 56.0, "Gameplay title stack must preserve mobile header clearance")
	_expect(hud_plate != null and hud_plate.custom_minimum_size.y == 112.0, "Gameplay objective strip height drifted")
	_expect(booster_tray != null and booster_tray.offset_bottom - booster_tray.offset_top == 160.0 and is_equal_approx(booster_tray.anchor_top, 0.805), "Gameplay booster tray geometry drifted")
	var hint_band := screen.get_node_or_null("Layout/Hint") as Label
	_expect(hint_band != null and booster_tray.global_position.y >= hint_band.global_position.y + hint_band.size.y + 12.0, "Gameplay booster tray must not cover the hint band")
	_expect(resource_bar != null and resource_bar.get_theme_stylebox("panel") is StyleBoxTexture, "Gameplay resource strip must use production chrome")
	_expect(coin_chip != null and coin_chip.size.x <= 300.0 and coin_chip.get_theme_stylebox("panel") is StyleBoxTexture, "Gameplay coin chip must use compact asset-backed chrome")
	_expect(gem_chip != null and gem_chip.size.x <= 300.0 and gem_chip.get_theme_stylebox("panel") is StyleBoxTexture, "Gameplay gem chip must use compact asset-backed chrome")
	_expect(level_badge_plate != null and level_badge_plate.size.x <= 200.0 and level_badge_plate.get_theme_stylebox("panel") is StyleBoxTexture, "Gameplay level badge must use a compact asset-backed plate")
	_expect(hud_plate != null and hud_plate.get_theme_stylebox("panel") is StyleBoxTexture, "Gameplay objective/moves HUD must use production chrome")
	_expect(booster_tray != null and booster_tray.get_theme_stylebox("panel") is StyleBoxTexture, "Gameplay booster tray must use production chrome")
	_expect(keeper != null and keeper.custom_minimum_size.y >= 88.0 and keeper.icon != null, "ASK KEEPER must retain a mobile touch target and production familiar art")
	_expect(sealed_a != null and sealed_a.disabled and sealed_a.icon != null, "First future booster slot must be visibly sealed with production art")
	_expect(sealed_b != null and sealed_b.disabled and sealed_b.icon != null, "Second future booster slot must be visibly sealed with production art")
	_expect(sealed_c != null and sealed_c.disabled and sealed_c.icon != null, "Third future booster slot must be visibly sealed with production art")
	_expect(settings != null and settings.custom_minimum_size.y >= 88.0 and settings.icon != null, "Lower gameplay bar must expose a real Settings utility")
	_expect(keeper_label != null and keeper_label.custom_minimum_size.y >= 32.0 and keeper_label.get_theme_font_size("font_size") >= 22, "ASK KEEPER label must stay readable above the tray border")
	_expect(settings_label != null and settings_label.custom_minimum_size.y >= 32.0 and settings_label.get_theme_font_size("font_size") >= 22, "Settings label must stay readable above the tray border")
	_expect(sealed_label != null and sealed_label.custom_minimum_size.y >= 32.0 and sealed_label.get_theme_font_size("font_size") >= 18, "Sealed booster state must remain legible rather than disappearing into the tray border")
	_expect(keeper_slot != null and keeper_slot.size_flags_vertical == Control.SIZE_SHRINK_CENTER, "Booster slot stacks must shrink-center inside the tray instead of stretching labels through the ornamental border")

	screen.settings_requested.connect(func(): settings_requested = true)
	if settings != null:
		settings.emit_signal("pressed")
		await process_frame
	_expect(settings_requested, "Lower gameplay Settings utility must preserve navigation semantics")

	screen.set_player_resources(4, 1234, 7)
	await process_frame
	var coin := screen.get_node_or_null("ResourceBar/Resources/CoinChip/Content/CoinResource") as Label
	var gem := screen.get_node_or_null("ResourceBar/Resources/GemChip/Content/GemResource") as Label
	var coin_icon := screen.get_node_or_null("ResourceBar/Resources/CoinChip/Content/Icon") as TextureRect
	var gem_icon := screen.get_node_or_null("ResourceBar/Resources/GemChip/Content/Icon") as TextureRect
	_expect(coin != null and coin.text == "1,234", "Authored gameplay coin slot must bind durable resource truth")
	_expect(gem != null and gem.text == "7", "Authored gameplay gem slot must bind durable resource truth")
	_expect(coin_icon != null and coin_icon.texture != null and gem_icon != null and gem_icon.texture != null, "Authored gameplay resource icons must load")

	var reward_values := screen.get_node_or_null("ResultOverlay/Card/Content/ResultRewardValues") as HBoxContainer
	var keeper_cat := screen.get_node_or_null("ResultOverlay/Card/Content/ResultProclamation/KeeperCat") as TextureRect
	_expect(reward_values != null and reward_values.get_child_count() == 2, "Authored result values must preserve coin and gem reward slots")
	var result_action := screen.get_node_or_null("ResultOverlay/Card/Content/Action") as Button
	var result_objective := screen.get_node_or_null("ResultOverlay/Card/Content/ObjectiveSummary") as Label
	_expect(result_action != null and result_action.custom_minimum_size.y >= 82.0, "Result primary action must retain the North Star mobile CTA scale")
	_expect(result_objective != null and result_objective.get_theme_stylebox("normal") != null, "Result objective completion must sit on an authored plate")
	_expect(keeper_cat != null and keeper_cat.texture != null, "Authored terminal proclamation must use Keeper production art")

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
