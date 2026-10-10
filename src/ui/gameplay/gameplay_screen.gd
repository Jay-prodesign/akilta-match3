class_name Match3GameplayScreen
extends Control

signal level_won(level_id: String, curio_id: String, house_stage_reward: int)
signal level_exit_requested
signal feedback_requested(kind: String)

const BoardState = preload("res://src/match3/domain/board_state.gd")
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
var current_win_title: String = "THE CABINET STIRS"
var current_win_detail: String = "Something in the Curio Boutique has awakened."
var _pending_win: bool = false
var _pending_terminal_result: String = ""
var _pending_hud_refresh: bool = false
var haptics = HapticsController.new()

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
	_install_candidate_divider()
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
	current_level_id = String(parsed.get("id", ""))
	current_reward_curio = String(parsed.get("reward_curio", ""))
	current_house_stage_reward = int(parsed.get("house_stage_reward", 0))
	current_win_title = String(parsed.get("win_title", "THE CABINET STIRS"))
	current_win_detail = String(parsed.get("win_detail", "Something in the Curio Boutique has awakened."))
	eyebrow_label.text = String(parsed.get("eyebrow", "CURIO BOUTIQUE"))
	title_label.text = String(parsed.get("title", "Hidden Display"))
	hint_label.text = String(parsed.get("hint", "Swipe a sigil."))
	board_state = BoardState.from_level(parsed, seed_value)
	board_view.set_board(board_state)
	_configure_teaching_move(parsed)
	_pending_win = false
	_pending_terminal_result = ""
	_pending_hud_refresh = false
	pause_overlay.visible = false
	result_overlay.visible = false
	if result_ritual != null:
		result_ritual.set("mode", "result")
		result_ritual.set("glow_strength", 0.75)
		result_ritual.queue_redraw()
	_refresh_hud()
	return true

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
	return true

func resume_level() -> bool:
	if not pause_overlay.visible:
		return false
	pause_overlay.visible = false
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
	if awakening_view != null and awakening_view.has_method("set_objective"):
		awakening_view.set_objective(
			int(board_state.objective_progress),
			int(board_state.objective_target),
			String(board_state.objective_family)
		)
	if awakening_copy != null:
		var remaining := maxi(0, int(board_state.objective_target) - int(board_state.objective_progress))
		awakening_copy.text = "%d / %d SIGILS · %s" % [
			int(board_state.objective_progress),
			int(board_state.objective_target),
			"THE MOON CAMEO WAKES" if remaining == 0 else "%d REMAIN" % remaining
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
		if result_ritual != null:
			result_ritual.set("mode", "result")
			result_ritual.set("glow_strength", 0.75)
			result_ritual.queue_redraw()
		result_action.text = "RETURN TO THE HOUSE"
		result_overlay.visible = true
	elif result == "failed":
		haptics.request_terminal("failed")
		feedback_requested.emit("fail")
		_pending_win = false
		result_title.text = "THE ROOM WAITS"
		result_detail.text = "The House keeps its secrets. Try another arrangement."
		if result_ritual != null:
			result_ritual.set("mode", "fail")
			result_ritual.set("glow_strength", 0.12)
			result_ritual.queue_redraw()
		result_action.text = "TRY AGAIN"
		result_overlay.visible = true

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

