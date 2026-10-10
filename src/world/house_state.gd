class_name Match3HouseState
extends RefCounted

static func descriptor(stage: int) -> Dictionary:
	if stage >= 1:
		return {
			"stage": 1,
			"room": "curio_boutique",
			"state": "first_cabinet_awake",
			"headline": "The first cabinet remembers.",
			"detail": "Moonlight catches on a relic that was not there before."
		}
	return {
		"stage": 0,
		"room": "curio_boutique",
		"state": "dormant",
		"headline": "The Curio Boutique sleeps.",
		"detail": "Win a puzzle to wake the first display."
	}
