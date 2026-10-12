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
	_expect(bool(contract.get("authored_hud_plate", false)), "Gameplay HUD plate must be authored in the scene tree")
	_expect(bool(contract.get("authored_resource_bar", false)), "Gameplay resource bar must be authored")
	_expect(bool(contract.get("authored_keeper_tray", false)), "ASK KEEPER tray must be authored")
	_expect(bool(contract.get("authored_result_values", false)), "Terminal reward values must be authored")
	_expect(bool(contract.get("authored_result_proclamation", false)), "Terminal House proclamation must be authored")
	_expect(not bool(contract.get("runtime_shell_factory", true)), "Gameplay must not rebuild persistent presentation shell at runtime")

	var objective := screen.get_node_or_null("Layout/HUDPlate/HUD/Objective") as Label
	var moves := screen.get_node_or_null("Layout/HUDPlate/HUD/Moves") as Label
	var keeper := screen.get_node_or_null("BoosterTray/BoosterActions/HintBoost") as Button
	_expect(objective != null and moves != null, "Authored HUD objective/moves slots missing")
	_expect(keeper != null and keeper.custom_minimum_size.y >= 56.0 and keeper.icon != null, "ASK KEEPER must retain a mobile touch target and production familiar art")

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
