extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const BoardState := preload("res://src/match3/domain/board_state.gd")
const MoveResolver := preload("res://src/match3/domain/move_resolver.gd")
const LEVEL_PATH := "res://content/levels/ch01/level_001.json"
const SAVE_PATH := "user://capture_level1_failure.json"
const SETTINGS_PATH := "user://capture_level1_failure_settings.json"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	_cleanup()
	var level_data := _read_level()
	var move := _find_failing_move(level_data)
	if move.is_empty():
		return _fail(null, "no deterministic failing move found")

	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await _frames(3)
	if String(app.current_route_name()) != "boot":
		return _fail(app, "failure capture must begin on splash")
	var splash = app.current_screen()
	var enter := splash.get_node_or_null("Layout/Enter") as Button if splash != null else null
	if enter == null:
		return _fail(app, "failure capture splash enter control missing")
	enter.emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "house":
		return _fail(app, "failure capture splash did not enter House")
	if not app.show_map() or not app.show_prestart(1) or not app.start_level(1):
		return _fail(app, "failed to enter Level 1")
	await _frames(3)

	var gameplay = app.current_screen()
	gameplay.board_state.moves_remaining = 1
	gameplay._refresh_hud()
	var trace = gameplay.attempt_swap(move["from"], move["to"])
	if trace == null or not trace.accepted or String(trace.result) != "failed":
		return _fail(app, "exhaustion move did not fail")
	var board_view = gameplay.get_node_or_null("Layout/BoardView")
	if board_view != null and board_view.is_motion_active():
		await board_view.trace_motion_finished
	await _frames(2)
	if not gameplay.result_overlay.visible:
		return _fail(app, "failure overlay missing")
	var failure_eyebrow: Label = gameplay.get_node("ResultOverlay/Card/Content/Eyebrow")
	var failure_reward: Label = gameplay.get_node("ResultOverlay/Card/Content/RewardName")
	var failure_house_change: Label = gameplay.get_node("ResultOverlay/Card/Content/HouseChange")
	if failure_eyebrow.text != "RITUAL UNFINISHED":
		return _fail(app, "failed Level 1 must not claim a recovered Curio")
	if failure_reward.text != "MOON CAMEO · STILL SEALED":
		return _fail(app, "failed Level 1 must keep the Moon Cameo sealed")
	if not failure_house_change.text.begins_with("No Curio is added"):
		return _fail(app, "failed Level 1 must explain that House progression was not granted")
	if not await _save(app, "level1-fail-result.png"):
		return

	if not gameplay.retry_current_level():
		return _fail(app, "retry failed")
	await _frames(3)
	if gameplay.result_overlay.visible or int(gameplay.board_state.moves_remaining) != int(level_data["moves"]):
		return _fail(app, "retry did not restore clean Level 1")
	if not await _save(app, "level1-retry-restored.png"):
		return

	print("CAPTURE_PASS: Level 1 fail retry")
	app.queue_free()
	await process_frame
	_cleanup()
	quit(0)

func _read_level() -> Dictionary:
	var file := FileAccess.open(LEVEL_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _find_failing_move(level_data: Dictionary) -> Dictionary:
	var width := int(level_data.get("width", 0))
	var height := int(level_data.get("height", 0))
	for y in range(height):
		for x in range(width):
			var from := Vector2i(x, y)
			for delta in [Vector2i.RIGHT, Vector2i.DOWN]:
				var to: Vector2i = from + Vector2i(delta)
				if to.x >= width or to.y >= height:
					continue
				var board = BoardState.from_level(level_data, 1001)
				board.moves_remaining = 1
				var trace = MoveResolver.try_swap(board, from, to)
				if trace.accepted and String(trace.result) == "failed":
					return {"from": from, "to": to}
	return {}

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _save(app: Node, file_name: String) -> bool:
	var image: Image = app.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail(app, "empty viewport")
		return false
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(file_name)
	if image.save_png(output_path) != OK:
		_fail(app, "save failed")
		return false
	print("CAPTURE_FRAME: %s" % output_path)
	return true

func _fail(app: Node, message: String) -> void:
	printerr("CAPTURE_FAIL: %s" % message)
	if app != null and is_instance_valid(app):
		app.queue_free()
	_cleanup()
	quit(1)

func _cleanup() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
