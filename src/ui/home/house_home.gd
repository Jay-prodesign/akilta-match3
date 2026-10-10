class_name Match3HouseHome
extends Control

signal play_requested(level_number: int)

const HouseState = preload("res://src/world/house_state.gd")

@onready var room_view = $Layout/RoomView
@onready var headline: Label = $Layout/Headline
@onready var detail: Label = $Layout/Detail
@onready var curio_label: Label = $Layout/CurioChip/Label
@onready var play_button: Button = $Layout/PlayButton

var progress
var available_level_count: int = 1

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)

func set_available_level_count(value: int) -> void:
	available_level_count = max(0, value)
	if progress != null:
		_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func _refresh() -> void:
	var stage: int = 0
	var owned_curios: Array[String] = []
	if progress != null:
		stage = int(progress.house_stage)
		for curio in progress.curios:
			owned_curios.append(String(curio))
	var state: Dictionary = HouseState.descriptor(stage)
	headline.text = String(state.get("headline", "The Curio Boutique sleeps."))
	detail.text = String(state.get("detail", ""))
	room_view.set_house_state(stage, owned_curios)
	if stage >= 2:
		curio_label.text = "2 CURIOS · MOON CAMEO + MOTH RELIQUARY"
	elif stage >= 1:
		curio_label.text = "CURIO 01 · MOON CAMEO AWAKENED"
	else:
		curio_label.text = "DORMANT DISPLAY"
	var next_level: int = int(progress.highest_level_unlocked) if progress != null else 1
	var has_authored_next: bool = next_level <= available_level_count
	play_button.disabled = not has_authored_next
	play_button.text = "ENTER LEVEL %d" % next_level if has_authored_next else "MORE CURIOS STIR SOON"

func _on_play_pressed() -> void:
	if progress == null:
		return
	var level_number: int = int(progress.highest_level_unlocked)
	if level_number <= available_level_count:
		play_requested.emit(level_number)
