class_name Match3HouseState
extends RefCounted

static func descriptor(stage: int) -> Dictionary:
	if stage >= 3:
		return {
			"stage": 3,
			"room": "curio_boutique",
			"state": "three_displays_awake",
			"headline": "Three displays breathe in the moonlight.",
			"detail": "The Thorned Locket joins the Moon Cameo and Moth Reliquary. The boutique is becoming yours."
		}
	if stage >= 2:
		return {"stage":2,"room":"curio_boutique","state":"second_reliquary_awake","headline":"The boutique is learning your name.","detail":"The Moth Reliquary opens beside the Moon Cameo. Another display is still dark."}
	if stage >= 1:
		return {"stage":1,"room":"curio_boutique","state":"first_cabinet_awake","headline":"The first cabinet remembers.","detail":"Moonlight catches on a relic that was not there before."}
	return {"stage":0,"room":"curio_boutique","state":"dormant","headline":"THE HOUSE AWAITS","detail":"Win a puzzle to wake the first display."}
