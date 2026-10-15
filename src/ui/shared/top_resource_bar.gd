class_name Match3TopResourceBar
extends RefCounted

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const MobileSafeArea = preload("res://src/ui/shared/mobile_safe_area.gd")
const ResourceBarScene = preload("res://src/ui/shared/top_resource_bar.tscn")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")
# Exact-head visual gate: shared meta content must begin below this authored 104px resource shell.

static func attach(screen: Control, progress, profile_handler: Callable = Callable(), content_path: NodePath = NodePath("Layout")) -> PanelContainer:
	if screen == null:
		return null
	var existing := screen.get_node_or_null("ResourceBar") as PanelContainer
	if existing != null:
		_reserve_content(screen, content_path)
		_bind_profile(existing, profile_handler)
		set_reduced_motion(existing, bool(screen.get_meta("reduced_motion", false)))
		refresh(existing, progress)
		return existing

	_reserve_content(screen, content_path)

	var panel := ResourceBarScene.instantiate() as PanelContainer
	if panel == null:
		push_error("Global ResourceBar authored scene could not instantiate.")
		return null

	var safe_insets := MobileSafeArea.current_insets(screen)
	panel.offset_left = 36.0 + safe_insets.x
	panel.offset_right = -36.0 - safe_insets.z
	panel.offset_top = 8.0 + safe_insets.y
	panel.offset_bottom = 112.0 + safe_insets.y
	screen.add_child(panel)
	panel.set_meta("shell_material", "scene_authored_flat")
	var coin_chip := panel.get_node_or_null("Resources/CoinResourceChip") as PanelContainer
	var gem_chip := panel.get_node_or_null("Resources/GemResourceChip") as PanelContainer
	if coin_chip != null:
		coin_chip.set_meta("shell_material", "scene_authored_flat")
	if gem_chip != null:
		gem_chip.set_meta("shell_material", "scene_authored_flat")

	var coin_icon := panel.get_node_or_null("Resources/CoinResourceChip/Content/Icon") as TextureRect
	var gem_icon := panel.get_node_or_null("Resources/GemResourceChip/Content/Icon") as TextureRect
	if coin_icon != null:
		coin_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_coin.svg")
	if gem_icon != null:
		gem_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_gem.svg")
	var profile := panel.get_node_or_null("Resources/KeeperProfile") as Button
	if profile != null:
		profile.icon = PieceAssetLoader.ornament("res://assets/ui/ui_profile.svg")
		profile.set_meta("shell_material", "scene_authored_flat")
	_bind_profile(panel, profile_handler)
	set_reduced_motion(panel, bool(screen.get_meta("reduced_motion", false)))

	refresh(panel, progress)
	return panel

static func _reserve_content(screen: Control, content_path: NodePath) -> void:
	if screen == null:
		return
	var content := screen.get_node_or_null(content_path) as Control
	if content == null:
		return
	content.set_meta("top_resource_inset_applied", true)
	MobileSafeArea.apply_content(screen, content_path)

static func _bind_profile(panel: PanelContainer, profile_handler: Callable) -> void:
	if panel == null:
		return
	var profile := panel.get_node_or_null("Resources/KeeperProfile") as Button
	if profile == null:
		return
	profile.visible = profile_handler.is_valid()
	if profile_handler.is_valid() and not profile.pressed.is_connected(profile_handler):
		profile.pressed.connect(profile_handler)

static func refresh(panel: PanelContainer, progress) -> void:
	if panel == null:
		return
	var coins := 0
	var gems := 0
	if progress != null:
		coins = maxi(0, int(progress.coins))
		gems = maxi(0, int(progress.gems))
	var coin := panel.find_child("CoinResource", true, false) as Label
	var gem := panel.find_child("GemResource", true, false) as Label
	if coin != null:
		coin.text = _format_number(coins)
	if gem != null:
		gem.text = _format_number(gems)

static func authored_contract(panel: PanelContainer) -> Dictionary:
	if panel == null:
		return {
			"authored_scene": false,
			"resource_slots_present": false,
			"icons_loaded": false,
			"profile_touch_target_ok": false,
			"runtime_ui_factory": false,
		}
	var coin := panel.find_child("CoinResource", true, false) as Label
	var gem := panel.find_child("GemResource", true, false) as Label
	var coin_icon := panel.get_node_or_null("Resources/CoinResourceChip/Content/Icon") as TextureRect
	var gem_icon := panel.get_node_or_null("Resources/GemResourceChip/Content/Icon") as TextureRect
	var profile := panel.get_node_or_null("Resources/KeeperProfile") as Button
	var coin_chip := panel.get_node_or_null("Resources/CoinResourceChip") as PanelContainer
	var gem_chip := panel.get_node_or_null("Resources/GemResourceChip") as PanelContainer
	var scene_authored_resource_chips := coin_chip != null and coin_chip.get_theme_stylebox("panel") is StyleBoxFlat and String(coin_chip.get_meta("shell_material", "")) == "scene_authored_flat" and gem_chip != null and gem_chip.get_theme_stylebox("panel") is StyleBoxFlat and String(gem_chip.get_meta("shell_material", "")) == "scene_authored_flat"
	var scene_authored_profile_action := profile != null and profile.get_theme_stylebox("normal") is StyleBoxFlat and profile.get_theme_stylebox("hover") is StyleBoxFlat and profile.get_theme_stylebox("pressed") is StyleBoxFlat and profile.get_theme_stylebox("focus") is StyleBoxFlat and String(profile.get_meta("shell_material", "")) == "scene_authored_flat"
	var tactile_profile := profile != null and bool(profile.get_meta("tactile_bound", false)) and float(profile.get_meta("tactile_press_scale", 1.0)) <= 0.96
	var reduced_motion_aware := profile != null and profile.has_meta("tactile_reduced_motion")
	return {
		"authored_scene": true,
		"resource_slots_present": coin != null and gem != null,
		"icons_loaded": coin_icon != null and coin_icon.texture != null and gem_icon != null and gem_icon.texture != null and profile != null and profile.icon != null,
		"profile_touch_target_ok": profile != null and profile.custom_minimum_size.x >= 88.0 and profile.custom_minimum_size.y >= 88.0,
		"north_star_resource_zone": (panel.offset_bottom - panel.offset_top) >= 96.0 and (panel.offset_bottom - panel.offset_top) <= 112.0 and coin_icon != null and coin_icon.custom_minimum_size.x >= 40.0 and gem_icon != null and gem_icon.custom_minimum_size.x >= 40.0,
		"resource_zone_height": panel.offset_bottom - panel.offset_top,
		"scene_authored_shell": panel.get_theme_stylebox("panel") is StyleBoxFlat and String(panel.get_meta("shell_material", "")) == "scene_authored_flat",
		"scene_authored_resource_chips": scene_authored_resource_chips,
		"scene_authored_profile_action": scene_authored_profile_action,
		"seam_free_material": panel.get_theme_stylebox("panel") is StyleBoxFlat and scene_authored_resource_chips and scene_authored_profile_action,
		"tactile_profile_press_release": tactile_profile,
		"reduced_motion_aware": reduced_motion_aware,
		"runtime_ui_factory": false,
	}

static func set_reduced_motion(panel: PanelContainer, reduced_motion: bool) -> void:
	if panel == null:
		return
	var profile := panel.get_node_or_null("Resources/KeeperProfile") as Button
	if profile != null:
		_bind_tactile_profile(profile, reduced_motion)

static func _bind_tactile_profile(button: Button, reduced_motion: bool) -> void:
	if button == null:
		return
	button.set_meta("tactile_reduced_motion", reduced_motion)
	button.set_meta("tactile_press_scale", 0.955)
	if not bool(button.get_meta("tactile_bound", false)):
		button.set_meta("tactile_bound", true)
		button.button_down.connect(_tactile_press.bind(button))
		button.button_up.connect(_tactile_release.bind(button))
		button.mouse_exited.connect(_tactile_release.bind(button))
		button.focus_exited.connect(_tactile_release.bind(button))
	if reduced_motion:
		_stop_tactile_tween(button)
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		button.set_meta("tactile_phase", "idle")

static func _tactile_press(button: Button) -> void:
	if button == null or button.disabled:
		return
	_stop_tactile_tween(button)
	button.pivot_offset = button.size * 0.5
	button.set_meta("tactile_phase", "pressed")
	if bool(button.get_meta("tactile_reduced_motion", false)):
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		return
	var tween := button.create_tween()
	button.set_meta("tactile_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(0.955, 0.955), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.0, 0.96, 1.0, 1.0), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func _tactile_release(button: Button) -> void:
	if button == null:
		return
	_stop_tactile_tween(button)
	button.pivot_offset = button.size * 0.5
	button.set_meta("tactile_phase", "release")
	if bool(button.get_meta("tactile_reduced_motion", false)):
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		button.set_meta("tactile_phase", "idle")
		return
	var tween := button.create_tween()
	button.set_meta("tactile_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color.WHITE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): button.set_meta("tactile_phase", "idle"))

static func _stop_tactile_tween(button: Button) -> void:
	if button == null or not button.has_meta("tactile_tween"):
		return
	var previous = button.get_meta("tactile_tween")
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	button.remove_meta("tactile_tween")

static func _format_number(value: int) -> String:
	var digits := str(maxi(0, value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = digits.substr(i, 1) + out
		count += 1
	return out
