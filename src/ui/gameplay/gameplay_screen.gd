class_name Match3GameplayScreen
extends Control

signal level_won(level_id: String, curio_id: String, house_stage_reward: int)
signal level_exit_requested
signal feedback_requested(kind: String)
signal navigation_requested(section: String)

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MoveFinder = preload("res://src/match3/domain/move_finder.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")
const HapticsController = preload("res://src/feedback/haptics_controller.gd")
const KENNEY_DIVIDER_PATH := "res://assets/candidate/third_party/kenney/fantasy-ui-borders/divider-004.png"

@export var default_level_path := "res://content/levels/ch01/level_001.json"
@export var default_seed := 1001

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
var current_win_title: String = "THE CABINET STIRS"
var current_win_detail: String = "Something in the Curio Boutique has awakened."
var current_retry_hint: String = ""
var _pending_win: bool = false
var _pending_terminal_result: String = ""
var _pending_hud_refresh: bool = false
var haptics = HapticsController.new()
var _potion_used_for_attempt := false
var _level_badge_label: Label
var _booster_tray: PanelContainer

@onready var world_backdrop: TextureRect = $WorldBackdrop
@onready var eyebrow_label: Label = $Layout/Eyebrow
@onready var title_label: Label = $Layout/Title
@onready var board_view = $Layout/BoardView
@onready var objective_label: Label = $Layout/HUD/Objective
@onready var moves_label: Label = $Layout/HUD/Moves
@onready var pause_button: Button = $Layout/HUD/Pause
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_resume: Button = $PauseOverlay/Card/Content/Resume
@onready var pause_retry: Button = $PauseOverlay/Card/Content/Retry
@onready var pause_exit: Button = $PauseOverlay/Card/Content/Exit
@onready var hint_label: Label = $Layout/Hint
@onready var awakening_title: Label = $Layout/Awakening/Content/Label
@onready var awakening_view: Control = $Layout/Awakening/Content/ProgressView
@onready var awakening_copy: Label = $Layout/Awakening/Content/ProgressCopy
@onready var result_overlay: Control = $ResultOverlay
@onready var result_title: Label = $ResultOverlay/Card/Content/Title
@onready var result_detail: Label = $ResultOverlay/Card/Content/Detail
@onready var result_eyebrow: Label = $ResultOverlay/Card/Content/Eyebrow
@onready var result_reward_name: Label = $ResultOverlay/Card/Content/RewardName
@onready var result_house_change: Label = $ResultOverlay/Card/Content/HouseChange
@onready var result_ritual: Control = $ResultOverlay/Card/Content/RewardRitual
@onready var result_action: Button = $ResultOverlay/Card/Content/Action

func _ready() -> void:
	world_backdrop.texture = PieceAssetLoader.ornament("res://assets/world/ch01_curio_boutique/curio_boutique_moonlit_backdrop.svg")
	_install_candidate_divider()
	_build_top_resource_bar()
	_build_booster_tray()
	_build_bottom_navigation()
	if board_view.has_signal("swap_requested"):
		board_view.swap_requested.connect(_on_swap_requested)
	if board_view.has_signal("trace_motion_finished"):
		board_view.trace_motion_finished.connect(_on_board_trace_motion_finished)
	result_action.pressed.connect(_on_result_action_pressed)
	pause_button.pressed.connect(show_pause)
	pause_resume.pressed.connect(resume_level)
	pause_retry.pressed.connect(_on_pause_retry)
	pause_exit.pressed.connect(_on_pause_exit)
	pause_overlay.visible = false
	result_overlay.visible = false
	if FileAccess.file_exists(default_level_path):
		load_level_path(default_level_path, default_seed)

func apply_presentation_settings(state: Dictionary) -> void:
	if board_view != null and board_view.has_method("apply_presentation_settings"):
		board_view.apply_presentation_settings(state)
	haptics.apply_settings(state)

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
	current_level_id = String(parsed.get("id", ""))
	_update_level_badge()
	current_reward_curio = String(parsed.get("reward_curio", ""))
	current_house_stage_reward = int(parsed.get("house_stage_reward", 0))
	current_objective_type = String(parsed.get("objective", "collect_family"))
	current_objective_family = String(parsed.get("objective_family", "moon"))
	current_objective_target = int(parsed.get("objective_target", 1))
	var blockers_data: Variant = parsed.get("blockers", [])
	current_initial_blocker_count = blockers_data.size() if blockers_data is Array else 0
	current_win_title = String(parsed.get("win_title", "THE CABINET STIRS"))
	current_win_detail = String(parsed.get("win_detail", "Something in the Curio Boutique has awakened."))
	current_retry_hint = String(parsed.get("retry_hint", ""))
	eyebrow_label.text = String(parsed.get("eyebrow", "CURIO BOUTIQUE"))
	title_label.text = String(parsed.get("title", "Hidden Display"))
	hint_label.text = String(parsed.get("hint", "Swipe a sigil."))
	var art_profile := String(parsed.get("visual_profile", "curio_boutique_opening"))
	_apply_level_art_profile(art_profile)
	board_state = BoardState.from_level(parsed, seed_value)
	if board_view.has_method("set_visual_profile"):
		board_view.set_visual_profile(art_profile)
	board_view.set_board(board_state)
	_configure_teaching_move(parsed)
	_pending_win = false
	_pending_terminal_result = ""
	_pending_hud_refresh = false
	pause_overlay.visible = false
	result_overlay.visible = false
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
	_level_badge_label.text = "◇ LEVEL %d" % level_number

func _apply_level_art_profile(profile: String) -> void:
	# The board symbols, room tint, and heading accents move together by chapter beat.
	match profile:
		"sealed_display":
			world_backdrop.modulate = Color(0.76, 0.86, 0.96, 0.36)
			eyebrow_label.add_theme_color_override("font_color", Color("#9fb7d0"))
			title_label.add_theme_color_override("font_color", Color("#f1e6d2"))
			objective_label.add_theme_color_override("font_color", Color("#a8c6d2"))
			moves_label.add_theme_color_override("font_color", Color("#d8c8a1"))
		"thornlight_arrangement":
			world_backdrop.modulate = Color(0.98, 0.72, 0.82, 0.36)
			eyebrow_label.add_theme_color_override("font_color", Color("#d9a0b8"))
			title_label.add_theme_color_override("font_color", Color("#f5e6e2"))
			objective_label.add_theme_color_override("font_color", Color("#c7a0df"))
			moves_label.add_theme_color_override("font_color", Color("#e6bd83"))
		_:
			world_backdrop.modulate = Color(0.92, 0.82, 0.78, 0.34)
			eyebrow_label.add_theme_color_override("font_color", Color("#b7a5b8"))
			title_label.add_theme_color_override("font_color", Color("#f1e8dc"))
			objective_label.add_theme_color_override("font_color", Color("#bca1cf"))
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
	if board_state == null or result_overlay.visible or pause_overlay.visible:
		return false
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		return false
	pause_overlay.visible = true
	if _booster_tray != null:
		_booster_tray.visible = false
	return true

func resume_level() -> bool:
	if not pause_overlay.visible:
		return false
	pause_overlay.visible = false
	if _booster_tray != null:
		_booster_tray.visible = true
	return true

func _on_pause_retry() -> void:
	if not pause_overlay.visible:
		return
	pause_overlay.visible = false
	retry_current_level()

func _on_pause_exit() -> void:
	if not pause_overlay.visible:
		return
	pause_overlay.visible = false
	level_exit_requested.emit()

func attempt_swap(from: Vector2i, to: Vector2i):
	if board_state == null or result_overlay.visible or pause_overlay.visible:
		return null
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		return null
	if board_view.has_method("snapshot_before_move"):
		board_view.snapshot_before_move()
	last_trace = MoveResolver.try_swap(board_state, from, to)
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
	_refresh_move_feedback(last_trace)
	if last_trace.accepted:
		if board_view.has_method("clear_teaching_move"):
			board_view.clear_teaching_move()
		var feedback_types: Array[String] = last_trace.event_types()
		if feedback_types.has("combo_triggered") or feedback_types.has("special_triggered") or feedback_types.has("special_created"):
			haptics.request_special()
			feedback_requested.emit("special")
		else:
			haptics.request_match()
			feedback_requested.emit("match")
		var terminal_result := String(last_trace.result)
		if terminal_result == "won" or terminal_result == "failed":
			if motion_started:
				_pending_terminal_result = terminal_result
			else:
				_show_result_if_terminal(terminal_result)
	return last_trace

func continue_after_win() -> bool:
	if not _pending_win:
		return false
	_pending_win = false
	level_won.emit(current_level_id, current_reward_curio, current_house_stage_reward)
	return true

func retry_current_level() -> bool:
	if current_level_path == "":
		return false
	haptics.reset_for_new_attempt()
	feedback_requested.emit("retry")
	return load_level_path(current_level_path, current_seed)

func _on_swap_requested(from: Vector2i, to: Vector2i) -> void:
	attempt_swap(from, to)

func _refresh_move_feedback(trace) -> void:
	if trace == null:
		return
	var types: Array[String] = trace.event_types()
	if types.has("combo_triggered"):
		hint_label.text = "The relics answer together. The whole cabinet shudders."
	elif types.has("special_created"):
		hint_label.text = "A Moon Beam formed. Match it to unleash the whole row."
	elif types.has("special_triggered"):
		hint_label.text = "The sigil opens. Follow the chain reaction."
	elif types.has("shuffle"):
		hint_label.text = "No path remained. The House rearranged the sigils."
	elif not bool(trace.accepted):
		hint_label.text = "Those sigils refuse the arrangement. Try another adjacent swap."

func _refresh_hud() -> void:
	if board_state == null:
		objective_label.text = "Awaken the collection"
		moves_label.text = "—"
		return
	moves_label.text = "%d moves" % int(board_state.moves_remaining)
	var progress_value := int(board_state.objective_progress)
	var target_value := int(board_state.objective_target)
	var progress_family := String(board_state.objective_family)
	var progress_unit := "SIGILS"
	if String(board_state.objective_type) == "clear_blockers":
		progress_value = maxi(0, current_initial_blocker_count - int(board_state.remaining_blockers()))
		target_value = maxi(1, current_initial_blocker_count)
		progress_family = "wax_seal"
		progress_unit = "SEALS"
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
		objective_label.text = "Gather %s sigils  %d/%d" % [
			family_label,
			int(board_state.objective_progress),
			int(board_state.objective_target)
		]
	elif String(board_state.objective_type) == "clear_blockers":
		objective_label.text = "Break the wax seals  %d left" % int(board_state.remaining_blockers())
	else:
		objective_label.text = "Awaken the collection"

func _show_result_if_terminal(result: String) -> void:
	if result == "won":
		haptics.request_terminal("won")
		feedback_requested.emit("win")
		_pending_win = true
		result_title.text = current_win_title
		result_detail.text = current_win_detail
		_configure_result_reward_copy(true)
		if result_ritual != null:
			result_ritual.set("mode", "result")
			result_ritual.set("relic_id", current_reward_curio)
			result_ritual.set("glow_strength", 0.75)
			result_ritual.queue_redraw()
		result_action.text = "RETURN TO THE HOUSE"
		if _booster_tray != null:
			_booster_tray.visible = false
		result_overlay.visible = true
	elif result == "failed":
		haptics.request_terminal("failed")
		feedback_requested.emit("fail")
		_pending_win = false
		result_title.text = "THE ROOM WAITS"
		result_detail.text = "The House keeps its secrets. %s" % current_retry_hint if current_retry_hint != "" else "The House keeps its secrets. Try another arrangement."
		_configure_result_reward_copy(false)
		if result_ritual != null:
			result_ritual.set("mode", "fail")
			result_ritual.set("relic_id", current_reward_curio)
			result_ritual.set("glow_strength", 0.12)
			result_ritual.queue_redraw()
		result_action.text = "TRY AGAIN"
		if _booster_tray != null:
			_booster_tray.visible = false
		result_overlay.visible = true

func _configure_result_reward_copy(won: bool) -> void:
	var reward_name := current_reward_curio.replace("_", " ").to_upper()
	if reward_name == "":
		reward_name = "HIDDEN CURIO"
	if won:
		var relic_number := maxi(1, current_house_stage_reward)
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
	if _pending_terminal_result == "":
		return
	var result := _pending_terminal_result
	_pending_terminal_result = ""
	_show_result_if_terminal(result)


func _install_candidate_divider() -> void:
	var layout := get_node_or_null("Layout")
	if layout == null or layout.get_node_or_null("TitleDivider") != null:
		return
	if not FileAccess.file_exists(KENNEY_DIVIDER_PATH):
		return
	var image := Image.load_from_file(KENNEY_DIVIDER_PATH)
	if image == null or image.is_empty():
		return
	var divider := TextureRect.new()
	divider.name = "TitleDivider"
	divider.custom_minimum_size = Vector2(0, 16)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.modulate = Color(0.851, 0.71, 0.416, 0.52)
	divider.texture = ImageTexture.create_from_image(image)
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_SCALE
	layout.add_child(divider)
	layout.move_child(divider, min(2, layout.get_child_count() - 1))


func _build_bottom_navigation() -> void:
	var panel := PanelContainer.new()
	panel.name = "BottomNavigation"
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 14.0
	panel.offset_right = -14.0
	panel.offset_top = -66.0
	panel.offset_bottom = -8.0
	panel.z_index = 20
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B0D17")
	style.border_color = Color("#D5AD70", 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var nav_scroll := ScrollContainer.new()
	nav_scroll.name = "NavigationScroll"
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nav_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(nav_scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_scroll.add_child(row)
	for item in [{"label":"⌂ HOUSE","id":"house"},{"label":"✦ CURIOS","id":"curios"},{"label":"☾ MAP","id":"map"},{"label":"✧ EVENTS","id":"events"},{"label":"◇ SHOP","id":"shop"},{"label":"♙ PROFILE","id":"profile"}]:
		var button := Button.new()
		button.text = String(item["label"])
		button.custom_minimum_size = Vector2(0, 46)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", Color("#F4E5D3"))
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("#251529")
		button_style.border_color = Color("#D5AD70", 0.32)
		button_style.set_border_width_all(1)
		button_style.set_corner_radius_all(6)
		button.add_theme_stylebox_override("normal", button_style)
		button.add_theme_stylebox_override("hover", button_style)
		button.pressed.connect(func(): navigation_requested.emit(String(item["id"])))
		row.add_child(button)

func _build_top_resource_bar() -> void:
	var panel := PanelContainer.new()
	panel.name = "ResourceBar"
	panel.anchor_left = 0.04
	panel.anchor_right = 0.96
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_top = 6.0
	panel.offset_bottom = 46.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B0D17", 0.94)
	style.border_color = Color("#D5AD70", 0.68)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var row := HBoxContainer.new()
	row.name = "Resources"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	for value in ["☾ CURIO BOUTIQUE", "✦ CHAPTER ONE", "◇ LEVEL 1"]:
		var label := Label.new()
		label.text = value
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#F4E5D3"))
		label.add_theme_font_size_override("font_size", 14)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if value.begins_with("◇"):
			label.name = "LevelBadge"
			_level_badge_label = label
		row.add_child(label)

func _build_booster_tray() -> void:
	var panel := PanelContainer.new()
	panel.name = "BoosterTray"
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -124.0
	panel.offset_bottom = -72.0
	panel.z_index = 18
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#101320", 0.97)
	shell.border_color = Color("#D5AD70", 0.72)
	shell.set_border_width_all(1)
	shell.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", shell)
	add_child(panel)
	_booster_tray = panel
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	_add_booster_button(row, "☾ HINT", "res://assets/pieces/moon_sigil.svg", _use_hint_boost)
	_add_booster_button(row, "⚗ +3 MOVES", "res://assets/pieces/potion.svg", _use_potion_boost)
	_add_booster_button(row, "✦ RETRY", "res://assets/pieces/skull.svg", _use_retry_boost)

func _add_booster_button(parent: HBoxContainer, caption: String, art_path: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("#F4E5D3"))
	button.icon = PieceAssetLoader.ornament(art_path)
	button.expand_icon = true
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#251529")
	box.border_color = Color("#D5AD70", 0.38)
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", box)
	button.pressed.connect(action)
	parent.add_child(button)

func _use_potion_boost() -> void:
	if board_state == null or _potion_used_for_attempt or result_overlay.visible or pause_overlay.visible:
		return
	_potion_used_for_attempt = true
	board_state.moves_remaining += 3
	_refresh_hud()
	hint_label.text = "The emerald potion grants three extra moves."
	feedback_requested.emit("special")

func _use_hint_boost() -> void:
	if board_state == null or result_overlay.visible or pause_overlay.visible:
		return
	var move: Dictionary = MoveFinder.first_legal_move(board_state)
	if move.is_empty():
		hint_label.text = "The House is reshaping the sigils. Try a different line."
		return
	board_view.set_teaching_move(move["from"], move["to"])
	hint_label.text = "Follow the moonlit highlight for a legal match."
	feedback_requested.emit("match")

func _use_retry_boost() -> void:
	if board_state == null or result_overlay.visible or pause_overlay.visible:
		return
	retry_current_level()
