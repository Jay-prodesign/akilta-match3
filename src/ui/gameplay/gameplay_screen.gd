class_name Match3GameplayScreen
extends Control

const BoardState = preload("res://src/match3/domain/board_state.gd")
const MoveResolver = preload("res://src/match3/domain/move_resolver.gd")

@export var default_level_path := "res://content/levels/ch01/level_001.json"
@export var default_seed := 1001

var board_state
var last_trace

@onready var board_view = $Layout/BoardView
@onready var objective_label: Label = $Layout/HUD/Objective
@onready var moves_label: Label = $Layout/HUD/Moves
@onready var result_overlay: Control = $ResultOverlay
@onready var result_title: Label = $ResultOverlay/Card/Title
@onready var result_detail: Label = $ResultOverlay/Card/Detail

func _ready() -> void:
	if board_view.has_signal("swap_requested"):
		board_view.swap_requested.connect(_on_swap_requested)
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
	board_state = BoardState.from_level(parsed, seed_value)
	board_view.set_board(board_state)
	result_overlay.visible = false
	_refresh_hud()
	return true

func attempt_swap(from: Vector2i, to: Vector2i):
	if board_state == null:
		return null
	last_trace = MoveResolver.try_swap(board_state, from, to)
	board_view.set_board(board_state)
	_refresh_hud()
	if last_trace.accepted:
		_show_result_if_terminal(String(last_trace.result))
	return last_trace

func _on_swap_requested(from: Vector2i, to: Vector2i) -> void:
	attempt_swap(from, to)

func _refresh_hud() -> void:
	if board_state == null:
		objective_label.text = "Awaken the collection"
		moves_label.text = "—"
		return
	moves_label.text = "%d moves" % int(board_state.moves_remaining)
	if String(board_state.objective_type) == "collect_family":
		objective_label.text = "Gather moon sigils  %d/%d" % [
			int(board_state.objective_progress),
			int(board_state.objective_target)
		]
	elif String(board_state.objective_type) == "clear_blockers":
		objective_label.text = "Break the seals  %d left" % int(board_state.remaining_blockers())
	else:
		objective_label.text = "Awaken the collection"

func _show_result_if_terminal(result: String) -> void:
	if result == "won":
		result_title.text = "THE CABINET STIRS"
		result_detail.text = "Something in the Curio Boutique has awakened."
		result_overlay.visible = true
	elif result == "failed":
		result_title.text = "THE ROOM WAITS"
		result_detail.text = "The House keeps its secrets. Try another arrangement."
		result_overlay.visible = true
