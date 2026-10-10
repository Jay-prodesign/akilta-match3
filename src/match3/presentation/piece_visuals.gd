class_name Match3PieceVisuals
extends RefCounted

const CONTRACT := {
	"moon": {
		"color": Color("#BFA5D8"),
		"silhouette": "crescent",
		"motif": "moon_cut",
		"value": 0.78
	},
	"rose": {
		"color": Color("#C7728F"),
		"silhouette": "faceted_rose",
		"motif": "thorn_rosette",
		"value": 0.62
	},
	"moth": {
		"color": Color("#A9C6C8"),
		"silhouette": "winged",
		"motif": "moth_eye",
		"value": 0.74
	},
	"key": {
		"color": Color("#D8B56A"),
		"silhouette": "key_relic",
		"motif": "keyhole",
		"value": 0.68
	},
	"leaf": {
		"color": Color("#8BAF7C"),
		"silhouette": "almond_leaf",
		"motif": "midrib",
		"value": 0.58
	}
}

static func contract() -> Dictionary:
	return CONTRACT.duplicate(true)

static func descriptor(family: String) -> Dictionary:
	return CONTRACT.get(family, {}).duplicate(true)
