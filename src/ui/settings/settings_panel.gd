class_name Match3SettingsPanel
extends Control

signal close_requested
signal interaction_feedback_requested(kind: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")

@export var card_normal_style: StyleBoxFlat
@export var card_high_style: StyleBoxFlat
@export var toggle_normal_style: StyleBoxFlat
@export var toggle_hover_style: StyleBoxFlat
@export var toggle_pressed_style: StyleBoxFlat
@export var toggle_high_style: StyleBoxFlat
@export var toggle_high_hover_style: StyleBoxFlat
@export var toggle_high_pressed_style: StyleBoxFlat
@export var close_normal_style: StyleBoxFlat
@export var close_hover_style: StyleBoxFlat
@export var close_pressed_style: StyleBoxFlat
@export var close_high_style: StyleBoxFlat


@onready var master_toggle: CheckButton = $Card/Content/Master
@onready var music_toggle: CheckButton = $Card/Content/Music
@onready var sfx_toggle: CheckButton = $Card/Content/SFX
@onready var haptics_toggle: CheckButton = $Card/Content/Haptics
@onready var reduced_toggle: CheckButton = $Card/Content/Reduced
@onready var contrast_toggle: CheckButton = $Card/Content/Contrast
@onready var close_button: Button = $Card/Content/Close
@onready var saved_note: Label = $Card/Content/SavedNote
@onready var house_sigil: TextureRect = $Card/Content/HouseSigil
@onready var world_art: TextureRect = $WorldArt

var settings
var _binding_controls := false
var _high_contrast := false

func _ready() -> void:
	world_art.texture = ScreenArt.texture("settings_bg_curio_house")
	house_sigil.texture = PieceAssetLoader.ornament("res://assets/pieces/moon_sigil.webp")
	_style_settings_overlay()
	close_button.pressed.connect(_on_close_pressed)
	master_toggle.toggled.connect(func(on): _on_toggle("master_muted", not on))
	music_toggle.toggled.connect(func(on): _on_toggle("music_muted", not on))
	sfx_toggle.toggled.connect(func(on): _on_toggle("sfx_muted", not on))
	haptics_toggle.toggled.connect(func(on): _on_toggle("haptics_enabled", on))
	reduced_toggle.toggled.connect(func(on): _on_toggle("reduced_motion", on))
	contrast_toggle.toggled.connect(func(on): _on_toggle("high_contrast", on))

func bind_settings(value) -> void:
	settings = value
	if not is_node_ready() or settings == null:
		return
	saved_note.text = "CHANGES SAVE ON THIS DEVICE"
	_binding_controls = true
	master_toggle.button_pressed = not bool(settings.get_value("master_muted", false))
	music_toggle.button_pressed = not bool(settings.get_value("music_muted", false))
	sfx_toggle.button_pressed = not bool(settings.get_value("sfx_muted", false))
	haptics_toggle.button_pressed = bool(settings.get_value("haptics_enabled", true))
	reduced_toggle.button_pressed = bool(settings.get_value("reduced_motion", false))
	contrast_toggle.button_pressed = bool(settings.get_value("high_contrast", false))
	_binding_controls = false
	_refresh_toggle_copy()
	apply_presentation_settings(settings.get_presentation_state())

func _on_toggle(key: String, value) -> void:
	if _binding_controls:
		return
	interaction_feedback_requested.emit("ui")
	_set_setting(key, value)
	_refresh_toggle_copy()

func _on_close_pressed() -> void:
	interaction_feedback_requested.emit("ui")
	close_requested.emit()

func _set_setting(key: String, value) -> void:
	if settings == null:
		return
	var label := key.replace("_", " ").to_upper()
	if settings.set_value(key, value):
		saved_note.text = "SAVED ON THIS DEVICE ✓ · %s UPDATED" % label
		saved_note.add_theme_color_override("font_color", Color("#D5AD70") if not _high_contrast else Color("#FFF1B6"))
	else:
		saved_note.text = "COULD NOT SAVE · TRY AGAIN"
		saved_note.add_theme_color_override("font_color", Color("#FFB4B4"))

func set_return_context(context: String) -> void:
	if not is_node_ready():
		await ready
	match context:
		"profile_settings":
			close_button.text = "RETURN TO PROFILE"
		"gameplay":
			close_button.text = "RETURN TO LEVEL"
		_:
			close_button.text = "RETURN TO HOUSE"

func apply_presentation_settings(state: Dictionary) -> void:
	_high_contrast = bool(state.get("high_contrast", false))
	_style_settings_overlay()
	_refresh_toggle_copy()

func state_contract() -> Dictionary:
	return {
		"bound": settings != null,
		"high_contrast": _high_contrast,
		"touch_targets_ok": [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle, close_button].all(func(control): return control.custom_minimum_size.y >= 88.0),
		"save_feedback": saved_note.text,
		"return_cta": close_button.text,
	}

func _refresh_toggle_copy() -> void:
	if not is_node_ready():
		return
	master_toggle.text = "Master audio · %s" % ("ON" if master_toggle.button_pressed else "OFF")
	music_toggle.text = "Music · %s" % ("ON" if music_toggle.button_pressed else "OFF")
	sfx_toggle.text = "Ritual sounds · %s" % ("ON" if sfx_toggle.button_pressed else "OFF")
	haptics_toggle.text = "Haptics · %s" % ("ON" if haptics_toggle.button_pressed else "OFF")
	reduced_toggle.text = "Reduced motion · %s" % ("ON" if reduced_toggle.button_pressed else "OFF")
	contrast_toggle.text = "High contrast · %s" % ("ON" if contrast_toggle.button_pressed else "OFF")

func _style_settings_overlay() -> void:
	var card := get_node_or_null("Card") as PanelContainer
	if card != null:
		card.add_theme_stylebox_override("panel", card_high_style if _high_contrast else card_normal_style)
	for toggle in [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle]:
		_style_toggle(toggle)
	close_button.add_theme_stylebox_override("normal", close_high_style if _high_contrast else close_normal_style)
	close_button.add_theme_stylebox_override("hover", close_hover_style)
	close_button.add_theme_stylebox_override("pressed", close_pressed_style)
	close_button.add_theme_stylebox_override("focus", close_hover_style)
	close_button.add_theme_color_override("font_color", Color("#FFF7E8"))
	close_button.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	close_button.add_theme_font_size_override("font_size", 22)

func _style_toggle(toggle: CheckButton) -> void:
	if toggle == null:
		return
	toggle.add_theme_stylebox_override("normal", toggle_high_style if _high_contrast else toggle_normal_style)
	toggle.add_theme_stylebox_override("hover", toggle_high_hover_style if _high_contrast else toggle_hover_style)
	toggle.add_theme_stylebox_override("pressed", toggle_high_pressed_style if _high_contrast else toggle_pressed_style)
	toggle.add_theme_stylebox_override("focus", toggle_high_hover_style if _high_contrast else toggle_hover_style)
	toggle.add_theme_color_override("font_color", Color("#FFFFFF") if _high_contrast else Color("#E8DCE4"))
	toggle.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	toggle.add_theme_font_size_override("font_size", 21)

func settings_authored_contract() -> Dictionary:
	return {
		"authored_house_sigil": house_sigil != null and house_sigil.texture != null,
		"authored_world_backdrop": world_art != null and world_art.texture != null,
		"standalone_destination_surface": true,
		"sigil_raster_runtime": true,
		"authored_style_resources": card_normal_style != null and card_high_style != null and toggle_normal_style != null and toggle_high_style != null and close_normal_style != null and close_high_style != null,
		"runtime_ui_factory": false,
		"north_star_title_hierarchy": ($Card/Content/Title as Label).get_theme_font_size("font_size") >= 46,
		"north_star_toggle_height": [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle].all(func(control): return control.custom_minimum_size.y >= 88.0),
		"intro_subordinate": ($Card/Content/Intro as Label) != null and not ($Card/Content/Intro as Label).visible,
		"runtime_style_factory": false,
	}

