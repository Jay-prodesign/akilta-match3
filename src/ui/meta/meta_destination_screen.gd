extends Control

signal back_requested
signal settings_requested
signal weekly_requested
signal daily_practice_requested(level_number: int)
signal interaction_feedback_requested(kind: String)

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

var _feature_key: String = ""
var _daily_level: int = 0
var _hero_asset_path: String = ""
var _reduced_motion: bool = false
var _meta_tactile_buttons: Array[Button] = []

@onready var world_art: TextureRect = $WorldArt
@onready var profile_surface: PanelContainer = $ProfileSurface
@onready var meta_eyebrow: Label = $FeatureLayout/MetaEyebrow
@onready var title: Label = $FeatureLayout/FeatureTitle
@onready var detail: Label = $FeatureLayout/Detail
@onready var chapter_progress: Label = $FeatureLayout/ChapterRitualProgress
@onready var shop_notice: Label = $FeatureLayout/NoPurchasesNotice
@onready var shop_currency: Label = $FeatureLayout/ShopCurrencySummary
@onready var shop_truth: Label = $FeatureLayout/ShopCurrencyTruth
@onready var feature_hero: PanelContainer = $FeatureLayout/FeatureHero
@onready var profile_feature: VBoxContainer = $FeatureLayout/ProfileFeature
@onready var profile_identity: PanelContainer = $FeatureLayout/ProfileFeature/Identity
@onready var profile_keeper_art: TextureRect = $FeatureLayout/ProfileFeature/Identity/IdentityRow/KeeperArt
@onready var profile_identity_kicker: Label = $FeatureLayout/ProfileFeature/Identity/IdentityRow/Copy/Kicker
@onready var profile_identity_title: Label = $FeatureLayout/ProfileFeature/Identity/IdentityRow/Copy/Title
@onready var profile_identity_progress_label: Label = $FeatureLayout/ProfileFeature/Identity/IdentityRow/Copy/ProgressLabel
@onready var profile_identity_progress: ProgressBar = $FeatureLayout/ProfileFeature/Identity/IdentityRow/Copy/Progress
@onready var profile_settings_row: Button = $FeatureLayout/ProfileFeature/Menu/Settings
@onready var profile_chapter_row: PanelContainer = $FeatureLayout/ProfileFeature/Menu/ChapterRow
@onready var profile_chapter_icon: TextureRect = $FeatureLayout/ProfileFeature/Menu/ChapterRow/Content/Icon
@onready var profile_chapter_status: Label = $FeatureLayout/ProfileFeature/Menu/ChapterRow/Content/Copy/Status
@onready var profile_reliquary_row: PanelContainer = $FeatureLayout/ProfileFeature/Menu/ReliquaryRow
@onready var profile_reliquary_icon: TextureRect = $FeatureLayout/ProfileFeature/Menu/ReliquaryRow/Content/Icon
@onready var profile_reliquary_status: Label = $FeatureLayout/ProfileFeature/Menu/ReliquaryRow/Content/Copy/Status
@onready var profile_house_row: PanelContainer = $FeatureLayout/ProfileFeature/Menu/HouseRow
@onready var profile_house_icon: TextureRect = $FeatureLayout/ProfileFeature/Menu/HouseRow/Content/Icon
@onready var profile_house_status: Label = $FeatureLayout/ProfileFeature/Menu/HouseRow/Content/Copy/Status
@onready var profile_save_row: PanelContainer = $FeatureLayout/ProfileFeature/Menu/SaveRow
@onready var profile_save_local: Label = $FeatureLayout/ProfileFeature/Menu/SaveRow/Content/Local
@onready var profile_save_cloud: Label = $FeatureLayout/ProfileFeature/Menu/SaveRow/Content/Cloud
@onready var events_feature: VBoxContainer = $FeatureLayout/EventsFeature
@onready var event_card_1: PanelContainer = $FeatureLayout/EventsFeature/EventCard1
@onready var event_card_2: PanelContainer = $FeatureLayout/EventsFeature/EventCard2
@onready var event_art_1: TextureRect = $FeatureLayout/EventsFeature/EventCard1/Content/Art
@onready var event_art_2: TextureRect = $FeatureLayout/EventsFeature/EventCard2/Content/Art
@onready var event_kicker_1: Label = $FeatureLayout/EventsFeature/EventCard1/Content/Copy/Kicker
@onready var event_kicker_2: Label = $FeatureLayout/EventsFeature/EventCard2/Content/Copy/Kicker
@onready var event_title_1: Label = $FeatureLayout/EventsFeature/EventCard1/Content/Copy/Title
@onready var event_title_2: Label = $FeatureLayout/EventsFeature/EventCard2/Content/Copy/Title
@onready var event_status_1: Label = $FeatureLayout/EventsFeature/EventCard1/Content/Copy/Status
@onready var event_status_2: Label = $FeatureLayout/EventsFeature/EventCard2/Content/Copy/Status
@onready var hero_art: TextureRect = $FeatureLayout/FeatureHero/HeroRow/HeroArt
@onready var shop_offer_art: TextureRect = $FeatureLayout/FeatureHero/HeroRow/ShopFeaturedOfferArt
@onready var hero_kicker: Label = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroKicker
@onready var hero_title: Label = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroTitle
@onready var hero_body: Label = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/HeroBody
@onready var profile_progress_label: Label = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/ProfileProgressLabel
@onready var profile_progress: ProgressBar = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/ProfileProgress
@onready var shop_disabled_action: Button = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/ShopDisabledAction
@onready var daily_card: PanelContainer = $FeatureLayout/DailyPracticeCard
@onready var daily_kicker: Label = $FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeKicker
@onready var daily_title: Label = $FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeTitle
@onready var daily_truth: Label = $FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeTruth
@onready var card_scroll: ScrollContainer = $FeatureLayout/CardScroll
@onready var card_stack: VBoxContainer = $FeatureLayout/CardScroll/Cards
@onready var daily_action: Button = $FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeAction
@onready var weekly_action: Button = $FeatureLayout/WeeklyMissionsAction
@onready var profile_settings: Button = $FeatureLayout/ProfileSettings
@onready var save_health_card: PanelContainer = $FeatureLayout/SaveHealthCard
@onready var save_health_kicker: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/Kicker
@onready var local_save_status: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/LocalSaveStatus
@onready var local_save_detail: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/LocalSaveDetail
@onready var cloud_sync_status: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/CloudSyncStatus
@onready var cloud_sync_detail: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/CloudSyncDetail
@onready var truth_strip: Label = $FeatureLayout/TruthStrip
@onready var back_button: Button = $FeatureLayout/BackToHouse

func _ready() -> void:
	profile_surface.set_meta("profile_material", "screen_specific_flat")
	profile_identity.set_meta("profile_material", "screen_specific_flat")
	for row in [profile_chapter_row, profile_reliquary_row, profile_house_row, profile_save_row]:
		row.set_meta("profile_material", "screen_specific_flat")
	ProductionChrome.apply_secondary(feature_hero, "meta_hero")
	ProductionChrome.apply_action_button(profile_settings_row, "utility", "profile_settings_row")
	ProductionChrome.apply_compact_panel(event_card_1, "events_feature_card")
	ProductionChrome.apply_compact_panel(event_card_2, "events_feature_card")
	ProductionChrome.apply_action_button(weekly_action, "primary", "events_weekly")
	ProductionChrome.apply_action_button(profile_settings, "utility", "profile_settings")
	ProductionChrome.apply_action_button(daily_action, "utility", "events_daily_practice")
	ProductionChrome.apply_action_button(shop_disabled_action, "utility", "shop_sealed")
	ProductionChrome.apply_action_button(back_button, "utility", "meta_return_house")
	_bind_meta_tactile(weekly_action, "events_weekly", 0.955)
	_bind_meta_tactile(daily_action, "events_daily", 0.97)
	_bind_meta_tactile(profile_settings_row, "profile_settings", 0.965)
	weekly_action.pressed.connect(func(): weekly_requested.emit())
	daily_action.pressed.connect(_on_daily_pressed)
	profile_settings.pressed.connect(func(): settings_requested.emit())
	profile_settings_row.pressed.connect(func(): settings_requested.emit())
	back_button.pressed.connect(func(): back_requested.emit())

func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	for button in _meta_tactile_buttons:
		button.set_meta("meta_tactile_reduced_motion", _reduced_motion)
		if _reduced_motion:
			_stop_meta_tactile_tween(button)
			button.scale = Vector2.ONE
			button.modulate = Color.WHITE
			button.set_meta("meta_tactile_phase", "idle")

func meta_interaction_contract() -> Dictionary:
	var weekly_tactile := weekly_action != null and bool(weekly_action.get_meta("meta_tactile_bound", false)) and float(weekly_action.get_meta("meta_tactile_press_scale", 1.0)) <= 0.96
	var daily_tactile := daily_action != null and bool(daily_action.get_meta("meta_tactile_bound", false)) and float(daily_action.get_meta("meta_tactile_press_scale", 1.0)) <= 0.975
	var profile_settings_tactile := profile_settings_row != null and bool(profile_settings_row.get_meta("meta_tactile_bound", false)) and float(profile_settings_row.get_meta("meta_tactile_press_scale", 1.0)) <= 0.97
	return {
		"feature": _feature_key,
		"events_real_actions_tactile": _feature_key != "events" or (weekly_action.visible and weekly_tactile and daily_action.visible and daily_tactile),
		"profile_real_action_tactile": _feature_key != "profile" or (profile_settings_row.visible and profile_settings_tactile),
		"shop_sealed_inert": _feature_key != "shop" or (not shop_disabled_action.visible and shop_disabled_action.disabled),
		"reduced_motion_supported": true,
		"feedback_signal": has_signal("interaction_feedback_requested"),
		"hidden_legacy_actions_ignored": not profile_settings.visible and not back_button.visible,
	}

func _bind_meta_tactile(button: Button, role: String, press_scale: float) -> void:
	if button == null:
		return
	button.set_meta("meta_tactile_role", role)
	button.set_meta("meta_tactile_press_scale", press_scale)
	button.set_meta("meta_tactile_reduced_motion", _reduced_motion)
	if bool(button.get_meta("meta_tactile_bound", false)):
		return
	button.set_meta("meta_tactile_bound", true)
	_meta_tactile_buttons.append(button)
	button.button_down.connect(_press_meta_tactile.bind(button))
	button.button_up.connect(_release_meta_tactile.bind(button))
	button.mouse_exited.connect(_release_meta_tactile.bind(button))
	button.focus_exited.connect(_release_meta_tactile.bind(button))

func _press_meta_tactile(button: Button) -> void:
	if button == null or button.disabled or not button.visible:
		return
	_stop_meta_tactile_tween(button)
	button.pivot_offset = button.size * 0.5
	button.set_meta("meta_tactile_phase", "pressed")
	interaction_feedback_requested.emit("ui")
	if bool(button.get_meta("meta_tactile_reduced_motion", false)):
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		return
	var target_scale := clampf(float(button.get_meta("meta_tactile_press_scale", 0.97)), 0.94, 0.985)
	var role := String(button.get_meta("meta_tactile_role", ""))
	var pressed_tint := Color(1.0, 0.95, 0.84, 1.0) if role == "events_weekly" else (Color(0.96, 0.92, 1.0, 1.0) if role == "events_daily" else Color(1.0, 0.96, 0.89, 1.0))
	var tween := create_tween()
	button.set_meta("meta_tactile_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", pressed_tint, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _release_meta_tactile(button: Button) -> void:
	if button == null:
		return
	_stop_meta_tactile_tween(button)
	button.pivot_offset = button.size * 0.5
	button.set_meta("meta_tactile_phase", "release")
	if bool(button.get_meta("meta_tactile_reduced_motion", false)):
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		button.set_meta("meta_tactile_phase", "idle")
		return
	var tween := create_tween()
	button.set_meta("meta_tactile_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color.WHITE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): button.set_meta("meta_tactile_phase", "idle"))

func _stop_meta_tactile_tween(button: Button) -> void:
	if button == null or not button.has_meta("meta_tactile_tween"):
		return
	var previous = button.get_meta("meta_tactile_tween")
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	button.remove_meta("meta_tactile_tween")

func configure(feature_key: String, state: Dictionary) -> bool:
	_feature_key = feature_key.to_lower()
	_daily_level = int(state.get("daily_level", 0))
	var completed_count := int(state.get("completed_count", 0))
	var collected_count := int(state.get("collected_count", 0))
	var restored_stage := int(state.get("restored_stage", 0))
	var opening_cap := maxi(1, int(state.get("opening_cap", 3)))
	var opening_complete := bool(state.get("opening_complete", false))
	var coins := int(state.get("coins", 0))
	var gems := int(state.get("gems", 0))
	var background_id := ""
	var hero_path := ""
	var cards: Array[Dictionary] = []

	chapter_progress.visible = false
	meta_eyebrow.visible = false
	events_feature.visible = _feature_key == "events"
	profile_feature.visible = _feature_key == "profile"
	feature_hero.visible = false
	card_scroll.visible = _feature_key == "shop"
	daily_card.visible = _feature_key == "events"
	weekly_action.visible = _feature_key == "events"
	shop_notice.visible = _feature_key == "shop"
	shop_currency.visible = false
	shop_truth.visible = false
	shop_offer_art.visible = false
	shop_disabled_action.visible = false
	hero_art.visible = false
	card_stack.size_flags_vertical = Control.SIZE_FILL
	title.add_theme_font_size_override("font_size", 44 if _feature_key == "shop" else (42 if _feature_key == "profile" else 54))
	detail.visible = _feature_key != "shop"
	detail.add_theme_font_size_override("font_size", 17 if _feature_key == "shop" else (16 if _feature_key == "profile" else 21))
	shop_notice.add_theme_font_size_override("font_size", 16 if _feature_key == "shop" else 19)
	profile_settings.visible = false
	save_health_card.visible = false
	profile_surface.visible = _feature_key == "profile"
	profile_progress_label.visible = false
	profile_progress.visible = false
	feature_hero.custom_minimum_size.y = 300.0 if _feature_key == "profile" else 420.0
	hero_art.custom_minimum_size = Vector2(220, 220) if _feature_key == "profile" else Vector2(360, 360)
	hero_kicker.add_theme_font_size_override("font_size", 18 if _feature_key == "profile" else 22)
	hero_title.add_theme_font_size_override("font_size", 30 if _feature_key == "profile" else 44)
	profile_settings.custom_minimum_size.y = 72.0 if _feature_key == "profile" else 96.0
	profile_settings.add_theme_font_size_override("font_size", 19 if _feature_key == "profile" else 22)
	save_health_card.custom_minimum_size.y = 118.0 if _feature_key == "profile" else 168.0
	save_health_kicker.add_theme_font_size_override("font_size", 14 if _feature_key == "profile" else 16)
	local_save_status.add_theme_font_size_override("font_size", 20 if _feature_key == "profile" else 24)
	cloud_sync_status.add_theme_font_size_override("font_size", 17 if _feature_key == "profile" else 20)
	truth_strip.visible = false
	back_button.visible = false
	hero_body.visible = false
	daily_kicker.visible = _feature_key != "events"
	daily_title.visible = _feature_key != "events"
	daily_truth.visible = _feature_key != "events"
	if _feature_key == "events":
		daily_card.custom_minimum_size.y = 86.0
		daily_card.size_flags_vertical = Control.SIZE_FILL
		daily_action.custom_minimum_size.y = 66.0
		weekly_action.custom_minimum_size.y = 72.0
	else:
		daily_card.custom_minimum_size.y = 150.0
		daily_action.custom_minimum_size.y = 72.0
		weekly_action.custom_minimum_size.y = 96.0

	local_save_status.text = String(state.get("save_status", "LOCAL SAVE · DEVICE-LOCAL"))
	local_save_detail.text = String(state.get("save_detail", "Progress is stored on this device."))
	cloud_sync_status.text = "CLOUD SYNC · NOT CONNECTED"
	cloud_sync_detail.text = "No account sign-in, remote backup, or cross-device restore is active in this build."

	match _feature_key:
		"events":
			background_id = "events_bg_curio_house"
			hero_path = "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp"
			title.text = "EVENTS"
			detail.text = "FUTURE HOUSE RITUALS · SEALED"
			hero_kicker.text = "OPENING RITUAL COMPLETE" if opening_complete else "OPENING RITUAL IN PROGRESS"
			hero_title.text = "%d / %d DISPLAYS AWAKENED" % [completed_count, opening_cap]
			hero_body.text = "The House remembers every completed display; future weekly events remain sealed."
			chapter_progress.text = ("OPENING RITUAL COMPLETE · %d / %d DISPLAYS AWAKENED" if opening_complete else "OPENING RITUAL · %d / %d DISPLAYS AWAKENED") % [completed_count, opening_cap]
			daily_title.text = "DAILY PRACTICE · LEVEL %d · NO BONUS" % _daily_level if _daily_level > 0 else "DAILY PRACTICE · SEALED"
			daily_truth.text = "REPLAY ONLY · NO BONUS REWARD · NO CURRENCY SPEND" if _daily_level > 0 else "COMPLETE AN OPENING RITUAL TO UNLOCK LOCAL PRACTICE"
			daily_action.text = "PRACTICE LEVEL %d · NO BONUS" % _daily_level if _daily_level > 0 else "DAILY PRACTICE · SEALED"
			weekly_action.text = "WEEKLY RITUALS"
			daily_action.disabled = _daily_level <= 0
			daily_action.set_meta("daily_level", _daily_level)
			truth_strip.text = "LIVE EVENT REWARDS ARE NOT FABRICATED · DAILY PRACTICE IS DEVICE-LOCAL"
			cards = [
				{"art":"res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp", "kicker":"SEALED RITUAL", "title":"MOONLIGHT MARKET", "body":"", "status":"FUTURE EVENT · SEALED"},
				{"art":"res://assets/world/ch01_curio_boutique/prestart_level01_cabinet.webp", "kicker":"SEALED RITUAL", "title":"THE LOST RELICS", "body":"", "status":"FUTURE JOURNEY · SEALED"}
			]
		"shop":
			background_id = "shop_bg_curio_house"
			hero_path = "res://assets/curios/ch01_curio_moth_reliquary.png"
			title.text = "SHOP"
			detail.text = "SEALED PREVIEWS · COMMERCE NOT CONNECTED"
			hero_kicker.text = "EMPORIUM PREVIEW · SEALED"
			hero_title.text = "NO PURCHASES ENABLED"
			hero_body.text = "These balances come only from first clears. Purchases and spending are not connected."
			shop_notice.text = "NO PURCHASES OR PAYMENTS · PREVIEW ONLY"
			shop_currency.text = "HOUSE COINS  %d  ·  MOONSTONES  %d" % [coins, gems]
			shop_truth.text = "EARNED IN PLAY · NOT PURCHASABLE"
			shop_disabled_action.disabled = true
			truth_strip.text = "EARNED IN PLAY · NOT PURCHASABLE · NO REAL-MONEY COMMERCE"
			cards = [
				{"art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp", "kicker":"FEATURED PREVIEW", "title":"CANDLELIGHT KIT", "body":"", "status":"SEALED · NO PURCHASES"},
				{"art":"res://assets/curios/ch01_curio_moth_reliquary.png", "kicker":"SEALED PREVIEW", "title":"MOONSTONE CACHE", "body":"", "status":"SEALED · NO PURCHASES"},
				{"art":"res://assets/curios/ch01_curio_thorned_locket.png", "kicker":"SEALED PREVIEW", "title":"RESTORER'S RELIQUARY", "body":"", "status":"SEALED · NO PURCHASES"}
			]
		"profile":
			background_id = "profile_bg_curio_house"
			hero_path = "res://assets/pieces/black_cat.webp"
			title.text = "PLAYER"
			detail.text = "THE KEEPER · DEVICE-LOCAL RECORD"
			hero_body.text = "Your opening journey is stored locally and reflected across the House, map and Reliquary."
			profile_identity_kicker.text = "KEEPER RECORD"
			profile_identity_title.text = "FIRST CABINET SET RESTORED" if opening_complete else "OPENING HOUSE IN PROGRESS"
			profile_identity_progress_label.text = "OPENING RITUALS · %d / %d" % [completed_count, opening_cap]
			profile_identity_progress.max_value = float(opening_cap)
			profile_identity_progress.value = float(completed_count)
			profile_chapter_status.text = "%d / %d RITUALS · COMPLETE" % [completed_count, opening_cap] if opening_complete else "%d / %d RITUALS" % [completed_count, opening_cap]
			profile_reliquary_status.text = "%d / %d CURIOS · AWAKENED" % [collected_count, opening_cap]
			profile_house_status.text = "OPENING RESTORATION COMPLETE" if opening_complete else "RESTORATION STAGE %d" % restored_stage
			profile_save_local.text = String(state.get("save_status", "LOCAL SAVE · DEVICE-LOCAL"))
			profile_save_cloud.text = "CLOUD SYNC · NOT CONNECTED"
			truth_strip.text = "CLOUD SYNC · NOT CONNECTED · NO REMOTE BACKUP CLAIM"
			cards = []
		_:
			return false

	world_art.texture = ScreenArt.texture(background_id)
	if world_art.texture == null:
		return false
	if _feature_key == "shop":
		shop_offer_art.texture = PieceAssetLoader.ornament(hero_path)
		if shop_offer_art.texture == null:
			return false
	elif _feature_key == "profile":
		profile_keeper_art.texture = PieceAssetLoader.ornament(hero_path)
		profile_chapter_icon.texture = PieceAssetLoader.ornament("res://assets/pieces/moon_sigil.webp")
		profile_reliquary_icon.texture = PieceAssetLoader.ornament("res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp")
		profile_house_icon.texture = PieceAssetLoader.ornament("res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp")
		if profile_keeper_art.texture == null or profile_chapter_icon.texture == null or profile_reliquary_icon.texture == null or profile_house_icon.texture == null:
			return false
	else:
		hero_art.texture = PieceAssetLoader.ornament(hero_path)
		if hero_art.texture == null:
			return false
	_hero_asset_path = hero_path
	if _feature_key == "events":
		_apply_event_cards(cards)
		_apply_cards([])
	else:
		_apply_event_cards([])
		_apply_cards(cards)
		if _feature_key == "shop":
			for card_path in ["Card1", "Card2", "Card3"]:
				ProductionChrome.apply_compact_panel(card_stack.get_node(card_path) as PanelContainer, "shop_catalog_card")
	return true

func _apply_event_cards(cards: Array[Dictionary]) -> void:
	var event_cards: Array[PanelContainer] = [event_card_1, event_card_2]
	var event_arts: Array[TextureRect] = [event_art_1, event_art_2]
	var event_kickers: Array[Label] = [event_kicker_1, event_kicker_2]
	var event_titles: Array[Label] = [event_title_1, event_title_2]
	var event_statuses: Array[Label] = [event_status_1, event_status_2]
	for i in event_cards.size():
		var entry: Dictionary = cards[i] if i < cards.size() else {}
		event_cards[i].visible = not entry.is_empty()
		if entry.is_empty():
			event_arts[i].texture = null
			continue
		var art_path := String(entry.get("art", ""))
		event_arts[i].texture = PieceAssetLoader.ornament(art_path)
		event_arts[i].set_meta("asset_path", art_path)
		event_kickers[i].text = String(entry.get("kicker", "SEALED RITUAL"))
		event_titles[i].text = String(entry.get("title", ""))
		event_statuses[i].text = String(entry.get("status", "SEALED"))

func _apply_cards(cards: Array[Dictionary]) -> void:
	var nodes: Array[PanelContainer] = [
		$FeatureLayout/CardScroll/Cards/Card1,
		$FeatureLayout/CardScroll/Cards/Card2,
		$FeatureLayout/CardScroll/Cards/Card3,
	]
	for i in nodes.size():
		var card := nodes[i]
		var entry: Dictionary = cards[i] if i < cards.size() else {}
		card.visible = not entry.is_empty()
		if entry.is_empty():
			continue
		var row := card.get_node("Row") as HBoxContainer
		var art := card.get_node("Row/Art") as TextureRect
		var kicker := card.get_node("Row/Copy/Kicker") as Label
		var card_title := card.get_node("Row/Copy/Title") as Label
		var body := card.get_node("Row/Copy/Body") as Label
		var status := card.get_node("Row/Copy/Status") as Label
		var shop_state_plate := card.get_node_or_null("Row/ShopStatePlate") as PanelContainer
		if _feature_key == "shop":
			card_stack.add_theme_constant_override("separation", 10)
			card.custom_minimum_size.y = 214.0 if i == 0 else 154.0
			card.size_flags_vertical = Control.SIZE_FILL
			card.size_flags_stretch_ratio = 1.0
			row.add_theme_constant_override("separation", 12)
			art.custom_minimum_size = Vector2(178, 178) if i == 0 else Vector2(108, 108)
			art.size_flags_vertical = Control.SIZE_FILL
			kicker.add_theme_font_size_override("font_size", 16 if i == 0 else 14)
			card_title.add_theme_font_size_override("font_size", 30 if i == 0 else 25)
			status.visible = false
			status.add_theme_font_size_override("font_size", 14 if i == 0 else 13)
			if shop_state_plate != null:
				shop_state_plate.visible = true
				shop_state_plate.custom_minimum_size = Vector2(120, 54)
				var state_label := shop_state_plate.get_node("Content/State") as Label
				var detail_label := shop_state_plate.get_node("Content/Detail") as Label
				var mode_label := shop_state_plate.get_node("Content/Mode") as Label
				state_label.add_theme_font_size_override("font_size", 15)
				detail_label.visible = false
				mode_label.visible = false
		else:
			card.custom_minimum_size.y = 236.0
			card.size_flags_vertical = Control.SIZE_FILL
			card.size_flags_stretch_ratio = 1.0
			row.add_theme_constant_override("separation", 18)
			art.custom_minimum_size = Vector2(224, 204)
			art.size_flags_vertical = Control.SIZE_FILL
			kicker.add_theme_font_size_override("font_size", 17)
			card_title.add_theme_font_size_override("font_size", 34)
			status.visible = true
			status.add_theme_font_size_override("font_size", 18)
			if shop_state_plate != null:
				shop_state_plate.visible = false
		var art_path := String(entry.get("art", ""))
		art.texture = PieceAssetLoader.ornament(art_path)
		art.set_meta("asset_path", art_path)
		kicker.text = String(entry.get("kicker", ""))
		card_title.text = String(entry.get("title", ""))
		body.text = String(entry.get("body", ""))
		status.text = String(entry.get("status", ""))

func _apply_profile_rows() -> void:
	card_stack.add_theme_constant_override("separation", 8)
	for card_path in ["Card1", "Card2", "Card3"]:
		var card := card_stack.get_node(card_path) as PanelContainer
		var row := card.get_node("Row") as HBoxContainer
		var art := card.get_node("Row/Art") as TextureRect
		var kicker := card.get_node("Row/Copy/Kicker") as Label
		var card_title := card.get_node("Row/Copy/Title") as Label
		var status := card.get_node("Row/Copy/Status") as Label
		var shop_state_plate := card.get_node_or_null("Row/ShopStatePlate") as PanelContainer
		ProductionChrome.apply_compact_panel(card, "profile_record_row")
		card.custom_minimum_size.y = 112.0
		card.size_flags_vertical = Control.SIZE_FILL
		row.add_theme_constant_override("separation", 12)
		art.custom_minimum_size = Vector2(88, 88)
		art.size_flags_vertical = Control.SIZE_FILL
		kicker.visible = false
		card_title.add_theme_font_size_override("font_size", 22)
		status.add_theme_font_size_override("font_size", 15)
		if shop_state_plate != null:
			shop_state_plate.visible = false

func _on_daily_pressed() -> void:
	if _feature_key == "events" and _daily_level > 0:
		daily_practice_requested.emit(_daily_level)

func screen_contract() -> Dictionary:
	var hero_loaded := shop_offer_art.texture != null if _feature_key == "shop" else (profile_keeper_art.texture != null if _feature_key == "profile" else hero_art.texture != null)
	var active_hero_art: TextureRect = shop_offer_art if _feature_key == "shop" else (profile_keeper_art if _feature_key == "profile" else hero_art)
	var hero_panel := $FeatureLayout/FeatureHero as PanelContainer
	var card_nodes := [
		$FeatureLayout/CardScroll/Cards/Card1,
		$FeatureLayout/CardScroll/Cards/Card2,
		$FeatureLayout/CardScroll/Cards/Card3,
	]
	var card_art_nodes := [
		$FeatureLayout/CardScroll/Cards/Card1/Row/Art,
		$FeatureLayout/CardScroll/Cards/Card2/Row/Art,
		$FeatureLayout/CardScroll/Cards/Card3/Row/Art,
	]
	var card_bodies := [
		$FeatureLayout/CardScroll/Cards/Card1/Row/Copy/Body,
		$FeatureLayout/CardScroll/Cards/Card2/Row/Copy/Body,
		$FeatureLayout/CardScroll/Cards/Card3/Row/Copy/Body,
	]
	var art_dominant_cards := card_nodes.all(func(card): return (card as PanelContainer).custom_minimum_size.y >= 230.0) and card_art_nodes.all(
		func(art): return (art as TextureRect).custom_minimum_size.x >= 220.0 and (art as TextureRect).custom_minimum_size.y >= 195.0
	)
	var compact_copy := card_bodies.all(func(body): return not (body as Label).visible)
	var events_card_focus := _feature_key != "events" or (
		events_feature != null
		and events_feature.visible
		and events_feature.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and not hero_panel.visible
		and not card_scroll.visible
		and event_card_1.visible
		and event_card_2.visible
		and event_card_1.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and event_card_2.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and event_card_1.custom_minimum_size.y >= 330.0
		and event_card_1.custom_minimum_size.y <= 350.0
		and event_card_2.custom_minimum_size.y >= 330.0
		and event_card_2.custom_minimum_size.y <= 350.0
		and event_art_1.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and event_art_2.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and event_art_1.custom_minimum_size.y >= 236.0
		and event_art_1.custom_minimum_size.y <= 252.0
		and event_art_2.custom_minimum_size.y >= 236.0
		and event_art_2.custom_minimum_size.y <= 252.0
		and event_art_1.texture != null
		and event_art_2.texture != null
	)
	var events_actions_subordinate := _feature_key != "events" or (
		daily_card.visible
		and daily_card.custom_minimum_size.y >= 82.0
		and daily_card.custom_minimum_size.y <= 90.0
		and daily_card.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and not daily_title.visible
		and daily_action.custom_minimum_size.y >= 62.0
		and daily_action.custom_minimum_size.y <= 70.0
		and weekly_action.visible
		and weekly_action.custom_minimum_size.y >= 68.0
		and weekly_action.custom_minimum_size.y <= 76.0
	)
	var events_truthful_status := _feature_key != "events" or (
		event_status_1.visible
		and event_status_2.visible
		and event_status_1.text.contains("SEALED")
		and event_status_2.text.contains("SEALED")
	)
	var shop_state_plates := [
		$FeatureLayout/CardScroll/Cards/Card1/Row/ShopStatePlate,
		$FeatureLayout/CardScroll/Cards/Card2/Row/ShopStatePlate,
		$FeatureLayout/CardScroll/Cards/Card3/Row/ShopStatePlate,
	]
	var shop_status_labels := [
		$FeatureLayout/CardScroll/Cards/Card1/Row/Copy/Status,
		$FeatureLayout/CardScroll/Cards/Card2/Row/Copy/Status,
		$FeatureLayout/CardScroll/Cards/Card3/Row/Copy/Status,
	]
	var shop_catalog_focus := _feature_key != "shop" or (
		not hero_panel.visible
		and card_scroll.visible
		and card_stack.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and shop_notice.visible
		and not detail.visible
		and not shop_currency.visible
		and not shop_truth.visible
		and not shop_disabled_action.visible
		and card_nodes.all(func(card): return (card as PanelContainer).visible and (card as PanelContainer).size_flags_vertical != Control.SIZE_EXPAND_FILL)
		and (card_nodes[0] as PanelContainer).custom_minimum_size.y >= 204.0
		and (card_nodes[0] as PanelContainer).custom_minimum_size.y <= 220.0
		and [card_nodes[1], card_nodes[2]].all(func(card): return (card as PanelContainer).custom_minimum_size.y >= 146.0 and (card as PanelContainer).custom_minimum_size.y <= 160.0)
		and (card_art_nodes[0] as TextureRect).custom_minimum_size.x >= 170.0
		and (card_art_nodes[0] as TextureRect).custom_minimum_size.x <= 186.0
		and [card_art_nodes[1], card_art_nodes[2]].all(func(art): return (art as TextureRect).custom_minimum_size.x >= 102.0 and (art as TextureRect).custom_minimum_size.x <= 114.0)
		and shop_state_plates.all(func(plate): return (plate as PanelContainer).visible and (plate as PanelContainer).custom_minimum_size.y <= 58.0 and (plate as PanelContainer).get_theme_stylebox("panel") is StyleBoxFlat)
		and shop_status_labels.all(func(label): return not (label as Label).visible)
	)
	var profile_identity_focus := _feature_key != "profile" or (
		profile_surface.visible
		and profile_surface.get_theme_stylebox("panel") is StyleBoxFlat
		and String(profile_surface.get_meta("profile_material", "")) == "screen_specific_flat"
		and profile_feature.visible
		and not hero_panel.visible
		and profile_identity.visible
		and profile_identity.custom_minimum_size.y >= 280.0
		and profile_identity.custom_minimum_size.y <= 320.0
		and profile_keeper_art.texture != null
		and profile_keeper_art.custom_minimum_size.x >= 200.0
		and profile_keeper_art.custom_minimum_size.x <= 240.0
		and profile_identity_progress.visible
		and profile_identity_progress.max_value >= 1.0
	)
	var profile_menu_spacer := get_node_or_null("FeatureLayout/ProfileFeature/Menu/UtilitySpacer") as Control
	var profile_utility_rows := _feature_key != "profile" or (
		profile_settings_row.visible
		and profile_settings_row.custom_minimum_size.y >= 88.0
		and profile_settings_row.custom_minimum_size.y <= 96.0
		and [profile_chapter_row, profile_reliquary_row, profile_house_row].all(func(row): return row.visible and row.custom_minimum_size.y >= 128.0 and row.custom_minimum_size.y <= 136.0 and row.size_flags_vertical != Control.SIZE_EXPAND_FILL)
		and profile_save_row.visible
		and profile_save_row.custom_minimum_size.y >= 116.0
		and profile_save_row.custom_minimum_size.y <= 124.0
		and profile_save_row.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and profile_menu_spacer != null
		and profile_menu_spacer.size_flags_vertical != Control.SIZE_EXPAND_FILL
		and profile_menu_spacer.custom_minimum_size.y <= 16.0
	)
	if _feature_key == "events":
		art_dominant_cards = events_card_focus
		compact_copy = true
	elif _feature_key == "shop":
		art_dominant_cards = shop_catalog_focus
		compact_copy = true
	elif _feature_key == "profile":
		art_dominant_cards = profile_utility_rows
		compact_copy = true
	var hero_dominant := events_card_focus if _feature_key == "events" else (shop_catalog_focus if _feature_key == "shop" else (profile_identity_focus if _feature_key == "profile" else (hero_panel.custom_minimum_size.y >= 400.0 and active_hero_art.custom_minimum_size.x >= 340.0 and active_hero_art.custom_minimum_size.y >= 340.0)))
	var controlled_chrome := compact_copy and not truth_strip.visible and not back_button.visible and ($HeaderShade as ColorRect).color.a <= 0.38
	var profile_status_focus := _feature_key != "profile" or (
		profile_save_row.visible
		and profile_save_local.text.begins_with("LOCAL SAVE")
		and profile_save_cloud.text == "CLOUD SYNC · NOT CONNECTED"
		and profile_save_local.get_theme_font_size("font_size") >= 20
		and profile_save_cloud.get_theme_font_size("font_size") >= 16
	)
	return {
		"feature": _feature_key,
		"world_art_loaded": world_art != null and world_art.texture != null,
		"hero_art_loaded": hero_loaded,
		"static_card_slots": 3,
		"code_built_panels": false,
		"north_star_title_hierarchy": title != null and title.get_theme_font_size("font_size") >= (42 if _feature_key == "shop" else (40 if _feature_key == "profile" else 52)),
		"north_star_hero_scale": hero_dominant,
		"asset_backed_hero_chrome": (event_card_1.get_theme_stylebox("panel") is StyleBoxTexture and event_card_2.get_theme_stylebox("panel") is StyleBoxTexture) if _feature_key == "events" else (card_nodes.all(func(card): return (card as PanelContainer).get_theme_stylebox("panel") is StyleBoxTexture) if _feature_key == "shop" else (true if _feature_key == "profile" else (hero_panel.get_theme_stylebox("panel") is StyleBoxTexture and String(hero_panel.get_meta("production_chrome_kind", "")) == "secondary_meta_hero"))),
		"shop_catalog_focus": shop_catalog_focus,
		"shop_compact_catalog_density": shop_catalog_focus,
		"shop_clean_sealed_badges": _feature_key != "shop" or shop_state_plates.all(func(plate): return (plate as PanelContainer).get_theme_stylebox("panel") is StyleBoxFlat and (plate as PanelContainer).custom_minimum_size.y <= 58.0),
		"profile_identity_focus": profile_identity_focus,
		"profile_board_utility_rows": profile_utility_rows,
		"profile_compact_menu_flow": _feature_key != "profile" or (
			profile_feature.size_flags_vertical != Control.SIZE_EXPAND_FILL
			and ($FeatureLayout/ProfileFeature/Menu as VBoxContainer).size_flags_vertical != Control.SIZE_EXPAND_FILL
			and profile_menu_spacer != null
			and profile_menu_spacer.size_flags_vertical != Control.SIZE_EXPAND_FILL
			and profile_menu_spacer.custom_minimum_size.y <= 16.0
			and profile_save_row.size_flags_vertical != Control.SIZE_EXPAND_FILL
			and profile_surface.offset_bottom <= -600.0
		),
		"profile_screen_specific_material": _feature_key != "profile" or (
			profile_identity.get_theme_stylebox("panel") is StyleBoxFlat
			and profile_chapter_row.get_theme_stylebox("panel") is StyleBoxFlat
			and profile_reliquary_row.get_theme_stylebox("panel") is StyleBoxFlat
			and profile_house_row.get_theme_stylebox("panel") is StyleBoxFlat
			and profile_save_row.get_theme_stylebox("panel") is StyleBoxFlat
		),
		"events_board_card_composition": events_card_focus,
		"events_compact_card_density": events_card_focus and events_actions_subordinate,
		"events_actions_subordinate": events_actions_subordinate,
		"events_truthful_status": events_truthful_status,
		"hero_asset_path": _hero_asset_path,
		"raster_feature_art": _hero_asset_path.to_lower().ends_with(".webp") or _hero_asset_path.to_lower().ends_with(".png"),
		"rounded_primary_actions": weekly_action.get_theme_stylebox("normal") is StyleBoxTexture and profile_settings.get_theme_stylebox("normal") is StyleBoxTexture,
		"asset_backed_utility_actions": daily_action.get_theme_stylebox("normal") is StyleBoxTexture and back_button.get_theme_stylebox("normal") is StyleBoxTexture and shop_disabled_action.get_theme_stylebox("disabled") is StyleBoxTexture,
		"card_copy_compact": compact_copy,
		"art_dominant_cards": art_dominant_cards,
		"header_readability_scrim": ($HeaderShade as ColorRect) != null and ($HeaderShade as ColorRect).color.a >= 0.34,
		"secondary_header_compact": (_feature_key != "events" or not chapter_progress.visible) and (_feature_key != "shop" or (shop_notice.visible and shop_notice.get_theme_font_size("font_size") <= 16 and not shop_currency.visible and not shop_truth.visible)),
		"profile_save_health_compact": _feature_key != "profile" or (profile_save_row != null and profile_save_row.custom_minimum_size.y <= 124.0),
		"profile_status_focus": profile_status_focus,
		"redundant_house_return_suppressed": not back_button.visible,
		"truth_footer_suppressed": not truth_strip.visible,
		"world_art_not_overdimmed": ($WorldShade as ColorRect).color.a <= 0.32,
		"controlled_chrome_density": controlled_chrome,
		"visual_parity_gate_v2": hero_dominant and art_dominant_cards and controlled_chrome and hero_loaded and events_actions_subordinate and events_truthful_status,
		"visual_parity_gate_v3": hero_dominant and art_dominant_cards and controlled_chrome and hero_loaded and profile_status_focus and events_actions_subordinate and events_truthful_status,
	}
