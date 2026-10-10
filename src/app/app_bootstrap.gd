class_name AppBootstrap
extends Node

const ProgressScript = preload("res://src/progression/player_progress.gd")
const SaveStoreScript = preload("res://src/save/save_store.gd")
const GameplayScene = preload("res://src/ui/gameplay/gameplay_screen.tscn")
const HouseScene = preload("res://src/ui/home/house_home.tscn")

@export var environment: String = "development"
@export var save_path_override: String = ""

var progress
var _store
var _current_screen: Node
var _route_name: String = ""

@onready var screen_host: Node = $ScreenHost

func _ready() -> void:
	var path: String = save_path_override if save_path_override != "" else SaveStoreScript.DEFAULT_PATH
	_store = SaveStoreScript.new(path)
	progress = ProgressScript.from_dict(_store.load_or_default())
	if progress.house_stage > 0:
		show_house()
	else:
		start_level(1)

func current_route_name() -> String:
	return _route_name

func start_level(level_number: int = 1) -> void:
	var screen = GameplayScene.instantiate()
	_show_screen(screen, "gameplay")
	if screen.has_signal("level_won"):
		screen.level_won.connect(_on_level_won)

func complete_level_win(transaction_id: String, level_id: String, curio_id: String = "moon_cameo") -> bool:
	if progress == null:
		progress = ProgressScript.new()
	var applied: bool = bool(progress.apply_level_win(transaction_id, level_id, curio_id))
	if not applied:
		return false
	if _store == null:
		var path: String = save_path_override if save_path_override != "" else SaveStoreScript.DEFAULT_PATH
		_store = SaveStoreScript.new(path)
	if not _store.save(progress.to_dict()):
		return false
	show_house()
	return true

func show_house() -> void:
	var screen = HouseScene.instantiate()
	_show_screen(screen, "house")
	if screen.has_method("set_progress"):
		screen.set_progress(progress)
	if screen.has_signal("play_requested"):
		screen.play_requested.connect(start_level)

func _on_level_won(level_id: String) -> void:
	var transaction_id := "win:%s:%d" % [level_id, progress.processed_transactions.size() + 1]
	complete_level_win(transaction_id, level_id, "moon_cameo")

func _show_screen(screen: Node, route: String) -> void:
	if _current_screen != null and is_instance_valid(_current_screen):
		screen_host.remove_child(_current_screen)
		_current_screen.queue_free()
	_current_screen = screen
	screen_host.add_child(screen)
	_route_name = route
