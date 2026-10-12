extends SceneTree

const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []
var nav_action := ""
var profile_pressed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen := Control.new()
	screen.name = "ShellFixture"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.size = Vector2(1080, 1920)
	root.add_child(screen)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(layout)
	await process_frame

	var progress = ProgressScript.new()
	progress.lives = 5
	progress.coins = 12345
	progress.gems = 67

	var nav := ProductNavigation.attach(screen, "house", Callable(self, "_on_nav"), NodePath("Layout"))
	var bar := TopResourceBar.attach(screen, progress, Callable(self, "_on_profile"))
	await process_frame

	var nav_contract: Dictionary = ProductNavigation.authored_contract(nav)
	_expect(bool(nav_contract.get("authored_scene", false)), "ProductNavigation must instantiate an authored scene")
	_expect(bool(nav_contract.get("all_slots_present", false)), "ProductNavigation must expose all five authored destinations")
	_expect(bool(nav_contract.get("icons_loaded", false)), "ProductNavigation authored icons must load")
	_expect(bool(nav_contract.get("touch_targets_ok", false)), "ProductNavigation destinations must retain mobile touch targets")
	_expect(bool(nav_contract.get("compact_house_bar", false)), "ProductNavigation must retain the compact North Star house-bar proportion")
	_expect(not bool(nav_contract.get("runtime_ui_factory", true)), "ProductNavigation must not create persistent shell nodes at runtime")

	var house := nav.get_node_or_null("Scroll/Items/NavHouse") as Button
	var curios := nav.get_node_or_null("Scroll/Items/NavCurios") as Button
	_expect(house != null and house.disabled and String(house.get_meta("interaction_state", "")) == "selected", "Active House destination must be selected and non-reentrant")
	_expect(curios != null and not curios.disabled, "Inactive Curios destination must remain actionable")
	if curios != null:
		curios.emit_signal("pressed")
		await process_frame
	_expect(nav_action == "curios", "Authored ProductNavigation must preserve navigation handler semantics")

	var bar_contract: Dictionary = TopResourceBar.authored_contract(bar)
	_expect(bool(bar_contract.get("authored_scene", false)), "TopResourceBar must instantiate an authored scene")
	_expect(bool(bar_contract.get("resource_slots_present", false)), "TopResourceBar coin/gem slots missing")
	_expect(bool(bar_contract.get("icons_loaded", false)), "TopResourceBar authored icons must load")
	_expect(bool(bar_contract.get("profile_touch_target_ok", false)), "Keeper profile control must retain mobile touch target")
	_expect(not bool(bar_contract.get("runtime_ui_factory", true)), "TopResourceBar must not create persistent shell nodes at runtime")

	var life := bar.find_child("LifeResource", true, false) as Label
	var coin := bar.find_child("CoinResource", true, false) as Label
	var gem := bar.find_child("GemResource", true, false) as Label
	_expect(life != null and life.text == "FULL", "TopResourceBar must expose truthful life state")
	_expect(coin != null and coin.text == "12,345", "TopResourceBar must bind durable coin truth")
	_expect(gem != null and gem.text == "67", "TopResourceBar must bind durable gem truth")
	var profile := bar.get_node_or_null("Resources/KeeperProfile") as Button
	_expect(profile != null and profile.visible, "Keeper profile action must be visible when a handler exists")
	if profile != null:
		profile.emit_signal("pressed")
		await process_frame
	_expect(profile_pressed, "Keeper profile authored shell must preserve handler semantics")

	progress.lives = 3
	progress.coins = 222
	progress.gems = 9
	TopResourceBar.refresh(bar, progress)
	_expect(life.text == "3 / 5" and coin.text == "222" and gem.text == "9", "TopResourceBar refresh must update existing authored slots")

	screen.queue_free()
	await process_frame
	_finish()

func _on_nav(action: String) -> void:
	nav_action = action

func _on_profile() -> void:
	profile_pressed = true

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored global product shell")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
