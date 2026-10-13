extends SceneTree

const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")
const LockedExplanation = preload("res://src/ui/shared/locked_explanation.gd")
const PRESTART := preload("res://src/ui/prestart/level_prestart.tscn")
const GAMEPLAY := preload("res://src/ui/gameplay/gameplay_screen.tscn")
const RESTORATION := preload("res://src/ui/home/restoration_overlay.tscn")
const CURIO_DETAIL := preload("res://src/ui/collection/curio_detail_panel.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var contract := ProductionChrome.contract()
	_expect(bool(contract.get("asset_backed", false)), "shared production chrome texture must decode at runtime")
	_expect(String(contract.get("runtime_path", "")).ends_with(".png"), "shared production chrome must resolve to raster PNG at runtime")
	_expect(float(contract.get("nine_slice_margin", 0.0)) >= 56.0, "shared production chrome must retain safe 9-slice corners")
	await _expect_panel(PRESTART, "Layout/Card")
	await _expect_panel(GAMEPLAY, "PauseOverlay/Card")
	await _expect_panel(GAMEPLAY, "ResultOverlay/Card")
	await _expect_panel(RESTORATION, "CeremonyCard")
	await _expect_panel(CURIO_DETAIL, "CurioDetailCard")
	await _expect_locked_panel()
	_finish()

func _expect_panel(scene: PackedScene, path: String) -> void:
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var panel := instance.get_node_or_null(path) as Control
	_expect(panel != null, "production chrome panel missing: %s" % path)
	_expect(panel != null and panel.get_theme_stylebox("panel") is StyleBoxTexture, "panel must use asset-backed production chrome: %s" % path)
	_expect(panel != null and String(panel.get_meta("production_chrome_asset", "")).ends_with(".png"), "panel must expose raster chrome provenance: %s" % path)
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
