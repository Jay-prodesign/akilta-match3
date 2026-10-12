extends SceneTree

const HapticsController = preload("res://src/feedback/haptics_controller.gd")

var failures: Array[String] = []
var calls: Array[Dictionary] = []

func _init() -> void:
	var h = HapticsController.new()
	h.set_platform_sink(func(duration_ms: int, category: int): calls.append({"ms": duration_ms, "category": category}))

	h.apply_settings({"haptics_enabled": false})
	_expect(not h.request_match(), "disabled haptics must fail open without vibrating")
	_expect(calls.is_empty(), "disabled haptics must make no platform call")

	h.apply_settings({"haptics_enabled": true})
	_expect(h.request_ui(), "enabled UI haptic must play")
	_expect(not h.request_ui(), "dense UI requests must be throttled")
	_expect(h.request_match(), "enabled match haptic must play")
	_expect(not h.request_match(), "dense match requests must be throttled")
	_expect(h.request_special(), "special haptic must remain distinct from match throttle")
	_expect(h.request_terminal("won"), "win haptic must play once per attempt")
	_expect(not h.request_terminal("won"), "terminal haptic must be once per attempt")
	_expect(calls.size() == 4, "ui + match + special + win must produce exactly four platform calls")
	_expect(int(calls[0]["ms"]) == HapticsController.UI_MS, "ui duration contract")
	_expect(int(calls[1]["ms"]) == HapticsController.MATCH_MS, "match duration contract")
	_expect(int(calls[2]["ms"]) == HapticsController.SPECIAL_MS, "special duration contract")
	_expect(int(calls[3]["ms"]) == HapticsController.WIN_MS, "win duration contract")

	h.reset_for_new_attempt()
	_expect(h.request_terminal("failed"), "retry must re-arm terminal feedback for a later fail")
	_expect(int(calls[4]["ms"]) == HapticsController.FAIL_MS, "fail duration contract")

	var ui_diag: Dictionary = h.get_diagnostics(HapticsController.Category.UI)
	_expect(int(ui_diag["requests"]) == 2 and int(ui_diag["played"]) == 1 and int(ui_diag["suppressed"]) == 1, "UI haptics must record one played and one throttled request")

	var match_diag: Dictionary = h.get_diagnostics(HapticsController.Category.MATCH)
	_expect(int(match_diag["requests"]) == 3, "match diagnostics must include disabled and throttled requests")
	_expect(int(match_diag["played"]) == 1, "only one match tick should have played")
	_expect(int(match_diag["suppressed"]) == 2, "disabled + throttled match requests should be suppressed")

	if failures.is_empty():
		print("TEST_PASS: first-party Match-3 haptics feedback")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
