class_name Match3ScreenArtRegistry
extends RefCounted

# Production screen art is intentionally raster-only. SVG remains valid for
# functional icons and temporary structural UI, but never for final world art.
const ART := {
	"hub_bg_grandhall": "res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp",
	"prestart_bg_curio_boutique": "res://assets/world/ch01_curio_boutique/prestart_bg_curio_boutique.webp",
	"prestart_ch01_level01_art": "res://assets/world/ch01_curio_boutique/prestart_level01_cabinet.webp",
	"prestart_ch01_shared_art": "res://assets/world/ch01_curio_boutique/prestart_curio_boutique_shared.webp",
	"gameplay_bg_curio_boutique": "res://assets/world/ch01_curio_boutique/gameplay_bg_curio_boutique.webp",
}

static var _cache: Dictionary = {}

static func path(asset_id: String) -> String:
	return String(ART.get(asset_id, ""))

static func texture(asset_id: String) -> Texture2D:
	if _cache.has(asset_id):
		return _cache[asset_id]
	var asset_path := path(asset_id)
	if asset_path == "":
		return null
	var extension := asset_path.get_extension().to_lower()
	if extension != "png" and extension != "webp":
		push_error("Screen art must be raster: %s -> %s" % [asset_id, asset_path])
		return null
	if not FileAccess.file_exists(asset_path):
		push_error("Missing required production screen art: %s -> %s" % [asset_id, asset_path])
		return null
	var resource := load(asset_path) as Texture2D
	if resource == null:
		push_error("Failed to load production screen art: %s -> %s" % [asset_id, asset_path])
		return null
	_cache[asset_id] = resource
	return resource

static func missing_required() -> PackedStringArray:
	var missing := PackedStringArray()
	for asset_id in ART:
		if not FileAccess.file_exists(String(ART[asset_id])):
			missing.append(String(asset_id))
	return missing
