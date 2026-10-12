extends Control

signal close_requested

@onready var hero_art: TextureRect = $Card/Content/HeroArt
@onready var title: Label = $Card/Content/Name
@onready var origin: Label = $Card/Content/Origin
@onready var effect: Label = $Card/Content/HouseEffect
@onready var close: Button = $Card/Content/Close

func _ready() -> void:
	close.pressed.connect(func(): close_requested.emit())

func configure(curio_id: String, curio_name: String, origin_copy: String, effect_copy: String, texture: Texture2D) -> bool:
	if curio_id == "" or texture == null:
		return false
	title.text = curio_name
	origin.text = origin_copy
	effect.text = effect_copy
	hero_art.texture = texture
	set_meta("curio_id", curio_id)
	return true

func inspect_contract() -> Dictionary:
	return {
		"authored_scene": true,
		"curio_id": String(get_meta("curio_id", "")),
		"art_loaded": hero_art != null and hero_art.texture != null,
	}
