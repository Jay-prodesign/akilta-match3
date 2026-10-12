extends Control

signal close_requested

@onready var art: TextureRect = $Card/Content/KeeperArt
@onready var close: Button = $Card/Content/Close

func _ready() -> void:
	close.pressed.connect(func(): close_requested.emit())

func configure(texture: Texture2D) -> bool:
	if texture == null:
		return false
	art.texture = texture
	return true

func keeper_contract() -> Dictionary:
	return {
		"authored_scene": true,
		"art_loaded": art != null and art.texture != null,
		"role": "non_mutating_legal_move_guide",
		"spends_resources": false,
		"changes_board": false,
		"adds_moves": false,
	}
