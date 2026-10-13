class_name Match3TopResourceBar
extends RefCounted

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const MobileSafeArea = preload("res://src/ui/shared/mobile_safe_area.gd")
const ResourceBarScene = preload("res://src/ui/shared/top_resource_bar.tscn")

static func attach(screen: Control, progress, profile_handler: Callable = Callable()) -> PanelContainer:
	if screen == null:
		return null
	var existing := screen.get_node_or_null("ResourceBar") as PanelContainer
	if existing != null:
		refresh(existing, progress)
		return existing

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

	var life_icon := panel.get_node_or_null("Resources/LifeResourceChip/Content/Icon") as TextureRect
	var coin_icon := panel.get_node_or_null("Resources/CoinResourceChip/Content/Icon") as TextureRect
	var gem_icon := panel.get_node_or_null("Resources/GemResourceChip/Content/Icon") as TextureRect
	if life_icon != null:
		life_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_heart.svg")
	if coin_icon != null:
		coin_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_coin.svg")
	if gem_icon != null:
		gem_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_gem.svg")
	var profile := panel.get_node_or_null("Resources/KeeperProfile") as Button
	if profile != null:
		profile.icon = PieceAssetLoader.ornament("res://assets/ui/ui_profile.svg")
	if profile != null:
		if profile_handler.is_valid():
			profile.visible = true
			profile.pressed.connect(profile_handler)
		else:
			profile.visible = false

	refresh(panel, progress)
	return panel

static func refresh(panel: PanelContainer, progress) -> void:
	if panel == null:
		return
	var lives := 0
	var coins := 0
	var gems := 0
	if progress != null:
		lives = maxi(0, int(progress.lives))
		coins = maxi(0, int(progress.coins))
		gems = maxi(0, int(progress.gems))
	var life := panel.find_child("LifeResource", true, false) as Label
	var coin := panel.find_child("CoinResource", true, false) as Label
	var gem := panel.find_child("GemResource", true, false) as Label
	if life != null:
		life.text = _format_number(lives)
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
	var life := panel.find_child("LifeResource", true, false) as Label
	var coin := panel.find_child("CoinResource", true, false) as Label
	var gem := panel.find_child("GemResource", true, false) as Label
	var life_icon := panel.get_node_or_null("Resources/LifeResourceChip/Content/Icon") as TextureRect
	var coin_icon := panel.get_node_or_null("Resources/CoinResourceChip/Content/Icon") as TextureRect
	var gem_icon := panel.get_node_or_null("Resources/GemResourceChip/Content/Icon") as TextureRect
	var profile := panel.get_node_or_null("Resources/KeeperProfile") as Button
	return {
		"authored_scene": true,
		"resource_slots_present": life != null and coin != null and gem != null,
		"icons_loaded": life_icon != null and life_icon.texture != null and coin_icon != null and coin_icon.texture != null and gem_icon != null and gem_icon.texture != null and profile != null and profile.icon != null,
		"profile_touch_target_ok": profile != null and profile.custom_minimum_size.x >= 88.0 and profile.custom_minimum_size.y >= 88.0,
		"north_star_resource_zone": (panel.offset_bottom - panel.offset_top) >= 96.0 and (panel.offset_bottom - panel.offset_top) <= 112.0 and life_icon != null and life_icon.custom_minimum_size.x >= 40.0 and coin_icon != null and coin_icon.custom_minimum_size.x >= 40.0 and gem_icon != null and gem_icon.custom_minimum_size.x >= 40.0,
		"resource_zone_height": panel.offset_bottom - panel.offset_top,
		"runtime_ui_factory": false,
	}

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
