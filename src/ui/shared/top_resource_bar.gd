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
	ProductionChrome.apply_shell(panel, "top")
	var coin_chip := panel.get_node_or_null("Resources/CoinResourceChip") as PanelContainer
	var gem_chip := panel.get_node_or_null("Resources/GemResourceChip") as PanelContainer
	ProductionChrome.apply_compact_panel(coin_chip, "coin_resource")
	ProductionChrome.apply_compact_panel(gem_chip, "gem_resource")

	var coin_icon := panel.get_node_or_null("Resources/CoinResourceChip/Content/Icon") as TextureRect
	var gem_icon := panel.get_node_or_null("Resources/GemResourceChip/Content/Icon") as TextureRect
	if coin_icon != null:
		coin_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_coin.svg")
	if gem_icon != null:
		gem_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_gem.svg")
	var profile := panel.get_node_or_null("Resources/KeeperProfile") as Button
	if profile != null:
		profile.icon = PieceAssetLoader.ornament("res://assets/ui/ui_profile.svg")
		ProductionChrome.apply_interactive_button(profile, false, "keeper_profile")
	_bind_profile(panel, profile_handler)

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
	var asset_backed_resource_chips := coin_chip != null and coin_chip.get_theme_stylebox("panel") is StyleBoxTexture and gem_chip != null and gem_chip.get_theme_stylebox("panel") is StyleBoxTexture
	var asset_backed_profile_action := profile != null and profile.get_theme_stylebox("normal") is StyleBoxTexture and profile.get_theme_stylebox("hover") is StyleBoxTexture and profile.get_theme_stylebox("pressed") is StyleBoxTexture and profile.get_theme_stylebox("focus") is StyleBoxTexture
	return {
		"authored_scene": true,
		"resource_slots_present": coin != null and gem != null,
		"icons_loaded": coin_icon != null and coin_icon.texture != null and gem_icon != null and gem_icon.texture != null and profile != null and profile.icon != null,
		"profile_touch_target_ok": profile != null and profile.custom_minimum_size.x >= 88.0 and profile.custom_minimum_size.y >= 88.0,
		"north_star_resource_zone": (panel.offset_bottom - panel.offset_top) >= 96.0 and (panel.offset_bottom - panel.offset_top) <= 112.0 and coin_icon != null and coin_icon.custom_minimum_size.x >= 40.0 and gem_icon != null and gem_icon.custom_minimum_size.x >= 40.0,
		"resource_zone_height": panel.offset_bottom - panel.offset_top,
		"asset_backed_shell": panel.get_theme_stylebox("panel") is StyleBoxTexture and String(panel.get_meta("production_chrome_kind", "")) == "top",
		"quiet_shell": String(panel.get_meta("production_chrome_asset", "")) == ProductionChrome.QUIET_PANEL_PATH,
		"asset_backed_resource_chips": asset_backed_resource_chips,
		"asset_backed_profile_action": asset_backed_profile_action and String(profile.get_meta("production_chrome_kind", "")) == "interactive_keeper_profile",
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
