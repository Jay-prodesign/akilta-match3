extends SceneTree

const Typography = preload("res://src/ui/theme/typography.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(FileAccess.file_exists(Typography.DISPLAY_FONT_PATH), "Cormorant Garamond must be vendored")
	_expect(FileAccess.file_exists(Typography.UI_FONT_PATH), "Manrope must be vendored")
	_expect(FileAccess.file_exists("res://assets/licenses/CormorantGaramond-OFL.txt"), "Cormorant OFL notice must exist")
	_expect(FileAccess.file_exists("res://assets/licenses/Manrope-OFL.txt"), "Manrope OFL notice must exist")

	var contract: Dictionary = Typography.contract()
	_expect(bool(contract.get("display_font_loaded", false)), "Cormorant display font must load from raw vendored bytes")
	_expect(bool(contract.get("ui_font_loaded", false)), "Manrope UI font must load from raw vendored bytes")
	_expect(String(contract.get("loader", "")) == "runtime_fontfile_data", "font loading must not depend on import cache")
	_expect(String(contract.get("license", "")).contains("Open Font License"), "typography contract must retain OFL provenance")

	var root_control := Control.new()
	var title := Label.new()
	title.name = "Title"
	root_control.add_child(title)
	var body := Label.new()
	body.name = "Detail"
	root_control.add_child(body)
	var button := Button.new()
	button.name = "Action"
	root_control.add_child(button)

	var stats: Dictionary = Typography.apply(root_control)
	_expect(int(stats.get("display", 0)) == 1, "Title must receive one display-font assignment")
	_expect(int(stats.get("ui", 0)) == 2, "body and button must receive UI-font assignments")
	_expect(title.has_theme_font_override("font"), "Title must receive Cormorant override")
	_expect(body.has_theme_font_override("font"), "functional body text must receive Manrope override")
	_expect(button.has_theme_font_override("font"), "buttons must receive Manrope override")
	_expect(title.get_theme_font("font") == Typography.display_font(), "Title must use runtime Cormorant font object")
	_expect(body.get_theme_font("font") == Typography.ui_font(), "body must use runtime Manrope font object")
	_expect(button.get_theme_font("font") == Typography.ui_font(), "button must use runtime Manrope font object")

	root_control.free()
	if failures.is_empty():
		print("TEST_PASS: OFL Curio House typography")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
