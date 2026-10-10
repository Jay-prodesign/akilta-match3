class_name Match3SplashScreen
extends Control

signal continue_requested

@onready var enter_button: Button = $Layout/Enter

func _ready() -> void:
	_install_splash_art()
	enter_button.pressed.connect(func(): continue_requested.emit())

func _install_splash_art() -> void:
	const ART_PATH := "res://assets/world/ch01_curio_boutique/north_star_splash.svg"
	var file := FileAccess.open(ART_PATH, FileAccess.READ)
	if file == null:
		return
	var image := Image.new()
	var error := image.load_svg_from_string(file.get_as_text(), 1.0)
	file.close()
	if error != OK or image.is_empty():
		return
	var art := TextureRect.new()
	art.name = "NorthStarSplashArt"
	art.texture = ImageTexture.create_from_image(image)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	move_child(art, 1)
	var shade := get_node_or_null("Backdrop")
	if shade is ColorRect:
		(shade as ColorRect).color.a = 0.20
