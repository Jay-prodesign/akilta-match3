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
		"color": Color("#A9C6C8"),
		"silhouette": "raven_profile",
		"motif": "amber_raven_eye",
		"value": 0.74,
		"display_name": "Raven",
		"material": "midnight_feather",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	},
	"key": {
		"color": Color("#D8B56A"),
		"silhouette": "potion_flask",
		"motif": "emerald_sigillum",
		"value": 0.68,
		"display_name": "Emerald Potion",
		"material": "alchemical_glass",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	},
	"leaf": {
		"color": Color("#8BAF7C"),
		"silhouette": "pentagram_medallion",
		"motif": "arcane_star",
		"value": 0.58,
		"display_name": "Pentagram Sigil",
		"material": "gilded_arcane_enamel",
		"world_role": "base_family",
		"status": "first_party_svg_candidate_v2"
	}
}

static func contract() -> Dictionary:
	return CONTRACT.duplicate(true)

static func descriptor(family: String) -> Dictionary:
	return CONTRACT.get(family, {}).duplicate(true)
