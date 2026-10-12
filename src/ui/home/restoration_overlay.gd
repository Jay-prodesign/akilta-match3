extends Control

signal continue_requested

@onready var hero_title: Label = $RestorationHeader/RestorationHeroTitle
@onready var motif: TextureRect = $AwakeningMotif
@onready var curio_art: TextureRect = $CeremonyCard/CeremonyContent/CeremonyRow/RestoredCurioArt
@onready var body: Label = $CeremonyCard/CeremonyContent/CeremonyRow/Copy/Body
@onready var continue_button: Button = $CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue

func _ready() -> void:
	continue_button.pressed.connect(func(): continue_requested.emit())

func configure(curio_name: String, restoration_copy: String, motif_texture: Texture2D, curio_texture: Texture2D) -> bool:
	if curio_name == "" or motif_texture == null or curio_texture == null:
		return false
	hero_title.text = curio_name
	body.text = restoration_copy
	motif.texture = motif_texture
	curio_art.texture = curio_texture
	return true

func restoration_contract() -> Dictionary:
	return {
		"authored_scene": true,
		"motif_loaded": motif != null and motif.texture != null,
		"curio_art_loaded": curio_art != null and curio_art.texture != null,
	}
