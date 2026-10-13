extends Control

signal back_requested
signal settings_requested
signal weekly_requested
signal daily_practice_requested(level_number: int)

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

var _feature_key: String = ""
var _daily_level: int = 0
var _hero_asset_path: String = ""

@onready var world_art: TextureRect = $WorldArt
@onready var title: Label = $FeatureLayout/FeatureTitle
@onready var detail: Label = $FeatureLayout/Detail
@onready var chapter_progress: Label = $FeatureLayout/ChapterRitualProgress
@onready var shop_notice: Label = $FeatureLayout/NoPurchasesNotice
@onready var shop_currency: Label = $FeatureLayout/ShopCurrencySummary
@onready var shop_truth: Label = $FeatureLayout/ShopCurrencyTruth
@onready var hero_art: TextureRect = $FeatureLayout/FeatureHero/HeroRow/HeroArt
@onready var shop_offer_art: TextureRect = $FeatureLayout/FeatureHero/HeroRow/ShopFeaturedOfferArt
@onready var hero_kicker: Label = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroKicker
@onready var hero_title: Label = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/FeatureHeroTitle
@onready var hero_body: Label = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/HeroBody
@onready var shop_disabled_action: Button = $FeatureLayout/FeatureHero/HeroRow/HeroCopy/ShopDisabledAction
@onready var daily_card: PanelContainer = $FeatureLayout/DailyPracticeCard
@onready var daily_title: Label = $FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeTitle
@onready var daily_truth: Label = $FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeTruth
@onready var daily_action: Button = $FeatureLayout/DailyPracticeCard/DailyContent/DailyPracticeAction
@onready var weekly_action: Button = $FeatureLayout/WeeklyMissionsAction
@onready var profile_settings: Button = $FeatureLayout/ProfileSettings
@onready var save_health_card: PanelContainer = $FeatureLayout/SaveHealthCard
@onready var local_save_status: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/LocalSaveStatus
@onready var local_save_detail: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/LocalSaveDetail
@onready var cloud_sync_status: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/CloudSyncStatus
@onready var cloud_sync_detail: Label = $FeatureLayout/SaveHealthCard/SaveHealthContent/CloudSyncDetail
@onready var truth_strip: Label = $FeatureLayout/TruthStrip
@onready var back_button: Button = $FeatureLayout/BackToHouse

func _ready() -> void:
	ProductionChrome.apply_secondary($FeatureLayout/FeatureHero, "meta_hero")
	ProductionChrome.apply_action_button(weekly_action, "primary", "events_weekly")
	ProductionChrome.apply_action_button(profile_settings, "primary", "profile_settings")
	ProductionChrome.apply_action_button(daily_action, "utility", "events_daily_practice")
	ProductionChrome.apply_action_button(shop_disabled_action, "utility", "shop_sealed")
	ProductionChrome.apply_action_button(back_button, "utility", "meta_return_house")
	weekly_action.pressed.connect(func(): weekly_requested.emit())
	daily_action.pressed.connect(_on_daily_pressed)
	profile_settings.pressed.connect(func(): settings_requested.emit())
	back_button.pressed.connect(func(): back_requested.emit())

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
	daily_card.visible = _feature_key == "events"
	weekly_action.visible = _feature_key == "events"
	shop_notice.visible = false
	shop_currency.visible = _feature_key == "shop"
	shop_truth.visible = _feature_key == "shop"
	shop_offer_art.visible = _feature_key == "shop"
	shop_disabled_action.visible = _feature_key == "shop"
	hero_art.visible = _feature_key != "shop"
	profile_settings.visible = _feature_key == "profile"
	save_health_card.visible = _feature_key == "profile"
	truth_strip.visible = false
	back_button.visible = false
	hero_body.visible = false

	local_save_status.text = String(state.get("save_status", "LOCAL SAVE · DEVICE-LOCAL"))
	local_save_detail.text = String(state.get("save_detail", "Progress is stored on this device."))
	cloud_sync_status.text = "CLOUD SYNC · NOT CONNECTED"
	cloud_sync_detail.text = "No account sign-in, remote backup, or cross-device restore is active in this build."

	match _feature_key:
		"events":
			background_id = "events_bg_curio_house"
			hero_path = "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp"
			title.text = "EVENT CENTER"
			detail.text = "SEASONAL RITUALS · WEEKLY ALTAR · DAILY PRACTICE"
			hero_kicker.text = "OPENING RITUAL COMPLETE" if opening_complete else "OPENING RITUAL IN PROGRESS"
			hero_title.text = "%d / %d DISPLAYS AWAKENED" % [completed_count, opening_cap]
			hero_body.text = "The House remembers every completed display; future weekly events remain sealed."
			chapter_progress.text = ("OPENING RITUAL COMPLETE · %d / %d DISPLAYS AWAKENED" if opening_complete else "OPENING RITUAL · %d / %d DISPLAYS AWAKENED") % [completed_count, opening_cap]
			daily_title.text = "DAILY HOUSE RITUAL · LEVEL %d" % _daily_level if _daily_level > 0 else "DAILY HOUSE RITUAL · SEALED"
			daily_truth.text = "REPLAY ONLY · NO BONUS REWARD · NO CURRENCY SPEND" if _daily_level > 0 else "COMPLETE AN OPENING RITUAL TO UNLOCK LOCAL PRACTICE"
			daily_action.text = "PRACTICE LEVEL %d" % _daily_level if _daily_level > 0 else "RESTORE A DISPLAY TO UNLOCK"
			daily_action.disabled = _daily_level <= 0
			daily_action.set_meta("daily_level", _daily_level)
			truth_strip.text = "LIVE EVENT REWARDS ARE NOT FABRICATED · DAILY PRACTICE IS DEVICE-LOCAL"
			cards = [
				{"art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp", "kicker":"RITUAL I", "title":"MOONLIGHT MARKET", "body":"The opening cabinet set is restored. The House is ready for a future moonlit event." if opening_complete else "Awaken the three opening displays to restore the Curio House.", "status":"OPENING CHAPTER COMPLETE · FUTURE MARKET EVENT REMAINS SEALED" if opening_complete else "CHAPTER PROGRESS TRACKED · MARKET EVENT NOT YET ACTIVE"},
				{"art":"res://assets/curios/ch01_curio_moth_reliquary.png", "kicker":"RITUAL II", "title":"THE LOST RELICS", "body":"A sealed reliquary marks a future cabinet journey.", "status":"UPPER CABINETS SEALED · FUTURE JOURNEY" if opening_complete else "LOCKED · COMPLETE THE OPENING CHAPTER"},
				{"art":"res://assets/curios/ch01_curio_thorned_locket.png", "kicker":"RITUAL III", "title":"WEEKLY RITUALS", "body":"Weekly ritual challenges will live here when a live mission feed exists.", "status":"FUTURE FEATURE · NO CLAIMABLE REWARDS"}
			]
		"shop":
			background_id = "shop_bg_curio_house"
			hero_path = "res://assets/curios/ch01_curio_moth_reliquary.png"
			title.text = "THE CURIO EMPORIUM"
			detail.text = "SEALED ECONOMY PREVIEW · NOTHING HERE CAN CHARGE YOU"
			hero_kicker.text = "EMPORIUM PREVIEW · SEALED"
			hero_title.text = "NO PURCHASES ENABLED"
			hero_body.text = "These balances come only from first clears. Purchases and spending are not connected."
			shop_notice.text = "THE EMPORIUM IS SEALED · NO PURCHASES OR PAYMENTS"
			shop_currency.text = "HOUSE COINS  %d  ·  MOONSTONES  %d" % [coins, gems]
			shop_truth.text = "EARNED IN PLAY · NOT PURCHASABLE"
			shop_disabled_action.disabled = true
			truth_strip.text = "EARNED IN PLAY · NOT PURCHASABLE · NO REAL-MONEY COMMERCE"
			cards = [
				{"art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp", "kicker":"SEALED CABINET I", "title":"CANDLELIGHT KIT", "body":"A future soft-currency cabinet for restoration supplies.", "status":"SEALED · ECONOMY PREVIEW ONLY"},
				{"art":"res://assets/curios/ch01_curio_moth_reliquary.png", "kicker":"SEALED CABINET II", "title":"MOONSTONE CACHE", "body":"A future premium-currency cabinet. No price or payment flow is active.", "status":"SEALED · NO REAL-MONEY PURCHASES"},
				{"art":"res://assets/curios/ch01_curio_thorned_locket.png", "kicker":"SEALED CABINET III", "title":"RESTORER'S RELIQUARY", "body":"A future curated bundle surface for boosters and curios.", "status":"SEALED · STORE NOT CONNECTED"}
			]
		"profile":
			background_id = "profile_bg_curio_house"
			hero_path = "res://assets/pieces/black_cat.webp"
			title.text = "THE KEEPER"
			detail.text = "YOUR HOUSE · CURIOS · PROGRESS · PREFERENCES"
			hero_kicker.text = "FIRST CABINET SET RESTORED" if opening_complete else "KEEPER RECORD"
			hero_title.text = "%d CURIOS · RESTORATION STAGE %d" % [collected_count, restored_stage]
			hero_body.text = "Your opening journey is stored locally and reflected across the House, map and Reliquary."
			truth_strip.text = "CLOUD SYNC · NOT CONNECTED · NO REMOTE BACKUP CLAIM"
			cards = [
				{"art":"res://assets/pieces/moon_sigil.webp", "kicker":"KEEPER RECORD I", "title":"CHAPTER PROGRESS", "body":"Opening chapter complete · %d of %d rituals." % [completed_count, opening_cap] if opening_complete else "%d of %d opening rituals completed." % [completed_count, opening_cap], "status":"FIRST CABINET SET RESTORED" if opening_complete else "YOUR SAVED JOURNEY"},
				{"art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp", "kicker":"KEEPER RECORD II", "title":"RELIQUARY", "body":"%d of %d opening curios awakened." % [collected_count, opening_cap], "status":"OPENING SET COMPLETE" if opening_complete else "RELICS RECOVERED"},
				{"art":"res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp", "kicker":"KEEPER RECORD III", "title":"HOUSE RESTORATION", "body":"Restoration stage %d." % restored_stage, "status":"OPENING RESTORATION COMPLETE" if opening_complete else "PROGRESS SAVED ON THIS DEVICE"}
			]
		_:
			return false

	world_art.texture = ScreenArt.texture(background_id)
	if world_art.texture == null:
		return false
	if _feature_key == "shop":
		shop_offer_art.texture = PieceAssetLoader.ornament(hero_path)
		if shop_offer_art.texture == null:
			return false
	else:
		hero_art.texture = PieceAssetLoader.ornament(hero_path)
		if hero_art.texture == null:
			return false
	_hero_asset_path = hero_path
	_apply_cards(cards)
	return true

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
		var art := card.get_node("Row/Art") as TextureRect
		var kicker := card.get_node("Row/Copy/Kicker") as Label
		var card_title := card.get_node("Row/Copy/Title") as Label
		var body := card.get_node("Row/Copy/Body") as Label
		var status := card.get_node("Row/Copy/Status") as Label
		var art_path := String(entry.get("art", ""))
		art.texture = PieceAssetLoader.ornament(art_path)
		art.set_meta("asset_path", art_path)
		kicker.text = String(entry.get("kicker", ""))
		card_title.text = String(entry.get("title", ""))
		body.text = String(entry.get("body", ""))
		status.text = String(entry.get("status", ""))

func _on_daily_pressed() -> void:
	if _feature_key == "events" and _daily_level > 0:
		daily_practice_requested.emit(_daily_level)

func screen_contract() -> Dictionary:
	var hero_loaded := shop_offer_art.texture != null if _feature_key == "shop" else hero_art.texture != null
	var active_hero_art: TextureRect = shop_offer_art if _feature_key == "shop" else hero_art
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
	var hero_dominant := hero_panel.custom_minimum_size.y >= 400.0 and active_hero_art.custom_minimum_size.x >= 340.0 and active_hero_art.custom_minimum_size.y >= 340.0
	var controlled_chrome := compact_copy and not truth_strip.visible and not back_button.visible and ($HeaderShade as ColorRect).color.a <= 0.38
	var profile_status_focus := _feature_key != "profile" or (
		save_health_card != null
		and save_health_card.visible
		and not local_save_detail.visible
		and not cloud_sync_detail.visible
		and local_save_status.get_theme_font_size("font_size") >= 24
		and cloud_sync_status.get_theme_font_size("font_size") >= 20
	)
	return {
		"feature": _feature_key,
		"world_art_loaded": world_art != null and world_art.texture != null,
		"hero_art_loaded": hero_loaded,
		"static_card_slots": 3,
		"code_built_panels": false,
		"north_star_title_hierarchy": title != null and title.get_theme_font_size("font_size") >= 52,
		"north_star_hero_scale": hero_dominant,
		"asset_backed_hero_chrome": hero_panel.get_theme_stylebox("panel") is StyleBoxTexture and String(hero_panel.get_meta("production_chrome_kind", "")) == "secondary_meta_hero",
		"hero_asset_path": _hero_asset_path,
		"raster_feature_art": _hero_asset_path.to_lower().ends_with(".webp") or _hero_asset_path.to_lower().ends_with(".png"),
		"rounded_primary_actions": weekly_action.get_theme_stylebox("normal") is StyleBoxTexture and profile_settings.get_theme_stylebox("normal") is StyleBoxTexture,
		"asset_backed_utility_actions": daily_action.get_theme_stylebox("normal") is StyleBoxTexture and back_button.get_theme_stylebox("normal") is StyleBoxTexture and shop_disabled_action.get_theme_stylebox("disabled") is StyleBoxTexture,
		"card_copy_compact": compact_copy,
		"art_dominant_cards": art_dominant_cards,
		"header_readability_scrim": ($HeaderShade as ColorRect) != null and ($HeaderShade as ColorRect).color.a >= 0.34,
		"secondary_header_compact": (_feature_key != "events" or not chapter_progress.visible) and (_feature_key != "shop" or not shop_notice.visible),
		"profile_save_health_compact": _feature_key != "profile" or (save_health_card != null and save_health_card.custom_minimum_size.y <= 170.0),
		"profile_status_focus": profile_status_focus,
		"redundant_house_return_suppressed": not back_button.visible,
		"truth_footer_suppressed": not truth_strip.visible,
		"world_art_not_overdimmed": ($WorldShade as ColorRect).color.a <= 0.32,
		"controlled_chrome_density": controlled_chrome,
		"visual_parity_gate_v2": hero_dominant and art_dominant_cards and controlled_chrome and hero_loaded,
		"visual_parity_gate_v3": hero_dominant and art_dominant_cards and controlled_chrome and hero_loaded and profile_status_focus,
	}
