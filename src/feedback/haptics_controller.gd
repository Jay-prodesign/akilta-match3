class_name Match3HapticsController
extends RefCounted

## AKILTA first-party adaptation of the fail-open/throttled haptics pattern proven in
## Sekiph82/Scrubbots scripts/haptics/haptics_controller.gd.
## Product-neutral infrastructure only: Match Game owns the event vocabulary and timings.

const INVALID_MS := 9
const UI_MS := 12
const MATCH_MS := 18
const SPECIAL_MS := 42
const WIN_MS := 180
const FAIL_MS := 55
const INVALID_THROTTLE_MS := 120
const UI_THROTTLE_MS := 90
const MATCH_THROTTLE_MS := 55

enum Category { INVALID, UI, MATCH, SPECIAL, WIN, FAIL }

var _enabled := true
var _last_invalid_ms := -100000
var _last_ui_ms := -100000
var _last_match_ms := -100000
var _terminal_emitted := false
var _platform_sink: Callable = Callable()
var _requests: Dictionary = {}
var _played: Dictionary = {}
var _suppressed: Dictionary = {}

func _init() -> void:
	for category in Category.values():
		_requests[category] = 0
		_played[category] = 0
		_suppressed[category] = 0

func apply_settings(state: Dictionary) -> void:
	_enabled = bool(state.get("haptics_enabled", true))

func is_enabled() -> bool:
	return _enabled

func request_invalid() -> bool:
	_requests[Category.INVALID] += 1
	if not _enabled:
		_suppressed[Category.INVALID] += 1
		return false
	var now := Time.get_ticks_msec()
	if now - _last_invalid_ms < INVALID_THROTTLE_MS:
		_suppressed[Category.INVALID] += 1
		return false
	_last_invalid_ms = now
	return _emit(INVALID_MS, Category.INVALID)

func request_ui() -> bool:
	_requests[Category.UI] += 1
	if not _enabled:
		_suppressed[Category.UI] += 1
		return false
	var now := Time.get_ticks_msec()
	if now - _last_ui_ms < UI_THROTTLE_MS:
		_suppressed[Category.UI] += 1
		return false
	_last_ui_ms = now
	return _emit(UI_MS, Category.UI)

func request_match() -> bool:
	_requests[Category.MATCH] += 1
	if not _enabled:
		_suppressed[Category.MATCH] += 1
		return false
	var now := Time.get_ticks_msec()
	if now - _last_match_ms < MATCH_THROTTLE_MS:
		_suppressed[Category.MATCH] += 1
		return false
	_last_match_ms = now
	return _emit(MATCH_MS, Category.MATCH)

func request_special() -> bool:
	_requests[Category.SPECIAL] += 1
	if not _enabled:
		_suppressed[Category.SPECIAL] += 1
		return false
	return _emit(SPECIAL_MS, Category.SPECIAL)

func request_terminal(result: String) -> bool:
	var category := Category.WIN if result == "won" else Category.FAIL
	_requests[category] += 1
	if _terminal_emitted or not _enabled:
		_suppressed[category] += 1
		return false
	_terminal_emitted = true
	return _emit(WIN_MS if result == "won" else FAIL_MS, category)

func reset_for_new_attempt() -> void:
	_terminal_emitted = false
	_last_match_ms = -100000

func set_platform_sink(sink: Callable) -> void:
	_platform_sink = sink

func get_diagnostics(category: int) -> Dictionary:
	return {
		"requests": int(_requests.get(category, 0)),
		"played": int(_played.get(category, 0)),
		"suppressed": int(_suppressed.get(category, 0)),
	}

func _emit(duration_ms: int, category: int) -> bool:
	_played[category] = int(_played.get(category, 0)) + 1
	if _platform_sink.is_valid():
		_platform_sink.call(duration_ms, category)
	elif Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(duration_ms)
	return true
