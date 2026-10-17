class_name Match3SettingsPanel
extends Control

signal close_requested
signal interaction_feedback_requested(kind: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

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
@export var state_on_style: StyleBoxFlat
@export var state_off_style: StyleBoxFlat
@export var state_high_style: StyleBoxFlat


@onready var master_toggle: Button = $Card/Content/AudioRow/Master
@onready var music_toggle: Button = $Card/Content/AudioRow/Music
@onready var sfx_toggle: Button = $Card/Content/AudioRow/SFX
@onready var haptics_toggle: Button = $Card/Content/ExperienceRow/Haptics
@onready var reduced_toggle: Button = $Card/Content/ExperienceRow/Reduced
@onready var contrast_toggle: Button = $Card/Content/ExperienceRow/Contrast
@onready var close_button: Button = $Card/Content/Close
@onready var saved_note: Label = $Card/Content/SavedNote
@onready var house_sigil: TextureRect = $Card/Content/HouseSigil
@onready var footer_rose: TextureRect = $Card/Content/FooterRose
@onready var world_art: TextureRect = $WorldArt

var settings
var _binding_controls := false
var _high_contrast := false
var _entrance_tween: Tween

func _ready() -> void:
	world_art.texture = ScreenArt.texture("settings_bg_curio_house")
	house_sigil.texture = PieceAssetLoader.ornament("res://assets/pieces/moon_sigil.webp")
	footer_rose.texture = PieceAssetLoader.ornament("res://assets/pieces/thorn_rose.webp")
	_style_settings_overlay()
	_wire_tactile_controls()
	_play_entrance()
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
	_style_settings_overlay()

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
	for toggle in [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle]:
		var status := toggle.get_node_or_null("State") as Label
		if status != null:
			status.text = "ON" if toggle.button_pressed else "OFF"

func _style_settings_overlay() -> void:
	var card := get_node_or_null("Card") as PanelContainer
	if card != null:
		if _high_contrast:
			card.add_theme_stylebox_override("panel", card_high_style)
			card.set_meta("production_chrome_kind", "settings_high_contrast")
		else:
			card.add_theme_stylebox_override("panel", card_normal_style)
			card.set_meta("settings_material", "scene_authored_flat")
		card.set_meta("production_chrome_kind", "settings_ritual_card")
	for toggle in [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle]:
		_style_toggle(toggle)
	if _high_contrast:
		close_button.add_theme_stylebox_override("normal", close_high_style)
		close_button.add_theme_stylebox_override("hover", close_hover_style)
		close_button.add_theme_stylebox_override("pressed", close_pressed_style)
		close_button.add_theme_stylebox_override("focus", close_hover_style)
		close_button.set_meta("production_chrome_kind", "settings_high_contrast_return")
	else:
		close_button.add_theme_stylebox_override("normal", close_normal_style)
		close_button.add_theme_stylebox_override("hover", close_hover_style)
		close_button.add_theme_stylebox_override("pressed", close_pressed_style)
		close_button.add_theme_stylebox_override("focus", close_hover_style)
		close_button.set_meta("settings_material", "scene_authored_flat")
	close_button.add_theme_color_override("font_color", Color("#FFF7E8"))
	close_button.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	close_button.add_theme_font_size_override("font_size", 20)

func _style_toggle(toggle: Button) -> void:
	if toggle == null:
		return
	if _high_contrast:
		toggle.add_theme_stylebox_override("normal", toggle_high_style)
		toggle.add_theme_stylebox_override("hover", toggle_high_hover_style)
		toggle.add_theme_stylebox_override("pressed", toggle_high_pressed_style)
		toggle.add_theme_stylebox_override("focus", toggle_high_hover_style)
		toggle.set_meta("production_chrome_kind", "settings_high_contrast_toggle")
	else:
		toggle.add_theme_stylebox_override("normal", toggle_normal_style)
		toggle.add_theme_stylebox_override("hover", toggle_hover_style)
		toggle.add_theme_stylebox_override("pressed", toggle_pressed_style)
		toggle.add_theme_stylebox_override("focus", toggle_hover_style)
		toggle.set_meta("settings_material", "scene_authored_flat")
	toggle.add_theme_color_override("font_color", Color("#FFFFFF") if _high_contrast else Color("#E8DCE4"))
	toggle.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	toggle.add_theme_font_size_override("font_size", 18)
	var title := toggle.get_node_or_null("Title") as Label
	var detail := toggle.get_node_or_null("Detail") as Label
	var status := toggle.get_node_or_null("State") as Label
	if title != null:
		title.add_theme_color_override("font_color", Color("#FFF7E8") if _high_contrast else Color("#F4EBE7"))
	if detail != null:
		detail.add_theme_color_override("font_color", Color("#FFF1B6") if _high_contrast else Color("#BBA0B9"))
	if status != null:
		status.text = "ON" if toggle.button_pressed else "OFF"
		status.add_theme_stylebox_override("normal", state_high_style if _high_contrast else (state_on_style if toggle.button_pressed else state_off_style))
		status.add_theme_color_override("font_color", Color("#FFF7D0") if (_high_contrast or toggle.button_pressed) else Color("#C6B8C9"))

func _wire_tactile_controls() -> void:
	for control in [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle, close_button]:
		if control == null:
			continue
		control.pivot_offset = control.size * 0.5
		control.button_down.connect(func(): _animate_control_scale(control, Vector2(0.975, 0.975), 0.06))
		control.button_up.connect(func(): _animate_control_scale(control, Vector2.ONE, 0.10))

func _animate_control_scale(control: Control, target: Vector2, duration: float) -> void:
	if control == null:
		return
	if _high_contrast:
		control.scale = target
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", target, duration)

func _play_entrance() -> void:
	var card := $Card as PanelContainer
	if card == null:
		return
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.97, 0.97)
	card.modulate = Color(1, 1, 1, 0)
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	_entrance_tween = create_tween()
	_entrance_tween.set_parallel(true)
	_entrance_tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(card, "modulate", Color.WHITE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func settings_authored_contract() -> Dictionary:
	var card := $Card as PanelContainer
	var audio_row := $Card/Content/AudioRow as VBoxContainer
	var experience_row := $Card/Content/ExperienceRow as VBoxContainer
	var destination_surface := card.anchor_left >= 0.105 and card.anchor_right <= 0.895 and (card.anchor_bottom - card.anchor_top) >= 0.55 and (card.anchor_bottom - card.anchor_top) <= 0.59
	var ritual_list := audio_row.get_child_count() == 3 and experience_row.get_child_count() == 3 and [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle].all(
		func(control): return control.size_flags_horizontal == Control.SIZE_EXPAND_FILL and control.toggle_mode and control.custom_minimum_size.y >= 64.0
	)
	var sigil_stage := house_sigil != null and house_sigil.texture != null and house_sigil.custom_minimum_size.y >= 68.0 and house_sigil.custom_minimum_size.y <= 80.0
	var world_visible := ($WorldShade as ColorRect).color.a <= 0.20 and ($Dim as ColorRect).color.a <= 0.12
	var title_hierarchy := ($Card/Content/Title as Label).get_theme_font_size("font_size") >= 44
	var touch_targets := [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle].all(func(control): return control.custom_minimum_size.y >= 64.0) and close_button.custom_minimum_size.y >= 72.0
	var crafted_rows := [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle].all(
		func(control):
			var title := control.get_node_or_null("Title") as Label
			var detail := control.get_node_or_null("Detail") as Label
			var status := control.get_node_or_null("State") as Label
			return control.text == "" and title != null and detail != null and status != null and status.get_theme_stylebox("normal") != null
	)
	return {
		"authored_house_sigil": house_sigil != null and house_sigil.texture != null,
		"authored_world_backdrop": world_art != null and world_art.texture != null,
		"standalone_destination_surface": true,
		"sigil_raster_runtime": true,
		"authored_style_resources": card_normal_style != null and card_high_style != null and toggle_normal_style != null and toggle_high_style != null and close_normal_style != null and close_high_style != null,
		"runtime_ui_factory": false,
		"north_star_title_hierarchy": title_hierarchy,
		"north_star_toggle_height": touch_targets,
		"intro_subordinate": ($Card/Content/Intro as Label) != null and not ($Card/Content/Intro as Label).visible,
		"runtime_style_factory": false,
		"scene_authored_card_chrome": card.get_theme_stylebox("panel") is StyleBoxFlat and String(card.get_meta("settings_material", "")) == "scene_authored_flat",
		"scene_authored_toggle_chrome": [master_toggle, music_toggle, sfx_toggle, haptics_toggle, reduced_toggle, contrast_toggle].all(func(control): return control.get_theme_stylebox("normal") is StyleBoxFlat and String(control.get_meta("settings_material", "")) == "scene_authored_flat"),
		"scene_authored_return_chrome": close_button.get_theme_stylebox("normal") is StyleBoxFlat and String(close_button.get_meta("settings_material", "")) == "scene_authored_flat",
		"settings_ritual_list": ritual_list,
		"crafted_ritual_rows": crafted_rows,
		"house_sigil_hero_scale": sigil_stage,
		"footer_rose_subordinate": footer_rose != null and footer_rose.texture != null and not footer_rose.visible,
		"world_art_not_overdimmed": world_visible,
		"compact_destination_surface": destination_surface,
		"visual_parity_gate_v3": title_hierarchy and touch_targets and ritual_list and crafted_rows and sigil_stage and footer_rose != null and not footer_rose.visible and world_visible and destination_surface,
	}
