extends SceneTree

const AudioDirector = preload("res://src/feedback/audio_director.gd")

var failures: Array[String] = []
var calls: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var director = AudioDirector.new()
	root.add_child(director)
	await process_frame

	var contract: Dictionary = director.contract()
	_expect(String(contract.get("license", "")) == "CC0", "audio contract must remain CC0-only")
	_expect(bool(contract.get("ambient_loaded", false)), "Curio House ambient candidate must load")
	_expect(bool(contract.get("chime_loaded", false)), "ritual chime candidate must load")
	_expect(bool(contract.get("soft_match_loaded", false)), "soft match tap must be generated for repeated gameplay feedback")
	_expect(String(contract.get("match_feedback", "")) == "procedural_soft_wood_glass_tap", "match feedback must use the gentle replacement rather than the old repeated bell")
	_expect(String(contract.get("music_bus", "")) == "Music", "ambient must route through Music bus")
	_expect(String(contract.get("sfx_bus", "")) == "SFX", "feedback must route through SFX bus")
	_expect((contract.get("feedback", {}) as Dictionary).size() >= 5, "semantic feedback profiles must exist")
	_expect(String(contract.get("mix_profile", "")) == "restrained_dark_cabinet_v2", "mix must use the restrained cabinet profile")
	_expect(float(contract.get("ambient_gain_db", 0.0)) <= -32.0, "ambient must stay subtle beneath gameplay")
	_expect(float(contract.get("match_gain_db", 0.0)) <= -30.0, "repeated match taps must not be piercing")
	var profiles: Dictionary = contract.get("feedback", {})
	_expect(float(profiles["win"]["gain_db"]) > float(profiles["special"]["gain_db"]), "win can lift above ordinary special feedback without becoming loud")
	_expect(float(profiles["fail"]["gain_db"]) <= -30.0, "failure feedback must remain restrained")

	director.set_play_sink(func(kind: String, profile: Dictionary): calls.append({"kind": kind, "profile": profile}))
	for kind in ["match", "special", "win", "fail", "retry"]:
		_expect(director.request_feedback(kind), "%s feedback must be accepted" % kind)
	_expect(not director.request_feedback("unknown"), "unknown feedback must fail open")
	_expect(calls.size() == 5, "five semantic feedback requests must reach the sink")
	_expect(float(calls[2]["profile"]["pitch"]) > float(calls[0]["profile"]["pitch"]), "win chime must read brighter than match")
	_expect(float(calls[3]["profile"]["pitch"]) < float(calls[0]["profile"]["pitch"]), "fail chime must read lower than match")

	director.queue_free()
	await process_frame
	if failures.is_empty():
		print("TEST_PASS: CC0 Level 1 audio feedback")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
