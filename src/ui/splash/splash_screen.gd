class_name Match3SplashScreen
extends Control

signal continue_requested

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")

@onready var enter_button: Button = $Layout/Enter

func _ready() -> void:
	_install_splash_art()
	_style_enter_button()
	enter_button.pressed.connect(func(): continue_requested.emit())

func _install_splash_art() -> void:
	var texture := ScreenArt.texture("splash_bg_curio_boutique")
	if texture == null:
		return
	var art := TextureRect.new()
	art.name = "SplashWorldArt"
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	# Authored world art sits below the existing Backdrop shade and UI.
	move_child(art, 0)
	var shade := get_node_or_null("Backdrop")
	if shade is ColorRect:
		(shade as ColorRect).color = Color(0.018, 0.012, 0.026, 0.44)

func _style_enter_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#48244A")
	normal.border_color = Color("#D5AD70")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	normal.shadow_size = 12
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#633265")
	enter_button.add_theme_stylebox_override("normal", normal)
	enter_button.add_theme_stylebox_override("hover", hover)
	enter_button.add_theme_stylebox_override("pressed", hover)
	enter_button.add_theme_color_override("font_color", Color("#F4E5D3"))
	enter_button.add_theme_color_override("font_hover_color", Color("#FFF1D9"))
	enter_button.add_theme_font_size_override("font_size", 25)
	enter_button.custom_minimum_size.y = maxf(enter_button.custom_minimum_size.y, 64.0)
