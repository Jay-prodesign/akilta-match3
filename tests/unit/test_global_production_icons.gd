extends SceneTree

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")

const ICONS := [
	"res://assets/ui/nav_house.svg",
	"res://assets/ui/nav_curios.svg",
	"res://assets/ui/nav_map.svg",
	"res://assets/ui/nav_events.svg",
	"res://assets/ui/nav_shop.svg",
	"res://assets/ui/ui_coin.svg",
	"res://assets/ui/ui_gem.svg",
	"res://assets/ui/ui_profile.svg",
	"res://assets/ui/ui_settings.svg",
]

var failures: Array[String] = []

func _init() -> void:
	for path in ICONS:
		var text := FileAccess.get_file_as_string(path)
		_expect(text.contains("cat-coven-production-icon-v1"), "%s missing production-family marker" % path)
		_expect(text.contains("width=\"128\"") and text.contains("height=\"128\""), "%s must use the 128x128 master geometry" % path)
		_expect(text.contains("linearGradient id=\"gold\"") and text.contains("linearGradient id=\"plum\""), "%s must retain the shared material gradients" % path)
		var texture := PieceAssetLoader.ornament(path)
		_expect(texture != null, "%s must runtime-decode as a texture" % path)
		_expect(texture != null and texture.get_width() >= 96 and texture.get_height() >= 96, "%s must remain legible at production master size" % path)
	if failures.is_empty():
		print("TEST_PASS: global production icon family")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
