extends SceneTree

const APP_SCENE := preload("res://src/app/app_bootstrap.tscn")
const ProgressScript = preload("res://src/progression/player_progress.gd")
const SaveStoreScript = preload("res://src/save/save_store.gd")
const SAVE_PATH := "user://returning_player_resume_test.json"
const SETTINGS_PATH := "user://returning_player_resume_settings.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	var progress = ProgressScript.new()
	if not progress.apply_level_win("resume-l1", "ch01_level_001", "moon_cameo", 1):
		return _fail(null, "could not seed Level 1 durable progress")
	if not progress.apply_level_win("resume-l2", "ch01_level_002", "moth_reliquary", 2):
		return _fail(null, "could not seed Level 2 durable progress")
	progress.lives = 3
	progress.coins = 777
	progress.gems = 9
	var store = SaveStoreScript.new(SAVE_PATH)
	if not store.save(progress.to_dict()):
		return _fail(null, "could not persist returning-player seed")

	var app = APP_SCENE.instantiate()
	app.save_path_override = SAVE_PATH
	app.settings_path_override = SETTINGS_PATH
	root.add_child(app)
	await _frames(4)

	if String(app.current_route_name()) != "boot":
		return _fail(app, "relaunch must still enter through authored Splash / BOOT")
	if int(app.progress.house_stage) != 2 or app.progress.curios.size() != 2 or int(app.progress.highest_level_unlocked) != 3:
		return _fail(app, "durable progression did not hydrate before entering House")
	if int(app.progress.lives) != 3 or int(app.progress.coins) != 777 or int(app.progress.gems) != 9:
		return _fail(app, "durable resources did not hydrate on relaunch")

	var splash = app.current_screen()
	var enter := splash.get_node_or_null("Layout/Enter") as Button if splash != null else null
	if enter == null:
		return _fail(app, "returning-player Splash enter control missing")
	enter.emit_signal("pressed")
	await _frames(4)

	if String(app.current_route_name()) != "house":
		return _fail(app, "S00 relaunch did not reach S01 House")
	var house = app.current_screen()
	if house == null or not house.has_method("ftue_house_contract"):
		return _fail(app, "returning House FTUE contract missing")
	if bool(house.ftue_house_contract().get("active", true)):
		return _fail(app, "returning player must not see first-ritual guidance")
	var return_banner := house.get_node_or_null("Layout/ReturningPlayerBanner") as PanelContainer if house != null else null
	var return_label := house.get_node_or_null("Layout/ReturningPlayerBanner/Label") as Label if house != null else null
	var headline := house.get_node_or_null("Layout/Headline") as Label if house != null else null
	var curio_label := house.get_node_or_null("Layout/CurioChip/Label") as Label if house != null else null
	var play := house.get_node_or_null("Layout/PlayButton") as Button if house != null else null
	if return_banner == null or return_banner.visible or return_label == null or not return_label.text.contains("WELCOME BACK") or not return_label.text.contains("2 / 3") or headline == null or not headline.text.contains("WELCOME BACK") or not headline.text.contains("2 / 3 CURIOS"):
		return _fail(app, "House did not expose canonical returning_player state in the primary Home title")
	if curio_label == null or not curio_label.text.contains("2 / 3 CURIOS"):
		return _fail(app, "House did not restore 2/3 Curio truth")
	if play == null or play.text != "PLAY LEVEL 3":
		return _fail(app, "returning House did not expose the next useful action")
	if not house.has_method("house_hotspot_contract"):
		return _fail(app, "House hotspot contract missing")
	var hotspot_contract: Dictionary = house.house_hotspot_contract()
	var hotspot_states: Dictionary = hotspot_contract.get("states", {})
	var moth_state: Dictionary = hotspot_states.get("moth_reliquary", {})
	var thorn_state: Dictionary = hotspot_states.get("thorned_locket", {})
	if String(moth_state.get("state", "")) != "owned" or bool(moth_state.get("disabled", true)):
		return _fail(app, "returning House must keep the owned Moth Reliquary hotspot active")
	if String(thorn_state.get("state", "")) != "locked" or not bool(thorn_state.get("disabled", false)):
		return _fail(app, "returning House must keep the unowned Thorned Locket hotspot sealed")
	var moth_hotspot: Button = house.get_node_or_null("RoomView/CurioHotspots/MothHotspot") as Button
	if moth_hotspot == null:
		return _fail(app, "returning House Moth hotspot missing")
	moth_hotspot.emit_signal("pressed")
	await _frames(2)
	var house_detail_name: Label = house.get_node_or_null("HouseCurioInspect/Card/Content/Name") as Label
	if house_detail_name == null or house_detail_name.text != "MOTH RELIQUARY":
		return _fail(app, "House hotspot must open the persisted Moth Reliquary detail")
	var house_close: Button = house.get_node_or_null("HouseCurioInspect/Card/Content/Close") as Button
	if house_close == null:
		return _fail(app, "House Curio detail close action missing")
	house_close.emit_signal("pressed")
	await _frames(2)

	if not app.show_collection():
		return _fail(app, "returning House -> Reliquary failed")
	await _frames(3)
	var returning_collection = app.current_screen()
	var returning_moth_detail: Button = returning_collection.get_node_or_null("Layout/Cards/Slot2/DetailActionLayer/InspectAction") as Button
	if returning_moth_detail == null:
		return _fail(app, "returning Reliquary Moth detail action missing")
	returning_moth_detail.emit_signal("pressed")
	await _frames(2)
	var view_moth_in_house: Button = returning_collection.get_node_or_null("CurioDetailOverlay/CurioDetailCard/Content/ViewInHouse") as Button
	if view_moth_in_house == null:
		return _fail(app, "owned Moth detail must expose View In House")
	view_moth_in_house.emit_signal("pressed")
	await _frames(3)
	if String(app.current_route_name()) != "house":
		return _fail(app, "View In House must return to House route")
	house = app.current_screen()
	var returned_moth_name: Label = house.get_node_or_null("HouseCurioInspect/Card/Content/Name") as Label
	if returned_moth_name == null or returned_moth_name.text != "MOTH RELIQUARY":
		return _fail(app, "Curio -> House handoff must preserve Moth identity")
	var returned_moth_close: Button = house.get_node_or_null("HouseCurioInspect/Card/Content/Close") as Button
	if returned_moth_close == null:
		return _fail(app, "Curio -> House detail close missing")
	returned_moth_close.emit_signal("pressed")
	await _frames(2)
	play = house.get_node_or_null("Layout/PlayButton") as Button
	if play == null:
		return _fail(app, "House play action missing after Curio round trip")

	play.emit_signal("pressed")
	await _frames(4)
	if String(app.current_route_name()) != "map":
		return _fail(app, "returning-player next action did not reach the active chapter route")
	var map = app.current_screen()
	var level1: Button = map.get_level_button(1) if map != null else null
	var level2: Button = map.get_level_button(2) if map != null else null
	var level3: Button = map.get_level_button(3) if map != null else null
	if level1 == null or level2 == null or level3 == null:
		return _fail(app, "returning map is missing opening level nodes")
	if level1.disabled or level2.disabled or level3.disabled:
		return _fail(app, "returning map did not preserve replayable completed levels and unlocked frontier")
	if level1.text != "✓" or level2.text != "✓":
		return _fail(app, "returning map did not preserve completed-level truth")

	app.queue_free()
	await process_frame
	_cleanup()
	print("TEST_PASS: returning player relaunch resume journey")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(app: Node, message: String) -> void:
	printerr("TEST_FAIL: %s" % message)
	if app != null and is_instance_valid(app):
		app.queue_free()
	_cleanup()
	quit(1)

func _cleanup() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
