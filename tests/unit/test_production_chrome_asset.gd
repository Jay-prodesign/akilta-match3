extends SceneTree

const STYLE_PATH := "res://src/ui/theme/primary_panel_frame.tres"
const PRESTART := preload("res://src/ui/prestart/level_prestart.tscn")
const GAMEPLAY := preload("res://src/ui/gameplay/gameplay_screen.tscn")
const RESTORATION := preload("res://src/ui/home/restoration_overlay.tscn")
const CURIO_DETAIL := preload("res://src/ui/collection/curio_detail_panel.tscn")
const LOCKED := preload("res://src/ui/shared/locked_explanation.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(ResourceLoader.exists(STYLE_PATH), "shared production chrome style must exist")
	var style := load(STYLE_PATH)
	_expect(style is StyleBoxTexture, "shared production chrome must be a StyleBoxTexture")
	if style is StyleBoxTexture:
		_expect((style as StyleBoxTexture).texture != null, "shared production chrome texture must load")
		_expect((style as StyleBoxTexture).texture_margin_left >= 56.0, "shared production chrome must retain safe 9-slice corners")
	await _expect_panel(PRESTART, "Layout/Card")
	await _expect_panel(GAMEPLAY, "PauseOverlay/Card")
	await _expect_panel(GAMEPLAY, "ResultOverlay/Card")
	await _expect_panel(RESTORATION, "CeremonyCard")
	await _expect_panel(CURIO_DETAIL, "CurioDetailCard")
	await _expect_panel(LOCKED, "LockedPanel")
	_finish()

func _expect_panel(scene: PackedScene, path: String) -> void:
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var panel := instance.get_node_or_null(path) as PanelContainer
	_expect(panel != null, "production chrome panel missing: %s" % path)
	_expect(panel != null and panel.get_theme_stylebox("panel") is StyleBoxTexture, "panel must use asset-backed production chrome: %s" % path)
	instance.queue_free()
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
