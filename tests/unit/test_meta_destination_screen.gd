extends SceneTree

const MetaScene = preload("res://src/ui/meta/meta_destination_screen.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := {
		"completed_count": 3,
		"collected_count": 3,
		"restored_stage": 3,
		"opening_cap": 3,
		"opening_complete": true,
		"coins": 240,
		"gems": 12,
		"daily_level": 2,
		"save_status": "LOCAL SAVE · HEALTHY",
		"save_detail": "Progress is stored transactionally on this device.",
	}
	for feature in ["events", "shop", "profile"]:
		var screen = MetaScene.instantiate()
		root.add_child(screen)
		await process_frame
		_expect(screen.configure(feature, state), "%s destination must configure" % feature)
		var contract: Dictionary = screen.screen_contract()
		_expect(bool(contract.get("world_art_loaded", false)), "%s must load authored raster world art" % feature)
		_expect(bool(contract.get("hero_art_loaded", false)), "%s must load hero object art" % feature)
		_expect(int(contract.get("static_card_slots", 0)) == 3, "%s must own three authored card slots" % feature)
		_expect(not bool(contract.get("code_built_panels", true)), "%s must not return to bootstrap-built panel UI" % feature)
		_expect(bool(contract.get("north_star_title_hierarchy", false)), "%s must retain a strong North Star page title" % feature)
		_expect(bool(contract.get("north_star_hero_scale", false)), "%s must retain a hero-scale authored feature card" % feature)
		_expect(bool(contract.get("raster_feature_art", false)), "%s hero art must use production raster assets" % feature)
		_expect(screen.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroArt") != null, "%s must keep a scene-owned hero art slot" % feature)
		var expected_title := "EVENT CENTER" if feature == "events" else ("THE CURIO EMPORIUM" if feature == "shop" else "THE KEEPER")
		_expect((screen.get_node("FeatureLayout/FeatureTitle") as Label).text == expected_title, "%s must preserve its authored route title" % feature)
		for card_name in ["Card1", "Card2", "Card3"]:
			var art := screen.get_node_or_null("FeatureLayout/CardScroll/Cards/%s/Row/Art" % card_name) as TextureRect
			_expect(art != null and art.texture != null, "%s %s must render object art" % [feature, card_name])
			if art != null and art.texture != null:
				_expect(String(art.get_meta("asset_path", "")).ends_with(".webp") or String(art.get_meta("asset_path", "")).ends_with(".png"), "%s %s must use raster object art" % [feature, card_name])
		if feature == "events":
			var weekly := {"hit": false}
			screen.weekly_requested.connect(func(): weekly["hit"] = true)
			(screen.get_node("FeatureLayout/WeeklyMissionsAction") as Button).emit_signal("pressed")
			_expect(bool(weekly["hit"]), "events primary action must open weekly rituals")
			var daily := {"level": 0}
			screen.daily_practice_requested.connect(func(level_number: int): daily["level"] = level_number)
			(screen.get_node("FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeAction") as Button).emit_signal("pressed")
			_expect(int(daily["level"]) == 2, "events secondary action must preserve daily practice level")
		if feature == "profile":
			var profile_hero := screen.get_node("FeatureLayout/FeatureHero/HeroRow/HeroArt") as TextureRect
			_expect(profile_hero != null and String(contract.get("hero_asset_path", "")).ends_with("black_cat.webp"), "profile hero must use the Keeper familiar rather than a generic Curio")
			var settings := {"hit": false}
			screen.settings_requested.connect(func(): settings["hit"] = true)
			(screen.get_node("FeatureLayout/ProfileSettings") as Button).emit_signal("pressed")
			_expect(bool(settings["hit"]), "profile primary action must open settings")
		screen.queue_free()
		await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: authored meta destination screen family")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
