extends SceneTree

const ChapterScene := preload("res://src/ui/map/chapter_select.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = ChapterScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var fresh = ProgressScript.new()
	fresh.lives = 4
	fresh.coins = 321
	fresh.gems = 7
	screen.set_progress(fresh)
	await process_frame
	_expect(screen.chapter_state("curio_boutique") == "first_wing_open", "fresh S02 must expose first_wing_open")
	var current: Button = screen.get_chapter_button("curio_boutique")
	_expect(current != null and current.text.contains("OPENING RITUALS") and current.text.contains("0 / 3"), "fresh current wing copy")
	_expect(screen.get_node_or_null("ResourceBar") != null, "S02 global resources header missing")
	_expect(screen.get_node_or_null("Layout/ChapterHeader/HeaderBack") != null, "S02 header back missing")
	var backdrop: TextureRect = screen.get_node_or_null("ChapterWorldBackdrop")
	_expect(backdrop != null and backdrop.texture != null, "S02 authored chapter-world raster missing")
	for id in ["witch_atelier", "dark_vanity", "archive", "moon_conservatory", "cemetery_garden"]:
		var locked: Button = screen.get_chapter_button(id)
		_expect(locked != null and locked.disabled, "%s must remain locked" % id)
		_expect(screen.chapter_state(id) == "future_wings_locked", "%s must expose future_wings_locked" % id)
		_expect(locked.icon == null, "%s must not use placeholder wing artwork" % id)

	var partial = ProgressScript.new()
	partial.apply_level_win("chapters-l1", "ch01_level_001", "moon_cameo", 1)
	partial.apply_level_win("chapters-l2", "ch01_level_002", "moth_reliquary", 2)
	partial.lives = 3
	partial.coins = 777
	partial.gems = 9
	screen.set_progress(partial)
	await process_frame
	_expect(screen.chapter_state("curio_boutique") == "current_partial", "2/3 S02 must expose current_partial")
	_expect(current.text.contains("2 / 3 DISPLAYS AWAKENED") and current.text.contains("CONTINUE"), "partial current-wing CTA truth")
	var resource_coin: Label = screen.get_node_or_null("ResourceBar/Resources/CoinResourceChip/HBoxContainer/CoinResource") as Label
	if resource_coin == null:
		resource_coin = screen.find_child("CoinResource", true, false) as Label
	_expect(resource_coin != null and resource_coin.text == "777", "S02 resource header must use persisted coin truth")

	var complete = ProgressScript.new()
	complete.apply_level_win("chapters-c1", "ch01_level_001", "moon_cameo", 1)
	complete.apply_level_win("chapters-c2", "ch01_level_002", "moth_reliquary", 2)
	complete.apply_level_win("chapters-c3", "ch01_level_003", "thorned_locket", 3)
	screen.set_progress(complete)
	await process_frame
	_expect(screen.chapter_state("curio_boutique") == "current_complete", "3/3 S02 must expose current_complete")
	_expect(current.text.contains("RESTORED") and current.text.contains("3 / 3") and current.text.contains("FIRST CABINET SET"), "complete current-wing replay truth")
	var lock_reason: Label = screen.get_node_or_null("Layout/LockReason")
	_expect(lock_reason != null and lock_reason.text.contains("FIVE WINGS REMAIN SEALED"), "completed S02 must keep future-wing lock reason truthful")

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("TEST_PASS: S02 Chapters production state contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
