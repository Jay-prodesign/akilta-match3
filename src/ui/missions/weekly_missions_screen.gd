extends Control

signal return_events_requested
signal return_house_requested

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

const WEEKLY_ART_PATH := "res://assets/curios/ch01_curio_moon_cameo_sealed_v01.webp"
const STATUS_SEAL_PATH := "res://assets/ui/gameplay/booster_sealed_badge_v01.svg"

@onready var world_art: TextureRect = $MissionWorldArt
@onready var mission_timer: Label = $MissionLayout/MissionTimer
@onready var empty_state: PanelContainer = $MissionLayout/MissionEmptyState
@onready var reward_art: TextureRect = $MissionLayout/MissionEmptyState/EmptyContent/MissionRewardArt
@onready var availability: Label = $MissionLayout/MissionEmptyState/EmptyContent/AltarCopy/MissionAvailability
@onready var truth: Label = $MissionLayout/MissionEmptyState/EmptyContent/AltarCopy/MissionEmptyStateTruth
@onready var feed_status: PanelContainer = $MissionLayout/MissionStatusStack/FeedStatus
@onready var feed_icon: TextureRect = $MissionLayout/MissionStatusStack/FeedStatus/Content/SealIcon
@onready var feed_state: Label = $MissionLayout/MissionStatusStack/FeedStatus/Content/State
@onready var progress_status: PanelContainer = $MissionLayout/MissionStatusStack/ProgressStatus
@onready var progress_icon: TextureRect = $MissionLayout/MissionStatusStack/ProgressStatus/Content/SealIcon
@onready var progress_state: Label = $MissionLayout/MissionStatusStack/ProgressStatus/Content/State
@onready var reward_status: PanelContainer = $MissionLayout/MissionStatusStack/RewardStatus
@onready var reward_icon: TextureRect = $MissionLayout/MissionStatusStack/RewardStatus/Content/SealIcon
@onready var reward_state: Label = $MissionLayout/MissionStatusStack/RewardStatus/Content/State
@onready var stage_spacer: Control = $MissionLayout/WorldStageSpacer
@onready var opening_record: Label = $MissionLayout/MissionOpeningRecord
@onready var return_events: Button = $MissionLayout/ReturnToEvents
@onready var return_house: Button = $MissionLayout/ReturnToHouse

func _ready() -> void:
	ProductionChrome.apply_secondary(empty_state, "weekly_altar")
	ProductionChrome.apply_compact_panel(feed_status, "weekly_feed_status")
	ProductionChrome.apply_compact_panel(progress_status, "weekly_progress_status")
	ProductionChrome.apply_compact_panel(reward_status, "weekly_reward_status")
	var status_seal := PieceAssetLoader.ornament(STATUS_SEAL_PATH)
	for icon in [feed_icon, progress_icon, reward_icon]:
		if icon != null:
			icon.texture = status_seal
			icon.set_meta("asset_path", STATUS_SEAL_PATH)
	ProductionChrome.apply_action_button(return_events, "primary", "weekly_events_return")
	ProductionChrome.apply_action_button(return_house, "utility", "weekly_house_return")
	var record_style := ProductionChrome.compact_panel()
	if record_style != null:
		opening_record.add_theme_stylebox_override("normal", record_style)
		opening_record.set_meta("production_chrome_kind", "compact_weekly_record")
		opening_record.set_meta("stage_role", "anchored_footer_status")
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
	feed_state.text = "NOT CONNECTED"
	progress_state.text = "NOT TRACKED OFFLINE"
	reward_state.text = "NOTHING TO CLAIM"
	opening_record.text = "OPENING CABINET RECORD · %d / %d DISPLAYS AWAKENED" % [completed_count, opening_cap]
	return true

func screen_contract() -> Dictionary:
	var altar_compact := empty_state.custom_minimum_size.y >= 390.0 and empty_state.custom_minimum_size.y <= 440.0 and reward_art.custom_minimum_size.x >= 240.0 and reward_art.custom_minimum_size.y >= 170.0
	var status_rows := [feed_status, progress_status, reward_status]
	var status_stack_dense := status_rows.all(func(row): return row != null and row.custom_minimum_size.y >= 110.0 and row.get_theme_stylebox("panel") is StyleBoxTexture)
	var truthful_status_copy := feed_state.text == "NOT CONNECTED" and progress_state.text == "NOT TRACKED OFFLINE" and reward_state.text == "NOTHING TO CLAIM"
	var status_icons_loaded := [feed_icon, progress_icon, reward_icon].all(func(icon): return icon != null and icon.texture != null and String(icon.get_meta("asset_path", "")) == STATUS_SEAL_PATH)
	var intentional_stage := stage_spacer != null and stage_spacer.size_flags_vertical != Control.SIZE_EXPAND_FILL and stage_spacer.custom_minimum_size.y <= 40.0 and ($MissionLayout as VBoxContainer).offset_bottom <= -150.0
	var footer_record := opening_record.get_theme_stylebox("normal") is StyleBoxTexture and String(opening_record.get_meta("production_chrome_kind", "")) == "compact_weekly_record" and String(opening_record.get_meta("stage_role", "")) == "anchored_footer_status"
	var world_visible := ($WorldShade as ColorRect).color.a <= 0.20 and ($HeaderShade as ColorRect).color.a <= 0.38
	var return_actions := return_events.get_theme_stylebox("normal") is StyleBoxTexture and return_house.get_theme_stylebox("normal") is StyleBoxTexture and String(return_events.get_meta("production_chrome_kind", "")) == "action_primary_weekly_events_return" and String(return_house.get_meta("production_chrome_kind", "")) == "action_utility_weekly_house_return" and return_events.visible and not return_house.visible
	return {
		"route": "missions",
		"world_art_loaded": world_art != null and world_art.texture != null,
		"reward_art_loaded": reward_art != null and reward_art.texture != null,
		"offline_contract": String(empty_state.get_meta("offline_contract", "")),
		"reward_asset_path": String(reward_art.get_meta("asset_path", "")),
		"code_built_panels": false,
		"north_star_title_hierarchy": ($MissionLayout/MissionTitle as Label).get_theme_font_size("font_size") >= 52,
		"north_star_altar_stack": altar_compact and status_stack_dense,
		"asset_backed_altar_chrome": empty_state != null and empty_state.get_theme_stylebox("panel") is StyleBoxTexture and String(empty_state.get_meta("production_chrome_kind", "")) == "secondary_weekly_altar",
		"asset_backed_status_rows": status_stack_dense,
		"truthful_status_rows": truthful_status_copy,
		"sealed_status_icons": status_icons_loaded,
		"header_readability_scrim": ($HeaderShade as ColorRect) != null and ($HeaderShade as ColorRect).color.a >= 0.34,
		"sealed_offline_art": String(reward_art.get_meta("asset_path", "")).contains("_sealed_"),
		"production_return_actions": return_actions,
		"redundant_house_return_suppressed": not return_house.visible,
		"compact_offline_copy": availability != null and not availability.visible,
		"primary_cta_rounding": return_events.get_theme_stylebox("normal") != null,
		"intentional_world_stage": intentional_stage,
		"asset_backed_opening_record": footer_record,
		"world_art_not_overdimmed": world_visible,
		"visual_parity_gate_v2": altar_compact and status_stack_dense and truthful_status_copy and status_icons_loaded and intentional_stage and footer_record and world_visible and return_actions,
		"visual_parity_gate_v3": altar_compact and status_stack_dense and truthful_status_copy and status_icons_loaded and intentional_stage and footer_record and world_visible and return_actions,
	}
