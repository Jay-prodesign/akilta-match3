extends SceneTree

const SettingsScene = preload("res://src/ui/settings/settings_panel.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = SettingsScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var contract: Dictionary = screen.settings_authored_contract()
	_expect(bool(contract.get("authored_house_sigil", false)), "Settings must render an authored House sigil")
	_expect(bool(contract.get("authored_world_backdrop", false)), "Settings must render authored House world art")
	_expect(bool(contract.get("standalone_destination_surface", false)), "Settings must identify as a standalone destination surface")
	_expect(bool(contract.get("sigil_raster_runtime", false)), "Settings House sigil must use raster runtime art")
	_expect(bool(contract.get("authored_style_resources", false)), "Settings normal/high-contrast style resources must be authored")
	_expect(not bool(contract.get("runtime_ui_factory", true)), "Settings must not create player-facing nodes at runtime")
	_expect(bool(contract.get("north_star_title_hierarchy", false)), "Settings must retain a strong North Star title hierarchy")
	_expect(bool(contract.get("north_star_toggle_height", false)), "Settings controls must retain deliberate mobile rows at compact North Star density")
	_expect(bool(contract.get("intro_subordinate", false)), "Settings explanatory prose must not compete with controls")
	_expect(not bool(contract.get("runtime_style_factory", true)), "Settings must not create StyleBox presentation resources at runtime")
	_expect(bool(contract.get("scene_authored_card_chrome", false)), "Settings card must preserve its clean scene-authored dark/gold material")
	_expect(bool(contract.get("scene_authored_toggle_chrome", false)), "Settings rows must preserve screen-specific normal/hover/pressed materials")
	_expect(bool(contract.get("scene_authored_return_chrome", false)), "Settings return CTA must stay subordinate on its authored material")
	_expect(bool(contract.get("settings_ritual_list", false)), "Settings controls must read as a vertical ritual list instead of a web-style grid")
	_expect(bool(contract.get("crafted_ritual_rows", false)), "Settings ritual rows must separate setting identity, supporting copy and state medallions instead of flat developer toggle text")
	_expect(bool(contract.get("house_sigil_hero_scale", false)), "Settings House sigil must retain a hero-scale visual anchor")
	_expect(bool(contract.get("world_art_not_overdimmed", false)), "Settings must keep House world art visible around the control surface")
	_expect(bool(contract.get("compact_destination_surface", false)), "Settings control card must keep the world visible while preserving compact North Star density")
	_expect(bool(contract.get("visual_parity_gate_v3", false)), "Settings must satisfy the final-direction visual parity gate")

	var card := screen.get_node_or_null("Card") as PanelContainer
	var sigil := screen.get_node_or_null("Card/Content/HouseSigil") as TextureRect
	var world_art := screen.get_node_or_null("WorldArt") as TextureRect
	var close := screen.get_node_or_null("Card/Content/Close") as Button
	_expect(card != null, "Settings authored Card missing")
	_expect(sigil != null and sigil.texture != null and sigil.custom_minimum_size.y >= 68.0 and sigil.custom_minimum_size.y <= 80.0, "Settings authored raster sigil must anchor the compact utility surface")
	_expect(world_art != null and world_art.texture != null, "Settings authored world backdrop slot missing")
	_expect(close != null and close.custom_minimum_size.y >= 72.0, "Settings return CTA must retain a deliberate mobile touch target")
	_expect(card.get_theme_stylebox("panel") is StyleBoxFlat, "Default Settings card must preserve screen-specific authored material")

	screen.apply_presentation_settings({"high_contrast": true})
	await process_frame
	_expect(card.get_theme_stylebox("panel") == screen.card_high_style, "High contrast Settings card must switch to authored high-contrast resource")
	for path in ["AudioRow/Master", "AudioRow/Music", "AudioRow/SFX", "ExperienceRow/Haptics", "ExperienceRow/Reduced", "ExperienceRow/Contrast"]:
		var toggle := screen.get_node_or_null("Card/Content/%s" % path) as Button
		_expect(toggle != null and toggle.custom_minimum_size.y >= 64.0, "Settings toggle touch target missing: %s" % path)
		if toggle != null:
			_expect(toggle.get_theme_stylebox("normal") == screen.toggle_high_style, "High contrast toggle must use authored style: %s" % path)

	screen.apply_presentation_settings({"high_contrast": false})
	await process_frame
	_expect(card.get_theme_stylebox("panel") is StyleBoxFlat, "Settings must return to its scene-authored normal material")
	_expect(close.get_theme_stylebox("normal") is StyleBoxFlat, "Settings return CTA must restore its scene-authored material")

	screen.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored Settings utility screen")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
