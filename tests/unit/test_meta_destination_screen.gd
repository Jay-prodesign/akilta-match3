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
		var interaction: Dictionary = screen.meta_interaction_contract()
		_expect(bool(interaction.get("reduced_motion_supported", false)), "%s meta actions must respect Reduced Motion" % feature)
		_expect(bool(interaction.get("feedback_signal", false)), "%s meta actions must expose semantic UI feedback" % feature)
		_expect(bool(interaction.get("hidden_legacy_actions_ignored", false)), "%s interaction craft must ignore hidden legacy actions" % feature)
		_expect(bool(interaction.get("shop_sealed_inert", false)), "%s must keep sealed Shop commerce inert" % feature)
		_expect(bool(contract.get("world_art_loaded", false)), "%s must load authored raster world art" % feature)
		_expect(bool(contract.get("hero_art_loaded", false)), "%s must load hero object art" % feature)
		_expect(int(contract.get("static_card_slots", 0)) == 3, "%s must own three authored card slots" % feature)
		_expect(not bool(contract.get("code_built_panels", true)), "%s must not return to bootstrap-built panel UI" % feature)
		_expect(bool(contract.get("north_star_title_hierarchy", false)), "%s must retain a strong North Star page title" % feature)
		_expect(bool(contract.get("north_star_hero_scale", false)), "%s must retain a hero-scale authored feature card" % feature)
		var hero_panel := screen.get_node_or_null("FeatureLayout/FeatureHero") as PanelContainer
		var active_hero_art := screen.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/ShopFeaturedOfferArt") as TextureRect if feature == "shop" else screen.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroArt") as TextureRect
		if feature == "events":
			_expect(hero_panel != null and not hero_panel.visible, "events must not reuse the generic meta hero")
			var event_feature := screen.get_node_or_null("FeatureLayout/EventsFeature") as VBoxContainer
			var event_card_1 := screen.get_node_or_null("FeatureLayout/EventsFeature/EventCard1") as PanelContainer
			var event_card_2 := screen.get_node_or_null("FeatureLayout/EventsFeature/EventCard2") as PanelContainer
			_expect(event_feature != null and event_feature.visible and event_feature.size_flags_vertical != Control.SIZE_EXPAND_FILL and event_card_1 != null and event_card_1.visible and event_card_1.size_flags_vertical != Control.SIZE_EXPAND_FILL and event_card_1.custom_minimum_size.y >= 430.0 and event_card_1.custom_minimum_size.y <= 450.0 and event_card_2 != null and event_card_2.visible and event_card_2.size_flags_vertical != Control.SIZE_EXPAND_FILL and event_card_2.custom_minimum_size.y >= 430.0 and event_card_2.custom_minimum_size.y <= 450.0, "events must own two bounded North Star event cards instead of stretching into full-height slabs")
		elif feature == "shop":
			_expect(hero_panel != null and not hero_panel.visible, "shop must use catalog composition instead of the generic meta hero")
			_expect(bool(contract.get("shop_catalog_focus", false)), "shop must present one featured sealed preview plus two catalog previews")
			_expect(bool(contract.get("shop_compact_catalog_density", false)), "shop must keep the sealed catalog compact instead of stretching cards into slabs")
			_expect(bool(contract.get("shop_clean_sealed_badges", false)), "shop sealed states must use compact readable badges instead of squeezed multi-line chrome")
			var shop_detail := screen.get_node_or_null("FeatureLayout/Detail") as Label
			_expect(shop_detail != null and not shop_detail.visible, "shop must suppress redundant subtitle copy above the sealed catalog")
		elif feature == "profile":
			var profile_identity := screen.get_node_or_null("FeatureLayout/ProfileFeature/Identity") as PanelContainer
			var profile_progress := screen.get_node_or_null("FeatureLayout/ProfileFeature/Identity/IdentityRow/Copy/Progress") as ProgressBar
			_expect(hero_panel != null and not hero_panel.visible, "profile must not reuse the generic meta hero")
			_expect(profile_identity != null and profile_identity.visible and profile_identity.custom_minimum_size.y >= 360.0 and profile_identity.custom_minimum_size.y <= 400.0, "profile must use its dedicated compact player-identity card")
			_expect(active_hero_art != null and active_hero_art.custom_minimum_size.x >= 270.0 and active_hero_art.custom_minimum_size.x <= 290.0, "profile Keeper portrait must stay compact")
			_expect(profile_progress != null and profile_progress.visible, "profile must expose truthful opening progress instead of fake XP")
		else:
			_expect(hero_panel != null and hero_panel.custom_minimum_size.y >= 400.0, "%s hero must occupy a true visual stage" % feature)
			_expect(active_hero_art != null and active_hero_art.custom_minimum_size.x >= 340.0 and active_hero_art.custom_minimum_size.y >= 340.0, "%s hero art must dominate its feature card" % feature)
		_expect(bool(contract.get("asset_backed_hero_chrome", false)), "%s hero card must use asset-backed production chrome" % feature)
		_expect(bool(preload("res://src/ui/theme/production_chrome.gd").contract().get("secondary_hero_family_verified", false)), "%s hero chrome family must resolve through the verified shared asset" % feature)
		_expect(bool(contract.get("raster_feature_art", false)), "%s hero art must use production raster assets" % feature)
		_expect(bool(contract.get("card_copy_compact", false)), "%s cards must prioritize art/title/status instead of paragraph copy" % feature)
		_expect(bool(contract.get("art_dominant_cards", false)), "%s cards must reserve production-scale visual area instead of collapsing into form rows" % feature)
		_expect(bool(contract.get("asset_backed_utility_actions", false)), "%s utility actions must use shared production chrome" % feature)
		_expect(bool(contract.get("world_art_not_overdimmed", false)), "%s must keep authored world art visible rather than hiding it behind UI shade" % feature)
		_expect(bool(contract.get("controlled_chrome_density", false)), "%s must keep status chrome subordinate to hero art" % feature)
		_expect(bool(contract.get("redundant_house_return_suppressed", false)), "%s must rely on shared product navigation instead of a duplicate House button" % feature)
		_expect(bool(contract.get("truth_footer_suppressed", false)), "%s must keep diagnostic truth copy out of the player-facing footer" % feature)
		_expect(bool(contract.get("visual_parity_gate_v2", false)), "%s must satisfy the final-direction secondary-screen visual parity gate" % feature)
		_expect(bool(contract.get("visual_parity_gate_v3", false)), "%s must satisfy the navigation/readability secondary-screen parity gate" % feature)
		_expect(bool(contract.get("header_readability_scrim", false)), "%s must retain a dedicated top readability scrim over authored world art" % feature)
		_expect(bool(contract.get("secondary_header_compact", false)), "%s must avoid redundant progress/commerce lines above the hero" % feature)
		_expect(screen.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroArt") != null, "%s must keep a scene-owned hero art slot" % feature)
		var expected_title := "EVENTS" if feature == "events" else ("SHOP" if feature == "shop" else "PLAYER")
		_expect((screen.get_node("FeatureLayout/FeatureTitle") as Label).text == expected_title, "%s must preserve its authored route title" % feature)
		for card_name in ["Card1", "Card2", "Card3"]:
			var card := screen.get_node_or_null("FeatureLayout/CardScroll/Cards/%s" % card_name) as PanelContainer
			var art := screen.get_node_or_null("FeatureLayout/CardScroll/Cards/%s/Row/Art" % card_name) as TextureRect
			if feature == "events":
				_expect(card != null and not card.visible, "events must suppress generic meta cards in favor of its dedicated event composition")
				continue
			if feature == "profile":
				_expect(card != null and not card.visible, "profile must suppress generic meta cards in favor of its dedicated utility list")
				continue
			_expect(card != null and card.visible and art != null and art.texture != null, "%s %s must render object art" % [feature, card_name])
			if feature == "shop":
				var card_index := ["Card1", "Card2", "Card3"].find(card_name)
				var min_art := 278.0 if card_index == 0 else 182.0
				var max_art := 294.0 if card_index == 0 else 198.0
				var min_card := 330.0 if card_index == 0 else 232.0
				var max_card := 350.0 if card_index == 0 else 248.0
				var state_plate := screen.get_node_or_null("FeatureLayout/CardScroll/Cards/%s/Row/ShopStatePlate" % card_name) as PanelContainer
				var status_label := screen.get_node_or_null("FeatureLayout/CardScroll/Cards/%s/Row/Copy/Status" % card_name) as Label
				_expect(card.custom_minimum_size.y >= min_card and card.custom_minimum_size.y <= max_card and card.size_flags_vertical != Control.SIZE_EXPAND_FILL, "shop %s must retain compact fixed-height catalog density" % card_name)
				_expect(art.custom_minimum_size.x >= min_art and art.custom_minimum_size.x <= max_art and art.custom_minimum_size.y >= min_art and art.custom_minimum_size.y <= max_art, "shop %s art must match compact catalog scale" % card_name)
				_expect(state_plate != null and state_plate.visible and state_plate.custom_minimum_size.y <= 58.0 and state_plate.get_theme_stylebox("panel") is StyleBoxFlat, "shop %s must expose one compact sealed-state plate" % card_name)
				_expect(status_label != null and not status_label.visible, "shop %s must not duplicate sealed truth in a second status line" % card_name)
				var plate_detail := screen.get_node_or_null("FeatureLayout/CardScroll/Cards/%s/Row/ShopStatePlate/Content/Detail" % card_name) as Label
				var plate_mode := screen.get_node_or_null("FeatureLayout/CardScroll/Cards/%s/Row/ShopStatePlate/Content/Mode" % card_name) as Label
				_expect(plate_detail != null and not plate_detail.visible and plate_mode != null and not plate_mode.visible, "shop %s sealed badge must avoid unreadable duplicate microcopy" % card_name)
			else:
				_expect(art != null and art.custom_minimum_size.x >= 220.0 and art.custom_minimum_size.y >= 195.0, "%s %s art must not collapse into a thumbnail row" % [feature, card_name])
			if art != null and art.texture != null:
				_expect(String(art.get_meta("asset_path", "")).ends_with(".webp") or String(art.get_meta("asset_path", "")).ends_with(".png"), "%s %s must use raster object art" % [feature, card_name])
		if feature == "events":
			var events_world := screen.get_node_or_null("WorldArt") as TextureRect
			_expect(events_world != null and events_world.texture != null and events_world.texture.get_width() >= 1080 and events_world.texture.get_height() >= 1500, "events world reuse must retain the verified 1080x1500 chapter-world raster")
			_expect(bool(contract.get("events_board_card_composition", false)), "events must match the locked board's two-card composition without inventing live event truth")
			_expect(bool(contract.get("events_compact_card_density", false)), "events must keep cards and real actions at compact North Star density")
			_expect(bool(contract.get("events_actions_subordinate", false)), "events local practice and weekly navigation must remain readable but subordinate to event content")
			_expect(bool(contract.get("events_truthful_status", false)), "events cards must expose sealed truth instead of fabricated timers or rewards")
			for event_card in ["EventCard1", "EventCard2"]:
				var event_art := screen.get_node_or_null("FeatureLayout/EventsFeature/%s/Content/Art" % event_card) as TextureRect
				_expect(event_art != null and event_art.texture != null and event_art.texture.get_width() >= 512 and event_art.texture.get_height() >= 512, "events %s must retain production-resolution Curio art" % event_card)
			_expect(bool(interaction.get("events_real_actions_tactile", false)), "events Weekly and Daily actions must own visible press/release depth")
			var feedback_hits := {"count": 0}
			screen.interaction_feedback_requested.connect(func(_kind: String): feedback_hits["count"] = int(feedback_hits["count"]) + 1)
			var weekly_button := screen.get_node("FeatureLayout/WeeklyMissionsAction") as Button
			var daily_button := screen.get_node("FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeAction") as Button
			weekly_button.emit_signal("button_down")
			await create_timer(0.09).timeout
			_expect(weekly_button.scale.x < 0.98 and weekly_button.scale.y < 0.98, "events Weekly action must visibly compress on press")
			_expect(int(feedback_hits["count"]) == 1, "events Weekly press must emit exactly one semantic feedback request")
			weekly_button.emit_signal("button_up")
			await create_timer(0.21).timeout
			_expect(absf(weekly_button.scale.x - 1.0) < 0.01 and absf(weekly_button.scale.y - 1.0) < 0.01, "events Weekly action must spring cleanly back on release")
			daily_button.emit_signal("button_down")
			await create_timer(0.09).timeout
			_expect(daily_button.scale.x < 0.99 and daily_button.scale.x > 0.94, "events Daily action must own a subtler press response")
			daily_button.emit_signal("button_up")
			await create_timer(0.21).timeout
			screen.apply_presentation_settings({"reduced_motion": true})
			weekly_button.emit_signal("button_down")
			await create_timer(0.09).timeout
			_expect(absf(weekly_button.scale.x - 1.0) < 0.001 and absf(weekly_button.scale.y - 1.0) < 0.001, "Reduced Motion must suppress Events transform animation")
			weekly_button.emit_signal("button_up")
			screen.apply_presentation_settings({"reduced_motion": false})
			var weekly := {"hit": false}
			screen.weekly_requested.connect(func(): weekly["hit"] = true)
			weekly_button.emit_signal("pressed")
			_expect(bool(weekly["hit"]), "events primary action must open weekly rituals")
			var daily := {"level": 0}
			screen.daily_practice_requested.connect(func(level_number: int): daily["level"] = level_number)
			daily_button.emit_signal("pressed")
			_expect(int(daily["level"]) == 2, "events secondary action must preserve daily practice level")
			var sealed_state := state.duplicate(true)
			sealed_state["daily_level"] = 0
			_expect(screen.configure("events", sealed_state), "events sealed daily state must reconfigure")
			var before_disabled_press := int(feedback_hits["count"])
			daily_button.emit_signal("button_down")
			await create_timer(0.08).timeout
			_expect(daily_button.disabled and int(feedback_hits["count"]) == before_disabled_press and absf(daily_button.scale.x - 1.0) < 0.001, "sealed Daily action must stay inert and emit no fake feedback")
		if feature == "shop":
			var shop_offer := screen.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/ShopFeaturedOfferArt") as TextureRect
			_expect(shop_offer != null and shop_offer.texture != null and shop_offer.texture.get_width() >= 512 and shop_offer.texture.get_height() >= 512, "shop sealed preview source art must remain production-resolution")
			for shop_card in ["Card1", "Card2", "Card3"]:
				var shop_art := screen.get_node_or_null("FeatureLayout/CardScroll/Cards/%s/Row/Art" % shop_card) as TextureRect
				_expect(shop_art != null and shop_art.texture != null and shop_art.texture.get_width() >= 512 and shop_art.texture.get_height() >= 512, "shop %s must retain production-resolution first-party Curio art" % shop_card)
			var shop_action := screen.get_node_or_null("FeatureLayout/FeatureHero/HeroRow/HeroCopy/ShopDisabledAction") as Button
			_expect(shop_action != null and shop_action.disabled and not shop_action.visible, "shop must not expose a purchase CTA while commerce is sealed")
			var notice := screen.get_node("FeatureLayout/NoPurchasesNotice") as Label
			_expect(notice.visible and notice.text.find("NO PURCHASES OR PAYMENTS") >= 0, "shop preview must state that purchases and payments are disabled")
			_expect(not (screen.get_node("FeatureLayout/ShopCurrencySummary") as Label).visible and not (screen.get_node("FeatureLayout/ShopCurrencyTruth") as Label).visible, "shop must rely on the shared resource bar instead of duplicate economy rows")
		if feature == "profile":
			var profile_hero := screen.get_node("FeatureLayout/ProfileFeature/Identity/IdentityRow/KeeperArt") as TextureRect
			_expect(profile_hero != null and profile_hero.texture != null and String(contract.get("hero_asset_path", "")).ends_with("black_cat.webp"), "profile identity must use the Keeper familiar rather than a generic Curio")
			_expect(bool(contract.get("profile_save_health_compact", false)), "profile save-health truth must stay compact instead of dominating the screen")
			_expect(bool(contract.get("profile_status_focus", false)), "profile save health must prioritize readable local/cloud statuses over paragraph copy")
			_expect(bool(contract.get("profile_identity_focus", false)), "profile must center the authored Keeper identity and truthful opening progress on its own framed utility surface")
			var profile_surface := screen.get_node_or_null("ProfileSurface") as PanelContainer
			_expect(profile_surface != null and profile_surface.visible and profile_surface.get_theme_stylebox("panel") is StyleBoxFlat, "profile must own a clean screen-specific framed surface")
			_expect(bool(contract.get("profile_screen_specific_material", false)), "profile screen-specific frames must avoid stretched shared 9-slice seam artifacts")
			_expect(bool(contract.get("profile_board_utility_rows", false)), "profile must use board-like compact utility rows instead of oversized progress cards")
			_expect(bool(contract.get("profile_compact_menu_flow", false)), "profile truthful utility rows and save status must flow continuously instead of being split by a giant empty corridor")
			var profile_progress_label := screen.get_node_or_null("FeatureLayout/ProfileFeature/Identity/IdentityRow/Copy/ProgressLabel") as Label
			var profile_progress := screen.get_node_or_null("FeatureLayout/ProfileFeature/Identity/IdentityRow/Copy/Progress") as ProgressBar
			var settings_button := screen.get_node_or_null("FeatureLayout/ProfileFeature/Menu/Settings") as Button
			var chapter_row := screen.get_node_or_null("FeatureLayout/ProfileFeature/Menu/ChapterRow") as PanelContainer
			var reliquary_row := screen.get_node_or_null("FeatureLayout/ProfileFeature/Menu/ReliquaryRow") as PanelContainer
			var house_row := screen.get_node_or_null("FeatureLayout/ProfileFeature/Menu/HouseRow") as PanelContainer
			var save_row := screen.get_node_or_null("FeatureLayout/ProfileFeature/Menu/SaveRow") as PanelContainer
			_expect(profile_progress_label != null and profile_progress_label.text == "OPENING RITUALS · 3 / 3" and profile_progress != null and profile_progress.value == 3.0, "profile progress bar must reflect real completed opening rituals")
			_expect(settings_button != null and settings_button.custom_minimum_size.y >= 104.0 and settings_button.custom_minimum_size.y <= 112.0 and settings_button.text.contains("SETTINGS"), "profile settings must read as a compact dedicated utility row")
			_expect(bool(interaction.get("profile_real_action_tactile", false)), "profile Settings row must own visible press/release depth")
			var profile_feedback_hits := {"count": 0}
			screen.interaction_feedback_requested.connect(func(_kind: String): profile_feedback_hits["count"] = int(profile_feedback_hits["count"]) + 1)
			settings_button.emit_signal("button_down")
			await create_timer(0.09).timeout
			_expect(settings_button.scale.x < 0.98 and settings_button.scale.y < 0.98, "profile Settings must visibly compress on press")
			_expect(int(profile_feedback_hits["count"]) == 1, "profile Settings press must emit exactly one semantic feedback request")
			settings_button.emit_signal("button_up")
			await create_timer(0.21).timeout
			_expect(absf(settings_button.scale.x - 1.0) < 0.01 and absf(settings_button.scale.y - 1.0) < 0.01, "profile Settings must spring cleanly back on release")
			screen.apply_presentation_settings({"reduced_motion": true})
			settings_button.emit_signal("button_down")
			await create_timer(0.09).timeout
			_expect(absf(settings_button.scale.x - 1.0) < 0.001 and absf(settings_button.scale.y - 1.0) < 0.001, "Reduced Motion must suppress Profile Settings transform animation")
			settings_button.emit_signal("button_up")
			screen.apply_presentation_settings({"reduced_motion": false})
			_expect(chapter_row != null and reliquary_row != null and house_row != null and save_row != null and chapter_row.visible and reliquary_row.visible and house_row.visible and save_row.visible, "profile dedicated utility list must expose all truthful rows")
			_expect(chapter_row.size_flags_vertical != Control.SIZE_EXPAND_FILL and reliquary_row.size_flags_vertical != Control.SIZE_EXPAND_FILL and house_row.size_flags_vertical != Control.SIZE_EXPAND_FILL and save_row.size_flags_vertical != Control.SIZE_EXPAND_FILL, "profile utility rows must not absorb arbitrary empty vertical space")
			var settings := {"hit": false}
			screen.settings_requested.connect(func(): settings["hit"] = true)
			settings_button.emit_signal("pressed")
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
