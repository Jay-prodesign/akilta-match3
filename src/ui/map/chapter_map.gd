class_name Match3ChapterMap
extends Control

signal back_requested
signal level_requested(level_number: int)

@export var canonical_level_cap: int = 1

@onready var chapter_progress: Label = $Layout/Progress
@onready var route_view: Control = $Layout/RoutePanel/RouteView
@onready var back_button: Button = $Layout/Back

var progress

func _ready() -> void:
	back_button.pressed.connect(func(): back_requested.emit())
	route_view.level_requested.connect(func(level_number: int): level_requested.emit(level_number))
	route_view.set_canonical_level_cap(canonical_level_cap)
	_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	var completed: int = int(progress.completed_levels.size()) if progress != null else 0
	chapter_progress.text = "CURIO BOUTIQUE · %d AWAKENING%s" % [completed, "" if completed == 1 else "S"]
	route_view.set_progress(progress)
