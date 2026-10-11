class_name Match3ChapterMap
extends Control

signal back_requested
signal level_requested(level_number: int)

@export var canonical_level_cap: int = 1
@export var visible_route_levels: int = 10

@onready var chapter_progress: Label = $Layout/Progress
@onready var intro: Label = $Layout/Intro
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
	var awakened := mini(completed, canonical_level_cap)
	chapter_progress.text = "CURIO BOUTIQUE  ·  %d / %d DISPLAYS AWAKENED" % [awakened, canonical_level_cap]
	if intro != null:
		if canonical_level_cap > 0 and awakened >= canonical_level_cap:
			intro.text = "The opening cabinet set is restored. Revisit any awakened ritual while the upper cabinets remain sealed."
		elif awakened > 0:
			intro.text = "%d of %d displays are awake. The next cabinet has opened; continue the Curio Boutique ritual." % [awakened, canonical_level_cap]
		else:
			intro.text = "Complete the opening three rituals to restore the first cabinet set. Upper cabinets remain visible but sealed for later journeys."
	route_view.set_progress(progress)

func _focus_frontier() -> void:
	if scroll == null or route_view == null:
		return
	# Keep the next playable node visible after returning from a completed level.
	# The founder approval cap remains authoritative even when save progress is ahead.
	var frontier: int = 1
	if progress != null:
		frontier = int(progress.highest_level_unlocked)
	frontier = clampi(frontier, 1, max(1, canonical_level_cap))
	var target: Button = get_level_button(frontier)
	if target != null:
		scroll.ensure_control_visible(target)
