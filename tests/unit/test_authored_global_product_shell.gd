extends SceneTree

const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const ProgressScript = preload("res://src/progression/player_progress.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

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
	progress.coins = 12345
	progress.gems = 67

	var bar := TopResourceBar.attach(screen, progress, Callable(), NodePath("Layout"))
	var profile_before_upgrade := bar.get_node_or_null("Resources/KeeperProfile") as Button
	_expect(profile_before_upgrade != null and not profile_before_upgrade.visible, "TopResourceBar without a profile handler must keep the profile utility hidden")
	var upgraded_bar := TopResourceBar.attach(screen, progress, Callable(self, "_on_profile"), NodePath("Layout"))
	_expect(upgraded_bar == bar, "TopResourceBar must upgrade the authored instance instead of duplicating it")
	var nav := ProductNavigation.attach(screen, "house", Callable(self, "_on_nav"), NodePath("Layout"))
	await process_frame

	var nav_contract: Dictionary = ProductNavigation.authored_contract(nav)
	_expect(bool(nav_contract.get("authored_scene", false)), "ProductNavigation must instantiate an authored scene")
	_expect(bool(nav_contract.get("all_slots_present", false)), "ProductNavigation must expose all five authored destinations")
	_expect(bool(nav_contract.get("icons_loaded", false)), "ProductNavigation authored icons must load")
	_expect(bool(nav_contract.get("touch_targets_ok", false)), "ProductNavigation destinations must retain mobile touch targets")
	_expect(bool(nav_contract.get("north_star_nav_zone", false)), "ProductNavigation must occupy the canonical 128–144 logical px North Star navigation zone")
	_expect(float(nav_contract.get("nav_zone_height", 0.0)) == 136.0, "ProductNavigation authored baseline height must be 136 logical px")
	_expect(bool(nav_contract.get("scene_authored_shell", false)), "ProductNavigation shell must preserve its clean authored scene material")
	_expect(bool(nav_contract.get("scene_authored_interactive_chrome", false)), "ProductNavigation destination states must preserve authored normal/pressed/selected materials")
	_expect(bool(nav_contract.get("seam_free_material", false)), "ProductNavigation must not stretch the shared 9-slice chrome across the global shell")
	_expect(bool(nav_contract.get("tactile_press_release", false)), "ProductNavigation destinations must own a visible press/release scale response")
	_expect(bool(nav_contract.get("reduced_motion_aware", false)), "ProductNavigation tactile response must respect Reduced Motion")
	var global_icon_sources := [
		"res://assets/ui/nav_house.svg",
		"res://assets/ui/nav_curios.svg",
		"res://assets/ui/nav_map.svg",
		"res://assets/ui/nav_events.svg",
		"res://assets/ui/nav_shop.svg",
		"res://assets/ui/ui_coin.svg",
		"res://assets/ui/ui_gem.svg",
		"res://assets/ui/ui_profile.svg",
		"res://assets/ui/ui_settings.svg",
	]
	for source_path in global_icon_sources:
		var icon_texture := PieceAssetLoader.ornament(source_path)
		var resolved_path := PieceAssetLoader.resolved_path(source_path)
		_expect(icon_texture != null, "Global functional icon must load: %s" % source_path)
		_expect(resolved_path.ends_with(".webp"), "Global functional icon must resolve to authored raster WebP before SVG fallback: %s -> %s" % [source_path, resolved_path])
		_expect(icon_texture != null and icon_texture.get_width() == 128 and icon_texture.get_height() == 128, "Global functional icon must keep the locked 128x128 raster master: %s" % source_path)
	_expect(not bool(nav_contract.get("runtime_ui_factory", true)), "ProductNavigation must not create persistent shell nodes at runtime")

	var house := nav.get_node_or_null("Scroll/Items/NavHouse") as Button
	var curios := nav.get_node_or_null("Scroll/Items/NavCurios") as Button
	_expect(house != null and house.disabled and String(house.get_meta("interaction_state", "")) == "selected", "Active House destination must be selected and non-reentrant")
	_expect(curios != null and not curios.disabled, "Inactive Curios destination must remain actionable")
	if curios != null:
		curios.emit_signal("button_down")
		await create_timer(0.08).timeout
		_expect(curios.scale.x < 0.98 and curios.scale.y < 0.98, "Inactive shell destination must visibly compress on press")
		curios.emit_signal("button_up")
		await create_timer(0.20).timeout
		_expect(absf(curios.scale.x - 1.0) < 0.01 and absf(curios.scale.y - 1.0) < 0.01, "Shell destination must spring cleanly back on release")
		ProductNavigation.set_reduced_motion(nav, true)
		curios.emit_signal("button_down")
		await create_timer(0.08).timeout
		_expect(absf(curios.scale.x - 1.0) < 0.001 and absf(curios.scale.y - 1.0) < 0.001, "Reduced Motion must suppress ProductNavigation transform animation")
		curios.emit_signal("button_up")
		ProductNavigation.set_reduced_motion(nav, false)
		curios.emit_signal("pressed")
		await process_frame
	_expect(nav_action == "curios", "Authored ProductNavigation must preserve navigation handler semantics")

	var bar_contract: Dictionary = TopResourceBar.authored_contract(bar)
	_expect(bool(bar_contract.get("authored_scene", false)), "TopResourceBar must instantiate an authored scene")
	_expect(bool(bar_contract.get("resource_slots_present", false)), "TopResourceBar coin/gem slots missing")
	_expect(bool(bar_contract.get("icons_loaded", false)), "TopResourceBar authored icons must load")
	_expect(bool(bar_contract.get("profile_touch_target_ok", false)), "Keeper profile control must retain the 88 logical px mobile touch target")
	_expect(bool(bar_contract.get("north_star_resource_zone", false)), "TopResourceBar must occupy the canonical 96–112 logical px resource zone")
	_expect(float(bar_contract.get("resource_zone_height", 0.0)) == 104.0, "TopResourceBar authored baseline height must be 104 logical px")
	_expect(bool(bar_contract.get("scene_authored_shell", false)), "TopResourceBar shell must preserve its clean authored scene material")
	_expect(bool(bar_contract.get("scene_authored_resource_chips", false)), "TopResourceBar resource chips must preserve their authored scene material")
	_expect(bool(bar_contract.get("scene_authored_profile_action", false)), "TopResourceBar Keeper profile states must preserve authored normal/pressed/focus material")
	_expect(bool(bar_contract.get("seam_free_material", false)), "TopResourceBar must not stretch the shared 9-slice chrome across resource chips")
	_expect(bool(bar_contract.get("tactile_profile_press_release", false)), "Keeper profile action must own a visible press/release response")
	_expect(bool(bar_contract.get("reduced_motion_aware", false)), "Keeper profile tactile response must respect Reduced Motion")
	_expect(layout.offset_top >= 128.0, "TopResourceBar must reserve the canonical top content start instead of covering screen titles")
	_expect(layout.offset_bottom <= -152.0, "ProductNavigation must preserve the canonical bottom content reserve")
	_expect(bar.find_child("LifeResource", true, false) == null, "Shared resource bar must not expose unimplemented life economy")
	_expect(bar.get_node_or_null("Resources/LifeResourceChip") == null, "Shared resource bar must not retain a hidden life-economy chip")
	_expect(not bool(bar_contract.get("runtime_ui_factory", true)), "TopResourceBar must not create persistent shell nodes at runtime")

	var coin := bar.find_child("CoinResource", true, false) as Label
	var gem := bar.find_child("GemResource", true, false) as Label
	_expect(coin != null and coin.text == "12,345", "TopResourceBar must bind durable coin truth")
	_expect(gem != null and gem.text == "67", "TopResourceBar must bind durable gem truth")
	var profile := bar.get_node_or_null("Resources/KeeperProfile") as Button
	_expect(profile != null and profile.visible, "Keeper profile action must be visible when a handler exists")
	if profile != null:
		profile.emit_signal("button_down")
		await create_timer(0.08).timeout
		_expect(profile.scale.x < 0.98 and profile.scale.y < 0.98, "Keeper profile must visibly compress on press")
		profile.emit_signal("button_up")
		await create_timer(0.20).timeout
		_expect(absf(profile.scale.x - 1.0) < 0.01 and absf(profile.scale.y - 1.0) < 0.01, "Keeper profile must spring cleanly back on release")
		TopResourceBar.set_reduced_motion(bar, true)
		profile.emit_signal("button_down")
		await create_timer(0.08).timeout
		_expect(absf(profile.scale.x - 1.0) < 0.001 and absf(profile.scale.y - 1.0) < 0.001, "Reduced Motion must suppress Keeper profile transform animation")
		profile.emit_signal("button_up")
		TopResourceBar.set_reduced_motion(bar, false)
		profile.emit_signal("pressed")
		await process_frame
	_expect(profile_pressed, "Keeper profile authored shell must preserve handler semantics")

	progress.coins = 222
	progress.gems = 9
	TopResourceBar.refresh(bar, progress)
	_expect(coin.text == "222" and gem.text == "9", "TopResourceBar refresh must update all authored resource slots")

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
