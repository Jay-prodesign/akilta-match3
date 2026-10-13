class_name Match3ScreenArtRegistry
extends RefCounted

# Production screen art is intentionally raster-only. SVG remains valid for
# functional icons and temporary structural UI, but never for final world art.
const ART := {
	"chapter_route_curio_boutique": "res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp",
	"reliquary_bg_curio_boutique": "res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp",
	"splash_bg_curio_boutique": "res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp",
	"hub_bg_grandhall": "res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp",
	"events_bg_curio_house": "res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp",
	"shop_bg_curio_house": "res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp",
	"profile_bg_curio_house": "res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp",
	"settings_bg_curio_house": "res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp",
	"chapters_bg_curio_house": "res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp",
	"prestart_bg_curio_boutique": "res://assets/world/ch01_curio_boutique/prestart_bg_curio_boutique.webp",
	"prestart_ch01_level01_art": "res://assets/world/ch01_curio_boutique/prestart_level01_cabinet.webp",
	"prestart_ch01_shared_art": "res://assets/world/ch01_curio_boutique/prestart_level01_cabinet.webp",
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

	# Exported builds prefer Godot's imported-resource remap. Fresh headless CI
	# may not have an import cache yet, so native exports also retain the authored
	# raster bytes and this loader can decode them as a deterministic fallback.
	if ResourceLoader.exists(asset_path):
		var imported := ResourceLoader.load(asset_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
		if imported != null:
			_cache[asset_id] = imported
			return imported

	if not FileAccess.file_exists(asset_path):
		push_error("Missing required production screen art: %s -> %s" % [asset_id, asset_path])
		return null
	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes(asset_path)
	var err := image.load_png_from_buffer(bytes) if extension == "png" else image.load_webp_from_buffer(bytes)
	if err != OK or image.is_empty():
		push_error("Failed to decode production screen art: %s -> %s" % [asset_id, asset_path])
		return null
	var decoded := ImageTexture.create_from_image(image)
	_cache[asset_id] = decoded
	return decoded

static func missing_required() -> PackedStringArray:
	var missing := PackedStringArray()
	for asset_id in ART:
		var asset_path := String(ART[asset_id])
		if not ResourceLoader.exists(asset_path) and not FileAccess.file_exists(asset_path):
			missing.append(String(asset_id))
	return missing
