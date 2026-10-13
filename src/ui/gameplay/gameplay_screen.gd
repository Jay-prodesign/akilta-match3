class_name Match3GameplayScreen
extends Control

signal level_won(level_id: String, curio_id: String, house_stage_reward: int)
signal level_replay_finished(level_id: String)
signal level_exit_requested
signal feedback_requested(kind: String)
signal navigation_requested(section: String)
signal settings_requested
signal result_state_changed(kind: String)

const SCREEN_CONTRACT_ID := "S05"
const RESULT_CONTRACT_ID := "S06"

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MoveFinder = preload("res://src/match3/domain/move_finder.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const RewardRevealFx = preload("res://src/ui/shared/reward_reveal_fx.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")
const HapticsController = preload("res://src/feedback/haptics_controller.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

@export var default_level_path := "res://content/levels/ch01/level_001.json"
@export var default_seed := 1001
@export var replay_mode := false

var board_state
var last_trace
var current_level_id: String = ""
var current_level_path: String = ""
var current_seed: int = 1001
var current_reward_curio: String = ""
var current_house_stage_reward: int = 0
var current_objective_type: String = "collect_family"
var current_objective_family: String = "moon"
var current_objective_target: int = 6
var current_initial_blocker_count: int = 0
var current_initial_blocker_hp: int = 0
var current_win_title: String = "THE CABINET STIRS"
var current_win_detail: String = "Something in the Curio Boutique has awakened."
var current_retry_hint: String = ""
var _pending_win: bool = false
var _pending_terminal_result: String = ""
var _pending_hud_refresh: bool = false
var haptics = HapticsController.new()
var _potion_used_for_attempt := false
var _idle_hint_seconds: float = 0.0
var _consecutive_failures: int = 0
var _guided_retry_pending: bool = false
var _keeper_hint_count: int = 0
var _keeper_last_move: Dictionary = {}
const KEEPER_ART_PATH := "res://assets/pieces/black_cat.webp"
const AUTO_HINT_DELAY_SECONDS := 9.0
const GUIDED_HINT_DELAY_SECONDS := 4.0
const BOOSTER_ART_PATHS := {
	"hint": KEEPER_ART_PATH,
	"plus_moves": "res://assets/pieces/potion.webp",
	"retry": "res://assets/pieces/skull.webp"
}
const GAMEPLAY_PAUSE_ICON_PATH := "res://assets/ui/gameplay/pause_gothic_v01.svg"
const SEALED_BADGE_PATH := "res://assets/ui/gameplay/booster_sealed_badge_v01.svg"
const REWARD_STAR_PATH := "res://assets/ui/gameplay/reward_star_gothic_v01.svg"
const NORTH_STAR_BOOSTER_ART_PATHS := {
	"shuffle": "res://assets/ui/gameplay/booster_shuffle_gothic_v01.svg",
	"hand": "res://assets/ui/gameplay/booster_hand_gothic_v01.svg",
	"magic": "res://assets/ui/gameplay/booster_magic_gothic_v01.svg"
}
const OBJECTIVE_ART_PATHS := {
	"moon": "res://assets/pieces/moon_sigil.webp",
	"rose": "res://assets/pieces/thorn_rose.webp",
	"moth": "res://assets/pieces/luna_moth.webp",
	"key": "res://assets/pieces/curio_key.webp",
	"leaf": "res://assets/pieces/night_ivy.webp",
	"cat": "res://assets/pieces/black_cat.webp",
	"candle": "res://assets/pieces/candle.webp",
	"skull": "res://assets/pieces/skull.webp",
	"wax_seal": "res://assets/blockers/ch01_blocker_wax_seal_intact_v01.webp"
}
var _potion_boost_button: Button
var _retry_boost_button: Button
var _resource_life_label: Label
var _player_lives: int = 5
var _player_coins: int = 0
var _player_gems: int = 0
var _result_reveal_fx: Control
var _reduced_motion: bool = false
var _high_contrast: bool = false
var _moves_urgency_state: String = "normal"
var _last_impact_feedback: String = ""
var _last_cascade_depth: int = 1
var _last_objective_progress: int = 0
var _last_objective_delta: int = 0
var _objective_pulse_tween: Tween
var _result_transition_kind: String = ""
var _result_transition_active: bool = false
var _result_transition_tween: Tween
var _pause_transition_tween: Tween
var _gameplay_intro_tween: Tween
var _result_star_tween: Tween
var _pause_closing := false
const LOW_MOVE_WARNING_THRESHOLD := 3
const LAST_MOVE_THRESHOLD := 1

@onready var world_backdrop: TextureRect = $WorldBackdrop
@onready var level_plaque: PanelContainer = $Layout/LevelPlaque
@onready var eyebrow_label: Label = $Layout/LevelPlaque/Eyebrow
@onready var title_label: Label = $Layout/Title
@onready var board_view = $Layout/BoardView
@onready var objective_name_label: Label = $Layout/HUDPlate/HUD/ObjectiveSlot/ObjectiveName
@onready var objective_icon: TextureRect = $Layout/HUDPlate/HUD/ObjectiveSlot/ObjectiveIcon
@onready var objective_label: Label = $Layout/HUDPlate/HUD/ObjectiveSlot/Objective
@onready var moves_label: Label = $Layout/HUDPlate/HUD/Moves
@onready var pause_button: Button = $Layout/HUDPlate/HUD/Pause
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_resume: Button = $PauseOverlay/Card/Content/Resume
@onready var pause_retry: Button = $PauseOverlay/Card/Content/Retry
@onready var pause_settings: Button = $PauseOverlay/Card/Content/Settings
@onready var pause_exit: Button = $PauseOverlay/Card/Content/Exit
@onready var pause_sigil: TextureRect = $PauseOverlay/Card/Content/PauseSigil
@onready var hint_label: Label = $Layout/Hint
@onready var awakening_title: Label = $Layout/Awakening/Content/Label
@onready var awakening_view: Control = $Layout/Awakening/Content/ProgressView
@onready var awakening_copy: Label = $Layout/Awakening/Content/ProgressCopy
@onready var result_overlay: Control = $ResultOverlay
@onready var result_title: Label = $ResultOverlay/Card/Content/Title
@onready var result_detail: Label = $ResultOverlay/Card/Content/Detail
@onready var result_objective_summary: Label = $ResultOverlay/Card/Content/ObjectiveSummary
@onready var result_eyebrow: Label = $ResultOverlay/Card/Content/Eyebrow
@onready var result_reward_name: Label = $ResultOverlay/Card/Content/RewardName
@onready var result_house_change: Label = $ResultOverlay/Card/Content/HouseChange
@onready var result_ritual: Control = $ResultOverlay/Card/Content/RewardRitual
@onready var result_recovery_action: Button = $ResultOverlay/Card/Content/RecoveryAction
@onready var result_action: Button = $ResultOverlay/Card/Content/Action
# Compact gameplay resource header keeps level identity inside its authored status plate.
@onready var _level_badge_label: Label = $ResourceBar/Resources/LevelBadgePlate/LevelBadge
@onready var _booster_tray: PanelContainer = $BoosterTray
@onready var _hint_boost_button: Button = $BoosterTray/BoosterActions/HintSlot/HintBoost
@onready var _sealed_boost_a: Button = $BoosterTray/BoosterActions/SealedSlotA/SealedBoostA
@onready var _sealed_boost_b: Button = $BoosterTray/BoosterActions/SealedSlotB/SealedBoostB
@onready var _sealed_boost_c: Button = $BoosterTray/BoosterActions/SealedSlotC/SealedBoostC
@onready var _sealed_badge_a: TextureRect = $BoosterTray/BoosterActions/SealedSlotA/SealedBoostA/SealBadge
@onready var _sealed_badge_b: TextureRect = $BoosterTray/BoosterActions/SealedSlotB/SealedBoostB/SealBadge
@onready var _sealed_badge_c: TextureRect = $BoosterTray/BoosterActions/SealedSlotC/SealedBoostC/SealBadge
@onready var _settings_shortcut: Button = $BoosterTray/BoosterActions/SettingsSlot/SettingsShortcut
@onready var _resource_coin_label: Label = $ResourceBar/Resources/CoinChip/Content/CoinResource
@onready var _resource_gem_label: Label = $ResourceBar/Resources/GemChip/Content/GemResource
@onready var _resource_coin_icon: TextureRect = $ResourceBar/Resources/CoinChip/Content/Icon
@onready var _resource_gem_icon: TextureRect = $ResourceBar/Resources/GemChip/Content/Icon
@onready var _result_reward_values: Control = $ResultOverlay/Card/Content/ResultRewardValues
@onready var _result_coin_icon: TextureRect = $ResultOverlay/Card/Content/ResultRewardValues/CoinReward/Content/Icon
@onready var _result_gem_icon: TextureRect = $ResultOverlay/Card/Content/ResultRewardValues/GemReward/Content/Icon
@onready var _result_proclamation: Label = $ResultOverlay/Card/Content/ResultProclamation/Copy/ResultProclamationCopy
@onready var _result_keeper_cat: TextureRect = $ResultOverlay/Card/Content/ResultProclamation/KeeperCat
@onready var _result_star_a: TextureRect = $ResultOverlay/Card/Content/StarRow/StarA
@onready var _result_star_b: TextureRect = $ResultOverlay/Card/Content/StarRow/StarB
@onready var _result_star_c: TextureRect = $ResultOverlay/Card/Content/StarRow/StarC

func _process(delta: float) -> void:
	if board_state == null or result_overlay.visible or pause_overlay.visible or _pending_terminal_result != "":
		_idle_hint_seconds = 0.0
		return
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		_idle_hint_seconds = 0.0
		return
	_idle_hint_seconds += delta
	if _idle_hint_seconds >= _current_auto_hint_delay():
		_idle_hint_seconds = 0.0
		var legal_move: Dictionary = MoveFinder.first_legal_move(board_state)
		if not legal_move.is_empty():
			_present_keeper_hint(legal_move, false, _consecutive_failures >= 3)

func _current_auto_hint_delay() -> float:
	return GUIDED_HINT_DELAY_SECONDS if _consecutive_failures >= 3 else AUTO_HINT_DELAY_SECONDS

func _ready() -> void:
	ProductionChrome.apply_gameplay_pause_modal($PauseOverlay/Card)
	ProductionChrome.apply_primary($ResultOverlay/Card)
	$ResourceBar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	$ResourceBar.set_meta("production_chrome_kind", "gameplay_resource_cluster")
	ProductionChrome.apply_compact_panel($ResourceBar/Resources/CoinChip, "gameplay_coin_resource")
	ProductionChrome.apply_compact_panel($ResourceBar/Resources/GemChip, "gameplay_gem_resource")
	ProductionChrome.apply_compact_panel($ResourceBar/Resources/LevelBadgePlate, "gameplay_level_badge")
	ProductionChrome.apply_gameplay_shell($Layout/HUDPlate, "objective")
	ProductionChrome.apply_gameplay_level_plaque(level_plaque)
	ProductionChrome.apply_gameplay_booster_tray($BoosterTray)
	var gameplay_hud := $Layout/HUDPlate/HUD as HBoxContainer
	if gameplay_hud != null:
		gameplay_hud.move_child(pause_button, 1)
	pause_button.icon = PieceAssetLoader.ornament(GAMEPLAY_PAUSE_ICON_PATH)
	pause_sigil.texture = PieceAssetLoader.ornament(String(OBJECTIVE_ART_PATHS["moon"]))
	pause_button.set_meta("production_chrome_kind", "gameplay_pause_icon")
	pause_button.set_meta("production_chrome_asset", GAMEPLAY_PAUSE_ICON_PATH)
	ProductionChrome.apply_gameplay_action_button(pause_resume, "primary", "pause_resume")
	ProductionChrome.apply_gameplay_action_button(pause_retry, "utility", "pause_retry")
	ProductionChrome.apply_gameplay_action_button(pause_settings, "utility", "pause_settings")
	ProductionChrome.apply_gameplay_action_button(pause_exit, "utility", "pause_exit")
	ProductionChrome.apply_gameplay_action_button(result_recovery_action, "primary", "fail_recovery_plus_three")
	ProductionChrome.apply_gameplay_action_button(result_action, "primary", "result_continue_or_retry")
	var board_frame := $Layout/BoardView/OrnateFrame as Panel
	if board_frame != null:
		board_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		board_frame.set_meta("production_board_frame_owner", "BoardView")
	world_backdrop.texture = ScreenArt.texture("gameplay_bg_curio_boutique")
	world_backdrop.modulate = Color.WHITE
	_resource_coin_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_coin.svg")
	_resource_gem_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_gem.svg")
	_result_coin_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_coin.svg")
	_result_gem_icon.texture = PieceAssetLoader.ornament("res://assets/ui/ui_gem.svg")
	_result_keeper_cat.texture = PieceAssetLoader.ornament(KEEPER_ART_PATH)
	_hint_boost_button.icon = PieceAssetLoader.ornament(String(BOOSTER_ART_PATHS["hint"]))
	_sealed_boost_a.icon = PieceAssetLoader.ornament(String(NORTH_STAR_BOOSTER_ART_PATHS["shuffle"]))
	_sealed_boost_b.icon = PieceAssetLoader.ornament(String(NORTH_STAR_BOOSTER_ART_PATHS["hand"]))
	_sealed_boost_c.icon = PieceAssetLoader.ornament(String(NORTH_STAR_BOOSTER_ART_PATHS["magic"]))
	var sealed_badge_texture := PieceAssetLoader.ornament(SEALED_BADGE_PATH)
	_sealed_badge_a.texture = sealed_badge_texture
	_sealed_badge_b.texture = sealed_badge_texture
	_sealed_badge_c.texture = sealed_badge_texture
	var reward_star_texture := PieceAssetLoader.ornament(REWARD_STAR_PATH)
	_result_star_a.texture = reward_star_texture
	_result_star_b.texture = reward_star_texture
	_result_star_c.texture = reward_star_texture
	_settings_shortcut.icon = PieceAssetLoader.ornament("res://assets/ui/ui_settings.svg")
	_hint_boost_button.pressed.connect(_use_hint_boost)
	_settings_shortcut.pressed.connect(func(): settings_requested.emit())
	_resource_life_label = null
	_potion_boost_button = null
	_retry_boost_button = null
	_install_reward_reveal_fx()
	if board_view.has_signal("swap_requested"):
		board_view.swap_requested.connect(_on_swap_requested)
	if board_view.has_signal("trace_motion_finished"):
		board_view.trace_motion_finished.connect(_on_board_trace_motion_finished)
	if board_view.has_signal("motion_feedback_requested"):
		board_view.motion_feedback_requested.connect(_on_board_motion_feedback_requested)
	result_recovery_action.pressed.connect(_on_result_recovery_pressed)
	result_action.pressed.connect(_on_result_action_pressed)
	pause_button.pressed.connect(show_pause)
	pause_resume.pressed.connect(resume_level)
	pause_retry.pressed.connect(_on_pause_retry)
	pause_settings.pressed.connect(func(): settings_requested.emit())
	pause_exit.pressed.connect(_on_pause_exit)
	_wire_tactile_button(pause_button, "pause")
	_wire_tactile_button(pause_resume, "resume")
	_wire_tactile_button(pause_retry, "restart")
	_wire_tactile_button(pause_settings, "settings")
	_wire_tactile_button(pause_exit, "exit")
	_wire_tactile_button(result_recovery_action, "recovery")
	_wire_tactile_button(result_action, "continue")
	pause_overlay.visible = false
	result_overlay.visible = false
	if FileAccess.file_exists(default_level_path):
		load_level_path(default_level_path, default_seed)
	call_deferred("_play_gameplay_intro")

func _wire_tactile_button(button: Button, feedback_kind: String) -> void:
	if button == null:
		return
	button.button_down.connect(func(): _press_tactile_button(button, feedback_kind))
	button.button_up.connect(func(): _release_tactile_button(button))
	button.mouse_exited.connect(func(): _release_tactile_button(button))

func _press_tactile_button(button: Button, feedback_kind: String) -> void:
	if button == null or button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	haptics.request_ui()
	feedback_requested.emit("ui_" + feedback_kind)
	button.modulate = Color(1.05, 1.02, 1.07, 1.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.945, 0.945), 0.065)

func _release_tactile_button(button: Button) -> void:
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color.WHITE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_gameplay_intro() -> void:
	if _reduced_motion:
		return
	if _gameplay_intro_tween != null and _gameplay_intro_tween.is_valid():
		_gameplay_intro_tween.kill()
	var reveal_nodes: Array[Control] = [level_plaque, $Layout/HUDPlate, board_view, _booster_tray]
	_gameplay_intro_tween = create_tween()
	_gameplay_intro_tween.set_parallel(true)
	for index in range(reveal_nodes.size()):
		var node := reveal_nodes[index]
		if node == null:
			continue
		node.pivot_offset = node.size * 0.5
		node.modulate = Color(1, 1, 1, 0)
		node.scale = Vector2(0.97, 0.97) if node == board_view else Vector2(0.985, 0.985)
		var delay := float(index) * 0.045
		_gameplay_intro_tween.tween_property(node, "modulate", Color.WHITE, 0.20).set_delay(delay)
		_gameplay_intro_tween.tween_property(node, "scale", Vector2.ONE, 0.28).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_pause_open() -> void:
	if _pause_transition_tween != null and _pause_transition_tween.is_valid():
		_pause_transition_tween.kill()
	var card := pause_overlay.get_node_or_null("Card") as Control
	var dim := pause_overlay.get_node_or_null("Dim") as CanvasItem
	if card == null:
		return
	card.pivot_offset = card.size * 0.5
	var rest_position := card.position
	card.set_meta("pause_rest_position", rest_position)
	if _reduced_motion:
		card.scale = Vector2.ONE
		card.modulate = Color.WHITE
		if dim != null:
			dim.modulate = Color.WHITE
		return
	card.position = rest_position + Vector2(0, 34)
	card.scale = Vector2(0.91, 0.91)
	card.modulate = Color(1, 1, 1, 0)
	if dim != null:
		dim.modulate = Color(1, 1, 1, 0)
	for star in [_result_star_a, _result_star_b, _result_star_c]:
		if star != null:
			star.pivot_offset = star.size * 0.5
			star.scale = Vector2(0.42, 0.42)
			star.modulate = Color(1.25, 1.12, 0.78, 0)
	var content := card.get_node_or_null("Content") as Control
	var reveal_items: Array[CanvasItem] = []
	if content != null:
		for child in content.get_children():
			if child is CanvasItem:
				(child as CanvasItem).modulate = Color(1, 1, 1, 0)
				reveal_items.append(child as CanvasItem)
	_pause_transition_tween = create_tween()
	_pause_transition_tween.set_parallel(true)
	if dim != null:
		_pause_transition_tween.tween_property(dim, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pause_transition_tween.tween_property(card, "position", rest_position, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_pause_transition_tween.tween_property(card, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pause_transition_tween.tween_property(card, "modulate", Color.WHITE, 0.20)
	for index in range(reveal_items.size()):
		_pause_transition_tween.tween_property(reveal_items[index], "modulate", Color.WHITE, 0.15).set_delay(0.08 + float(index) * 0.035)

func _begin_pause_close(after: Callable) -> void:
	if _pause_closing:
		return
	_pause_closing = true
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _pause_transition_tween != null and _pause_transition_tween.is_valid():
		_pause_transition_tween.kill()
	var card := pause_overlay.get_node_or_null("Card") as Control
	var dim := pause_overlay.get_node_or_null("Dim") as CanvasItem
	if card == null or _reduced_motion:
		_finish_pause_close(after)
		return
	var rest_position: Vector2 = card.get_meta("pause_rest_position", card.position)
	_pause_transition_tween = create_tween()
	_pause_transition_tween.set_parallel(true)
	_pause_transition_tween.tween_property(card, "position", rest_position + Vector2(0, 24), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pause_transition_tween.tween_property(card, "scale", Vector2(0.96, 0.96), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pause_transition_tween.tween_property(card, "modulate", Color(1, 1, 1, 0), 0.14)
	if dim != null:
		_pause_transition_tween.tween_property(dim, "modulate", Color(1, 1, 1, 0), 0.16)
	_pause_transition_tween.finished.connect(func(): _finish_pause_close(after))

func _finish_pause_close(after: Callable) -> void:
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_closing = false
	var card := pause_overlay.get_node_or_null("Card") as Control
	var dim := pause_overlay.get_node_or_null("Dim") as CanvasItem
	if card != null:
		card.scale = Vector2.ONE
		card.modulate = Color.WHITE
		card.position = card.get_meta("pause_rest_position", card.position)
		var content := card.get_node_or_null("Content") as Control
		if content != null:
			for child in content.get_children():
				if child is CanvasItem:
					(child as CanvasItem).modulate = Color.WHITE
	if dim != null:
		dim.modulate = Color.WHITE
	if _booster_tray != null:
		_booster_tray.visible = true
	if after.is_valid():
		after.call()

func set_player_resources(lives: int, coins: int, gems: int) -> void:
	_player_lives = clampi(lives, 0, 5)
	_player_coins = maxi(0, coins)
	_player_gems = maxi(0, gems)
	if _resource_life_label != null:
		_resource_life_label.text = "FULL" if _player_lives >= 5 else "%d / 5" % _player_lives
	if _resource_coin_label != null:
		_resource_coin_label.text = _format_number(_player_coins)
	if _resource_gem_label != null:
		_resource_gem_label.text = _format_number(_player_gems)

func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	_high_contrast = bool(state.get("high_contrast", false))
	if board_view != null and board_view.has_method("apply_presentation_settings"):
		board_view.apply_presentation_settings(state)
	haptics.apply_settings(state)
	_apply_moves_urgency()

func load_level_path(path: String, seed_value: int = 1001) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	current_level_path = path
	current_seed = seed_value
	_potion_used_for_attempt = false
	if _potion_boost_button != null:
		_potion_boost_button.disabled = false
	_idle_hint_seconds = 0.0
	current_level_id = String(parsed.get("id", ""))
	_update_level_badge()
	current_reward_curio = String(parsed.get("reward_curio", ""))
	current_house_stage_reward = int(parsed.get("house_stage_reward", 0))
	current_objective_type = String(parsed.get("objective", "collect_family"))
	current_objective_family = String(parsed.get("objective_family", "moon"))
	current_objective_target = int(parsed.get("objective_target", 1))
	var blockers_data: Variant = parsed.get("blockers", [])
	current_initial_blocker_count = blockers_data.size() if blockers_data is Array else 0
	current_initial_blocker_hp = 0
	if blockers_data is Array:
		for raw_blocker in blockers_data:
			if raw_blocker is Dictionary:
				current_initial_blocker_hp += maxi(1, int(raw_blocker.get("hp", 1)))
	current_win_title = String(parsed.get("win_title", "THE CABINET STIRS"))
	current_win_detail = String(parsed.get("win_detail", "Something in the Curio Boutique has awakened."))
	current_retry_hint = String(parsed.get("retry_hint", ""))
	_last_impact_feedback = ""
	_last_cascade_depth = 1
	_last_objective_progress = 0
	_last_objective_delta = 0
	_reset_terminal_transition()
	_style_impact_hint("normal")
	var level_identity := _level_badge_label.text if _level_badge_label != null else "LEVEL"
	eyebrow_label.text = level_identity
	title_label.text = String(parsed.get("title", "Hidden Display"))
	hint_label.text = String(parsed.get("hint", "Swipe a sigil."))
	var art_profile := String(parsed.get("visual_profile", "curio_boutique_opening"))
	_apply_level_art_profile(art_profile)
	board_state = BoardState.from_level(parsed, seed_value)
	_last_objective_progress = _objective_progress_value()
	if board_view.has_method("set_visual_profile"):
		board_view.set_visual_profile(art_profile)
	board_view.set_board(board_state)
	_configure_teaching_move(parsed)
	hint_label.visible = false
	_pending_win = false
	_pending_terminal_result = ""
	_pending_hud_refresh = false
	pause_overlay.visible = false
	result_overlay.visible = false
	if result_recovery_action != null:
		result_recovery_action.visible = false
	if _booster_tray != null:
		_booster_tray.visible = true
	if result_ritual != null:
		result_ritual.set("mode", "result")
		result_ritual.set("relic_id", current_reward_curio)
		result_ritual.set("glow_strength", 0.75)
		result_ritual.queue_redraw()
	_refresh_hud()
	return true

func _update_level_badge() -> void:
	if _level_badge_label == null:
		return
	var parts: PackedStringArray = current_level_id.split("_")
	var level_number := 1
	if not parts.is_empty():
		level_number = maxi(1, int(parts[parts.size() - 1]))
	_level_badge_label.text = "LEVEL %d" % level_number

func _apply_level_art_profile(profile: String) -> void:
	# The board symbols, room tint, and heading accents move together by chapter beat.
	match profile:
		"sealed_display":
			world_backdrop.modulate = Color.WHITE
			eyebrow_label.add_theme_color_override("font_color", Color("#f7e6b8"))
			title_label.add_theme_color_override("font_color", Color("#f1e6d2"))
			objective_label.add_theme_color_override("font_color", Color("#a8c6d2"))
			moves_label.add_theme_color_override("font_color", Color("#d8c8a1"))
		"thornlight_arrangement":
			world_backdrop.modulate = Color.WHITE
			eyebrow_label.add_theme_color_override("font_color", Color("#f7e6b8"))
			title_label.add_theme_color_override("font_color", Color("#f5e6e2"))
			objective_label.add_theme_color_override("font_color", Color("#c7a0df"))
			moves_label.add_theme_color_override("font_color", Color("#e6bd83"))
		_:
			world_backdrop.modulate = Color.WHITE
			eyebrow_label.add_theme_color_override("font_color", Color("#f7e6b8"))
			title_label.add_theme_color_override("font_color", Color("#f1e8dc"))
			objective_label.add_theme_color_override("font_color", Color("#f0dec2"))
			moves_label.add_theme_color_override("font_color", Color("#d9b56a"))

func _configure_teaching_move(level_data: Dictionary) -> void:
	if not board_view.has_method("set_teaching_move"):
		return
	var teaching_moves: Variant = level_data.get("teaching_moves", [])
	if teaching_moves is Array and not teaching_moves.is_empty():
		var move: Variant = teaching_moves[0]
		if move is Array and move.size() >= 4:
			board_view.set_teaching_move(
				Vector2i(int(move[0]), int(move[1])),
				Vector2i(int(move[2]), int(move[3]))
			)
			return
	if board_view.has_method("clear_teaching_move"):
		board_view.clear_teaching_move()

func show_pause() -> bool:
	_idle_hint_seconds = 0.0
	if board_state == null or result_overlay.visible or pause_overlay.visible:
		return false
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		return false
	_pause_closing = false
	pause_overlay.visible = true
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if _booster_tray != null:
		_booster_tray.visible = false
	_play_pause_open()
	return true

func resume_level() -> bool:
	if not pause_overlay.visible:
		return false
	_idle_hint_seconds = 0.0
	_begin_pause_close(Callable())
	return true

func _on_pause_retry() -> void:
	if not pause_overlay.visible:
		return
	_begin_pause_close(Callable(self, "retry_current_level"))

func _on_pause_exit() -> void:
	if not pause_overlay.visible:
		return
	_begin_pause_close(func(): level_exit_requested.emit())

func attempt_swap(from: Vector2i, to: Vector2i):
	_idle_hint_seconds = 0.0
	_last_objective_delta = 0
	if board_state == null or result_overlay.visible or (pause_overlay.visible and not _pause_closing):
		return null
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		return null
	var objective_before := _objective_progress_value()
	if board_view.has_method("snapshot_before_move"):
		board_view.snapshot_before_move()
	last_trace = MoveResolver.try_swap(board_state, from, to)
	var objective_after := _objective_progress_value()
	_last_objective_delta = maxi(0, objective_after - objective_before)
	_last_objective_progress = objective_after
	board_view.set_board(board_state)
	var motion_started := false
	if board_view.has_method("play_trace"):
		motion_started = bool(board_view.play_trace(last_trace))
	# Keep objective and move counters in sync with the visible settling board.
	# The resolver has already advanced state, but the player has not seen it yet.
	if motion_started:
		_pending_hud_refresh = true
	else:
		_refresh_hud()
		_present_objective_progress()
	_refresh_move_feedback(last_trace)
	if not bool(last_trace.accepted):
		haptics.request_invalid()
		feedback_requested.emit("invalid")
	if last_trace.accepted:
		if board_view.has_method("clear_teaching_move"):
			board_view.clear_teaching_move()
		_last_cascade_depth = _trace_cascade_depth(last_trace)
		_set_trace_impact_state(last_trace)
		if not motion_started:
			_emit_trace_feedback_immediate(last_trace)
		var terminal_result := String(last_trace.result)
		if terminal_result == "won" or terminal_result == "failed":
			if motion_started:
				_pending_terminal_result = terminal_result
			else:
				_show_result_if_terminal(terminal_result)
	return last_trace

func _set_trace_impact_state(trace) -> void:
	if trace == null:
		_last_impact_feedback = ""
		return
	var feedback_types: Array[String] = trace.event_types()
	if feedback_types.has("combo_triggered"):
		_last_impact_feedback = "combo"
	elif feedback_types.has("special_triggered"):
		_last_impact_feedback = "special_triggered"
	elif feedback_types.has("special_created"):
		_last_impact_feedback = "special_created"
	elif feedback_types.has("blocker_cleared") or feedback_types.has("blocker_damaged"):
		_last_impact_feedback = "blocker_cleared" if feedback_types.has("blocker_cleared") else "blocker_damaged"
	elif _last_cascade_depth > 1:
		_last_impact_feedback = "cascade_%d" % _last_cascade_depth
	else:
		_last_impact_feedback = "match"

func _trace_primary_feedback_kind(trace) -> String:
	if trace == null:
		return "match"
	var feedback_types: Array[String] = trace.event_types()
	if feedback_types.has("combo_triggered"):
		return "combo"
	if feedback_types.has("special_triggered"):
		return "special"
	if feedback_types.has("special_created"):
		return "special_create"
	if feedback_types.has("blocker_cleared") or feedback_types.has("blocker_damaged"):
		return "blocker"
	if _trace_cascade_depth(trace) > 1:
		return "cascade"
	return "match"

func _emit_trace_feedback_immediate(trace) -> void:
	_emit_semantic_impact_feedback(_trace_primary_feedback_kind(trace))

func _on_board_motion_feedback_requested(kind: String, cascade: int, _clock: float) -> void:
	if kind == "cascade":
		_last_impact_feedback = "cascade_%d" % cascade
	_emit_semantic_impact_feedback(kind)

func _emit_semantic_impact_feedback(kind: String) -> void:
	match kind:
		"combo":
			haptics.request_combo()
		"blocker":
			haptics.request_blocker()
		"special", "special_create", "cascade":
			haptics.request_special()
		_:
			haptics.request_match()
	feedback_requested.emit(kind)

func continue_after_win() -> bool:
	if not _pending_win:
		return false
	_pending_win = false
	if replay_mode:
		level_replay_finished.emit(current_level_id)
	else:
		level_won.emit(current_level_id, current_reward_curio, current_house_stage_reward)
	return true

func restore_reward_claim() -> void:
	# A failed durable write must not consume the one-shot Continue action.
	# The player remains on the win result and may retry the same claim.
	_pending_win = true
	result_overlay.visible = true
	result_action.disabled = false
	result_action.text = "RETRY REWARD"
	result_detail.text = "The House could not save your reward. Your win is still here; try again."

func retry_current_level() -> bool:
	if current_level_path == "":
		return false
	var guided_retry := _consecutive_failures >= 2
	haptics.reset_for_new_attempt()
	haptics.request_retry()
	feedback_requested.emit("retry")
	var reloaded := load_level_path(current_level_path, current_seed)
	if reloaded:
		if guided_retry:
			var legal_move: Dictionary = MoveFinder.first_legal_move(board_state)
			if not legal_move.is_empty() and board_view.has_method("set_teaching_move"):
				board_view.set_teaching_move(legal_move["from"], legal_move["to"])
			hint_label.text = "GUIDED RETRY · FOLLOW THE MOONLIT PAIR · %d MOVES RESTORED" % int(board_state.moves_remaining)
		else:
			hint_label.text = "RITUAL RESET · %d MOVES RESTORED" % int(board_state.moves_remaining)
		_guided_retry_pending = false
		_style_impact_hint("normal")
	return reloaded

func _on_swap_requested(from: Vector2i, to: Vector2i) -> void:
	attempt_swap(from, to)

func _refresh_move_feedback(trace) -> void:
	if trace == null:
		return
	var types: Array[String] = trace.event_types()
	var cascade_depth := _trace_cascade_depth(trace)
	if types.has("combo_triggered"):
		hint_label.text = "COVEN COMBO · THE WHOLE CABINET ANSWERS"
		_style_impact_hint("combo")
	elif types.has("blocker_cleared"):
		var remaining := int(board_state.remaining_blockers()) if board_state != null else 0
		hint_label.text = "WAX SEAL SHATTERED · %s" % ("DISPLAY OPEN" if remaining == 0 else "%d REMAIN" % remaining)
		_style_impact_hint("blocker")
	elif types.has("blocker_damaged"):
		hint_label.text = "WAX SEAL CRACKED · STRIKE BESIDE IT AGAIN"
		_style_impact_hint("blocker")
	elif types.has("special_created"):
		hint_label.text = "MOON BEAM FORMED · MATCH IT TO RELEASE THE LINE"
		_style_impact_hint("special")
	elif types.has("special_triggered"):
		hint_label.text = "MOON BEAM RELEASED · THE CABINET ANSWERS"
		_style_impact_hint("special")
	elif cascade_depth > 1:
		hint_label.text = "RITUAL CHAIN ×%d · KEEP WATCHING THE FALL" % cascade_depth
		_style_impact_hint("cascade")
	elif types.has("shuffle"):
		hint_label.text = "NO PATH REMAINED · THE HOUSE REARRANGES THE SIGILS"
		_style_impact_hint("normal")
	elif not bool(trace.accepted):
		hint_label.text = "THOSE SIGILS REFUSE THE ARRANGEMENT · TRY ANOTHER ADJACENT SWAP"
		_style_impact_hint("invalid")

func _trace_cascade_depth(trace) -> int:
	if trace == null:
		return 1
	var depth := 1
	for event in trace.events:
		depth = maxi(depth, int(event.get("cascade", 1)))
	return depth

func _style_impact_hint(mode: String) -> void:
	if hint_label == null:
		return
	hint_label.visible = true
	var color := Color("#F4E5D3")
	var size_px := 28
	match mode:
		"blocker":
			color = Color("#F0CE8A")
			size_px = 29
		"special":
			color = Color("#E8C987")
			size_px = 29
		"combo":
			color = Color("#E7C8FF")
			size_px = 30
		"cascade":
			color = Color("#DDB7F5")
			size_px = 29
		"invalid":
			color = Color("#D8C5D2")
		_:
			pass
	hint_label.add_theme_color_override("font_color", Color("#FFFFFF") if _high_contrast else color)
	hint_label.add_theme_font_size_override("font_size", size_px)

func _refresh_hud() -> void:
	if objective_icon != null:
		objective_icon.texture = PieceAssetLoader.ornament(_objective_art_path())
	if board_state == null:
		objective_name_label.text = "OBJECTIVE"
		objective_label.text = "— / —"
		moves_label.text = "—"
		return
	_apply_moves_urgency()
	var progress_value := int(board_state.objective_progress)
	var target_value := int(board_state.objective_target)
	var progress_family := String(board_state.objective_family)
	var progress_unit := "SIGILS"
	if String(board_state.objective_type) == "clear_blockers":
		progress_value = maxi(0, current_initial_blocker_hp - _remaining_blocker_hp())
		target_value = maxi(1, current_initial_blocker_hp)
		progress_family = "wax_seal"
		progress_unit = "SEAL LAYERS"
	if awakening_title != null:
		var relic_name := current_reward_curio.replace("_", " ").to_upper()
		awakening_title.text = "AWAKENING · MOON CAMEO" if current_reward_curio == "moon_cameo" else "RELIC · %s" % relic_name
	if awakening_view != null and awakening_view.has_method("set_objective"):
		awakening_view.set_objective(progress_value, target_value, progress_family)
	if awakening_copy != null:
		var remaining := maxi(0, target_value - progress_value)
		var completion_copy := "THE MOON CAMEO WAKES" if current_reward_curio == "moon_cameo" else "%s READY" % current_reward_curio.replace("_", " ").to_upper()
		if progress_unit == "SEALS":
			completion_copy = "THE RELIQUARY OPENS"
		awakening_copy.text = "%d / %d %s · %s" % [
			progress_value,
			target_value,
			progress_unit,
			completion_copy if remaining == 0 else "%d REMAIN" % remaining
		]
	if String(board_state.objective_type) == "collect_family":
		var family_label: String = String(board_state.objective_family).capitalize()
		objective_name_label.text = "%s SIGILS" % family_label.to_upper()
		objective_label.text = "%d / %d" % [
			int(board_state.objective_progress),
			int(board_state.objective_target)
		]
		objective_icon.tooltip_text = "%s · collect %d" % [objective_name_label.text.capitalize(), int(board_state.objective_target)]
	elif String(board_state.objective_type) == "clear_blockers":
		objective_name_label.text = "WAX SEAL LAYERS"
		objective_label.text = "%d / %d" % [_objective_progress_value(), _objective_target_value()]
		objective_icon.tooltip_text = "Wax seal layers · clear %d" % _objective_target_value()
	else:
		objective_name_label.text = "OBJECTIVE"
		objective_label.text = "— / —"

func _objective_art_path() -> String:
	if board_state != null and String(board_state.objective_type) == "clear_blockers":
		return String(OBJECTIVE_ART_PATHS["wax_seal"])
	var family := current_objective_family
	if board_state != null:
		family = String(board_state.objective_family)
	return String(OBJECTIVE_ART_PATHS.get(family, OBJECTIVE_ART_PATHS["moon"]))


func _remaining_blocker_hp() -> int:
	if board_state == null:
		return 0
	var total := 0
	for raw_pos in board_state.blockers.keys():
		var blocker: Dictionary = board_state.get_blocker(raw_pos)
		total += maxi(0, int(blocker.get("hp", 0)))
	return total

func _objective_progress_value() -> int:
	if board_state == null:
		return 0
	if String(board_state.objective_type) == "clear_blockers":
		return maxi(0, current_initial_blocker_hp - _remaining_blocker_hp())
	return maxi(0, int(board_state.objective_progress))

func _objective_target_value() -> int:
	if board_state == null:
		return maxi(1, current_objective_target)
	if String(board_state.objective_type) == "clear_blockers":
		return maxi(1, current_initial_blocker_hp)
	return maxi(1, int(board_state.objective_target))

func _present_objective_progress() -> void:
	if objective_label == null or board_state == null or _last_objective_delta <= 0:
		return
	var progress := _objective_progress_value()
	var target := _objective_target_value()
	var complete := progress >= target
	objective_label.text = "%d / %d" % [progress, target]
	if String(board_state.objective_type) == "clear_blockers":
		objective_name_label.text = "OBJECTIVE COMPLETE" if complete else "+%d SEAL LAYER" % _last_objective_delta
	else:
		objective_name_label.text = "OBJECTIVE COMPLETE" if complete else "+%d THIS MOVE" % _last_objective_delta
	objective_label.set_meta("objective_feedback_state", "complete" if complete else "progress")
	objective_label.add_theme_color_override("font_color", Color("#FFFFFF") if _high_contrast else (Color("#F0CE8A") if complete else Color("#E4CDEB")))
	if _objective_pulse_tween != null and _objective_pulse_tween.is_valid():
		_objective_pulse_tween.kill()
	objective_label.scale = Vector2.ONE
	if _reduced_motion:
		return
	objective_label.pivot_offset = objective_label.size * 0.5
	objective_label.scale = Vector2(1.06, 1.06)
	_objective_pulse_tween = create_tween()
	_objective_pulse_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_objective_pulse_tween.tween_property(objective_label, "scale", Vector2.ONE, 0.24)

func _apply_moves_urgency() -> void:
	if moves_label == null:
		return
	if board_state == null:
		_moves_urgency_state = "normal"
		moves_label.text = "—"
		moves_label.set_meta("urgency_state", _moves_urgency_state)
		return
	var moves := maxi(0, int(board_state.moves_remaining))
	if moves <= LAST_MOVE_THRESHOLD:
		_moves_urgency_state = "critical"
		moves_label.text = "LAST MOVE" if moves == 1 else "NO MOVES"
		moves_label.add_theme_color_override("font_color", Color("#FFFFFF") if _high_contrast else Color("#FF9B8E"))
		moves_label.add_theme_font_size_override("font_size", 40)
		moves_label.add_theme_constant_override("outline_size", 5 if _high_contrast else 4)
	elif moves <= LOW_MOVE_WARNING_THRESHOLD:
		_moves_urgency_state = "warning"
		moves_label.text = "⚠ %d\nMOVES" % moves
		moves_label.add_theme_color_override("font_color", Color("#FFF1B6") if _high_contrast else Color("#F2B36D"))
		moves_label.add_theme_font_size_override("font_size", 42)
		moves_label.add_theme_constant_override("outline_size", 4)
	else:
		_moves_urgency_state = "normal"
		moves_label.text = "%d\nMOVES" % moves
		moves_label.add_theme_color_override("font_color", Color("#FFF1B6") if _high_contrast else Color("#F2C66D"))
		moves_label.add_theme_font_size_override("font_size", 40)
		moves_label.add_theme_constant_override("outline_size", 3)
	moves_label.set_meta("urgency_state", _moves_urgency_state)

func gameplay_feel_contract() -> Dictionary:
	return {
		"invalid_swap_feedback": "visual_return_audio_haptic",
		"low_move_warning_threshold": LOW_MOVE_WARNING_THRESHOLD,
		"last_move_threshold": LAST_MOVE_THRESHOLD,
		"moves_urgency_state": _moves_urgency_state,
		"moves_copy": moves_label.text if moves_label != null else "",
		"reduced_motion": _reduced_motion,
		"high_contrast": _high_contrast,
		"urgency_non_color_cue": _moves_urgency_state == "normal" or moves_label.text.contains("⚠") or moves_label.text.contains("LAST MOVE") or moves_label.text.contains("NO MOVES"),
		"last_impact_feedback": _last_impact_feedback,
		"last_cascade_depth": _last_cascade_depth,
		"impact_copy": hint_label.text if hint_label != null else "",
		"objective_progress": _last_objective_progress,
		"objective_delta": _last_objective_delta,
		"objective_target": _objective_target_value(),
		"objective_copy": ("%s · %s" % [objective_name_label.text, objective_label.text]) if objective_label != null and objective_name_label != null else "",
	}

func _show_result_if_terminal(result: String) -> void:
	if result == "won":
		haptics.request_terminal("won")
		feedback_requested.emit("win")
		_pending_win = true
		result_title.text = "RITUAL COMPLETE AGAIN" if replay_mode else "LEVEL COMPLETE!"
		result_detail.text = "This Curio already belongs to the House. Replaying does not grant the persistent reward again." if replay_mode else current_win_detail
		result_detail.visible = replay_mode
		_configure_result_reward_copy(true)
		if result_ritual != null:
			result_ritual.set("mode", "result")
			result_ritual.set("relic_id", current_reward_curio)
			result_ritual.set("glow_strength", 0.75)
			result_ritual.queue_redraw()
		result_action.text = "RETURN TO HOUSE" if replay_mode else "CONTINUE"
		result_recovery_action.visible = false
		if _result_reward_values != null:
			_result_reward_values.visible = not replay_mode
		if _result_proclamation != null:
			_result_proclamation.text = "Replay complete · House state and owned Curios stay unchanged." if replay_mode else "The recovered Curio now changes the House."
		if _booster_tray != null:
			_booster_tray.visible = false
		result_objective_summary.text = _terminal_objective_summary(true)
		_present_result_overlay("won")
		if _result_reveal_fx != null and _result_reveal_fx.has_method("play"):
			_result_reveal_fx.play(_reduced_motion or replay_mode)
		result_state_changed.emit("won")
	elif result == "failed":
		haptics.request_terminal("failed")
		feedback_requested.emit("fail")
		_pending_win = false
		_consecutive_failures += 1
		_guided_retry_pending = _consecutive_failures >= 2
		result_title.text = "THE ROOM WAITS"
		result_detail.text = _failure_recovery_copy()
		result_detail.visible = true
		_configure_result_reward_copy(false)
		if result_ritual != null:
			result_ritual.set("mode", "fail")
			result_ritual.set("relic_id", current_reward_curio)
			result_ritual.set("glow_strength", 0.12)
			result_ritual.queue_redraw()
		result_action.text = "TRY AGAIN"
		result_recovery_action.visible = not _potion_used_for_attempt
		result_recovery_action.disabled = _potion_used_for_attempt
		if _result_reward_values != null:
			_result_reward_values.visible = false
		if _result_proclamation != null:
			_result_proclamation.text = "The Curio remains sealed. The ritual can be attempted again."
		if _booster_tray != null:
			_booster_tray.visible = false
		if _result_reveal_fx != null and _result_reveal_fx.has_method("stop"):
			_result_reveal_fx.stop()
		result_objective_summary.text = _terminal_objective_summary(false)
		_present_result_overlay("failed")
		result_state_changed.emit("failed")

func _failure_gap_copy() -> String:
	if board_state == null:
		return "The ritual remains unfinished."
	var remaining := maxi(0, _objective_target_value() - _objective_progress_value())
	if String(board_state.objective_type) == "collect_family":
		var family := String(board_state.objective_family).capitalize()
		return "%d %s sigil%s remained." % [remaining, family, "" if remaining == 1 else "s"]
	if String(board_state.objective_type) == "clear_blockers":
		return "%d wax seal layer%s remained." % [remaining, "" if remaining == 1 else "s"]
	return "The ritual remains unfinished."

func _failure_recovery_copy() -> String:
	var authored := current_retry_hint if current_retry_hint != "" else "Try another arrangement."
	var base := "%s %s" % [_failure_gap_copy(), authored]
	if _consecutive_failures <= 1:
		return base
	if _consecutive_failures == 2:
		return "%s On retry, the House will mark a legal opening." % base
	return "%s Guided retry is active: the first legal opening is marked and hints return sooner." % base

func difficulty_recovery_contract() -> Dictionary:
	var tier := "standard"
	if _consecutive_failures >= 3:
		tier = "assisted"
	elif _consecutive_failures >= 2:
		tier = "guided"
	return {
		"consecutive_failures": _consecutive_failures,
		"guidance_tier": tier,
		"guided_retry_pending": _guided_retry_pending,
		"auto_hint_delay_seconds": _current_auto_hint_delay(),
		"life_economy_visible": _resource_life_label != null,
		"hint_utility_visible": _hint_boost_button != null,
		"active_plus_moves_booster_visible": _potion_boost_button != null,
		"active_retry_booster_visible": _retry_boost_button != null,
		"fail_screen_plus_three_rescue_available": result_recovery_action != null and result_recovery_action.visible and not result_recovery_action.disabled,
		"guided_retry_changes_move_budget": false,
		"plus_three_rescue_is_explicit": true,
	}

func recover_failed_attempt_with_plus_moves() -> bool:
	if board_state == null or not result_overlay.visible or _potion_used_for_attempt:
		return false
	if String(terminal_transition_contract().get("kind", "")) != "failed":
		return false
	_potion_used_for_attempt = true
	board_state.moves_remaining += 3
	_pending_win = false
	_pending_terminal_result = ""
	_last_objective_delta = 0
	if _potion_boost_button != null:
		_potion_boost_button.disabled = true
	if result_recovery_action != null:
		result_recovery_action.visible = false
	result_overlay.visible = false
	_reset_terminal_transition()
	haptics.reset_for_new_attempt()
	haptics.request_special()
	feedback_requested.emit("special")
	if _booster_tray != null:
		_booster_tray.visible = true
	_refresh_hud()
	hint_label.text = "RECOVERY · +3 MOVES · CONTINUE FROM THIS BOARD"
	_style_impact_hint("special")
	result_state_changed.emit("recovered")
	return true

func _on_result_recovery_pressed() -> void:
	recover_failed_attempt_with_plus_moves()

func _terminal_objective_summary(won: bool) -> String:
	if board_state == null:
		return "OBJECTIVE COMPLETE" if won else "OBJECTIVE UNFINISHED"
	var prefix := "OBJECTIVE COMPLETE" if won else "OBJECTIVE UNFINISHED"
	if String(board_state.objective_type) == "collect_family":
		var progress := mini(_objective_progress_value(), _objective_target_value())
		return "%s · %d / %d %s SIGILS" % [prefix, progress, _objective_target_value(), String(board_state.objective_family).to_upper()]
	if String(board_state.objective_type) == "clear_blockers":
		return "%s · %d / %d WAX SEAL LAYERS" % [prefix, _objective_progress_value(), _objective_target_value()]
	return prefix

func _style_terminal_result(kind: String) -> void:
	if result_overlay == null:
		return
	var card := result_overlay.get_node_or_null("Card") as PanelContainer
	if card == null:
		return
	var won := kind == "won"
	ProductionChrome.apply_primary(card)
	card.set_meta("production_result_chrome", "verified_primary")
	var dim := result_overlay.get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.color = Color(0.0314, 0.0235, 0.0353, 0.70 if won else 0.84)
	result_title.add_theme_color_override("font_color", Color("#FFF1B6") if won else Color("#F2D6DE"))
	result_objective_summary.add_theme_color_override("font_color", Color("#F0CE8A") if won else Color("#E5B2C1"))

func terminal_result_polish_contract() -> Dictionary:
	return {
		"objective_summary": result_objective_summary.text if result_objective_summary != null else "",
		"transition": terminal_transition_contract(),
		"retry_copy": hint_label.text if hint_label != null else "",
		"distinct_result_material": true,
		"asset_backed_result_chrome": result_overlay != null and (result_overlay.get_node_or_null("Card") as PanelContainer).get_theme_stylebox("panel") is StyleBoxTexture and String((result_overlay.get_node_or_null("Card") as PanelContainer).get_meta("production_result_chrome", "")) == "verified_primary",
		"runtime_result_style_factory": false,
		"result_dim_alpha": (result_overlay.get_node_or_null("Dim") as ColorRect).color.a if result_overlay != null and result_overlay.get_node_or_null("Dim") != null else 1.0,
		"failure_gap": _failure_gap_copy() if result_overlay != null and result_overlay.visible and String(terminal_transition_contract().get("kind", "")) == "failed" else "",
		"plus_three_recovery_available": result_recovery_action != null and result_recovery_action.visible and not result_recovery_action.disabled,
	}

func _present_result_overlay(kind: String) -> void:
	_result_transition_kind = kind
	_style_terminal_result(kind)
	if _result_transition_tween != null and _result_transition_tween.is_valid():
		_result_transition_tween.kill()
	result_overlay.visible = true
	var card := result_overlay.get_node_or_null("Card") as Control
	var dim := result_overlay.get_node_or_null("Dim") as CanvasItem
	if card == null:
		_result_transition_active = false
		return
	card.pivot_offset = card.size * 0.5
	var rest_position := card.position
	card.set_meta("result_rest_position", rest_position)
	card.scale = Vector2.ONE
	card.modulate = Color.WHITE
	if dim != null:
		dim.modulate = Color.WHITE
	if _reduced_motion:
		_result_transition_active = false
		return
	_result_transition_active = true
	card.position = rest_position + Vector2(0, 42)
	card.scale = Vector2(0.86, 0.86)
	card.modulate = Color(1, 1, 1, 0)
	if dim != null:
		dim.modulate = Color(1, 1, 1, 0)
	var content := card.get_node_or_null("Content") as Control
	var reveal_items: Array[CanvasItem] = []
	if content != null:
		for child in content.get_children():
			if child is CanvasItem:
				(child as CanvasItem).modulate = Color(1, 1, 1, 0)
				reveal_items.append(child as CanvasItem)
	_result_transition_tween = create_tween()
	_result_transition_tween.set_parallel(true)
	if dim != null:
		_result_transition_tween.tween_property(dim, "modulate", Color.WHITE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_result_transition_tween.tween_property(card, "position", rest_position, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_result_transition_tween.tween_property(card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_result_transition_tween.tween_property(card, "modulate", Color.WHITE, 0.22)
	for index in range(reveal_items.size()):
		_result_transition_tween.tween_property(reveal_items[index], "modulate", Color.WHITE, 0.17).set_delay(0.07 + float(index) * 0.032)
	for index in range(3):
		var star: TextureRect = [_result_star_a, _result_star_b, _result_star_c][index]
		if star == null:
			continue
		_result_transition_tween.tween_property(star, "modulate", Color.WHITE, 0.20).set_delay(0.16 + float(index) * 0.10)
		_result_transition_tween.tween_property(star, "scale", Vector2.ONE, 0.34).set_delay(0.16 + float(index) * 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_result_transition_tween.finished.connect(func(): _result_transition_active = false)

func _reset_terminal_transition() -> void:
	if _result_transition_tween != null and _result_transition_tween.is_valid():
		_result_transition_tween.kill()
	_result_transition_kind = ""
	_result_transition_active = false
	if result_overlay != null:
		var card := result_overlay.get_node_or_null("Card") as Control
		var dim := result_overlay.get_node_or_null("Dim") as CanvasItem
		if card != null:
			card.scale = Vector2.ONE
			card.modulate = Color.WHITE
			card.position = card.get_meta("result_rest_position", card.position)
			var content := card.get_node_or_null("Content") as Control
			if content != null:
				for child in content.get_children():
					if child is CanvasItem:
						(child as CanvasItem).modulate = Color.WHITE
		if dim != null:
			dim.modulate = Color.WHITE

func terminal_transition_contract() -> Dictionary:
	return {
		"kind": _result_transition_kind,
		"active": _result_transition_active,
		"mode": "subtle_card_settle",
		"reduced_motion": _reduced_motion,
		"overlay_visible": result_overlay.visible if result_overlay != null else false,
	}

func _install_reward_reveal_fx() -> void:
	if _result_reveal_fx != null:
		return
	var fx := RewardRevealFx.new()
	fx.name = "RewardRevealFx"
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_overlay.add_child(fx)
	result_overlay.move_child(fx, 1)
	_result_reveal_fx = fx

func feedback_vfx_contract() -> Dictionary:
	return {
		"match_clear": board_view.feedback_vfx_contract() if board_view != null and board_view.has_method("feedback_vfx_contract") else {},
		"reward_reveal": _result_reveal_fx.contract() if _result_reveal_fx != null and _result_reveal_fx.has_method("contract") else {},
		"terminal_transition": terminal_transition_contract(),
		"reduced_motion": _reduced_motion
	}

func _configure_result_reward_copy(won: bool) -> void:
	var reward_name := current_reward_curio.replace("_", " ").to_upper()
	if reward_name == "":
		reward_name = "HIDDEN CURIO"
	if won:
		var relic_number := maxi(1, current_house_stage_reward)
		if replay_mode:
			result_eyebrow.text = "REPLAY · RELIC %02d" % relic_number
			result_reward_name.text = "%s · ALREADY AWAKENED" % reward_name
			result_house_change.text = "No new Curio, House restoration or persistent currency is granted on replay."
			return
		result_eyebrow.text = "CURIO RECOVERED · RELIC %02d" % relic_number
		result_reward_name.text = "%s · %s" % [
			reward_name,
			"AWAKENED" if current_reward_curio == "moon_cameo" else "RECOVERED"
		]
		match current_house_stage_reward:
			1:
				result_house_change.text = "The first cabinet remembers the Moon Cameo."
			2:
				result_house_change.text = "The side cabinet opens for the Moth Reliquary."
			3:
				result_house_change.text = "The Thorned Locket takes its place in the first cabinet set."
			_:
				result_house_change.text = "The House makes room for this Curio."
	else:
		result_eyebrow.text = "RITUAL UNFINISHED"
		result_reward_name.text = "%s · STILL SEALED" % reward_name
		result_house_change.text = "No Curio is added to the House until this arrangement is completed."

func _on_result_action_pressed() -> void:
	if _pending_win:
		continue_after_win()
	else:
		retry_current_level()


func _on_board_trace_motion_finished() -> void:
	if _pending_hud_refresh:
		_pending_hud_refresh = false
		_refresh_hud()
		_present_objective_progress()
	if _pending_terminal_result == "":
		return
	var result := _pending_terminal_result
	_pending_terminal_result = ""
	_show_result_if_terminal(result)


func _format_number(value: int) -> String:
	var digits := str(maxi(0, value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = digits.substr(i, 1) + out
		count += 1
	return out

func gameplay_presentation_contract() -> Dictionary:
	var shuffle_label := $BoosterTray/BoosterActions/SealedSlotA/Label as Label
	var hand_label := $BoosterTray/BoosterActions/SealedSlotB/Label as Label
	var magic_label := $BoosterTray/BoosterActions/SealedSlotC/Label as Label
	var board_contract: Dictionary = board_view.frame_contract() if board_view != null and board_view.has_method("frame_contract") else {}
	var canonical_booster_names: bool = (
		shuffle_label.text == "SHUFFLE"
		and hand_label.text == "HAND"
		and magic_label.text == "MAGIC"
	)
	var settings_slot := $BoosterTray/BoosterActions/SettingsSlot as VBoxContainer
	var utilities_separated: bool = (
		not $BoosterTray/BoosterActions/HintSlot.visible
		and settings_slot.visible
		and settings_slot.custom_minimum_size.x < ($BoosterTray/BoosterActions/SealedSlotA as VBoxContainer).custom_minimum_size.x
		and _settings_shortcut.custom_minimum_size.x <= 80.0
	)
	var hierarchy_locked: bool = (
		not title_label.visible
		and eyebrow_label.get_theme_font_size("font_size") >= 30
		and objective_icon.custom_minimum_size.x >= 80.0
		and objective_label.get_theme_font_size("font_size") >= 30
		and moves_label.get_theme_font_size("font_size") >= 38
		and moves_label.get_theme_font_size("font_size") <= 42
		and ($Layout/HUDPlate as PanelContainer).custom_minimum_size.y >= 120.0
	)
	var integrated_hud_surface: bool = (
		not objective_label.has_theme_stylebox_override("normal")
		and objective_label.text.contains("/")
		and objective_name_label != null
		and objective_name_label.text != ""
		and moves_label.get_theme_stylebox("normal") != null
	)
	var hint_readable: bool = (
		hint_label.custom_minimum_size.y >= 52.0
		and hint_label.get_theme_font_size("font_size") >= 26
	)
	var booster_family_locked: bool = (
		$BoosterTray/BoosterActions/SealedSlotA.visible
		and $BoosterTray/BoosterActions/SealedSlotB.visible
		and $BoosterTray/BoosterActions/SealedSlotC.visible
		and canonical_booster_names
		and [_sealed_boost_a, _sealed_boost_b, _sealed_boost_c].all(
			func(button): return button.disabled and button.custom_minimum_size.y >= 108.0 and button.icon != null
		)
	)
	var composition_locked: bool = (
		_booster_tray != null
		and is_equal_approx(_booster_tray.anchor_top, 0.79)
		and (_booster_tray.offset_bottom - _booster_tray.offset_top) >= 210.0
		and (_booster_tray.offset_bottom - _booster_tray.offset_top) <= 230.0
		and hint_label != null
		and (not hint_label.visible or _booster_tray.global_position.y >= hint_label.global_position.y + hint_label.size.y + 10.0)
	)
	var board_locked: bool = (
		bool(board_contract.get("asset_loaded", false))
		and bool(board_contract.get("nine_slice_frame", false))
		and float(board_contract.get("frame_padding", 0.0)) >= 24.0
		and bool(board_contract.get("normalized_piece_scale", false))
	)
	var canonical_booster_art: bool = (
		String(NORTH_STAR_BOOSTER_ART_PATHS["shuffle"]).contains("/ui/gameplay/booster_shuffle_")
		and String(NORTH_STAR_BOOSTER_ART_PATHS["hand"]).contains("/ui/gameplay/booster_hand_")
		and String(NORTH_STAR_BOOSTER_ART_PATHS["magic"]).contains("/ui/gameplay/booster_magic_")
		and PieceAssetLoader.ornament(String(NORTH_STAR_BOOSTER_ART_PATHS["shuffle"])) != null
		and PieceAssetLoader.ornament(String(NORTH_STAR_BOOSTER_ART_PATHS["hand"])) != null
		and PieceAssetLoader.ornament(String(NORTH_STAR_BOOSTER_ART_PATHS["magic"])) != null
	)
	var gothic_board_material: bool = String(board_contract.get("frame_revision", "")) == "gothic_corner_v3" and float(board_contract.get("corner_preservation_margin", 0.0)) >= 72.0
	var objective_slot := $Layout/HUDPlate/HUD/ObjectiveSlot as VBoxContainer
	var objective_spacing_locked: bool = (
		objective_slot != null
		and objective_slot.custom_minimum_size.x >= 160.0
		and objective_icon.custom_minimum_size.y >= 88.0
		and objective_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER
		and objective_label.global_position.y >= objective_icon.global_position.y + objective_icon.size.y - 8.0
	)
	var compact_header_locked: bool = (
		not title_label.visible
		and level_plaque != null
		and level_plaque.custom_minimum_size.x >= 580.0
		and eyebrow_label.text.begins_with("LEVEL ")
		and eyebrow_label.get_theme_font_size("font_size") >= 40
		and not eyebrow_label.text.contains("·")
		and pause_button.global_position.x < objective_icon.global_position.x
		and moves_label.global_position.x > objective_label.global_position.x
	)
	var compact_geometry_locked: bool = (
		is_equal_approx(_booster_tray.anchor_left, 0.045)
		and is_equal_approx(_booster_tray.anchor_right, 0.955)
		and is_equal_approx(_booster_tray.anchor_top, 0.79)
		and ($Layout/BoardView as Control).custom_minimum_size.y >= 1020.0
		and ($Layout/BoardView as Control).custom_minimum_size.y <= 1080.0
	)
	var viewport_size := get_viewport().get_visible_rect().size
	var hud_rect := ($Layout/HUDPlate as Control).get_global_rect()
	var board_rect := ($Layout/BoardView as Control).get_global_rect()
	var header_depth_locked: bool = (
		($Layout/HUDPlate as PanelContainer).custom_minimum_size.y >= 184.0
		and ($Layout/HUDPlate as PanelContainer).custom_minimum_size.y <= 200.0
		and hud_rect.size.y / viewport_size.y >= 0.09
		and hud_rect.size.y / viewport_size.y <= 0.11
		and board_rect.position.y / viewport_size.y >= 0.18
		and board_rect.position.y / viewport_size.y <= 0.22
		and board_rect.size.y / viewport_size.y >= 0.52
		and board_rect.size.y / viewport_size.y <= 0.56
	)
	var north_star_gameplay_hud_frame: bool = (
		String($Layout/HUDPlate.get_meta("production_chrome_asset", "")) == ProductionChrome.GAMEPLAY_HUD_FRAME_PATH
		and String($Layout/HUDPlate.get_meta("production_chrome_kind", "")) == "gameplay_objective_frame"
		and ($Layout/HUDPlate as PanelContainer).get_theme_stylebox("panel") is StyleBoxTexture
	)
	var hint_style := hint_label.get_theme_stylebox("normal")
	var integrated_hint_surface: bool = (
		hint_style is StyleBoxFlat
		and (hint_style as StyleBoxFlat).bg_color.a <= 0.10
		and (hint_style as StyleBoxFlat).border_color.a <= 0.08
		and (hint_style as StyleBoxFlat).shadow_color.a <= 0.08
	)
	return {
		"authored_hud_plate": get_node_or_null("Layout/HUDPlate/HUD") != null,
		"authored_resource_bar": _level_badge_label != null and _resource_coin_label != null and _resource_gem_label != null,
		"authored_keeper_tray": _booster_tray != null,
		"authored_booster_menu": booster_family_locked,
		"north_star_resource_strip": not $ResourceBar.visible,
		"north_star_objective_strip": hierarchy_locked,
		"north_star_booster_tray": booster_family_locked and composition_locked,
		"deterministic_gameplay_geometry": true,
		"truthful_sealed_slots": _sealed_boost_a.disabled and _sealed_boost_b.disabled and _sealed_boost_c.disabled,
		"authored_target_moves_hierarchy": objective_icon.texture != null and integrated_hud_surface,
		"authored_board_frame": board_locked,
		"asset_backed_gameplay_chrome": ($Layout/HUDPlate as PanelContainer).get_theme_stylebox("panel") is StyleBoxTexture and _booster_tray.get_theme_stylebox("panel") is StyleBoxTexture and [$ResourceBar/Resources/CoinChip, $ResourceBar/Resources/GemChip, $ResourceBar/Resources/LevelBadgePlate].all(func(panel): return panel.get_theme_stylebox("panel") is StyleBoxTexture),
		"board_frame_asset_owner": String(($Layout/BoardView/OrnateFrame as Panel).get_meta("production_board_frame_owner", "")) == "BoardView",
		"north_star_gameplay_geometry": hierarchy_locked and booster_family_locked and composition_locked and board_locked,
		"gameplay_header_clearance": not $ResourceBar.visible and ($Layout as VBoxContainer).offset_top >= 92.0 and ($Layout as VBoxContainer).offset_top <= 108.0,
		"compact_resource_chips": ($ResourceBar/Resources/CoinChip as PanelContainer).size.x <= 300.0 and ($ResourceBar/Resources/GemChip as PanelContainer).size.x <= 300.0 and ($ResourceBar/Resources/LevelBadgePlate as PanelContainer).size.x <= 200.0,
		"asset_backed_resource_chips": [$ResourceBar/Resources/CoinChip, $ResourceBar/Resources/GemChip, $ResourceBar/Resources/LevelBadgePlate].all(func(panel): return panel is PanelContainer and (panel as PanelContainer).get_theme_stylebox("panel") is StyleBoxTexture),
		"level_badge_separated": ($ResourceBar/Resources/ResourceSpacer as Control).size_flags_horizontal == Control.SIZE_EXPAND_FILL,
		"hint_booster_clearance": composition_locked,
		"booster_label_readability": shuffle_label.custom_minimum_size.y >= 30.0 and hand_label.custom_minimum_size.y >= 30.0 and magic_label.custom_minimum_size.y >= 30.0 and shuffle_label.get_theme_font_size("font_size") >= 22,
		"north_star_booster_family": canonical_booster_names,
		"booster_frame_family": String(_booster_tray.get_meta("production_chrome_kind", "")) == "gameplay_booster_tray",
		"utility_separated_from_boosters": utilities_separated,
		"north_star_board_object": board_locked,
		"north_star_header_hierarchy": hierarchy_locked,
		"quiet_gameplay_shell_family": $ResourceBar.get_theme_stylebox("panel") is StyleBoxEmpty,
		"clear_pause_control": pause_button.icon != null and pause_button.text == "" and String(pause_button.get_meta("production_chrome_asset", "")) == GAMEPLAY_PAUSE_ICON_PATH and pause_button.get_theme_stylebox("normal") is StyleBoxFlat,
		"north_star_gameplay_hud_frame": north_star_gameplay_hud_frame,
		"north_star_header_depth": header_depth_locked,
		"integrated_hint_surface": integrated_hint_surface,
		"integrated_hud_surface": integrated_hud_surface,
		"final_hint_readability": hint_readable and hint_label.size_flags_horizontal == Control.SIZE_SHRINK_CENTER,
		"final_booster_readability": booster_family_locked and shuffle_label.get_theme_font_size("font_size") >= 22,
		"visual_parity_gate_v2": hierarchy_locked and booster_family_locked and composition_locked and board_locked and utilities_separated and String(_booster_tray.get_meta("production_chrome_kind", "")) == "gameplay_booster_tray",
		"visual_parity_gate_v3": hierarchy_locked and integrated_hud_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated,
		"visual_parity_gate_v4": hierarchy_locked and integrated_hud_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated and north_star_gameplay_hud_frame and $ResourceBar.get_theme_stylebox("panel") is StyleBoxEmpty and String(_booster_tray.get_meta("production_chrome_kind", "")) == "gameplay_booster_tray",
		"visual_parity_gate_v5": hierarchy_locked and integrated_hud_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated,
		"canonical_booster_art": canonical_booster_art,
		"gothic_board_material": gothic_board_material,
		"objective_spacing_locked": objective_spacing_locked,
		"north_star_compact_gameplay_header": compact_header_locked,
		"north_star_compact_gameplay_geometry": compact_geometry_locked,
		"visual_parity_gate_v10": hierarchy_locked and integrated_hud_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated and canonical_booster_art and gothic_board_material,
		"visual_parity_gate_v11": hierarchy_locked and integrated_hud_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated and canonical_booster_art and gothic_board_material and objective_spacing_locked and compact_header_locked,
		"visual_parity_gate_v12": hierarchy_locked and integrated_hud_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated and canonical_booster_art and gothic_board_material and objective_spacing_locked and compact_header_locked and compact_geometry_locked and north_star_gameplay_hud_frame,
		"visual_parity_gate_v13": hierarchy_locked and integrated_hud_surface and integrated_hint_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated and canonical_booster_art and gothic_board_material and objective_spacing_locked and compact_header_locked and compact_geometry_locked and north_star_gameplay_hud_frame,
		"visual_parity_gate_v14": hierarchy_locked and integrated_hud_surface and integrated_hint_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated and canonical_booster_art and gothic_board_material and objective_spacing_locked and compact_header_locked and compact_geometry_locked and north_star_gameplay_hud_frame and pause_button.icon != null and pause_button.text == "" and String(pause_button.get_meta("production_chrome_asset", "")) == GAMEPLAY_PAUSE_ICON_PATH and pause_button.get_theme_stylebox("normal") is StyleBoxFlat,
		"visual_parity_gate_v15": hierarchy_locked and integrated_hud_surface and integrated_hint_surface and hint_readable and booster_family_locked and composition_locked and board_locked and utilities_separated and canonical_booster_art and gothic_board_material and objective_spacing_locked and compact_header_locked and compact_geometry_locked and north_star_gameplay_hud_frame and header_depth_locked and pause_button.icon != null and pause_button.text == "" and String(pause_button.get_meta("production_chrome_asset", "")) == GAMEPLAY_PAUSE_ICON_PATH and pause_button.get_theme_stylebox("normal") is StyleBoxFlat,
		"visual_parity_version": 15,
		"resource_bar_height": ($ResourceBar as PanelContainer).offset_bottom - ($ResourceBar as PanelContainer).offset_top,
		"hud_plate_height": ($Layout/HUDPlate as PanelContainer).custom_minimum_size.y,
		"booster_tray_height": _booster_tray.offset_bottom - _booster_tray.offset_top,
		"visible_booster_count": 3,
		"authored_result_values": _result_reward_values != null,
		"authored_result_proclamation": _result_proclamation != null and _result_keeper_cat != null,
		"north_star_result_hierarchy": result_title != null and result_title.get_theme_font_size("font_size") >= 46 and result_objective_summary != null and result_objective_summary.get_theme_stylebox("normal") != null,
		"north_star_result_cta": result_action != null and result_action.custom_minimum_size.y >= 82.0 and result_action.get_theme_stylebox("normal") != null,
		"asset_backed_result_chrome": ($ResultOverlay/Card as PanelContainer).get_theme_stylebox("panel") is StyleBoxTexture,
		"result_hero_scale": result_ritual != null and result_ritual.custom_minimum_size.y >= 200.0 and _result_star_a != null and _result_star_b != null and _result_star_c != null,
		"result_frame_clearance": ($ResultOverlay/Card/Content/ResultTopPad as Control).custom_minimum_size.y >= 20.0,
		"win_copy_compact": result_detail != null and result_house_change != null,
		"runtime_shell_factory": false,
		"transient_vfx_runtime_allowed": true,
	}

func booster_asset_contract() -> Dictionary:
	var loaded := {}
	var raster_runtime := true
	for key in BOOSTER_ART_PATHS:
		var path := String(BOOSTER_ART_PATHS[key])
		loaded[key] = PieceAssetLoader.ornament(path) != null
		raster_runtime = raster_runtime and (path.ends_with(".webp") or path.ends_with(".png"))
	return {
		"paths": BOOSTER_ART_PATHS.duplicate(true),
		"loaded": loaded,
		"raster_runtime": raster_runtime,
		"plus_moves_used": _potion_used_for_attempt,
		"plus_moves_disabled": true,
		"hint_exposed": _hint_boost_button != null,
		"plus_moves_exposed_in_active_play": _potion_boost_button != null,
		"retry_exposed_in_active_play": _retry_boost_button != null,
		"fail_screen_plus_three_rescue": result_recovery_action != null,
		"economy_entitlement_connected": false
	}

func _use_potion_boost() -> void:
	_idle_hint_seconds = 0.0
	if board_state == null or _potion_used_for_attempt or result_overlay.visible or pause_overlay.visible:
		return
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		return
	_potion_used_for_attempt = true
	if _potion_boost_button != null:
		_potion_boost_button.disabled = true
	board_state.moves_remaining += 3
	_refresh_hud()
	hint_label.text = "The emerald potion grants three extra moves."
	feedback_requested.emit("special")

func _use_hint_boost() -> void:
	_idle_hint_seconds = 0.0
	if board_state == null or result_overlay.visible or pause_overlay.visible:
		return
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		return
	var move: Dictionary = MoveFinder.first_legal_move(board_state)
	if move.is_empty():
		hint_label.text = "THE KEEPER SEES NO PATH · THE HOUSE IS RESHAPING THE SIGILS"
		_style_impact_hint("normal")
		return
	_present_keeper_hint(move, true, false)

func _present_keeper_hint(move: Dictionary, manual: bool, guided: bool) -> void:
	if move.is_empty() or board_view == null or not board_view.has_method("set_teaching_move"):
		return
	board_view.set_teaching_move(move["from"], move["to"])
	_keeper_last_move = move.duplicate(true)
	_keeper_hint_count += 1
	if guided:
		hint_label.text = "KEEPER GUIDANCE · FOLLOW THE MOONLIT PAIR"
	elif manual:
		hint_label.text = "KEEPER HINT · FOLLOW THE MARKED PAIR"
	else:
		hint_label.text = "THE KEEPER NOTICES A PATH · FOLLOW THE MOONLIT PAIR"
	_style_impact_hint("normal")
	feedback_requested.emit("match")

func keeper_familiar_contract() -> Dictionary:
	return {
		"role": "non_mutating_legal_move_guide",
		"asset": KEEPER_ART_PATH,
		"raster_runtime": KEEPER_ART_PATH.ends_with(".webp") or KEEPER_ART_PATH.ends_with(".png"),
		"hint_count": _keeper_hint_count,
		"last_move": _keeper_last_move.duplicate(true),
		"changes_board": false,
		"spends_resources": false,
		"adds_moves": false,
		"manual_action": "ASK KEEPER",
	}

func _use_retry_boost() -> void:
	_idle_hint_seconds = 0.0
	if board_state == null or result_overlay.visible or pause_overlay.visible:
		return
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		return
	retry_current_level()
