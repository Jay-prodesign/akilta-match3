class_name Match3GameplayScreen
extends Control

signal level_won(level_id: String, curio_id: String, house_stage_reward: int)

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")
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

@onready var eyebrow_label: Label = $Layout/Eyebrow
@onready var title_label: Label = $Layout/Title
@onready var board_view = $Layout/BoardView
@onready var objective_label: Label = $Layout/HUD/Objective
@onready var moves_label: Label = $Layout/HUD/Moves
@onready var hint_label: Label = $Layout/Hint
@onready var result_overlay: Control = $ResultOverlay
@onready var result_title: Label = $ResultOverlay/Card/Content/Title
@onready var result_detail: Label = $ResultOverlay/Card/Content/Detail
@onready var result_action: Button = $ResultOverlay/Card/Content/Action

func _ready() -> void:
	_install_candidate_divider()
	if board_view.has_signal("swap_requested"):
		board_view.swap_requested.connect(_on_swap_requested)
	if board_view.has_signal("trace_motion_finished"):
		board_view.trace_motion_finished.connect(_on_board_trace_motion_finished)
	result_action.pressed.connect(_on_result_action_pressed)
	result_overlay.visible = false
	if FileAccess.file_exists(default_level_path):
		load_level_path(default_level_path, default_seed)

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
	_pending_win = false
	_pending_terminal_result = ""
	result_overlay.visible = false
	_refresh_hud()
	return true

func attempt_swap(from: Vector2i, to: Vector2i):
	if board_state == null or result_overlay.visible:
		return null
	if board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		return null
	last_trace = MoveResolver.try_swap(board_state, from, to)
	board_view.set_board(board_state)
	var motion_started := false
	if board_view.has_method("play_trace"):
		motion_started = bool(board_view.play_trace(last_trace))
	_refresh_hud()
	_refresh_move_feedback(last_trace)
	if last_trace.accepted:
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
		_pending_win = true
		result_title.text = current_win_title
		result_detail.text = current_win_detail
		result_action.text = "RETURN TO THE HOUSE"
		result_overlay.visible = true
	elif result == "failed":
		_pending_win = false
		result_title.text = "THE ROOM WAITS"
		result_detail.text = "The House keeps its secrets. Try another arrangement."
		result_action.text = "TRY AGAIN"
		result_overlay.visible = true

func _on_result_action_pressed() -> void:
	if _pending_win:
		continue_after_win()
	else:
		retry_current_level()


func _on_board_trace_motion_finished() -> void:
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
