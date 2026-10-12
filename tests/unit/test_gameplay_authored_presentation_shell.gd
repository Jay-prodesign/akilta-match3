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
	_expect(bool(contract.get("truthful_sealed_slots", false)), "Unavailable boosters must remain visibly sealed rather than pretending to be usable")
	_expect(bool(contract.get("authored_target_moves_hierarchy", false)), "Gameplay target and moves hierarchy must use authored production plates")
	_expect(bool(contract.get("authored_board_frame", false)), "Gameplay board must sit inside an authored ornamental frame")
	_expect(bool(contract.get("authored_result_values", false)), "Terminal reward values must be authored")
	_expect(bool(contract.get("authored_result_proclamation", false)), "Terminal House proclamation must be authored")
	_expect(bool(contract.get("north_star_result_hierarchy", false)), "Terminal reward must retain a strong North Star completion hierarchy")
	_expect(bool(contract.get("north_star_result_cta", false)), "Terminal reward CTA must match the large rounded North Star action family")
	_expect(not bool(contract.get("runtime_shell_factory", true)), "Gameplay must not rebuild persistent presentation shell at runtime")

	var objective := screen.get_node_or_null("Layout/HUDPlate/HUD/Objective") as Label
	var moves := screen.get_node_or_null("Layout/HUDPlate/HUD/Moves") as Label
	var objective_icon := screen.get_node_or_null("Layout/HUDPlate/HUD/ObjectiveIcon") as TextureRect
	var keeper := screen.get_node_or_null("BoosterTray/BoosterActions/HintSlot/HintBoost") as Button
	var sealed_a := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotA/SealedBoostA") as Button
	var sealed_b := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotB/SealedBoostB") as Button
	var sealed_c := screen.get_node_or_null("BoosterTray/BoosterActions/SealedSlotC/SealedBoostC") as Button
	var settings := screen.get_node_or_null("BoosterTray/BoosterActions/SettingsSlot/SettingsShortcut") as Button
	_expect(objective != null and moves != null, "Authored HUD objective/moves slots missing")
	_expect(objective_icon != null and objective_icon.texture != null, "Authored objective plate must expose production objective art")
	_expect(objective != null and objective.text.begins_with("TARGET ·"), "Objective copy must read as a clear top target block")
	_expect(moves != null and moves.custom_minimum_size.x >= 200.0, "Moves must retain a distinct right-side counter block")
	_expect(keeper != null and keeper.custom_minimum_size.y >= 60.0 and keeper.icon != null, "ASK KEEPER must retain a mobile touch target and production familiar art")
	_expect(sealed_a != null and sealed_a.disabled and sealed_a.icon != null, "First future booster slot must be visibly sealed with production art")
	_expect(sealed_b != null and sealed_b.disabled and sealed_b.icon != null, "Second future booster slot must be visibly sealed with production art")
	_expect(sealed_c != null and sealed_c.disabled and sealed_c.icon != null, "Third future booster slot must be visibly sealed with production art")
	_expect(settings != null and settings.custom_minimum_size.y >= 60.0 and settings.icon != null, "Lower gameplay bar must expose a real Settings utility")

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
