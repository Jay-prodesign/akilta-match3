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
	close_button.pressed.connect(func(): close_requested.emit())
	master_toggle.toggled.connect(func(on): _set("master_muted", not on))
	music_toggle.toggled.connect(func(on): _set("music_muted", not on))
	sfx_toggle.toggled.connect(func(on): _set("sfx_muted", not on))
	haptics_toggle.toggled.connect(func(on): _set("haptics_enabled", on))
	reduced_toggle.toggled.connect(func(on): _set("reduced_motion", on))
	contrast_toggle.toggled.connect(func(on): _set("high_contrast", on))

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

func _set(key: String, value) -> void:
	if settings != null:
		settings.set_value(key, value)
