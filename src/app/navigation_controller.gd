class_name Match3NavigationController
extends RefCounted

## AKILTA first-party adaptation.
## Source pattern: Sekiph82/Scrubbots scripts/app/navigation_controller.gd
## Pinned source head: c2b1c3c7ae0a301cd43d95dd003f0ddf1373eed0

signal route_changed(from_route: int, to_route: int, payload: Dictionary)
signal settings_changed(open: bool)

# Route names preserve COLLECTION/MAP for compatibility, but their canonical
# product surfaces are S08 Curios and S03 Chapter Detail respectively.
enum Route {
	BOOT,
	HOUSE,
	COLLECTION,
	MAP,
	PRESTART,
	GAMEPLAY,
	WIN_REWARDS,
	RESTORATION,
	CHAPTERS,
	MISSIONS,
	EVENTS,
	SHOP,
	PROFILE_SETTINGS
}

const _EDGES := {
	Route.BOOT: [Route.HOUSE],
	Route.HOUSE: [Route.COLLECTION, Route.CHAPTERS, Route.MAP, Route.EVENTS, Route.SHOP, Route.PROFILE_SETTINGS],
	Route.COLLECTION: [Route.HOUSE],
	Route.CHAPTERS: [Route.HOUSE, Route.MAP],
	Route.MAP: [Route.CHAPTERS, Route.HOUSE, Route.PRESTART],
	Route.PRESTART: [Route.MAP, Route.GAMEPLAY],
	Route.GAMEPLAY: [Route.WIN_REWARDS, Route.HOUSE],
	Route.WIN_REWARDS: [Route.RESTORATION, Route.HOUSE],
	Route.RESTORATION: [Route.HOUSE],
	Route.MISSIONS: [Route.EVENTS, Route.HOUSE],
	Route.EVENTS: [Route.HOUSE, Route.MISSIONS],
	Route.SHOP: [Route.HOUSE],
	Route.PROFILE_SETTINGS: [Route.HOUSE],
}

var _route: int = Route.BOOT
var _settings_open := false
var _in_transition := false
var _transition_id := 0
var _last_payload: Dictionary = {}

func current() -> int:
	return _route

func route_name(route: int = -1) -> String:
	var value := _route if route < 0 else route
	for key in Route:
		if Route[key] == value:
			return key
	return "UNKNOWN"

func transition_id() -> int:
	return _transition_id

func last_payload() -> Dictionary:
	return _last_payload.duplicate(true)

func can_go(to: int) -> bool:
	return not _in_transition and _EDGES.has(_route) and (_EDGES[_route] as Array).has(to)

func go(to: int, payload: Dictionary = {}) -> bool:
	if typeof(to) != TYPE_INT or not can_go(to):
		return false
	_in_transition = true
	var from := _route
	_route = to
	_transition_id += 1
	_last_payload = payload.duplicate(true)
	if _settings_open:
		_settings_open = false
		settings_changed.emit(false)
	route_changed.emit(from, to, _last_payload.duplicate(true))
	_in_transition = false
	return true

func is_settings_open() -> bool:
	return _settings_open

func open_settings() -> bool:
	if _in_transition or not (_route in [Route.HOUSE, Route.GAMEPLAY, Route.PROFILE_SETTINGS]) or _settings_open:
		return false
	_settings_open = true
	settings_changed.emit(true)
	return true

func close_settings() -> bool:
	if not _settings_open:
		return false
	_settings_open = false
	settings_changed.emit(false)
	return true

func back() -> String:
	if _in_transition:
		return "none"
	if _settings_open:
		close_settings()
		return "close_settings"
	match _route:
		Route.COLLECTION:
			return "house" if go(Route.HOUSE, {"via": "back"}) else "none"
		Route.CHAPTERS:
			return "house" if go(Route.HOUSE, {"via": "back"}) else "none"
		Route.MAP:
			return "chapters" if go(Route.CHAPTERS, {"via": "back"}) else "none"
		Route.PRESTART:
			return "map" if go(Route.MAP, {"via": "back"}) else "none"
		Route.EVENTS, Route.SHOP, Route.PROFILE_SETTINGS:
			return "house" if go(Route.HOUSE, {"via": "back"}) else "none"
	return "none"
