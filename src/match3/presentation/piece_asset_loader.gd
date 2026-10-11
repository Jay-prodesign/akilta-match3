class_name Match3PieceAssetLoader
extends RefCounted

# North Star board art mapped onto deterministic gameplay families.
# Family identity is invariant across visual profiles; profiles may change treatment later,
# but a moth can never become a cat, a key a potion, or ivy a pentagram.
const PATHS := {
	"moon": "res://assets/pieces/moon_sigil.svg",
	"rose": "res://assets/pieces/thorn_rose.svg",
	"moth": "res://assets/pieces/luna_moth.svg",
	"key": "res://assets/pieces/curio_key.svg",
	"leaf": "res://assets/pieces/night_ivy.svg",
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
	if not PATHS.has(family):
		return null
	# All tile families use the same raster-first resolver as scene art.
	# The actual art file must be authored; SVG is only a fallback.
	var result := ornament(String(PATHS[family]))
	if result != null:
		_textures[family] = result
	return result

const PROFILE_PATHS := {
	"curio_boutique_opening": {
		"moon": "res://assets/pieces/moon_sigil.svg",
		"rose": "res://assets/pieces/thorn_rose.svg",
		"moth": "res://assets/pieces/luna_moth.svg",
		"key": "res://assets/pieces/curio_key.svg",
		"leaf": "res://assets/pieces/night_ivy.svg",
		"cat": "res://assets/pieces/black_cat.svg",
		"candle": "res://assets/pieces/candle.svg",
		"skull": "res://assets/pieces/skull.svg"
	},
	"sealed_display": {
		"moon": "res://assets/pieces/moon_sigil.svg",
		"rose": "res://assets/pieces/thorn_rose.svg",
		"moth": "res://assets/pieces/luna_moth.svg",
		"key": "res://assets/pieces/curio_key.svg",
		"leaf": "res://assets/pieces/night_ivy.svg",
		"cat": "res://assets/pieces/black_cat.svg",
		"candle": "res://assets/pieces/candle.svg",
		"skull": "res://assets/pieces/skull.svg"
	},
	"thornlight_arrangement": {
		"moon": "res://assets/pieces/moon_sigil.svg",
		"rose": "res://assets/pieces/thorn_rose.svg",
		"moth": "res://assets/pieces/luna_moth.svg",
		"key": "res://assets/pieces/curio_key.svg",
		"leaf": "res://assets/pieces/night_ivy.svg",
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
		"source": "AKILTA first-party authored raster assets with owned SVG compatibility fallback",
		"status": "raster_first_piece_contract",
		"paid_dependency": false,
		"fallback": "owned_procedural_renderer",
		"families": loaded,
		"visual_profiles": PROFILE_PATHS.keys(),
	}

static func ornament(path: String) -> Texture2D:
	if _ornaments.has(path):
		return _ornaments[path]
	# Production art is raster-first, but a malformed candidate must never make
	# the canonical semantic object disappear. Prefer authored WebP, then PNG,
	# and only then the owned SVG source for that exact object.
	var candidates: Array[String] = []
	if path.get_extension().to_lower() == "svg":
		var webp_preferred := path.get_basename() + ".webp"
		var png_preferred := path.get_basename() + ".png"
		if FileAccess.file_exists(webp_preferred):
			candidates.append(webp_preferred)
		if FileAccess.file_exists(png_preferred):
			candidates.append(png_preferred)
	candidates.append(path)
	for chosen in candidates:
		if not FileAccess.file_exists(chosen):
			continue
		var image := Image.new()
		var err := ERR_FILE_UNRECOGNIZED
		match chosen.get_extension().to_lower():
			"png":
				err = image.load_png_from_buffer(FileAccess.get_file_as_bytes(chosen))
			"webp":
				err = image.load_webp_from_buffer(FileAccess.get_file_as_bytes(chosen))
			"svg":
				var file := FileAccess.open(chosen, FileAccess.READ)
				if file != null:
					err = image.load_svg_from_string(file.get_as_text(), 1.0)
					file.close()
		if err == OK and not image.is_empty():
			var result := ImageTexture.create_from_image(image)
			_ornaments[path] = result
			return result
	_failures[path] = candidates
	return null
