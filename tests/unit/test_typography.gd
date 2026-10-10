extends SceneTree

const Typography = preload("res://src/ui/theme/typography.gd")
const ThemeResource = preload("res://src/ui/theme/curio_house_theme.tres")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(FileAccess.file_exists("res://assets/fonts/CormorantGaramond-Variable.ttf"), "Cormorant Garamond must be vendored")
	_expect(FileAccess.file_exists("res://assets/fonts/Manrope-Variable.ttf"), "Manrope must be vendored")
	_expect(FileAccess.file_exists("res://assets/licenses/CormorantGaramond-OFL.txt"), "Cormorant OFL notice must exist")
	_expect(FileAccess.file_exists("res://assets/licenses/Manrope-OFL.txt"), "Manrope OFL notice must exist")
	_expect(ThemeResource != null and ThemeResource.default_font != null, "global Curio theme must load Manrope")
	var contract: Dictionary = Typography.contract()
	_expect(bool(contract.get("display_font_loaded", false)), "Cormorant display font must load")
	_expect(String(contract.get("license", "")).contains("Open Font License"), "typography contract must retain OFL provenance")
	var root := Control.new()
	var title := Label.new()
	title.name = "Title"
	root.add_child(title)
	var body := Label.new()
	body.name = "Detail"
	root.add_child(body)
	Typography.apply(root)
	_expect(title.has_theme_font_override("font"), "Title nodes must receive display font")
	_expect(not body.has_theme_font_override("font"), "functional body text must inherit the global UI font")
	root.free()
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
