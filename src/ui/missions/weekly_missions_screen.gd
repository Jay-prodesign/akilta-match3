extends Control

signal return_events_requested
signal return_house_requested
signal interaction_feedback_requested(kind: String)

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

const WEEKLY_ART_PATH := "res://assets/curios/ch01_curio_moon_cameo_sealed_v01.webp"
const STATUS_SEAL_PATH := "res://assets/ui/gameplay/booster_sealed_badge_v01.svg"

@onready var world_art: TextureRect = $MissionWorldArt
@onready var mission_title: Label = $MissionLayout/MissionTitle
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
@onready var opening_record: PanelContainer = $MissionLayout/MissionOpeningRecord
@onready var opening_reward_seal: TextureRect = $MissionLayout/MissionOpeningRecord/Content/RewardSeal
@onready var opening_reward_state: Label = $MissionLayout/MissionOpeningRecord/Content/State
@onready var opening_reward_truth: Label = $MissionLayout/MissionOpeningRecord/Content/Truth
@onready var return_events: Button = $MissionLayout/ReturnToEvents
@onready var return_house: Button = $MissionLayout/ReturnToHouse

var _reduced_motion := false
var _intro_started := false
var _intro_tween: Tween
var _return_tactile_tween: Tween

func _ready() -> void:
	empty_state.set_meta("weekly_material", "scene_authored_flat")
	for row in [feed_status, progress_status, reward_status]:
		row.set_meta("weekly_material", "scene_authored_flat")
	var status_seal := PieceAssetLoader.ornament(STATUS_SEAL_PATH)
	for icon in [feed_icon, progress_icon, reward_icon, opening_reward_seal]:
		if icon != null:
			icon.texture = status_seal
			icon.set_meta("asset_path", STATUS_SEAL_PATH)
	ProductionChrome.apply_action_button(return_events, "utility", "weekly_events_return")
	ProductionChrome.apply_action_button(return_house, "utility", "weekly_house_return")
	opening_record.set_meta("weekly_material", "scene_authored_flat")
	opening_record.set_meta("stage_role", "anchored_footer_status")
	_bind_return_tactile()
	return_events.pressed.connect(func(): return_events_requested.emit())
	return_house.pressed.connect(func(): return_house_requested.emit())

func configure(state: Dictionary) -> bool:
	world_art.texture = ScreenArt.texture("events_bg_curio_house")
	if world_art.texture == null:
		return false
	reward_art.texture = PieceAssetLoader.ornament(WEEKLY_ART_PATH)
	if reward_art.texture == null:
		return false
	reward_art.set_meta("asset_path", WEEKLY_ART_PATH)
	empty_state.set_meta("offline_contract", "truthful_empty_state")
	mission_timer.text = "LIVE CHALLENGES UNAVAILABLE OFFLINE"
	availability.text = "LIVE RITUALS WILL APPEAR HERE ONLY WHEN A MISSION FEED IS CONNECTED"
	truth.text = "RESET / OFFLINE STATE · NOTHING TO CLAIM"
	feed_state.text = "NOT CONNECTED"
	progress_state.text = "NOT TRACKED OFFLINE"
	reward_state.text = "NOTHING TO CLAIM"
	opening_reward_state.text = "SEALED · LIVE FEED REQUIRED"
	opening_reward_truth.text = "NOTHING TO CLAIM OFFLINE"
	call_deferred("_play_intro")
	return true


func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	return_events.set_meta("weekly_tactile_reduced_motion", _reduced_motion)
	if _reduced_motion:
		_stop_return_tactile()
		return_events.scale = Vector2.ONE
		return_events.modulate = Color.WHITE
		return_events.set_meta("weekly_tactile_phase", "idle")
		if _intro_started:
			_settle_intro()

func weekly_interaction_contract() -> Dictionary:
	var static_rows := [empty_state, feed_status, progress_status, reward_status, opening_record]
	return {
		"reveal_choreography": _intro_started and has_meta("weekly_reveal_phase"),
		"reveal_phase": String(get_meta("weekly_reveal_phase", "not_started")),
		"return_events_tactile": return_events != null and bool(return_events.get_meta("weekly_tactile_bound", false)) and float(return_events.get_meta("weekly_tactile_press_scale", 1.0)) <= 0.96,
		"reduced_motion_supported": true,
		"feedback_signal": has_signal("interaction_feedback_requested"),
		"static_rows_noninteractive": static_rows.all(func(row): return row != null and row.mouse_filter == Control.MOUSE_FILTER_IGNORE),
	}

func _bind_return_tactile() -> void:
	if return_events == null:
		return
	return_events.set_meta("weekly_tactile_bound", true)
	return_events.set_meta("weekly_tactile_press_scale", 0.96)
	return_events.set_meta("weekly_tactile_phase", "idle")
	return_events.button_down.connect(_press_return_tactile)
	return_events.button_up.connect(_release_return_tactile)
	return_events.mouse_exited.connect(_release_return_tactile)
	return_events.focus_exited.connect(_release_return_tactile)

func _press_return_tactile() -> void:
	if return_events == null or return_events.disabled:
		return
	_stop_return_tactile()
	return_events.pivot_offset = return_events.size * 0.5
	return_events.set_meta("weekly_tactile_phase", "pressed")
	interaction_feedback_requested.emit("ui")
	if _reduced_motion:
		return_events.scale = Vector2.ONE
		return_events.modulate = Color.WHITE
		return
	_return_tactile_tween = create_tween()
	_return_tactile_tween.set_parallel(true)
	_return_tactile_tween.tween_property(return_events, "scale", Vector2(0.96, 0.96), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_return_tactile_tween.tween_property(return_events, "modulate", Color(1.0, 0.96, 0.90, 1.0), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _release_return_tactile() -> void:
	if return_events == null:
		return
	_stop_return_tactile()
	return_events.pivot_offset = return_events.size * 0.5
	return_events.set_meta("weekly_tactile_phase", "release")
	if _reduced_motion:
		return_events.scale = Vector2.ONE
		return_events.modulate = Color.WHITE
		return_events.set_meta("weekly_tactile_phase", "idle")
		return
	_return_tactile_tween = create_tween()
	_return_tactile_tween.set_parallel(true)
	_return_tactile_tween.tween_property(return_events, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_return_tactile_tween.tween_property(return_events, "modulate", Color.WHITE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_return_tactile_tween.finished.connect(func(): return_events.set_meta("weekly_tactile_phase", "idle"))

func _stop_return_tactile() -> void:
	if _return_tactile_tween != null and _return_tactile_tween.is_valid():
		_return_tactile_tween.kill()
	_return_tactile_tween = null

func _play_intro() -> void:
	if _intro_started:
		return
	_intro_started = true
	set_meta("weekly_reveal_phase", "opening")
	if _reduced_motion:
		_settle_intro()
		return
	var reveal_nodes: Array[Control] = [mission_title, mission_timer, empty_state, feed_status, progress_status, reward_status, opening_record, return_events]
	for node in reveal_nodes:
		node.pivot_offset = node.size * 0.5
		node.modulate = Color(1, 1, 1, 0)
		node.scale = Vector2(0.985, 0.985)
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	for index in range(reveal_nodes.size()):
		var node := reveal_nodes[index]
		var delay := float(index) * 0.035
		_intro_tween.tween_property(node, "modulate", Color.WHITE, 0.15).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(node, "scale", Vector2.ONE, 0.21).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.finished.connect(func(): set_meta("weekly_reveal_phase", "idle"))

func _settle_intro() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	for node in [mission_title, mission_timer, empty_state, feed_status, progress_status, reward_status, opening_record, return_events]:
		if node != null:
			node.modulate = Color.WHITE
			node.scale = Vector2.ONE
	set_meta("weekly_reveal_phase", "idle")

func screen_contract() -> Dictionary:
	var altar_compact := empty_state.custom_minimum_size.y >= 112.0 and empty_state.custom_minimum_size.y <= 128.0 and reward_art.custom_minimum_size.x >= 80.0 and reward_art.custom_minimum_size.x <= 96.0 and reward_art.custom_minimum_size.y >= 80.0 and reward_art.custom_minimum_size.y <= 96.0
	var status_rows := [feed_status, progress_status, reward_status]
	var status_stack := $MissionLayout/MissionStatusStack as VBoxContainer
	var status_stack_dense := status_stack != null and status_stack.size_flags_vertical != Control.SIZE_EXPAND_FILL and status_rows.all(func(row): return row != null and row.custom_minimum_size.y >= 212.0 and row.custom_minimum_size.y <= 228.0 and row.size_flags_vertical != Control.SIZE_EXPAND_FILL and row.get_theme_stylebox("panel") is StyleBoxFlat and String(row.get_meta("weekly_material", "")) == "scene_authored_flat")
	var truthful_status_copy := feed_state.text == "NOT CONNECTED" and progress_state.text == "NOT TRACKED OFFLINE" and reward_state.text == "NOTHING TO CLAIM"
	var status_icons_loaded := [feed_icon, progress_icon, reward_icon, opening_reward_seal].all(func(icon): return icon != null and icon.texture != null and String(icon.get_meta("asset_path", "")) == STATUS_SEAL_PATH)
	var intentional_stage := stage_spacer != null and stage_spacer.size_flags_vertical != Control.SIZE_EXPAND_FILL and stage_spacer.custom_minimum_size.y <= 2.0 and ($MissionLayout as VBoxContainer).offset_bottom <= -140.0
	var footer_record := opening_record.visible and opening_record.custom_minimum_size.y >= 490.0 and opening_record.custom_minimum_size.y <= 510.0 and opening_record.size_flags_vertical != Control.SIZE_EXPAND_FILL and opening_reward_state.text == "SEALED · LIVE FEED REQUIRED" and opening_reward_truth.text == "NOTHING TO CLAIM OFFLINE" and opening_record.get_theme_stylebox("panel") is StyleBoxFlat and String(opening_record.get_meta("weekly_material", "")) == "scene_authored_flat" and String(opening_record.get_meta("stage_role", "")) == "anchored_footer_status"
	var world_visible := ($WorldShade as ColorRect).color.a <= 0.20 and ($HeaderShade as ColorRect).color.a <= 0.38
	var return_actions := return_events.get_theme_stylebox("normal") is StyleBoxTexture and return_house.get_theme_stylebox("normal") is StyleBoxTexture and String(return_events.get_meta("production_chrome_kind", "")) == "action_utility_weekly_events_return" and String(return_house.get_meta("production_chrome_kind", "")) == "action_utility_weekly_house_return" and return_events.visible and return_events.custom_minimum_size.y <= 80.0 and not return_house.visible
	return {
		"route": "missions",
		"world_art_loaded": world_art != null and world_art.texture != null,
		"reward_art_loaded": reward_art != null and reward_art.texture != null,
		"offline_contract": String(empty_state.get_meta("offline_contract", "")),
		"reward_asset_path": String(reward_art.get_meta("asset_path", "")),
		"code_built_panels": false,
		"north_star_title_hierarchy": ($MissionLayout/MissionTitle as Label).get_theme_font_size("font_size") >= 52,
		"north_star_altar_stack": altar_compact and status_stack_dense,
		"north_star_horizontal_mission_rows": status_stack_dense,
		"north_star_sealed_reward_panel": footer_record,
		"scene_authored_altar_material": empty_state != null and empty_state.get_theme_stylebox("panel") is StyleBoxFlat and String(empty_state.get_meta("weekly_material", "")) == "scene_authored_flat",
		"scene_authored_status_rows": status_stack_dense,
		"seam_free_weekly_material": empty_state.get_theme_stylebox("panel") is StyleBoxFlat and status_stack_dense and opening_record.get_theme_stylebox("panel") is StyleBoxFlat,
		"truthful_status_rows": truthful_status_copy,
		"sealed_status_icons": status_icons_loaded,
		"header_readability_scrim": ($HeaderShade as ColorRect) != null and ($HeaderShade as ColorRect).color.a >= 0.34,
		"sealed_offline_art": String(reward_art.get_meta("asset_path", "")).contains("_sealed_"),
		"production_return_actions": return_actions,
		"redundant_house_return_suppressed": not return_house.visible,
		"compact_offline_copy": availability != null and not availability.visible,
		"primary_cta_rounding": return_events.get_theme_stylebox("normal") != null,
		"intentional_world_stage": intentional_stage,
		"scene_authored_opening_record": footer_record,
		"world_art_not_overdimmed": world_visible,
		"visual_parity_gate_v2": altar_compact and status_stack_dense and truthful_status_copy and status_icons_loaded and intentional_stage and footer_record and world_visible and return_actions,
		"visual_parity_gate_v3": altar_compact and status_stack_dense and truthful_status_copy and status_icons_loaded and intentional_stage and footer_record and world_visible and return_actions,
		"north_star_compact_reward_stage": footer_record and opening_reward_seal.custom_minimum_size.y <= 230.0,
		"interaction_choreography": weekly_interaction_contract(),
	}
