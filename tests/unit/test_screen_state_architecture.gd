extends SceneTree

const CONTRACT := "res://content/product/screen_state_architecture.json"
const EXPECTED_SCREENS := ["S00","S01","S02","S03","S04","S05","S06","S07","S08","S09","S10","S11","S12"]
const EXPECTED_OVERLAYS := ["O01","O02","O03","O04","O05","O06","O07"]
const GOLDEN := ["S01","S04","S05","S06","S07","S01"]
const ALLOWED_POLICIES := ["component","authored_art","runtime","data","none"]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not FileAccess.file_exists(CONTRACT):
		_fail("screen/state architecture contract missing")
		_finish()
		return
	var file := FileAccess.open(CONTRACT, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if file != null:
		file.close()
	if not parsed is Dictionary:
		_fail("screen/state architecture contract must parse as a dictionary")
		_finish()
		return
	var data: Dictionary = parsed
	_expect(String(data.get("north_star_role","")) == "product_architecture_source", "North Star must be product architecture authority")
	_expect(not bool(data.get("bulk_art_authorized", true)), "bulk art must remain blocked before Golden Loop acceptance")
	var golden: Dictionary = data.get("golden_playable_loop", {})
	_expect(Array(golden.get("sequence", [])) == GOLDEN, "Golden Loop sequence must be House -> Prestart -> Gameplay -> Win -> Restoration -> House")
	_expect(bool(golden.get("downstream_expansion_blocked_until_accepted", false)), "downstream expansion must be gated by Golden Loop acceptance")

	var screen_ids: Array[String] = []
	for raw in data.get("screens", []):
		if not raw is Dictionary:
			_fail("screen entry must be a dictionary")
			continue
		var screen: Dictionary = raw
		var sid := String(screen.get("id",""))
		screen_ids.append(sid)
		_expect(String(screen.get("job","")).strip_edges() != "", "%s missing player job" % sid)
		_expect(not Array(screen.get("states",[])).is_empty(), "%s missing states" % sid)
		_expect(not Array(screen.get("regions",[])).is_empty(), "%s missing regions" % sid)
		for raw_region in screen.get("regions", []):
			_expect(raw_region is Dictionary, "%s region must be dictionary" % sid)
			if not raw_region is Dictionary: continue
			var region: Dictionary = raw_region
			_expect(not Array(region.get("blocks",[])).is_empty(), "%s/%s missing blocks" % [sid,String(region.get("id",""))])
			for raw_block in region.get("blocks", []):
				if not raw_block is Dictionary:
					_fail("%s block must be dictionary" % sid)
					continue
				var block: Dictionary = raw_block
				_expect(not Array(block.get("slots",[])).is_empty(), "%s/%s missing slots" % [sid,String(block.get("id",""))])
				for raw_slot in block.get("slots", []):
					if not raw_slot is Dictionary:
						_fail("%s slot must be dictionary" % sid)
						continue
					var slot: Dictionary = raw_slot
					var owner := "%s -> %s -> %s -> %s" % [sid,String(region.get("id","")),String(block.get("id","")),String(slot.get("id",""))]
					_expect(String(slot.get("kind","")).strip_edges() != "", "%s missing kind" % owner)
					_expect(String(slot.get("layer","")).strip_edges() != "", "%s missing technical layer" % owner)
					var policy := String(slot.get("asset_policy",""))
					_expect(ALLOWED_POLICIES.has(policy), "%s invalid asset policy %s" % [owner,policy])
					if policy == "authored_art":
						_expect(not Array(slot.get("states",[])).is_empty(), "%s authored art requires explicit state ownership" % owner)
	for expected in EXPECTED_SCREENS:
		_expect(screen_ids.has(expected), "missing canonical screen %s" % expected)

	var overlay_ids: Array[String] = []
	for raw in data.get("overlays", []):
		if raw is Dictionary:
			overlay_ids.append(String(raw.get("id","")))
	for expected in EXPECTED_OVERLAYS:
		_expect(overlay_ids.has(expected), "missing canonical overlay %s" % expected)
	_finish()

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
