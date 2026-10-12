class_name Match3PieceAssetLoader
extends RefCounted

# North Star board art mapped onto deterministic gameplay families.
# Family identity is invariant across visual profiles; a moth can never become
# a cat, a key a potion, or ivy a pentagram. Production runtime uses the
# authored raster family explicitly; owned SVGs remain exact-identity fallback.
const RUNTIME_PATHS := {
	"moon": "res://assets/pieces/moon_sigil.webp",
	"rose": "res://assets/pieces/thorn_rose.webp",
	"moth": "res://assets/pieces/luna_moth.webp",
	"key": "res://assets/pieces/curio_key.webp",
	"leaf": "res://assets/pieces/night_ivy.webp",
	"cat": "res://assets/pieces/black_cat.webp",
	"candle": "res://assets/pieces/candle.webp",
	"skull": "res://assets/pieces/skull.webp",
}

const SOURCE_PATHS := {
	"moon": "res://assets/pieces/moon_sigil.svg",
	"rose": "res://assets/pieces/thorn_rose.svg",
	"moth": "res://assets/pieces/luna_moth.svg",
	"key": "res://assets/pieces/curio_key.svg",
	"leaf": "res://assets/pieces/night_ivy.svg",
	"cat": "res://assets/pieces/black_cat.svg",
	"candle": "res://assets/pieces/candle.svg",
	"skull": "res://assets/pieces/skull.svg",
}

# Compatibility alias for callers that still need the canonical source map.
const PATHS := SOURCE_PATHS

static var _textures: Dictionary = {}
static var _failures: Dictionary = {}
static var _ornaments: Dictionary = {}
static var _resolved_paths: Dictionary = {}

static func texture(family: String) -> Texture2D:
	if _textures.has(family):
		return _textures[family]
	if not RUNTIME_PATHS.has(family):
		return null
	var runtime_path := String(RUNTIME_PATHS[family])
	var result := ornament(runtime_path)
	if result == null:
		result = ornament(String(SOURCE_PATHS.get(family, "")))
	if result != null:
		_textures[family] = result
	return result

const PROFILE_PATHS := {
	"curio_boutique_opening": {
		"moon": "res://assets/pieces/moon_sigil.webp",
		"rose": "res://assets/pieces/thorn_rose.webp",
		"moth": "res://assets/pieces/luna_moth.webp",
		"key": "res://assets/pieces/curio_key.webp",
		"leaf": "res://assets/pieces/night_ivy.webp",
		"cat": "res://assets/pieces/black_cat.webp",
		"candle": "res://assets/pieces/candle.webp",
		"skull": "res://assets/pieces/skull.webp"
	},
	"sealed_display": {
		"moon": "res://assets/pieces/moon_sigil.webp",
		"rose": "res://assets/pieces/thorn_rose.webp",
		"moth": "res://assets/pieces/luna_moth.webp",
		"key": "res://assets/pieces/curio_key.webp",
		"leaf": "res://assets/pieces/night_ivy.webp",
		"cat": "res://assets/pieces/black_cat.webp",
		"candle": "res://assets/pieces/candle.webp",
		"skull": "res://assets/pieces/skull.webp"
	},
	"thornlight_arrangement": {
		"moon": "res://assets/pieces/moon_sigil.webp",
		"rose": "res://assets/pieces/thorn_rose.webp",
		"moth": "res://assets/pieces/luna_moth.webp",
		"key": "res://assets/pieces/curio_key.webp",
		"leaf": "res://assets/pieces/night_ivy.webp",
		"cat": "res://assets/pieces/black_cat.webp",
		"candle": "res://assets/pieces/candle.webp",
		"skull": "res://assets/pieces/skull.webp"
	}
}

static func texture_for_profile(profile: String, family: String) -> Texture2D:
	var profile_paths: Dictionary = PROFILE_PATHS.get(profile, {})
	var path := String(profile_paths.get(family, RUNTIME_PATHS.get(family, "")))
	if path == "":
		return null
	var result := ornament(path)
	if result == null:
		result = ornament(String(SOURCE_PATHS.get(family, "")))
	return result

static func contract() -> Dictionary:
	var loaded: Dictionary = {}
	var resolved_runtime_paths: Dictionary = {}
	var raster_runtime := true
	for family in RUNTIME_PATHS:
		var family_name := String(family)
		loaded[family_name] = texture(family_name) != null
		var runtime_path := String(RUNTIME_PATHS[family_name])
		var resolved := resolved_path(runtime_path)
		resolved_runtime_paths[family_name] = resolved
		raster_runtime = raster_runtime and bool(loaded[family_name]) and (resolved.ends_with(".webp") or resolved.ends_with(".png"))
	return {
		"source": "AKILTA first-party authored production raster family with owned SVG exact-identity fallback",
		"status": "verified_production_raster_piece_family",
		"paid_dependency": false,
		"fallback": "owned_svg_exact_family_then_owned_procedural_renderer",
		"families": loaded,
		"runtime_paths": RUNTIME_PATHS.duplicate(true),
		"source_paths": SOURCE_PATHS.duplicate(true),
		"resolved_runtime_paths": resolved_runtime_paths,
		"raster_runtime": raster_runtime,
		"visual_profiles": PROFILE_PATHS.keys(),
	}

static func ornament(path: String) -> Texture2D:
	if _ornaments.has(path):
		return _ornaments[path]
	var candidates: Array[String] = []
	if path.get_extension().to_lower() == "svg":
		var webp_preferred := path.get_basename() + ".webp"
		var png_preferred := path.get_basename() + ".png"
		if ResourceLoader.exists(webp_preferred) or FileAccess.file_exists(webp_preferred):
			candidates.append(webp_preferred)
		if ResourceLoader.exists(png_preferred) or FileAccess.file_exists(png_preferred):
			candidates.append(png_preferred)
	candidates.append(path)

	for chosen in candidates:
		if ResourceLoader.exists(chosen):
			var imported := ResourceLoader.load(chosen, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
			if imported != null:
				_ornaments[path] = imported
				_resolved_paths[path] = chosen
				return imported
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
			var decoded := ImageTexture.create_from_image(image)
			_ornaments[path] = decoded
			_resolved_paths[path] = chosen
			return decoded
	_failures[path] = candidates
	push_error("Missing required gameplay asset: %s -> %s" % [path, ",".join(candidates)])
	return null

static func resolved_path(path: String) -> String:
	if not _ornaments.has(path):
		ornament(path)
	return String(_resolved_paths.get(path, ""))
