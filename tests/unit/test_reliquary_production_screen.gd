extends SceneTree

const CollectionScene = preload("res://src/ui/collection/curio_collection.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var progress = ProgressScript.new()
	progress.apply_level_win("r1", "ch01_level_001", "moon_cameo", 1)
	progress.apply_level_win("r2", "ch01_level_002", "moth_reliquary", 2)
	progress.apply_level_win("r3", "ch01_level_003", "thorned_locket", 3)

	var screen = CollectionScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_progress(progress)
	await process_frame

	var contract: Dictionary = screen.curio_asset_contract()
	_expect(bool(contract.get("raster_runtime", false)), "Reliquary must use raster runtime Curio art")
	_expect(bool(contract.get("authored_display_slots", false)), "Reliquary must own three authored Curio art slots")
	_expect(bool(contract.get("world_backdrop_loaded", false)), "Reliquary must load authored House-world backdrop")
	_expect(bool(contract.get("authored_detail_scene", false)), "Curio detail must be an authored scene")
	_expect(bool(contract.get("north_star_title_hierarchy", false)), "Reliquary must retain a strong North Star page title")
	_expect(bool(contract.get("north_star_count_plate", false)), "Reliquary progress must sit on an authored readable plate")
	_expect(bool(contract.get("curio_art_readable", false)), "Reliquary Curio art must remain readable inside compact cabinet niches")
	_expect(bool(contract.get("north_star_collection_grid", false)), "Reliquary must present the opening Curios as a truthful 2x2 cabinet grid")
	_expect(bool(contract.get("truthful_set_summary", false)), "Reliquary fourth grid cell must summarize the real three-Curio set rather than inventing another collectible")
	_expect(bool(contract.get("cabinet_niche_scale", false)), "Reliquary Curios must read as artwork-dominant cabinet niches rather than compressed cards")
	_expect(bool(contract.get("collection_copy_subordinate", false)), "Reliquary must keep long lore/origin copy behind Details instead of crowding the collection")
	_expect(bool(contract.get("collection_occupies_cabinet_stage", false)), "Reliquary opening set must own the collection stage instead of floating above empty world space")
	_expect(bool(contract.get("redundant_navigation_suppressed", false)), "Reliquary must rely on product navigation instead of a redundant form-like Back region")
	_expect(bool(contract.get("asset_backed_display_chrome", false)), "Reliquary displays must use verified quiet production chrome")
	_expect(bool(contract.get("asset_backed_actions", false)), "Reliquary DETAILS and Back actions must use verified production action chrome")
	_expect(not bool(contract.get("runtime_style_factory", true)), "Reliquary must not create StyleBox presentation resources at runtime")
	_expect(bool(contract.get("redundant_status_suppressed", false)), "Reliquary must avoid repeating the same set status in a detached footer band")
	_expect(bool(contract.get("intro_subordinate", false)), "Reliquary explanatory prose must not compete with the collection")
	_expect(not bool(contract.get("runtime_ui_factory", true)), "Reliquary must not rebuild presentation nodes at runtime")

	var moon_art := screen.get_node_or_null("Layout/Cards/MoonCard/Content/RitualArt") as TextureRect
	var moth_art := screen.get_node_or_null("Layout/Cards/Slot2/Content/Number/RewardArt") as TextureRect
	var locket_art := screen.get_node_or_null("Layout/Cards/Slot3/Content/Number/RewardArt") as TextureRect
	var footer := screen.get_node_or_null("Layout/CabinetFooter") as Label
	var back := screen.get_node_or_null("Layout/Back") as Button
	_expect(moon_art != null and moon_art.texture != null and moon_art.custom_minimum_size.y >= 280.0, "Moon Cameo must remain artwork-dominant inside its cabinet niche")
	_expect(moth_art != null and moth_art.texture != null, "Moth Reliquary authored display art missing")
	_expect(locket_art != null and locket_art.texture != null, "Thorned Locket authored display art missing")
	_expect(footer != null and not footer.visible and back != null and not back.visible, "Redundant footer/back chrome must stay out of the collection stage")
	var grid := screen.get_node_or_null("Layout/Cards") as GridContainer
	var summary := screen.get_node_or_null("Layout/Cards/SetSummary") as PanelContainer
	var summary_progress := screen.get_node_or_null("Layout/Cards/SetSummary/Content/Progress") as Label
	_expect(grid != null and grid.columns == 2 and grid.get_child_count() == 4, "Reliquary must render three real Curios plus one truthful set-summary cell")
	_expect(summary != null and summary_progress != null and summary_progress.text == "3 / 3 AWAKENED", "Completed Reliquary summary must mirror exact collection truth")

	for path in [
		"Layout/Cards/MoonCard/DetailActionLayer/InspectAction",
		"Layout/Cards/Slot2/DetailActionLayer/InspectAction",
		"Layout/Cards/Slot3/DetailActionLayer/InspectAction",
	]:
		_expect(screen.get_node_or_null(path) is Button, "Authored DETAILS action missing: %s" % path)

	var inspect := screen.get_node("Layout/Cards/MoonCard/DetailActionLayer/InspectAction") as Button
	inspect.emit_signal("pressed")
	await process_frame
	var detail = screen.get_node_or_null("CurioDetailOverlay")
	_expect(detail != null and detail.has_method("detail_contract"), "DETAILS must open the authored Curio detail scene")
	if detail != null and detail.has_method("detail_contract"):
		var detail_contract: Dictionary = detail.detail_contract()
		_expect(bool(detail_contract.get("authored_scene", false)), "Curio detail contract must identify authored presentation")
		_expect(bool(detail_contract.get("art_loaded", false)), "Curio detail hero art must load")
		_expect(bool(detail_contract.get("view_in_house_visible", false)), "Owned Curio detail must expose View in House")
		_expect(bool(detail_contract.get("north_star_actions", false)), "Curio detail actions must retain the rounded North Star mobile CTA scale")
		_expect(bool(detail_contract.get("asset_backed_actions", false)), "Curio detail actions must use verified primary/utility production chrome")
		_expect(bool(detail_contract.get("content_bounded_card", false)), "Curio detail card must fit its content instead of leaving oversized dead vertical space")
		_expect(bool(detail_contract.get("modal_veil_strength", false)), "Curio detail modal must sufficiently suppress the collection UI behind it")
		var close := detail.get_node_or_null("CurioDetailCard/Content/Close") as Button
		_expect(close != null, "Curio detail close action missing")
		if close != null:
			close.emit_signal("pressed")
			await process_frame
			_expect(screen.get_node_or_null("CurioDetailOverlay") == null, "Curio detail must return to Reliquary")

	screen.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored Reliquary production display")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
