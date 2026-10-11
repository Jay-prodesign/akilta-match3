extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const SAVE_PATH := "user://capture_golden_loop.json"
const SETTINGS_PATH := "user://capture_golden_loop_settings.json"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	_cleanup()
	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await _frames(4)

	if String(app.current_route_name()) != "boot":
		return _fail(app, "cold start must begin on S00 BOOT")
	if not await _save(app, "golden-00-splash.png"):
		return

	var splash = app.current_screen()
	var enter: Button = splash.get_node_or_null("Layout/Enter") as Button if splash != null else null
	if enter == null:
		return _fail(app, "S00 enter control missing")
	enter.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "house":
		return _fail(app, "S00 must enter S01 House")
	var house = app.current_screen()
	if not await _save(app, "golden-01-house-dormant.png"):
		return

	# Use the real House next-action component. It must enter S03 directly,
	# not bypass the route into Pre-start and not detour through S02.
	var house_cta: Button = house.get_node_or_null("Layout/PlayButton") as Button
	if house_cta == null or house_cta.disabled:
		return _fail(app, "S01 next action missing")
	house_cta.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "map":
		return _fail(app, "S01 next action must enter S03 Chapter Detail / Route")
	var route = app.current_screen()
	var level1: Button = route.get_level_button(1) if route != null and route.has_method("get_level_button") else null
	if level1 == null or level1.disabled:
		return _fail(app, "S03 must expose current Level 1")
	if not await _save(app, "golden-02-chapter-route.png"):
		return

	level1.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "prestart":
		return _fail(app, "S03 current level must enter S04 Pre-start")
	var prestart = app.current_screen()
	if prestart == null or prestart.get_node_or_null("ProductNavigation") != null:
		return _fail(app, "S04 must remain a focused surface without meta navigation")
	if not await _save(app, "golden-03-prestart.png"):
		return

	var start: Button = prestart.get_node_or_null("Layout/Card/Content/Start") as Button
	if start == null or start.disabled:
		return _fail(app, "S04 Play action missing")
	start.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "gameplay":
		return _fail(app, "S04 must enter S05 Gameplay")
	var gameplay = app.current_screen()
	if not await _save(app, "golden-04-gameplay.png"):
		return

	if not gameplay.show_pause():
		return _fail(app, "S05 pause state must open")
	await _frames(2)
	if not await _save(app, "golden-04b-pause.png"):
		return
	if not gameplay.resume_level():
		return _fail(app, "S05 pause state must resume")
	await _frames(2)

	var trace = gameplay.attempt_swap(Vector2i(1, 4), Vector2i(2, 4))
	if trace == null or not bool(trace.accepted) or String(trace.result) != "won":
		return _fail(app, "authored Level 1 move must reach win")
	var board_view = gameplay.get_node_or_null("Layout/BoardView")
	if board_view != null and board_view.has_method("is_motion_active") and bool(board_view.is_motion_active()):
		await board_view.trace_motion_finished
	await _frames(2)
	if not gameplay.result_overlay.visible:
		return _fail(app, "S06 reward/result must become visible")
	if String(app.current_route_name()) != "win_rewards":
		return _fail(app, "terminal win must own S06 WIN_REWARDS route")
	if not await _save(app, "golden-05-win-reward.png"):
		return

	if not gameplay.continue_after_win():
		return _fail(app, "S06 Continue must commit the first-time reward")
	await _frames(5)
	if String(app.current_route_name()) != "restoration":
		return _fail(app, "first-time reward must enter S07 Restoration before House")
	if int(app.progress.house_stage) != 1 or app.progress.curios.count("moon_cameo") != 1:
		return _fail(app, "durable Level 1 reward must be applied exactly once before restoration")
	var restoration_house = app.current_screen()
	var restoration_overlay: Control = restoration_house.get_node_or_null("RestorationOverlay") as Control if restoration_house != null else null
	var restoration_continue: Button = restoration_house.get_node_or_null("RestorationOverlay/CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue") as Button if restoration_house != null else null
	if restoration_overlay == null or not restoration_overlay.visible or restoration_continue == null:
		return _fail(app, "S07 same-camera restoration ceremony missing")
	if not await _save(app, "golden-06-restoration.png"):
		return

	restoration_continue.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "house":
		return _fail(app, "S07 Continue must return to S01 House")
	var returned_house = app.current_screen()
	var awakened_cameo: Control = returned_house.get_node_or_null("Layout/RoomView/MoonCameoOverlay") as Control if returned_house != null else null
	if awakened_cameo == null or not awakened_cameo.visible:
		return _fail(app, "returned S01 must render the persisted restored Curio")
	if not await _save(app, "golden-07-house-return.png"):
		return

	print("CAPTURE_PASS: canonical Golden Playable Loop")
	app.queue_free()
	await process_frame
	_cleanup()
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _save(app: Node, file_name: String) -> bool:
	var viewport: Viewport = app.get_viewport()
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_fail(app, "empty viewport for %s" % file_name)
		return false
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(file_name)
	if image.save_png(output_path) != OK:
		_fail(app, "save_png failed for %s" % file_name)
		return false
	print("CAPTURE_FRAME: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	return true

func _fail(app: Node, message: String) -> void:
	printerr("CAPTURE_FAIL: %s" % message)
	if app != null and is_instance_valid(app):
		app.queue_free()
	_cleanup()
	quit(1)

func _cleanup() -> void:
	for p in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
