class_name Match3PieceAssetLoader
extends RefCounted

# North Star board art mapped onto the deterministic five-family gameplay IDs.
const PATHS := {
	"moon": "res://assets/pieces/moon_sigil.svg",
	"rose": "res://assets/pieces/thorn_rose.svg",
	"moth": "res://assets/pieces/crow.svg",
	"key": "res://assets/pieces/potion.svg",
	"leaf": "res://assets/pieces/pentagram.svg",
	"cat": "res://assets/pieces/black_cat.svg",
	"candle": "res://assets/pieces/candle.svg",
	"skull": "res://assets/pieces/skull.svg",
}

static var _textures: Dictionary = {}
static var _failures: Dictionary = {}
static var _ornaments: Dictionary = {}

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

const PROFILE_PATHS := {
	"curio_boutique_opening": {
		"moon": "res://assets/pieces/moon_sigil.svg",
		"rose": "res://assets/pieces/thorn_rose.svg",
		"moth": "res://assets/pieces/crow.svg",
		"key": "res://assets/pieces/potion.svg",
		"leaf": "res://assets/pieces/pentagram.svg",
		"cat": "res://assets/pieces/black_cat.svg",
		"candle": "res://assets/pieces/candle.svg",
		"skull": "res://assets/pieces/skull.svg"
	},
	"sealed_display": {
		"moon": "res://assets/pieces/moon_sigil.svg",
		"rose": "res://assets/pieces/thorn_rose.svg",
		"moth": "res://assets/pieces/crow.svg",
		"key": "res://assets/pieces/potion.svg",
		"leaf": "res://assets/pieces/pentagram.svg",
		"cat": "res://assets/pieces/black_cat.svg",
		"candle": "res://assets/pieces/candle.svg",
		"skull": "res://assets/pieces/skull.svg"
	},
	"thornlight_arrangement": {
		"moon": "res://assets/pieces/moon_sigil.svg",
		"rose": "res://assets/pieces/thorn_rose.svg",
		"moth": "res://assets/pieces/crow.svg",
		"key": "res://assets/pieces/potion.svg",
		"leaf": "res://assets/pieces/pentagram.svg",
		"cat": "res://assets/pieces/black_cat.svg",
		"candle": "res://assets/pieces/candle.svg",
		"skull": "res://assets/pieces/skull.svg"
	}
}

static func texture_for_profile(profile: String, family: String) -> Texture2D:
	var profile_paths: Dictionary = PROFILE_PATHS.get(profile, {})
	var path := String(profile_paths.get(family, PATHS.get(family, "")))
	if path == "":
		return null
	return ornament(path)

static func contract() -> Dictionary:
	var loaded: Dictionary = {}
	for family in PATHS:
		loaded[family] = texture(String(family)) != null
	return {
		"source": "AKILTA first-party original SVG",
		"status": "north_star_symbol_set_v2",
		"paid_dependency": false,
		"fallback": "owned_procedural_renderer",
		"families": loaded,
		"visual_profiles": PROFILE_PATHS.keys(),
	}

static func ornament(path: String) -> Texture2D:
	if _ornaments.has(path):
		return _ornaments[path]
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var svg := file.get_as_text()
	file.close()
	var image := Image.new()
	if image.load_svg_from_string(svg, 1.0) != OK or image.is_empty():
		return null
	var texture := ImageTexture.create_from_image(image)
	_ornaments[path] = texture
	return texture
