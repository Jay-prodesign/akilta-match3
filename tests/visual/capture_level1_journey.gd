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
	var gameplay_contract: Dictionary = gameplay.gameplay_presentation_contract() if gameplay != null and gameplay.has_method("gameplay_presentation_contract") else {}
	for parity_key in [
		"visual_parity_gate_v12",
		"objective_spacing_locked",
		"north_star_compact_gameplay_header",
		"north_star_compact_gameplay_geometry",
		"canonical_booster_art",
		"gothic_board_material",
		"quiet_gameplay_shell_family",
		"integrated_hud_surface",
		"final_hint_readability",
		"final_booster_readability",
		"north_star_header_hierarchy",
		"north_star_board_object",
		"north_star_booster_family",
		"utility_separated_from_boosters",
		"hint_booster_clearance",
	]:
		if not bool(gameplay_contract.get(parity_key, false)):
			return _fail(app, "S05 North Star render gate failed: %s" % parity_key)
	var gameplay_viewport: Vector2 = gameplay.get_viewport().get_visible_rect().size
	var gameplay_resource_bar := gameplay.get_node_or_null("ResourceBar") as PanelContainer
	var gameplay_eyebrow := gameplay.get_node_or_null("Layout/Eyebrow") as Label
	var gameplay_title := gameplay.get_node_or_null("Layout/Title") as Label
	var gameplay_hud := gameplay.get_node_or_null("Layout/HUDPlate") as Control
	var gameplay_objective_icon := gameplay.get_node_or_null("Layout/HUDPlate/HUD/ObjectiveIcon") as Control
	var gameplay_objective := gameplay.get_node_or_null("Layout/HUDPlate/HUD/Objective") as Label
	var gameplay_moves := gameplay.get_node_or_null("Layout/HUDPlate/HUD/Moves") as Label
	var gameplay_pause := gameplay.get_node_or_null("Layout/HUDPlate/HUD/Pause") as Button
	var gameplay_board := gameplay.get_node_or_null("Layout/BoardView") as Control
	var gameplay_hint := gameplay.get_node_or_null("Layout/Hint") as Control
	var gameplay_tray := gameplay.get_node_or_null("BoosterTray") as Control
	var shuffle_label := gameplay.get_node_or_null("BoosterTray/BoosterActions/SealedSlotA/Label") as Control
	var hand_label := gameplay.get_node_or_null("BoosterTray/BoosterActions/SealedSlotB/Label") as Control
	var magic_label := gameplay.get_node_or_null("BoosterTray/BoosterActions/SealedSlotC/Label") as Control
	if gameplay_resource_bar == null or gameplay_eyebrow == null or gameplay_title == null or gameplay_hud == null or gameplay_objective_icon == null or gameplay_objective == null or gameplay_moves == null or gameplay_pause == null or gameplay_board == null or gameplay_hint == null or gameplay_tray == null:
		return _fail(app, "S05 North Star render gate missing level/HUD/board/hint/tray")
	if gameplay_resource_bar.visible:
		return _fail(app, "S05 meta currency/level row regressed into gameplay")
	var board_height_ratio: float = gameplay_board.size.y / gameplay_viewport.y
	var board_width_ratio: float = gameplay_board.size.x / gameplay_viewport.x
	var tray_width_ratio: float = gameplay_tray.size.x / gameplay_viewport.x
	if board_height_ratio < 0.54 or board_height_ratio > 0.58:
		return _fail(app, "S05 board height ratio drifted: %.3f" % board_height_ratio)
	if board_width_ratio < 0.90:
		return _fail(app, "S05 board width no longer dominates viewport: %.3f" % board_width_ratio)
	if tray_width_ratio < 0.82 or tray_width_ratio > 0.86:
		return _fail(app, "S05 booster tray width drifted: %.3f" % tray_width_ratio)
	var eyebrow_rect: Rect2 = gameplay_eyebrow.get_global_rect()
	var hud_rect: Rect2 = gameplay_hud.get_global_rect()
	var objective_icon_rect: Rect2 = gameplay_objective_icon.get_global_rect()
	var pause_rect: Rect2 = gameplay_pause.get_global_rect()
	var board_rect: Rect2 = gameplay_board.get_global_rect()
	var hint_rect: Rect2 = gameplay_hint.get_global_rect()
	var tray_rect: Rect2 = gameplay_tray.get_global_rect()
	var hint_width_ratio: float = hint_rect.size.x / gameplay_viewport.x
	if hint_width_ratio < 0.62 or hint_width_ratio > 0.70:
		return _fail(app, "S05 hint callout width drifted: %.3f" % hint_width_ratio)
	if gameplay_title.visible:
		return _fail(app, "S05 room title regressed into the compact gameplay header")
	if not gameplay_eyebrow.text.begins_with("LEVEL ") or gameplay_eyebrow.get_theme_font_size("font_size") < 22:
		return _fail(app, "S05 compact Level identity regressed")
	if eyebrow_rect.end.y + 4.0 > hud_rect.position.y:
		return _fail(app, "S05 Level identity and objective HUD overlap")
	if gameplay_objective.has_theme_stylebox_override("normal"):
		return _fail(app, "S05 objective regressed into a detached inner panel")
	if gameplay_objective.text.begins_with("TARGET\n"):
		return _fail(app, "S05 redundant target heading regressed")
	if gameplay_moves.get_theme_font_size("font_size") < 40 or gameplay_objective.get_theme_font_size("font_size") < 26:
		return _fail(app, "S05 objective/moves visual hierarchy regressed")
	if gameplay_hint.get_theme_font_size("font_size") < 21:
		return _fail(app, "S05 hint readability regressed")
	if not hud_rect.grow(-4.0).encloses(objective_icon_rect):
		return _fail(app, "S05 objective icon escapes the authored HUD frame")
	var objective_rect: Rect2 = gameplay_objective.get_global_rect()
	if objective_rect.size.x < gameplay_viewport.x * 0.36:
		return _fail(app, "S05 objective copy width collapsed: %.3f" % (objective_rect.size.x / gameplay_viewport.x))
	if objective_rect.position.x < objective_icon_rect.end.x + 6.0:
		return _fail(app, "S05 objective icon-to-copy clearance collapsed")
	if pause_rect.position.x >= objective_icon_rect.position.x:
		return _fail(app, "S05 pause control must remain at the quiet left edge of the HUD")
	if hud_rect.end.y > board_rect.position.y + 2.0:
		return _fail(app, "S05 objective HUD collides with board")
	if board_rect.end.y > hint_rect.position.y + 2.0:
		return _fail(app, "S05 board collides with authored hint band")
	if hint_rect.end.y + 24.0 > tray_rect.position.y:
		return _fail(app, "S05 hint-to-booster breathing room collapsed")
	for booster_label in [shuffle_label, hand_label, magic_label]:
		if booster_label == null or not tray_rect.grow(-8.0).encloses(booster_label.get_global_rect()):
			return _fail(app, "S05 booster label escapes production tray frame")
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
	var awakened_cameo: Control = returned_house.get_node_or_null("RoomView/MoonCameoOverlay") as Control if returned_house != null else null
	if awakened_cameo == null or not awakened_cameo.visible:
		return _fail(app, "returned S01 must render the persisted restored Curio")
	if not await _save(app, "golden-07-house-return.png"):
		return

	# Complete the canonical post-restoration verification: the same earned Curio
	# must be visible in S08 and inspectable through O04, not merely implied by House art.
	var curios_nav: Button = returned_house.get_node_or_null("ProductNavigation/Scroll/Items/NavCurios") as Button
	if curios_nav == null:
		return _fail(app, "returned S01 must expose Curios in the product shell")
	curios_nav.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "collection":
		return _fail(app, "House Curios destination must enter S08 Curio Collection")
	var collection = app.current_screen()
	var moon_state: Label = collection.get_node_or_null("Layout/Cards/MoonCard/Content/Copy/State") as Label if collection != null else null
	if moon_state == null or not moon_state.text.begins_with("AWAKENED"):
		return _fail(app, "S08 must show the exact earned Moon Cameo as awakened")
	if not await _save(app, "golden-08-curio-verification.png"):
		return

	var inspect: Button = collection.get_node_or_null("Layout/Cards/MoonCard/DetailActionLayer/InspectAction") as Button
	if inspect == null:
		return _fail(app, "S08 awakened Curio must expose O04 detail")
	inspect.emit_signal("pressed")
	await _frames(3)
	var detail_state: Label = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/State") as Label
	var detail_origin: Label = collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/Origin") as Label
	if detail_state == null or not detail_state.text.contains("AWAKENED") or detail_origin == null or not detail_origin.text.contains("LEVEL 1"):
		return _fail(app, "O04 must verify awakened ownership and Level 1 origin")
	if not await _save(app, "golden-09-curio-detail.png"):
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
