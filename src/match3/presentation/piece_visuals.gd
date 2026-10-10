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
		"status": "first_party_svg_candidate_v2"
	},
	"rose": {
		"color": Color("#C7728F"),
		"silhouette": "faceted_rose",
		"motif": "thorn_rosette",
		"value": 0.62,
		"display_name": "Thorn Rose",
		"material": "carved_wine_enamel",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	},
	"moth": {
		"color": Color("#77718E"),
		"silhouette": "crow_profile",
		"motif": "amber_crow_eye",
		"value": 0.74,
		"display_name": "Moon Crow",
		"material": "midnight_feather",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	},
	"key": {
		"color": Color("#45B88A"),
		"silhouette": "apothecary_flask",
		"motif": "emerald_elixir",
		"value": 0.68,
		"display_name": "Witchlight Potion",
		"material": "emerald_glass_and_antique_gold",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	},
	"leaf": {
		"color": Color("#C6A2E8"),
		"silhouette": "pentagram_medallion",
		"motif": "arcane_star",
		"value": 0.58,
		"display_name": "Pentagram Sigil",
		"material": "gilded_arcane_enamel",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	},,
	"cat": {
		"color": Color("#24202D"),
		"silhouette": "black_cat",
		"motif": "golden_eyes_and_crescent_collar",
		"value": 0.84,
		"display_name": "House Cat",
		"material": "obsidian_enamel",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	},
	"candle": {
		"color": Color("#E8B86C"),
		"silhouette": "wax_candle",
		"motif": "living_flame_and_gilded_seal",
		"value": 0.61,
		"display_name": "Witchlight Candle",
		"material": "ivory_wax_and_warm_gold",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	},
	"skull": {
		"color": Color("#E7DCC8"),
		"silhouette": "curio_skull",
		"motif": "dark_eye_sockets_and_aged_bone",
		"value": 0.72,
		"display_name": "Curio Skull",
		"material": "aged_bone_enamel",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	}
}

static func contract() -> Dictionary:
	return CONTRACT.duplicate(true)

static func descriptor(family: String) -> Dictionary:
	return CONTRACT.get(family, {}).duplicate(true)
