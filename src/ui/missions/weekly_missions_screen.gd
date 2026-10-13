extends Control

signal return_events_requested
signal return_house_requested

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

const WEEKLY_ART_PATH := "res://assets/curios/ch01_curio_moon_cameo_sealed_v01.webp"

@onready var world_art: TextureRect = $MissionWorldArt
@onready var mission_timer: Label = $MissionLayout/MissionTimer
@onready var empty_state: PanelContainer = $MissionLayout/MissionEmptyState
@onready var reward_art: TextureRect = $MissionLayout/MissionEmptyState/EmptyContent/MissionRewardArt
@onready var availability: Label = $MissionLayout/MissionEmptyState/EmptyContent/AltarCopy/MissionAvailability
@onready var truth: Label = $MissionLayout/MissionEmptyState/EmptyContent/AltarCopy/MissionEmptyStateTruth
@onready var opening_record: Label = $MissionLayout/MissionOpeningRecord
@onready var return_events: Button = $MissionLayout/ReturnToEvents
@onready var return_house: Button = $MissionLayout/ReturnToHouse

func _ready() -> void:
	ProductionChrome.apply_secondary(empty_state, "weekly_altar")
	ProductionChrome.apply_action_button(return_events, "primary", "weekly_events_return")
	ProductionChrome.apply_action_button(return_house, "utility", "weekly_house_return")
	return_events.pressed.connect(func(): return_events_requested.emit())
	return_house.pressed.connect(func(): return_house_requested.emit())

func configure(state: Dictionary) -> bool:
	var completed_count := int(state.get("completed_count", 0))
	var opening_cap := maxi(1, int(state.get("opening_cap", 3)))
	world_art.texture = ScreenArt.texture("events_bg_curio_house")
	if world_art.texture == null:
		return false
	reward_art.texture = PieceAssetLoader.ornament(WEEKLY_ART_PATH)
	if reward_art.texture == null:
		return false
	reward_art.set_meta("asset_path", WEEKLY_ART_PATH)
	empty_state.set_meta("offline_contract", "truthful_empty_state")
	mission_timer.text = "OFFLINE · LIVE RESET TIME UNAVAILABLE"
	availability.text = "LIVE RITUALS WILL APPEAR HERE ONLY WHEN A MISSION FEED IS CONNECTED"
	truth.text = "RESET / OFFLINE STATE · NOTHING TO CLAIM"
	opening_record.text = "OPENING CABINET RECORD · %d / %d DISPLAYS AWAKENED" % [completed_count, opening_cap]
	return true

func screen_contract() -> Dictionary:
	return {
		"route": "missions",
		"world_art_loaded": world_art != null and world_art.texture != null,
		"reward_art_loaded": reward_art != null and reward_art.texture != null,
		"offline_contract": String(empty_state.get_meta("offline_contract", "")),
		"reward_asset_path": String(reward_art.get_meta("asset_path", "")),
		"code_built_panels": false,
		"north_star_title_hierarchy": ($MissionLayout/MissionTitle as Label).get_theme_font_size("font_size") >= 52,
		"north_star_altar_stack": ($MissionLayout/MissionEmptyState/EmptyContent as VBoxContainer) != null and reward_art.custom_minimum_size.y <= 260.0,
		"asset_backed_altar_chrome": empty_state != null and empty_state.get_theme_stylebox("panel") is StyleBoxTexture and String(empty_state.get_meta("production_chrome_kind", "")) == "secondary_weekly_altar",
		"header_readability_scrim": ($HeaderShade as ColorRect) != null and ($HeaderShade as ColorRect).color.a >= 0.4,
		"sealed_offline_art": String(reward_art.get_meta("asset_path", "")).contains("_sealed_"),
		"production_return_actions": return_events.get_theme_stylebox("normal") is StyleBoxTexture and return_house.get_theme_stylebox("normal") is StyleBoxTexture and String(return_events.get_meta("production_chrome_kind", "")) == "action_primary_weekly_events_return" and String(return_house.get_meta("production_chrome_kind", "")) == "action_utility_weekly_house_return",
		"primary_cta_rounding": return_events.get_theme_stylebox("normal") != null,

	}
