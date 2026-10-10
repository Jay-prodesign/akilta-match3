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

func current_screen() -> Node:
	return _current_screen

func start_level(level_number: int = 1) -> bool:
	var level_path: String = _level_path(level_number)
	if not FileAccess.file_exists(level_path):
		return false
	var screen: Node = GameplayScene.instantiate()
	screen.set("default_level_path", level_path)
	screen.set("default_seed", 1000 + level_number)
	_show_screen(screen, "gameplay")
	if screen.has_signal("level_won"):
		screen.level_won.connect(_on_level_won)
	return true

func complete_level_win(transaction_id: String, level_id: String, curio_id: String = "moon_cameo", house_stage_reward: int = -1) -> bool:
	if progress == null:
		progress = ProgressScript.new()
	var candidate = ProgressScript.from_dict(progress.to_dict())
	var applied: bool = bool(candidate.apply_level_win(transaction_id, level_id, curio_id, house_stage_reward))
	if not applied:
		return false
	if _store == null:
		var path: String = save_path_override if save_path_override != "" else SaveStoreScript.DEFAULT_PATH
		_store = SaveStoreScript.new(path)
	if not _store.save(candidate.to_dict()):
		return false
	progress = candidate
	show_house()
	return true

func show_house() -> void:
	var screen: Node = HouseScene.instantiate()
	_show_screen(screen, "house")
	if screen.has_method("set_available_level_count"):
		screen.set_available_level_count(_available_level_count())
	if screen.has_method("set_progress"):
		screen.set_progress(progress)
	if screen.has_signal("play_requested"):
		screen.play_requested.connect(start_level)

func _on_level_won(level_id: String, curio_id: String, house_stage_reward: int) -> void:
	var transaction_id := "win:%s:%d" % [level_id, progress.processed_transactions.size() + 1]
	complete_level_win(transaction_id, level_id, curio_id, house_stage_reward)

func _level_path(level_number: int) -> String:
	return "res://content/levels/ch01/level_%03d.json" % level_number

func _available_level_count() -> int:
	var count := 0
	while FileAccess.file_exists(_level_path(count + 1)):
		count += 1
	return count

func _show_screen(screen: Node, route: String) -> void:
	if _current_screen != null and is_instance_valid(_current_screen):
		screen_host.remove_child(_current_screen)
		_current_screen.queue_free()
	_current_screen = screen
	screen_host.add_child(screen)
	_route_name = route
