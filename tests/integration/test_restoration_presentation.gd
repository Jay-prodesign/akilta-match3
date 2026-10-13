extends SceneTree

const HouseScene := preload("res://src/ui/home/house_home.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var dormant = HouseScene.instantiate()
	root.add_child(dormant)
	await _frames(2)
	var dormant_room = dormant.get_node_or_null("RoomView")
	_expect(dormant_room != null and dormant_room.has_method("living_house_contract"), "Dormant House living-state contract missing")
	var dormant_living: Dictionary = dormant_room.living_house_contract() if dormant_room != null and dormant_room.has_method("living_house_contract") else {}
	_expect(String(dormant_living.get("ambient_tier", "")) == "dormant", "stage 0 House must own a dormant ambient tier")
	_expect(float(dormant_living.get("stage_veil_alpha", 0.0)) >= 0.35, "dormant House must visibly suppress the fully-lit authored backdrop")
	_expect(bool(dormant_living.get("authored_backdrop_loaded", false)), "Living House must retain authored raster environment art")
	_expect(bool(dormant_living.get("same_camera", false)), "Living House stages must preserve the same camera")
	_expect(not bool(dormant_living.get("procedural_environment_fallback", true)), "Living House must not fall back to procedural room art")
	_expect(not bool(dormant_living.get("breathing_active", true)), "dormant House must not pulse")
	dormant.queue_free()
	await _frames(2)

	var reduced = HouseScene.instantiate()
	root.add_child(reduced)
	await _frames(2)
	reduced.set_available_level_count(3)
	reduced.apply_presentation_settings({"reduced_motion": true})
	var p2 = _progress_with_wins(2)
	reduced.set_progress(p2)
	reduced.show_restoration_ceremony("moth_reliquary", 2)
	await _frames(3)
	var reduced_vfx: Dictionary = reduced.restoration_vfx_contract()
	_expect(String(reduced_vfx.get("slot", "")) == "S07/house_hero/awakening_fx", "House awaken VFX must own canonical S07 awakening_fx slot")
	_expect(int(reduced_vfx.get("play_count", 0)) == 1, "Reduced Motion restoration must still register one semantic awaken event")
	_expect(bool(reduced_vfx.get("reduced_motion_supported", false)), "House awaken VFX must support Reduced Motion")
	_expect(bool(reduced_vfx.get("reduced_motion", false)), "Reduced Motion restoration VFX contract must report the active setting")
	_expect(not bool(reduced_vfx.get("active", true)), "Reduced Motion must resolve House awaken without decorative animation")
	_expect(not bool(reduced_vfx.get("echo_spawned", true)), "Reduced Motion must not spawn the transient Curio awakening echo")
	_expect(bool(reduced_vfx.get("world_fills_hidden_nav_region", false)), "Restoration world must fill the hidden navigation region instead of exposing a black footer")
	_expect(bool(reduced_vfx.get("world_art_full_bleed", false)), "Restoration authored world rect must extend to the bottom edge while navigation is hidden")
	var reduced_room = reduced.get_node_or_null("RoomView")
	var reduced_card: PanelContainer = reduced.get_node_or_null("RestorationOverlay/CeremonyCard") as PanelContainer
	var reduced_hero: TextureRect = reduced.get_node_or_null("RestorationOverlay/AwakeningMotif") as TextureRect
	_expect(reduced_room != null, "Reduced Motion restoration room missing")
	if reduced_room != null:
		var contract: Dictionary = reduced_room.restoration_contract()
		_expect(int(contract.get("stage", -1)) == 2, "Reduced Motion must resolve immediately to restoration stage 2")
		_expect(bool(contract.get("moth_reliquary_visible", false)), "Reduced Motion must retain the restored Moth Reliquary")
		_expect(reduced_room.modulate == Color.WHITE, "Reduced Motion must not leave the House in a transitional tint")
		_expect(reduced_room.get_node_or_null("RestorationAwakeningEcho") == null, "Reduced Motion must skip scale/tween awakening echo")
		var living: Dictionary = reduced_room.living_house_contract()
		_expect(String(living.get("ambient_tier", "")) == "side_display_awake", "stage 2 House must activate side-display atmosphere")
		_expect(float(living.get("stage_veil_alpha", 1.0)) < float(dormant_living.get("stage_veil_alpha", 0.0)), "restoration must progressively reveal the authored House")
		_expect(not bool(living.get("breathing_active", true)), "Reduced Motion must keep Living House lighting static")
		_expect(int(living.get("restored_curio_count", 0)) == 2, "stage 2 Living House must reflect two persistent Curios")
	_expect(reduced_card != null and reduced_card.size.y <= reduced.size.y * 0.13, "Restoration ceremony summary must stay compact over the House world")
	_expect(reduced_card != null and reduced_card.get_node_or_null("CeremonyContent/TopPad") != null, "Restoration ceremony must reserve a top inset inside production chrome")
	var reduced_continue := reduced.get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button
	_expect(reduced_continue != null and reduced_continue.custom_minimum_size.y >= 88.0, "Restoration CTA must preserve the 88px touch target after chrome inset")
	_expect(reduced_hero != null and reduced_hero.texture != null, "Restoration must render the recovered Curio motif as production hero artwork while exact item identity remains in the summary")
	var reduced_overlay_contract: Dictionary = reduced.get_node("RestorationOverlay").restoration_contract()
	_expect(bool(reduced_overlay_contract.get("house_first_composition", false)), "Restoration must keep the recovered Curio bounded so the House remains the visual hero")
	_expect(bool(reduced_overlay_contract.get("before_after_state_rail", false)), "Restoration must expose a truthful dormant-to-awakened state comparison")
	reduced.queue_free()
	await _frames(2)

	var animated = HouseScene.instantiate()
	root.add_child(animated)
	await _frames(2)
	animated.set_available_level_count(3)
	animated.apply_presentation_settings({"reduced_motion": false})
	var p3 = _progress_with_wins(3)
	animated.set_progress(p3)
	animated.show_restoration_ceremony("thorned_locket", 3)
	await _frames(3)
	var animated_vfx: Dictionary = animated.restoration_vfx_contract()
	_expect(String(animated_vfx.get("slot", "")) == "S07/house_hero/awakening_fx", "Animated House awaken VFX must retain canonical S07 slot ownership")
	_expect(int(animated_vfx.get("play_count", 0)) == 1 and int(animated_vfx.get("last_stage", 0)) == 3, "Stage 3 restoration must register exactly one House awaken VFX event")
	_expect(String(animated_vfx.get("last_curio_id", "")) == "thorned_locket", "House awaken VFX must preserve exact Curio identity")
	_expect(bool(animated_vfx.get("active", false)), "Animated House awaken VFX must be active during the observed transition window")
	_expect(bool(animated_vfx.get("echo_spawned", false)), "Stage 3 House awaken must spawn the contract-owned Curio echo")
	_expect(bool(animated_vfx.get("world_fills_hidden_nav_region", false)), "Animated restoration world must fill the hidden navigation region")
	_expect(bool(animated_vfx.get("world_art_full_bleed", false)), "Animated restoration authored world rect must use the ceremony full-bleed state")
	var animated_room = animated.get_node_or_null("RoomView")
	var animated_card: PanelContainer = animated.get_node_or_null("RestorationOverlay/CeremonyCard") as PanelContainer
	var animated_hero: TextureRect = animated.get_node_or_null("RestorationOverlay/AwakeningMotif") as TextureRect
	_expect(animated_room != null, "Animated restoration room missing")
	if animated_room != null:
		var contract: Dictionary = animated_room.restoration_contract()
		_expect(int(contract.get("stage", -1)) == 3, "Animated restoration must reach stage 3")
		_expect(bool(contract.get("thorned_locket_visible", false)), "Animated restoration must retain the Thorned Locket")
		var echo: TextureRect = animated_room.get_node_or_null("RestorationAwakeningEcho") as TextureRect
		_expect(echo != null and echo.texture != null, "Stage 3 must render the contract-owned Curio awakening echo")
		var living: Dictionary = animated_room.living_house_contract()
		_expect(String(living.get("ambient_tier", "")) == "opening_set_alive", "stage 3 House must reach fully alive opening ambience")
		_expect(bool(living.get("breathing_active", false)), "animated stage 3 House must keep subtle ambient breathing")
		_expect(float(living.get("stage_veil_alpha", 1.0)) < 0.10, "stage 3 House must reveal nearly all authored environment luminance")
		_expect(int(living.get("restored_curio_count", 0)) == 3, "stage 3 Living House must reflect all three persistent Curios")
	_expect(animated_card != null and animated_card.size.y <= animated.size.y * 0.13, "Animated ceremony summary must stay compact over the House world")
	_expect(animated_card != null and animated_card.get_node_or_null("CeremonyContent/TopPad") != null, "Animated restoration must preserve the production-chrome top inset")
	_expect(animated_hero != null and animated_hero.texture != null, "Animated restoration must retain the recovered Curio production motif")
	var animated_overlay_contract: Dictionary = animated.get_node("RestorationOverlay").restoration_contract()
	_expect(bool(animated_overlay_contract.get("house_first_composition", false)), "Animated restoration must preserve the bounded House-first Curio composition")
	var animated_continue := animated.get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button
	_expect(animated_continue != null, "Animated restoration continue CTA missing")
	if animated_continue != null:
		animated_continue.emit_signal("pressed")
		await _frames(3)
		_expect(animated_room.offset_bottom <= -90.0, "House world must restore the bottom navigation reserve after restoration closes")
		var returned_living: Dictionary = animated_room.living_house_contract()
		_expect(not bool(returned_living.get("restoration_full_bleed", true)), "House world must leave full-bleed mode after restoration closes")
	animated.queue_free()
	await _frames(2)

	if failures.is_empty():
		print("TEST_PASS: S07 restoration presentation and reduced-motion contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _progress_with_wins(count: int):
	var progress = ProgressScript.new()
	if count >= 1:
		progress.apply_level_win("restoration-l1", "ch01_level_001", "moon_cameo", 1)
	if count >= 2:
		progress.apply_level_win("restoration-l2", "ch01_level_002", "moth_reliquary", 2)
	if count >= 3:
		progress.apply_level_win("restoration-l3", "ch01_level_003", "thorned_locket", 3)
	return progress

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
