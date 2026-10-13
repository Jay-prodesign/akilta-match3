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
	_expect(current != null and current.text.contains("RARE FINDS") and current.text.contains("0 / 3 AWAKENED") and current.text.contains("BEGIN RESTORATION"), "fresh current wing copy")
	_expect(screen.has_method("chapter_visual_contract"), "S02 must expose its current-wing visual contract")
	if screen.has_method("chapter_visual_contract"):
		var visual_contract: Dictionary = screen.chapter_visual_contract()
		_expect(bool(visual_contract.get("authored_scene_structure", false)), "S02 must own six authored chapter slots in its scene tree")
		_expect(bool(visual_contract.get("world_backdrop_loaded", false)), "S02 authored House-world backdrop must load")
		_expect(bool(visual_contract.get("current_wing_art_loaded", false)), "S02 current wing authored place art must load")
		_expect(bool(visual_contract.get("current_wing_art_is_raster", false)), "S02 current wing place art must use raster runtime artwork")
		_expect(bool(visual_contract.get("future_wings_artless_until_authored", false)), "S02 future wings must remain artless rather than fabricate chapter artwork")
		_expect(bool(visual_contract.get("future_wings_use_house_world_glass", false)), "S02 sealed wings must reveal the authored House world instead of opaque empty slabs")
		_expect(not bool(visual_contract.get("future_wings_specific_art_claimed", true)), "S02 must not imply unauthored future-wing-specific artwork")
		_expect(bool(visual_contract.get("north_star_title_hierarchy", false)), "S02 must retain a strong North Star CHOOSE A WING title")
		_expect(bool(visual_contract.get("compact_header_back", false)), "S02 back control must remain compact instead of consuming header width")
		_expect(bool(visual_contract.get("summary_plate", false)), "S02 progress summary must sit on an authored plate")
		_expect(bool(visual_contract.get("chapter_descriptors_present", false)), "S02 sealed wings must preserve their North Star chapter identities without fabricated art")
		_expect(bool(visual_contract.get("north_star_vertical_wing_list", false)), "S02 must present the six House wings as a single North Star portrait list")
		_expect(bool(visual_contract.get("current_wing_art_subordinate", false)), "S02 current wing artwork must remain a compact list thumbnail rather than consume the card")
	_expect(screen.get_node_or_null("ResourceBar") != null, "S02 global resources header missing")
	_expect(screen.get_node_or_null("Layout/ChapterHeader/HeaderBack") != null, "S02 header back missing")
	var current_wing_art: TextureRect = current.get_node_or_null("CurrentWingArtwork") as TextureRect if current != null else null
	_expect(current_wing_art != null and current_wing_art.texture != null, "S02 current wing must render authored place art inside the active chapter card")
	_expect(current_wing_art != null and current_wing_art.get_parent() == current, "S02 current wing art must belong to the active chapter hotspot")
	var backdrop: TextureRect = screen.get_node_or_null("ChapterWorldBackdrop")
	_expect(backdrop != null and backdrop.texture != null, "S02 authored chapter-world raster missing")
	for id in ["witch_atelier", "dark_vanity", "archive", "moon_conservatory", "cemetery_garden"]:
		var locked: Button = screen.get_chapter_button(id)
		_expect(locked != null and not locked.disabled, "%s sealed card must remain inspectable" % id)
		_expect(screen.chapter_state(id) == "future_wings_locked", "%s must expose future_wings_locked" % id)
		_expect(locked.icon == null, "%s must not use placeholder wing artwork" % id)
	var future_wing: Button = screen.get_chapter_button("witch_atelier")
	future_wing.emit_signal("pressed")
	await process_frame
	var sealed_contract: Dictionary = screen.sealed_explanation_contract()
	_expect(bool(sealed_contract.get("open", false)), "sealed future wing must open an explanation")
	_expect(bool(sealed_contract.get("authored_scene", false)), "sealed future wing explanation must use the authored modal scene")
	_expect(bool(sealed_contract.get("touch_target_ok", false)), "sealed future wing explanation close action must retain a mobile touch target")
	_expect(not bool(sealed_contract.get("runtime_ui_factory", true)), "sealed explanation must not rebuild player-facing modal nodes at runtime")
	_expect(bool(sealed_contract.get("sealed_truth", false)) and bool(sealed_contract.get("no_fake_unlock", false)), "sealed explanation must forbid fabricated unlock truth")
	_expect(String(sealed_contract.get("sealed_kind", "")) == "future_chapter", "future wing sealed kind mismatch")
	_expect(String(sealed_contract.get("reason", "")).contains("not playable in this build"), "future wing reason must state build availability")
	_expect(String(sealed_contract.get("requirement", "")).contains("No unlock date") and String(sealed_contract.get("requirement", "")).contains("purchase path"), "future wing explanation must not invent date or commerce")
	var sealed_close: Button = screen.get_node_or_null("LockedExplanation/LockedPanel/Content/Close") as Button
	_expect(sealed_close != null, "sealed wing explanation close action missing")
	if sealed_close != null:
		sealed_close.emit_signal("pressed")
		await process_frame

	var partial = ProgressScript.new()
	partial.apply_level_win("chapters-l1", "ch01_level_001", "moon_cameo", 1)
	partial.apply_level_win("chapters-l2", "ch01_level_002", "moth_reliquary", 2)
	partial.lives = 3
	partial.coins = 777
	partial.gems = 9
	screen.set_progress(partial)
	await process_frame
	_expect(screen.chapter_state("curio_boutique") == "current_partial", "2/3 S02 must expose current_partial")
	_expect(current.text.contains("RARE FINDS") and current.text.contains("2 / 3 AWAKENED") and current.text.contains("CONTINUE RESTORATION"), "partial current-wing CTA truth")
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
	_expect(current.text.contains("RARE FINDS") and current.text.contains("RESTORED 3 / 3") and current.text.contains("REVISIT RITUALS"), "complete current-wing replay truth")
	var lock_reason: Label = screen.get_node_or_null("Layout/LockReason")
	_expect(lock_reason != null and lock_reason.text.contains("FIVE WINGS SEALED"), "completed S02 must keep future-wing lock reason truthful")

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
