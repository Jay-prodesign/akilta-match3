class_name Match3ChapterMap
extends Control

signal back_requested
signal level_requested(level_number: int)

@export var canonical_level_cap: int = 1

@onready var chapter_progress: Label = $Layout/Progress
@onready var level1_button: Button = $Layout/RoutePanel/Route/Level1
@onready var level2_button: Button = $Layout/RoutePanel/Route/Level2
@onready var level3_button: Button = $Layout/RoutePanel/Route/Level3
@onready var back_button: Button = $Layout/Back

var progress

func _ready() -> void:
	level1_button.pressed.connect(func(): _request_level(1))
	level2_button.pressed.connect(func(): _request_level(2))
	level3_button.pressed.connect(func(): _request_level(3))
	back_button.pressed.connect(func(): back_requested.emit())
	_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	var completed: int = int(progress.completed_levels.size()) if progress != null else 0
	chapter_progress.text = "CURIO BOUTIQUE · %d AWAKENING%s" % [completed, "" if completed == 1 else "S"]
	_configure_button(level1_button, 1)
	_configure_button(level2_button, 2)
	_configure_button(level3_button, 3)

func _configure_button(button: Button, level_number: int) -> void:
	var level_id := "ch01_level_%03d" % level_number
	var completed: bool = progress != null and progress.completed_levels.has(level_id)
	var within_gate: bool = level_number <= canonical_level_cap
	button.disabled = not within_gate
	if completed:
		button.text = "LEVEL %d · AWAKENED" % level_number
	elif within_gate:
		button.text = "LEVEL %d · ENTER" % level_number
	else:
		button.text = "LEVEL %d · SEALED" % level_number

func _request_level(level_number: int) -> void:
	if level_number <= canonical_level_cap:
		level_requested.emit(level_number)
