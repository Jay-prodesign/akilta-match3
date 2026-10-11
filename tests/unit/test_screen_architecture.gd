extends SceneTree

const CONTRACT := "res://assets/manifests/screen_contracts.json"
const ASSET_MANIFEST := "res://assets/manifests/screen_asset_manifest.json"
const REQUIRED_SCREENS := ["S00","S01","S02","S03","S04","S05","S06","S07","S08","S09","S10","S11","S12"]
const REQUIRED_OVERLAYS := ["O01","O02","O03","O04","O05","O06","O07"]
const GOLDEN := ["S01","S03","S04","S05","S06","S07","S01"]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var contract := _read_json(CONTRACT)
	if contract.is_empty():
		_fail("screen contract missing or invalid")
		_finish()
		return
	_expect(int(contract.get("schema_version", 0)) >= 2, "screen contract schema must be >= 2")
	_expect(contract.get("golden_playable_loop", []) == GOLDEN, "golden loop sequence drifted")
	var screens: Dictionary = contract.get("screens", {})
	var overlays: Dictionary = contract.get("overlays", {})
	for id in REQUIRED_SCREENS:
		_expect(screens.has(id), "missing required screen %s" % id)
		if screens.has(id):
			_validate_surface(id, screens[id], true)
	for id in REQUIRED_OVERLAYS:
		_expect(overlays.has(id), "missing required overlay %s" % id)
		if overlays.has(id):
			_validate_surface(id, overlays[id], false)
	var assets := _read_json(ASSET_MANIFEST)
	if not assets.is_empty():
		for raw in assets.get("assets", []):
			if not raw is Dictionary:
				continue
			var asset: Dictionary = raw
			_expect(String(asset.get("block", "")).strip_edges() != "", "%s lacks block owner" % String(asset.get("asset_id", "<asset>")))
			_expect(String(asset.get("slot", "")).strip_edges() != "", "%s lacks slot owner" % String(asset.get("asset_id", "<asset>")))
			_expect(asset.get("state", []).size() > 0, "%s lacks state owner" % String(asset.get("asset_id", "<asset>")))
	_finish()

func _validate_surface(id: String, value: Variant, is_screen: bool) -> void:
	_expect(value is Dictionary, "%s must be dictionary" % id)
	if not value is Dictionary:
		return
	var d: Dictionary = value
	_expect(String(d.get("name", "")).strip_edges() != "", "%s missing name" % id)
	_expect(d.get("states", []).size() > 0, "%s missing states" % id)
	if is_screen:
		_expect(String(d.get("purpose", "")).strip_edges() != "", "%s missing purpose" % id)
		var regions: Array = d.get("regions", [])
		_expect(regions.size() > 0, "%s missing regions" % id)
		for region in regions:
			_expect(region is Dictionary and String(region.get("id", "")) != "", "%s has invalid region" % id)
			if region is Dictionary:
				_validate_blocks(id, region.get("blocks", []))
	else:
		_validate_blocks(id, d.get("blocks", []))

func _validate_blocks(owner: String, blocks: Array) -> void:
	_expect(blocks.size() > 0, "%s has region with no blocks" % owner)
	for block in blocks:
		_expect(block is Dictionary and String(block.get("id", "")) != "", "%s has invalid block" % owner)
		if not block is Dictionary:
			continue
		var slots: Array = block.get("slots", [])
		_expect(slots.size() > 0, "%s/%s has no slots" % [owner, String(block.get("id", ""))])
		for slot in slots:
			_expect(slot is Dictionary and String(slot.get("id", "")) != "", "%s has invalid slot" % owner)
			if slot is Dictionary:
				_expect(slot.get("states", []).size() > 0, "%s/%s/%s has no state binding" % [owner, String(block.get("id","")), String(slot.get("id",""))])

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: complete screen/state architecture and slot ownership")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
