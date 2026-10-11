class_name Match3ScreenArtRegistry
extends RefCounted

# Production screen art is intentionally raster-only. SVG remains valid for
# functional icons and temporary structural UI, but never for final world art.
const ART := {
	"chapter_route_curio_boutique": "res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp",
	"reliquary_bg_curio_boutique": "res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp",
	"splash_bg_curio_boutique": "res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp",
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
	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes(asset_path)
	var err := ERR_FILE_UNRECOGNIZED
	if extension == "png":
		err = image.load_png_from_buffer(bytes)
	elif extension == "webp":
		err = image.load_webp_from_buffer(bytes)
	if err != OK or image.is_empty():
		push_error("Failed to decode production screen art: %s -> %s" % [asset_id, asset_path])
		return null
	var resource := ImageTexture.create_from_image(image)
	_cache[asset_id] = resource
	return resource

static func missing_required() -> PackedStringArray:
	var missing := PackedStringArray()
	for asset_id in ART:
		if not FileAccess.file_exists(String(ART[asset_id])):
			missing.append(String(asset_id))
	return missing
