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

const RASTER_OVERRIDES := {
	# Current material WebP key loses its silhouette against the dark board.
	# Keep the canonical object identity but use the brighter authored raster
	# until the final production-material Key replaces this review candidate.
	"res://assets/pieces/curio_key.svg": "res://assets/pieces/curio_key.png",
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
	# Production artwork is raster-first. A narrowly declared readability override
	# may outrank the material WebP; otherwise prefer WebP, then PNG. The canonical
	# owned SVG remains compatibility fallback only.
	var chosen := path
	if RASTER_OVERRIDES.has(path) and FileAccess.file_exists(String(RASTER_OVERRIDES[path])):
		chosen = String(RASTER_OVERRIDES[path])
	elif path.get_extension().to_lower() == "svg":
		var webp_preferred := path.get_basename() + ".webp"
		var png_preferred := path.get_basename() + ".png"
		if FileAccess.file_exists(webp_preferred):
			chosen = webp_preferred
		elif FileAccess.file_exists(png_preferred):
			chosen = png_preferred
	if not FileAccess.file_exists(chosen):
		return null
	var image := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if chosen.get_extension().to_lower() == "png":
		err = image.load_png_from_buffer(FileAccess.get_file_as_bytes(chosen))
	elif chosen.get_extension().to_lower() == "webp":
		err = image.load_webp_from_buffer(FileAccess.get_file_as_bytes(chosen))
	elif chosen.get_extension().to_lower() == "svg":
		var file := FileAccess.open(chosen, FileAccess.READ)
		if file == null:
			return null
		err = image.load_svg_from_string(file.get_as_text(), 1.0)
		file.close()
	if err != OK or image.is_empty():
		return null
	var result := ImageTexture.create_from_image(image)
	_ornaments[path] = result
	return result
