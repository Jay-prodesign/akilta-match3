extends SceneTree

const HouseScene = preload("res://src/ui/home/house_home.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var house = HouseScene.instantiate()
	root.add_child(house)
	await process_frame
	house.set_available_level_count(3)

	var fresh = ProgressScript.new()
	house.set_progress(fresh)
	await process_frame

	var presentation: Dictionary = house.house_presentation_contract()
	var north_star: Dictionary = house.north_star_home_contract()
	_expect(bool(presentation.get("persistent_slots_authored", false)), "House FTUE/returning/completion slots must be authored")
	_expect(bool(presentation.get("hotspots_authored", false)), "House Curio and Keeper hotspots must be authored")
	_expect(bool(presentation.get("curio_inspect_authored", false)), "House Curio inspect must use an authored scene")
	_expect(bool(presentation.get("keeper_role_authored", false)), "Keeper role must use an authored scene")
	_expect(bool(presentation.get("restoration_authored", false)), "House restoration must use an authored scene")
	_expect(not bool(presentation.get("runtime_overlay_factory", true)), "House must not rebuild player-facing overlays at runtime")
	_expect(float(north_star.get("primary_cta_height", 0.0)) >= 88.0 and float(north_star.get("primary_cta_height", 0.0)) <= 98.0 and float(north_star.get("primary_cta_width", 0.0)) >= 620.0 and float(north_star.get("primary_cta_width", 0.0)) <= 660.0, "House primary CTA must match the locked-board compact hero proportion")
	_expect(bool(north_star.get("primary_cta_centered", false)), "House primary CTA must remain centered above navigation")
	_expect(bool(north_star.get("bottom_nav_reserved", false)), "House content must reserve vertical space for the compact bottom navigation")
	_expect(bool(north_star.get("world_underlays_home_ui", false)), "House world must continue behind the lower Home UI instead of ending in a dead slab")
	_expect(bool(north_star.get("direct_level_cta", false)), "House CTA must expose the direct current-level action")
	_expect(bool(north_star.get("compact_title_plate", false)), "House must use the locked-board compact centered title plaque")
	_expect(bool(north_star.get("scene_authored_primary_cta", false)), "House primary CTA must preserve its seam-free authored gold/plum material")
	_expect(bool(north_star.get("status_strip_suppressed", false)), "House must not stack a redundant Curio status strip over the title/CTA hierarchy")
	_expect(bool(north_star.get("ftue_strip_suppressed", false)), "Fresh House must not insert a tutorial strip into the locked-board Home composition")
	var ftue: Dictionary = house.ftue_house_contract()
	_expect(bool(ftue.get("guidance_via_keeper", false)), "Fresh House must retain truthful optional guidance through the Keeper")
	var guide_art := house.get_node_or_null("Layout/FirstRitualGuide/GuideRow/KeeperArt") as TextureRect
	_expect(guide_art != null and guide_art.texture != null, "Optional House guidance must retain Keeper production art")
	for hotspot_path in [
		"RoomView/CurioHotspots/MoonHotspot",
		"RoomView/CurioHotspots/MothHotspot",
		"RoomView/CurioHotspots/ThornHotspot",
		"RoomView/CurioHotspots/KeeperHotspot",
	]:
		_expect(house.get_node_or_null(hotspot_path) is Button, "Authored House hotspot missing: %s" % hotspot_path)

	var keeper_hotspot := house.get_node("RoomView/CurioHotspots/KeeperHotspot") as Button
	keeper_hotspot.emit_signal("pressed")
	await process_frame
	var keeper_overlay = house.get_node_or_null("KeeperRoleOverlay")
	_expect(keeper_overlay != null and keeper_overlay.has_method("keeper_contract"), "Keeper hotspot must open authored Keeper role scene")
	if keeper_overlay != null and keeper_overlay.has_method("keeper_contract"):
		var keeper_contract: Dictionary = keeper_overlay.keeper_contract()
		_expect(bool(keeper_contract.get("authored_scene", false)) and bool(keeper_contract.get("art_loaded", false)), "Keeper role scene must render Keeper art")
		var keeper_close := keeper_overlay.get_node_or_null("Card/Content/Close") as Button
		if keeper_close != null:
			keeper_close.emit_signal("pressed")
			await process_frame

	var owned = ProgressScript.new()
	owned.apply_level_win("house-r1", "ch01_level_001", "moon_cameo", 1)
	house.set_progress(owned)
	await process_frame
	_expect(house.open_curio_inspect("moon_cameo"), "Owned Moon Cameo must open House inspect")
	await process_frame
	var inspect = house.get_node_or_null("HouseCurioInspect")
	_expect(inspect != null and inspect.has_method("inspect_contract"), "Owned Curio must open authored House inspect scene")
	if inspect != null and inspect.has_method("inspect_contract"):
		var inspect_contract: Dictionary = inspect.inspect_contract()
		_expect(bool(inspect_contract.get("authored_scene", false)) and bool(inspect_contract.get("art_loaded", false)), "House inspect scene must render owned Curio art")
		var inspect_close := inspect.get_node_or_null("Card/Content/Close") as Button
		if inspect_close != null:
			inspect_close.emit_signal("pressed")
			for _frame in range(12):
				await process_frame

	house.show_restoration_ceremony("moon_cameo", 1)
	await process_frame
	var restoration = house.get_node_or_null("RestorationOverlay")
	_expect(restoration != null and restoration.has_method("restoration_contract"), "Reward handoff must open authored House restoration scene")
	if restoration != null and restoration.has_method("restoration_contract"):
		var restoration_contract: Dictionary = restoration.restoration_contract()
		_expect(bool(restoration_contract.get("authored_scene", false)), "Restoration contract must identify authored scene")
		_expect(bool(restoration_contract.get("motif_loaded", false)) and bool(restoration_contract.get("curio_art_loaded", false)), "Restoration must render motif and exact Curio art")
		var continue_button := restoration.get_node_or_null("CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button
		_expect(continue_button != null, "Authored restoration must preserve focused Continue CTA")
		if continue_button != null:
			continue_button.emit_signal("pressed")
			await process_frame

	house.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored House state family")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
