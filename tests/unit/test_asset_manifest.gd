extends SceneTree

const MANIFEST := "res://assets/manifests/level1_asset_manifest.json"
const VALID_STATUSES := ["concept", "reference", "candidate", "approved", "shipping", "retired"]
const REQUIRED_FIELDS := ["id", "class", "scope", "path", "status", "target", "format", "role", "approval", "provenance"]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not FileAccess.file_exists(MANIFEST):
		_fail("Level 1 asset manifest is missing")
		_finish()
		return
	var file := FileAccess.open(MANIFEST, FileAccess.READ)
	if file == null:
		_fail("Level 1 asset manifest is unreadable")
		_finish()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_fail("Level 1 asset manifest must be a dictionary")
		_finish()
		return
	var data: Dictionary = parsed
	_expect(int(data.get("schema_version", 0)) == 1, "manifest schema_version must be 1")
	var viewport: Dictionary = data.get("design_viewport", {})
	_expect(int(viewport.get("width", 0)) == 1080 and int(viewport.get("height", 0)) == 1920, "manifest must pin 1080x1920 portrait baseline")
	var ids: Dictionary = {}
	var assets: Array = data.get("assets", [])
	_expect(assets.size() >= 20, "Level 1 manifest must cover the complete asset classes, not only five pieces")
	for raw in assets:
		if not raw is Dictionary:
			_fail("manifest asset entry must be a dictionary")
			continue
		var asset: Dictionary = raw
		for field in REQUIRED_FIELDS:
			_expect(asset.has(field) and String(asset.get(field, "")).strip_edges() != "", "%s missing required field %s" % [String(asset.get("id", "<unknown>")), field])
		var id := String(asset.get("id", ""))
		_expect(not ids.has(id), "duplicate semantic asset id: %s" % id)
		ids[id] = true
		var status := String(asset.get("status", ""))
		_expect(VALID_STATUSES.has(status), "%s has invalid status %s" % [id, status])
		var path := String(asset.get("path", ""))
		if status in ["candidate", "approved", "shipping"] and not path.begins_with("runtime:"):
			_expect(FileAccess.file_exists("res://" + path), "%s runtime-eligible asset path does not exist: %s" % [id, path])
		_expect(not String(asset.get("provenance", "")).to_lower().contains("paid"), "%s violates zero-paid-input contract" % id)
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: Level 1 asset production manifest")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
