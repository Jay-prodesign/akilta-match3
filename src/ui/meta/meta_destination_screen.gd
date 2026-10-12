extends Control

signal back_requested
signal settings_requested
signal weekly_requested
signal daily_practice_requested(level_number: int)

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

var _feature_key: String = ""
var _daily_level: int = 0

@onready var world_art: TextureRect = $WorldArt
@onready var title: Label = $Layout/Title
@onready var detail: Label = $Layout/Detail
@onready var hero_art: TextureRect = $Layout/Hero/HeroRow/HeroArt
@onready var hero_kicker: Label = $Layout/Hero/HeroRow/HeroCopy/HeroKicker
@onready var hero_title: Label = $Layout/Hero/HeroRow/HeroCopy/HeroTitle
@onready var hero_body: Label = $Layout/Hero/HeroRow/HeroCopy/HeroBody
@onready var primary_action: Button = $Layout/Actions/Primary
@onready var secondary_action: Button = $Layout/Actions/Secondary
@onready var truth_strip: Label = $Layout/TruthStrip
@onready var back_button: Button = $Layout/Back

func _ready() -> void:
	primary_action.pressed.connect(_on_primary_pressed)
	secondary_action.pressed.connect(_on_secondary_pressed)
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

	match _feature_key:
		"events":
			background_id = "events_bg_curio_house"
			hero_path = "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg"
			title.text = "EVENT CENTER"
			detail.text = "House rituals, returning-player practice and future seasonal rooms live here."
			hero_kicker.text = "OPENING RITUAL COMPLETE" if opening_complete else "OPENING RITUAL IN PROGRESS"
			hero_title.text = "%d / %d DISPLAYS AWAKENED" % [completed_count, opening_cap]
			hero_body.text = "The House remembers every completed display. Live events remain sealed until a real event feed exists."
			primary_action.text = "OPEN WEEKLY RITUALS"
			primary_action.visible = true
			primary_action.disabled = false
			secondary_action.visible = true
			secondary_action.disabled = _daily_level <= 0
			secondary_action.text = "PRACTICE LEVEL %d" % _daily_level if _daily_level > 0 else "DAILY HOUSE RITUAL · SEALED"
			truth_strip.text = "LIVE EVENT REWARDS ARE NOT FABRICATED · DAILY PRACTICE IS DEVICE-LOCAL"
			cards = [
				{"art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg", "kicker":"RITUAL I", "title":"MOONLIGHT MARKET", "body":"The restored opening cabinet anchors a future moonlit event room.", "status":"FUTURE EVENT · NO CLAIMABLE REWARD"},
				{"art":"res://assets/curios/ch01_curio_moth_reliquary.svg", "kicker":"RITUAL II", "title":"THE LOST RELICS", "body":"A sealed reliquary marks the next cabinet journey beyond the opening set.", "status":"SEALED · FUTURE JOURNEY"},
				{"art":"res://assets/curios/ch01_curio_thorned_locket.svg", "kicker":"RITUAL III", "title":"WEEKLY RITUALS", "body":"Weekly challenges occupy a dedicated truthful state when a mission feed is connected.", "status":"OFFLINE STATE · NOTHING TO CLAIM"}
			]
		"shop":
			background_id = "shop_bg_curio_house"
			hero_path = "res://assets/curios/ch01_curio_moth_reliquary.svg"
			title.text = "THE CURIO EMPORIUM"
			detail.text = "A sealed economy room. Your earned balances are visible; purchases are not enabled."
			hero_kicker.text = "HOUSE BALANCES"
			hero_title.text = "%d COINS · %d MOONSTONES" % [coins, gems]
			hero_body.text = "These balances come only from play in this build. No payment, purchase or spending flow is connected."
			primary_action.visible = false
			secondary_action.visible = false
			truth_strip.text = "EARNED IN PLAY · NOT PURCHASABLE · NO REAL-MONEY COMMERCE"
			cards = [
				{"art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg", "kicker":"SEALED CABINET I", "title":"CANDLELIGHT KIT", "body":"A future soft-currency cabinet for restoration supplies.", "status":"SEALED · ECONOMY PREVIEW ONLY"},
				{"art":"res://assets/curios/ch01_curio_moth_reliquary.svg", "kicker":"SEALED CABINET II", "title":"MOONSTONE CACHE", "body":"A future premium-currency surface. No price or payment flow is active.", "status":"SEALED · NO PURCHASES"},
				{"art":"res://assets/curios/ch01_curio_thorned_locket.svg", "kicker":"SEALED CABINET III", "title":"RESTORER'S RELIQUARY", "body":"A future curated cabinet for boosters and curios.", "status":"SEALED · STORE NOT CONNECTED"}
			]
		"profile":
			background_id = "profile_bg_curio_house"
			hero_path = "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg"
			title.text = "THE KEEPER"
			detail.text = "Your restored curios, House progress, local save health and presentation preferences."
			hero_kicker.text = String(state.get("save_status", "LOCAL SAVE · DEVICE-LOCAL"))
			hero_title.text = "%d CURIOS · RESTORATION STAGE %d" % [collected_count, restored_stage]
			hero_body.text = String(state.get("save_detail", "Progress is stored on this device."))
			primary_action.text = "AUDIO & ACCESSIBILITY"
			primary_action.visible = true
			primary_action.disabled = false
			secondary_action.visible = false
			truth_strip.text = "CLOUD SYNC · NOT CONNECTED · NO REMOTE BACKUP CLAIM"
			cards = [
				{"art":"res://assets/pieces/moon_sigil.svg", "kicker":"KEEPER RECORD I", "title":"CHAPTER PROGRESS", "body":"%d of %d opening rituals completed." % [completed_count, opening_cap], "status":"FIRST CABINET SET RESTORED" if opening_complete else "YOUR SAVED JOURNEY"},
				{"art":"res://assets/curios/ch01_curio_moon_cameo_awakened_v01.svg", "kicker":"KEEPER RECORD II", "title":"RELIQUARY", "body":"%d of %d opening curios awakened." % [collected_count, opening_cap], "status":"OPENING SET COMPLETE" if opening_complete else "RELICS RECOVERED"},
				{"art":"res://assets/world/ch01_curio_boutique/hub_bg_grandhall.webp", "kicker":"KEEPER RECORD III", "title":"HOUSE RESTORATION", "body":"The Grand Hall currently rests at restoration stage %d." % restored_stage, "status":"PROGRESS SAVED ON THIS DEVICE"}
			]
		_:
			return false

	world_art.texture = ScreenArt.texture(background_id)
	if world_art.texture == null:
		return false
	hero_art.texture = PieceAssetLoader.ornament(hero_path)
	if hero_art.texture == null:
		return false
	_apply_cards(cards)
	return true

func _apply_cards(cards: Array[Dictionary]) -> void:
	var nodes: Array[PanelContainer] = [
		$Layout/CardScroll/Cards/Card1,
		$Layout/CardScroll/Cards/Card2,
		$Layout/CardScroll/Cards/Card3,
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
		art.texture = PieceAssetLoader.ornament(String(entry.get("art", "")))
		kicker.text = String(entry.get("kicker", ""))
		card_title.text = String(entry.get("title", ""))
		body.text = String(entry.get("body", ""))
		status.text = String(entry.get("status", ""))

func _on_primary_pressed() -> void:
	match _feature_key:
		"events":
			weekly_requested.emit()
		"profile":
			settings_requested.emit()

func _on_secondary_pressed() -> void:
	if _feature_key == "events" and _daily_level > 0:
		daily_practice_requested.emit(_daily_level)

func screen_contract() -> Dictionary:
	return {
		"feature": _feature_key,
		"world_art_loaded": world_art != null and world_art.texture != null,
		"hero_art_loaded": hero_art != null and hero_art.texture != null,
		"static_card_slots": 3,
		"code_built_panels": false,
	}
