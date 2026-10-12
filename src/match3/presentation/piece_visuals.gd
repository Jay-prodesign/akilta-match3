class_name Match3PieceVisuals
extends RefCounted

const CONTRACT := {
	"moon": {
		"color": Color("#BFA5D8"),
		"silhouette": "crescent",
		"motif": "moon_cut",
		"value": 0.78,
		"display_name": "Moon Sigil",
		"material": "smoked_moonstone",
		"world_role": "base_family",
		"status": "production_raster_verified"
	},
	"rose": {
		"color": Color("#C7728F"),
		"silhouette": "faceted_rose",
		"motif": "thorn_rosette",
		"value": 0.62,
		"display_name": "Thorn Rose",
		"material": "carved_wine_enamel",
		"world_role": "base_family",
		"status": "production_raster_verified"
	},
	"moth": {
		"color": Color("#83BDC0"),
		"silhouette": "luna_moth",
		"motif": "paired_wing_eye_spots",
		"value": 0.74,
		"display_name": "Luna Moth",
		"material": "moonlit_cyan_enamel_and_antique_gold",
		"world_role": "base_family",
		"status": "production_raster_verified"
	},
	"key": {
		"color": Color("#D3A34E"),
		"silhouette": "antique_key",
		"motif": "four_lobed_bow_and_notched_bit",
		"value": 0.80,
		"display_name": "Curio Key",
		"material": "antique_gilt",
		"world_role": "base_family",
		"status": "production_raster_verified"
	},
	"leaf": {
		"color": Color("#78AA63"),
		"silhouette": "ivy_leaf",
		"motif": "gilded_veins",
		"value": 0.66,
		"display_name": "Night Ivy",
		"material": "lacquered_green_enamel",
		"world_role": "base_family",
		"status": "production_raster_verified"
	},
	"cat": {
		"color": Color("#24202D"),
		"silhouette": "black_cat",
		"motif": "golden_eyes_and_crescent_collar",
		"value": 0.84,
		"display_name": "House Cat",
		"material": "obsidian_enamel",
		"world_role": "base_family",
		"status": "production_raster_verified"
	},
	"candle": {
		"color": Color("#E8B86C"),
		"silhouette": "wax_candle",
		"motif": "living_flame_and_gilded_seal",
		"value": 0.61,
		"display_name": "Witchlight Candle",
		"material": "ivory_wax_and_warm_gold",
		"world_role": "base_family",
		"status": "production_raster_verified"
	},
	"skull": {
		"color": Color("#E7DCC8"),
		"silhouette": "curio_skull",
		"motif": "dark_eye_sockets_and_aged_bone",
		"value": 0.72,
		"display_name": "Curio Skull",
		"material": "aged_bone_enamel",
		"world_role": "base_family",
		"status": "production_raster_verified"
	}
}

static func contract() -> Dictionary:
	return CONTRACT.duplicate(true)

static func descriptor(family: String) -> Dictionary:
	return CONTRACT.get(family, {}).duplicate(true)
