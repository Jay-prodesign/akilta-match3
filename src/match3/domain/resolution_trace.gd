class_name Match3ResolutionTrace
extends RefCounted

var accepted: bool = false
var result: String = "playing"
var events: Array[Dictionary] = []

func add_event(event_type: String, payload: Dictionary = {}) -> void:
	var event := {"type": event_type}
	for key in payload.keys():
		event[key] = payload[key]
	events.append(event)

func event_types() -> Array[String]:
	var result_types: Array[String] = []
	for event in events:
		result_types.append(String(event.get("type", "")))
	return result_types

func debug_signature() -> String:
	return JSON.stringify(events)
