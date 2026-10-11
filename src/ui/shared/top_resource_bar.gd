class_name Match3TopResourceBar
extends RefCounted

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

static func attach(screen: Control, progress, profile_handler: Callable = Callable()) -> PanelContainer:
	if screen == null:
		return null
	var existing := screen.get_node_or_null("ResourceBar") as PanelContainer
	if existing != null:
		refresh(existing, progress)
		return existing

	var panel := PanelContainer.new()
	panel.name = "ResourceBar"
	panel.anchor_left = 0.02
	panel.anchor_right = 0.98
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_top = 6.0
	panel.offset_bottom = 58.0
	panel.z_index = 60
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#08070D", 0.94)
	shell.border_color = Color("#D5AD70", 0.72)
	shell.set_border_width_all(1)
	shell.set_corner_radius_all(12)
	shell.shadow_color = Color(0, 0, 0, 0.46)
	shell.shadow_size = 8
	shell.content_margin_left = 6
	shell.content_margin_right = 6
	shell.content_margin_top = 4
	shell.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", shell)
	screen.add_child(panel)

	var row := HBoxContainer.new()
	row.name = "Resources"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)

	_add_chip(row, "LifeResource", "res://assets/ui/ui_heart.svg", "FULL")
	_add_chip(row, "CoinResource", "res://assets/ui/ui_coin.svg", "12,340")
	_add_chip(row, "GemResource", "res://assets/ui/ui_gem.svg", "520")

	var profile := Button.new()
	profile.name = "KeeperProfile"
	profile.text = ""
	profile.icon = PieceAssetLoader.ornament("res://assets/ui/ui_profile.svg")
	profile.expand_icon = true
	profile.add_theme_constant_override("icon_max_width", 30)
	profile.custom_minimum_size = Vector2(50, 40)
	profile.tooltip_text = "Keeper profile and settings"
	var profile_box := StyleBoxFlat.new()
	profile_box.bg_color = Color("#201526", 0.94)
	profile_box.border_color = Color("#D5AD70", 0.46)
	profile_box.set_border_width_all(1)
	profile_box.set_corner_radius_all(10)
	var profile_focus := profile_box.duplicate() as StyleBoxFlat
	profile_focus.bg_color = Color("#4A2C50", 0.98)
	profile_focus.border_color = Color("#F0CE8A")
	profile_focus.set_border_width_all(2)
	profile.add_theme_stylebox_override("normal", profile_box)
	profile.add_theme_stylebox_override("hover", profile_focus)
	profile.add_theme_stylebox_override("pressed", profile_focus)
	profile.add_theme_stylebox_override("focus", profile_focus)
	if profile_handler.is_valid():
		profile.pressed.connect(profile_handler)
	row.add_child(profile)

	refresh(panel, progress)
	return panel

static func refresh(panel: PanelContainer, progress) -> void:
	if panel == null:
		return
	var lives := 5
	var coins := 12340
	var gems := 520
	if progress != null:
		lives = clampi(int(progress.lives), 0, 5)
		coins = maxi(0, int(progress.coins))
		gems = maxi(0, int(progress.gems))
	var life := panel.find_child("LifeResource", true, false) as Label
	var coin := panel.find_child("CoinResource", true, false) as Label
	var gem := panel.find_child("GemResource", true, false) as Label
	if life != null:
		life.text = "FULL" if lives >= 5 else "%d / 5" % lives
	if coin != null:
		coin.text = _format_number(coins)
	if gem != null:
		gem.text = _format_number(gems)

static func _add_chip(parent: HBoxContainer, node_name: String, icon_path: String, value: String) -> void:
	var chip := PanelContainer.new()
	chip.name = node_name + "Chip"
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#15111B", 0.88)
	box.border_color = Color("#745C73", 0.38)
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = 5
	box.content_margin_right = 7
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	chip.add_theme_stylebox_override("panel", box)
	parent.add_child(chip)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	chip.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(27, 27)
	icon.texture = PieceAssetLoader.ornament(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var label := Label.new()
	label.name = node_name
	label.text = value
	label.add_theme_color_override("font_color", Color("#F7E9D6"))
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)

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
