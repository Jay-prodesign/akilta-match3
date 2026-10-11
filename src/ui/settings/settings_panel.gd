class_name Match3SettingsPanel
extends Control

signal close_requested

@onready var master_toggle: CheckButton = $Card/Content/Master
@onready var music_toggle: CheckButton = $Card/Content/Music
@onready var sfx_toggle: CheckButton = $Card/Content/SFX
@onready var haptics_toggle: CheckButton = $Card/Content/Haptics
@onready var reduced_toggle: CheckButton = $Card/Content/Reduced
@onready var contrast_toggle: CheckButton = $Card/Content/Contrast
@onready var close_button: Button = $Card/Content/Close

var settings

func _ready() -> void:
	_style_settings_overlay()
	close_button.pressed.connect(func(): close_requested.emit())
	master_toggle.toggled.connect(func(on): _set_setting("master_muted", not on))
	music_toggle.toggled.connect(func(on): _set_setting("music_muted", not on))
	sfx_toggle.toggled.connect(func(on): _set_setting("sfx_muted", not on))
	haptics_toggle.toggled.connect(func(on): _set_setting("haptics_enabled", on))
	reduced_toggle.toggled.connect(func(on): _set_setting("reduced_motion", on))
	contrast_toggle.toggled.connect(func(on): _set_setting("high_contrast", on))

func bind_settings(value) -> void:
	settings = value
	if not is_node_ready() or settings == null:
		return
	master_toggle.button_pressed = not bool(settings.get_value("master_muted", false))
	music_toggle.button_pressed = not bool(settings.get_value("music_muted", false))
	sfx_toggle.button_pressed = not bool(settings.get_value("sfx_muted", false))
	haptics_toggle.button_pressed = bool(settings.get_value("haptics_enabled", true))
	reduced_toggle.button_pressed = bool(settings.get_value("reduced_motion", false))
	contrast_toggle.button_pressed = bool(settings.get_value("high_contrast", false))

func _set_setting(key: String, value) -> void:
	if settings != null:
		settings.set_value(key, value)

func _style_settings_overlay() -> void:
	var card := get_node_or_null("Card") as PanelContainer
	if card != null:
		var panel := StyleBoxFlat.new()
		panel.bg_color = Color("#121322")
		panel.border_color = Color("#D5AD70", 0.82)
		panel.set_border_width_all(2)
		panel.set_corner_radius_all(18)
		panel.shadow_color = Color(0, 0, 0, 0.7)
		panel.shadow_size = 24
		card.add_theme_stylebox_override("panel", panel)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#512957")
	close_style.border_color = Color("#D5AD70")
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(10)
	var hover := close_style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#69366F")
	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_stylebox_override("hover", hover)
	close_button.add_theme_stylebox_override("pressed", hover)
	close_button.add_theme_color_override("font_color", Color("#F4E5D3"))
	close_button.add_theme_color_override("font_hover_color", Color("#F4E5D3"))
