class_name Match3PieceAssetLoader
extends RefCounted

const PATHS := {
	"moon": "res://assets/pieces/moon_sigil.svg",
	"rose": "res://assets/pieces/thorn_rose.svg",
	"moth": "res://assets/pieces/luna_moth.svg",
	"key": "res://assets/pieces/curio_key.svg",
	"leaf": "res://assets/pieces/night_ivy.svg",
}

static var _textures: Dictionary = {}
static var _failures: Dictionary = {}

static func texture(family: String) -> Texture2D:
	if _textures.has(family):
		return _textures[family]
	if _failures.has(family) or not PATHS.has(family):
		return null
	var path := String(PATHS[family])
	if not FileAccess.file_exists(path):
		_failures[family] = "missing"
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures[family] = "unreadable"
		return null
	var svg := file.get_as_text()
	file.close()
	var image := Image.new()
	var err := image.load_svg_from_string(svg, 1.0)
	if err != OK or image.is_empty():
		_failures[family] = "svg_parse"
		return null
	var result := ImageTexture.create_from_image(image)
	_textures[family] = result
	return result

static func contract() -> Dictionary:
	var loaded: Dictionary = {}
	for family in PATHS:
		loaded[family] = texture(String(family)) != null
	return {
		"source": "AKILTA first-party original SVG",
		"status": "art_direction_candidate_v2",
		"paid_dependency": false,
		"fallback": "owned_procedural_renderer",
		"families": loaded,
	}
