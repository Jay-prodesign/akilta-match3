class_name Match3ChapterMap
extends Control

signal back_requested
signal level_requested(level_number: int)

@export var canonical_level_cap: int = 1
@export var visible_route_levels: int = 10

@onready var chapter_progress: Label = $Layout/Progress
@onready var scroll: ScrollContainer = $Layout/RoutePanel/Scroll
@onready var route_view: Control = $Layout/RoutePanel/Scroll/RouteView
@onready var back_button: Button = $Layout/Back

var progress

func _ready() -> void:
	back_button.pressed.connect(func(): back_requested.emit())
	route_view.level_requested.connect(func(level_number: int): level_requested.emit(level_number))
	route_view.visible_route_levels = visible_route_levels
	route_view.set_canonical_level_cap(canonical_level_cap)
	_refresh()
	call_deferred("_focus_frontier")

func set_progress(value) -> void:
	progress = value
	_refresh()
	call_deferred("_focus_frontier")

func get_level_button(level_number: int) -> Button:
	if route_view == null or not route_view.has_method("get_level_button"):
		return null
	return route_view.get_level_button(level_number)

func _refresh() -> void:
	if not is_node_ready():
		return
	var completed: int = int(progress.completed_levels.size()) if progress != null else 0
	chapter_progress.text = "CURIO BOUTIQUE · %d AWAKENING%s" % [completed, "" if completed == 1 else "S"]
	route_view.set_progress(progress)

func _focus_frontier() -> void:
	if scroll == null or route_view == null:
		return
	var target: Button = get_level_button(1)
	if target != null:
		scroll.ensure_control_visible(target)
