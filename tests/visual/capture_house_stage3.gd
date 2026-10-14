extends SceneTree

const ProgressScript = preload("res://src/progression/player_progress.gd")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://src/ui/home/house_home.tscn")
	if packed == null:
		printerr("CAPTURE_FAIL: House scene missing")
		quit(1)
		return

	var progress = ProgressScript.new()
	progress.house_stage = 3
	progress.highest_level_unlocked = 4
	progress.curios.append("moon_cameo")
	progress.curios.append("moth_reliquary")
	progress.curios.append("thorned_locket")
	progress.completed_levels.append("ch01_level_001")
	progress.completed_levels.append("ch01_level_002")
	progress.completed_levels.append("ch01_level_003")

	var screen = packed.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_available_level_count(3)
	screen.set_progress(progress)
	await process_frame
	await process_frame

	var room_view = screen.get_node_or_null("RoomView")
	if room_view == null or not room_view.has_method("restoration_contract"):
		printerr("CAPTURE_FAIL: House stage 3 restoration contract missing")
		quit(1)
		return
	var restoration: Dictionary = room_view.restoration_contract()
	if not bool(restoration.get("moth_reliquary_visible", false)):
		printerr("CAPTURE_FAIL: stage 3 House must visibly restore the Moth Reliquary")
		quit(1)
		return
	if not bool(restoration.get("thorned_locket_visible", false)):
		printerr("CAPTURE_FAIL: stage 3 House must visibly restore the Thorned Locket")
		quit(1)
		return
	var headline: Label = screen.get_node("Layout/Headline")
	if headline.text != "Three displays breathe in the moonlight.":
		printerr("CAPTURE_FAIL: stage 3 House copy does not reflect full opening restoration")
		quit(1)
		return
	var play_button: Button = screen.get_node("Layout/PlayButton")
	if play_button.text != "REVISIT CURIO BOUTIQUE":
		printerr("CAPTURE_FAIL: completed opening chapter must return to the restored Curio Boutique")
		quit(1)
		return
	var completion_banner: PanelContainer = screen.get_node_or_null("Layout/ChapterCompletionBanner")
	var completion_label: Label = screen.get_node_or_null("Layout/ChapterCompletionBanner/Label")
	if completion_banner == null or not completion_banner.visible or completion_label == null or not completion_label.text.contains("OPENING CABINET SET COMPLETE"):
		printerr("CAPTURE_FAIL: stage 3 House must preserve truthful opening-cabinet completion status")
		quit(1)
		return
	var life_resource: Label = screen.find_child("LifeResource", true, false) as Label
	var coin_resource: Label = screen.find_child("CoinResource", true, false) as Label
	var gem_resource: Label = screen.find_child("GemResource", true, false) as Label
	if life_resource == null or coin_resource == null or gem_resource == null:
		printerr("CAPTURE_FAIL: completed House must preserve the global life/coin/gem header contract")
		quit(1)
		return

	var viewport: Viewport = screen.get_viewport()
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("CAPTURE_FAIL: House stage 3 viewport image empty")
		quit(1)
		return
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join("house-stage3.png")
	var err: int = int(image.save_png(output_path))
	if err != OK:
		printerr("CAPTURE_FAIL: House stage 3 save_png error %d" % err)
		quit(1)
		return
	print("CAPTURE_PASS: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	screen.queue_free()
	await process_frame
	quit(0)
