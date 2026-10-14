extends SceneTree

const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")
const LockedExplanation = preload("res://src/ui/shared/locked_explanation.gd")
const PRESTART := preload("res://src/ui/prestart/level_prestart.tscn")
const GAMEPLAY := preload("res://src/ui/gameplay/gameplay_screen.tscn")
const RESTORATION := preload("res://src/ui/home/restoration_overlay.tscn")
const CURIO_DETAIL := preload("res://src/ui/collection/curio_detail_panel.tscn")
const HOUSE := preload("res://src/ui/home/house_home.tscn")
const CHAPTER_MAP := preload("res://src/ui/map/chapter_map.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var contract := ProductionChrome.contract()
	_expect(bool(contract.get("asset_backed", false)), "shared production chrome texture must decode at runtime")
	_expect(String(contract.get("runtime_path", "")).ends_with(".svg"), "shared production chrome must resolve from the authored frame source through the runtime image decoder")
	_expect(float(contract.get("nine_slice_margin", 0.0)) >= 56.0, "shared production chrome must retain safe 9-slice corners")
	_expect(bool(contract.get("global_interactive_family_ready", false)), "global interactive chrome variants must resolve from the authored 9-slice source")
	_expect(bool(contract.get("action_family_ready", false)), "Golden Loop action chrome must resolve primary and utility authored 9-slice variants")
	_expect(bool(contract.get("gameplay_hud_frame_asset_backed", false)), "gameplay objective HUD must resolve the authored gothic frame")
	_expect(String(contract.get("primary_action_runtime_path", "")).ends_with(".svg"), "primary action chrome must resolve through the authored action asset")
	await _expect_panel(PRESTART, "Layout/Card")
	await _expect_panel(GAMEPLAY, "PauseOverlay/Card")
	await _expect_panel(GAMEPLAY, "ResultOverlay/Card")
	await _expect_panel(RESTORATION, "CeremonyCard")
	await _expect_panel(CURIO_DETAIL, "CurioDetailCard")
	await _expect_locked_panel()
	await _expect_scene_authored_house_action(HOUSE, "Layout/PlayButton")
	await _expect_action(CHAPTER_MAP, "Layout/Back", "utility")
	await _expect_action(PRESTART, "Layout/Card/Content/Start", "primary")
	await _expect_action(PRESTART, "Layout/Back", "utility")
	await _expect_gameplay_pause()
	await _expect_action(GAMEPLAY, "PauseOverlay/Card/Content/Resume", "primary")
	await _expect_action(GAMEPLAY, "PauseOverlay/Card/Content/Retry", "utility")
	await _expect_action(GAMEPLAY, "PauseOverlay/Card/Content/Settings", "utility")
	await _expect_action(GAMEPLAY, "PauseOverlay/Card/Content/Exit", "utility")
	await _expect_action(GAMEPLAY, "ResultOverlay/Card/Content/RecoveryAction", "primary")
	await _expect_action(GAMEPLAY, "ResultOverlay/Card/Content/Action", "primary")
	await _expect_action(RESTORATION, "CeremonyCard/CeremonyContent/CeremonyRow/Copy/Continue", "primary")
	_finish()

func _expect_panel(scene: PackedScene, path: String) -> void:
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var panel := instance.get_node_or_null(path) as Control
	_expect(panel != null, "production chrome panel missing: %s" % path)
	_expect(panel != null and panel.get_theme_stylebox("panel") is StyleBoxTexture, "panel must use asset-backed production chrome: %s" % path)
	_expect(panel != null and String(panel.get_meta("production_chrome_asset", "")).ends_with(".svg"), "panel must expose authored chrome provenance: %s" % path)
	instance.queue_free()
	await process_frame

func _expect_scene_authored_house_action(scene: PackedScene, path: String) -> void:
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var button := instance.get_node_or_null(path) as Button
	_expect(button != null, "House action missing: %s" % path)
	_expect(button != null and button.get_theme_stylebox("normal") is StyleBoxFlat, "House action normal state must preserve its scene-authored material: %s" % path)
	_expect(button != null and button.get_theme_stylebox("hover") is StyleBoxFlat, "House action hover state must preserve its scene-authored material: %s" % path)
	_expect(button != null and button.get_theme_stylebox("pressed") is StyleBoxFlat, "House action pressed state must preserve its scene-authored material: %s" % path)
	_expect(button != null and String(button.get_meta("home_material", "")) == "scene_authored_flat", "House action material provenance mismatch: %s" % path)
	instance.queue_free()
	await process_frame

func _expect_action(scene: PackedScene, path: String, hierarchy: String) -> void:
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var button := instance.get_node_or_null(path) as Button
	_expect(button != null, "production action missing: %s" % path)
	_expect(button != null and button.get_theme_stylebox("normal") is StyleBoxTexture, "action normal state must be asset-backed: %s" % path)
	_expect(button != null and button.get_theme_stylebox("hover") is StyleBoxTexture, "action hover state must be asset-backed: %s" % path)
	_expect(button != null and button.get_theme_stylebox("pressed") is StyleBoxTexture, "action pressed state must be asset-backed: %s" % path)
	_expect(button != null and button.get_theme_stylebox("disabled") is StyleBoxTexture, "action disabled state must be asset-backed: %s" % path)
	_expect(button != null and String(button.get_meta("production_chrome_kind", "")).begins_with("action_" + hierarchy + "_"), "action hierarchy provenance mismatch: %s" % path)
	instance.queue_free()
	await process_frame

func _expect_interactive(scene: PackedScene, path: String, role: String) -> void:
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var button := instance.get_node_or_null(path) as Button
	_expect(button != null, "production interactive control missing: %s" % path)
	_expect(button != null and button.get_theme_stylebox("normal") is StyleBoxTexture, "interactive normal state must be asset-backed: %s" % path)
	_expect(button != null and button.get_theme_stylebox("hover") is StyleBoxTexture, "interactive hover state must be asset-backed: %s" % path)
	_expect(button != null and button.get_theme_stylebox("pressed") is StyleBoxTexture, "interactive pressed state must be asset-backed: %s" % path)
	_expect(button != null and button.get_theme_stylebox("disabled") is StyleBoxTexture, "interactive disabled state must be asset-backed: %s" % path)
	_expect(button != null and String(button.get_meta("production_chrome_kind", "")) == "interactive_" + role, "interactive provenance mismatch: %s" % path)
	instance.queue_free()
	await process_frame

func _expect_gameplay_pause() -> void:
	var instance := GAMEPLAY.instantiate()
	root.add_child(instance)
	await process_frame
	var button := instance.get_node_or_null("Layout/HUDPlate/HUD/Pause") as Button
	_expect(button != null, "gameplay pause control missing")
	_expect(button != null and button.icon != null, "gameplay pause must use authored icon art")
	_expect(button != null and button.text == "", "gameplay pause must not fall back to a text glyph")
	_expect(button != null and button.get_theme_stylebox("normal") is StyleBoxFlat, "gameplay pause must retain compact local control chrome")
	_expect(button != null and String(button.get_meta("production_chrome_kind", "")) == "gameplay_pause_icon", "gameplay pause provenance mismatch")
	_expect(button != null and String(button.get_meta("production_chrome_asset", "")).ends_with("/ui/gameplay/pause_gothic_v01.svg"), "gameplay pause icon asset mismatch")
	instance.queue_free()
	await process_frame

func _expect_locked_panel() -> void:
	var owner := Control.new()
	root.add_child(owner)
	var overlay := LockedExplanation.present(owner, "SEALED", "Not yet awake.", "Complete the required ritual.", "CLOSE")
	await process_frame
	var panel := overlay.get_node_or_null("LockedPanel") as Control if overlay != null else null
	_expect(panel != null and panel.get_theme_stylebox("panel") is StyleBoxTexture, "locked explanation must use asset-backed production chrome")
	owner.queue_free()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: production chrome asset-backed panels")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
