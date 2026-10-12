extends SceneTree

const LevelCatalog = preload("res://src/content/level_catalog.gd")
var failures: Array[String] = []

func _init() -> void:
	var catalog = LevelCatalog.load_default()
	_expect(catalog != null, "canonical level catalog must load")
	if catalog != null:
		var issues: Array[String] = catalog.validate()
		_expect(issues.is_empty(), "canonical level catalog must validate: %s" % str(issues))
		_expect(catalog.count() == 3, "current opening catalog must own exactly three verified levels")
		for number in range(1, catalog.count() + 1):
			var entry: Dictionary = catalog.entry(number)
			_expect(int(entry.get("number", 0)) == number, "catalog level numbers must be contiguous")
			_expect(String(entry.get("id", "")) == "ch01_level_%03d" % number, "catalog id must map deterministically")
			_expect(String(catalog.level_path(number)).ends_with("level_%03d.json" % number), "catalog path must map deterministically")
			var route_art := String(entry.get("route_art", ""))
			_expect(route_art.ends_with(".webp") or route_art.ends_with(".png"), "route art must be raster-first")
			_expect(FileAccess.file_exists(route_art), "route art must exist")
	if failures.is_empty():
		print("TEST_PASS: canonical data-driven level catalog authority")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
