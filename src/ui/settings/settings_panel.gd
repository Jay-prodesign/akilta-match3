class_name Match3SettingsPanel
extends Control

signal close_requested
signal interaction_feedback_requested(kind: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

@onready var master_toggle: CheckButton = $Card/Content/Master
@onready var music_toggle: CheckButton = $Card/Content/Music
@onready var sfx_toggle: CheckButton = $Card/Content/SFX
@onready var haptics_toggle: CheckButton = $Card/Content/Haptics
@onready var reduced_toggle: CheckButton = $Card/Content/Reduced
@onready var contrast_toggle: CheckButton = $Card/Content/Contrast
@onready var close_button: Button = $Card/Content/Close
@onready var saved_note: Label = $Card/Content/SavedNote

var settings
var _binding_controls := false
var _high_contrast := false

func _ready() -> void:
	_style_settings_overlay()
	_install_house_sigil()
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
		"touch_targets_ok": [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle, close_button].all(func(control): return control.custom_minimum_size.y >= 56.0),
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
		var panel := StyleBoxFlat.new()
		panel.bg_color = Color("#080A12") if _high_contrast else Color("#121322")
		panel.border_color = Color("#FFF1B6") if _high_contrast else Color("#D5AD70", 0.82)
		panel.set_border_width_all(3 if _high_contrast else 2)
		panel.set_corner_radius_all(18)
		panel.shadow_color = Color(0, 0, 0, 0.72)
		panel.shadow_size = 24
		panel.content_margin_left = 24
		panel.content_margin_right = 24
		panel.content_margin_top = 20
		panel.content_margin_bottom = 20
		card.add_theme_stylebox_override("panel", panel)
	for toggle in [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle]:
		_style_toggle(toggle)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#63356A") if _high_contrast else Color("#512957")
	close_style.border_color = Color("#FFF1B6") if _high_contrast else Color("#D5AD70")
	close_style.set_border_width_all(3 if _high_contrast else 2)
	close_style.set_corner_radius_all(12)
	var hover := close_style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#7B4482")
	var pressed := close_style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#3E1D43")
	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_stylebox_override("hover", hover)
	close_button.add_theme_stylebox_override("pressed", pressed)
	close_button.add_theme_stylebox_override("focus", hover)
	close_button.add_theme_color_override("font_color", Color("#FFF7E8"))
	close_button.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	close_button.add_theme_font_size_override("font_size", 20)

func _style_toggle(toggle: CheckButton) -> void:
	if toggle == null:
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#090A10", 0.98) if _high_contrast else Color("#15111B", 0.96)
	normal.border_color = Color("#FFF1B6", 0.84) if _high_contrast else Color("#745C73", 0.54)
	normal.set_border_width_all(2 if _high_contrast else 1)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#2A2130")
	hover.border_color = Color("#D5AD70")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#3A2640")
	pressed.border_color = Color("#F0CE8A")
	toggle.add_theme_stylebox_override("normal", normal)
	toggle.add_theme_stylebox_override("hover", hover)
	toggle.add_theme_stylebox_override("pressed", pressed)
	toggle.add_theme_stylebox_override("focus", hover)
	toggle.add_theme_color_override("font_color", Color("#FFFFFF") if _high_contrast else Color("#E8DCE4"))
	toggle.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	toggle.add_theme_font_size_override("font_size", 19)


func _install_house_sigil() -> void:
	var content := get_node_or_null("Card/Content") as VBoxContainer
	if content == null or content.has_node("HouseSigil"):
		return
	var sigil := TextureRect.new()
	sigil.name = "HouseSigil"
	sigil.custom_minimum_size = Vector2(0, 72)
	sigil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sigil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sigil.texture = PieceAssetLoader.ornament("res://assets/pieces/moon_sigil.svg")
	sigil.modulate = Color("#E8C987")
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(sigil)
	content.move_child(sigil, 3)
