extends SceneTree

const CONTRACT := "res://assets/manifests/screen_contracts.json"
const ASSET_MANIFEST := "res://assets/manifests/screen_asset_manifest.json"
const EXPECTED_SCREENS := ["S00","S01","S02","S03","S04","S05","S06","S07","S08","S09","S10","S11","S12"]
const EXPECTED_OVERLAYS := ["O01","O02","O03","O04","O05","O06","O07"]
const GOLDEN := ["S01","S03","S04","S05","S06","S07","S01"]
const ALLOWED_LAYERS := ["background_art","structural_ui","content_artwork","gameplay_asset","functional_icon","state_asset","runtime_vfx"]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not FileAccess.file_exists(CONTRACT):
		_fail("canonical screen contract missing")
		_finish()
		return
	var file := FileAccess.open(CONTRACT, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if file != null:
		file.close()
	if not parsed is Dictionary:
		_fail("canonical screen contract must parse as a dictionary")
		_finish()
		return
	var data: Dictionary = parsed
	_expect(String(data.get("authority","")).contains("product architecture"), "North Star must be interpreted as product architecture")
	_expect(Array(data.get("golden_playable_loop", [])) == GOLDEN, "Golden loop must be House -> Route -> Prestart -> Gameplay -> Win -> Restoration -> House")
	_expect(Array(data.get("cold_start_prefix", [])) == ["S00","S01"], "cold start must enter House through Splash")
	_expect(Array(data.get("failure_loop", [])) == ["S05","O03","S05"], "failure path must remain inside gameplay through Fail/Retry")

	var screens: Dictionary = data.get("screens", {})
	for expected in EXPECTED_SCREENS:
		_expect(screens.has(expected), "missing canonical screen %s" % expected)
	for sid in screens:
		var screen: Dictionary = screens[sid]
		_expect(String(screen.get("purpose","")).strip_edges() != "", "%s missing purpose" % sid)
		_expect(not Array(screen.get("states",[])).is_empty(), "%s missing states" % sid)
		_expect(not Array(screen.get("regions",[])).is_empty(), "%s missing regions" % sid)
		for raw_region in screen.get("regions", []):
			if not raw_region is Dictionary:
				_fail("%s region must be dictionary" % sid)
				continue
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
					_expect(String(slot.get("id","")).strip_edges() != "", "%s slot id missing" % owner)
					_expect(not Array(slot.get("states",[])).is_empty(), "%s states missing" % owner)
					if slot.has("layer"):
						_expect(ALLOWED_LAYERS.has(String(slot.get("layer",""))), "%s invalid layer" % owner)

	var overlays: Dictionary = data.get("overlays", {})
	for expected in EXPECTED_OVERLAYS:
		_expect(overlays.has(expected), "missing canonical overlay %s" % expected)

	var house: Dictionary = screens.get("S01", {})
	_expect(Array(house.get("exits", [])).has("S03"), "House must expose the current chapter route")
	var prestart: Dictionary = screens.get("S04", {})
	_expect(Array(prestart.get("entry", [])).has("S03"), "Prestart must be owned by the chapter route")
	_expect(not Array(prestart.get("entry", [])).has("S01_fast_continue"), "House must not bypass the route directly into Prestart")

	# P0 art production may only follow canonical Screen -> Region -> Block -> Slot -> State ownership.
	var manifest := _read_json(ASSET_MANIFEST)
	_expect(not manifest.is_empty(), "screen asset manifest must parse")
	if not manifest.is_empty():
		var gate: Dictionary = manifest.get("asset_production_gate", {})
		_expect(String(gate.get("status", "")) == "LOCKED_TO_GOLDEN_LOOP_ONLY", "asset production must stay locked to Golden Loop")
		_expect(Array(gate.get("golden_loop", [])) == GOLDEN, "asset gate must use the canonical Golden Loop")
		for raw_asset in manifest.get("assets", []):
			if not raw_asset is Dictionary:
				continue
			var asset: Dictionary = raw_asset
			if not bool(asset.get("architecture_owned", false)):
				continue
			var owners: Array = asset.get("contract_owners", [])
			_expect(not owners.is_empty(), "%s must declare canonical contract owners" % String(asset.get("asset_id", "<asset>")))
			for raw_owner in owners:
				if not raw_owner is Dictionary:
					_fail("%s has invalid contract owner" % String(asset.get("asset_id", "<asset>")))
					continue
				var owner: Dictionary = raw_owner
				var slot := _find_slot(screens, owner)
				var chain := "%s -> %s -> %s -> %s" % [String(owner.get("screen","")), String(owner.get("region","")), String(owner.get("block","")), String(owner.get("slot",""))]
				_expect(not slot.is_empty(), "%s points to missing canonical slot %s" % [String(asset.get("asset_id","<asset>")), chain])
				if not slot.is_empty():
					var allowed: Array = slot.get("states", [])
					for state in owner.get("states", []):
						_expect(allowed.has(state), "%s claims invalid state %s on %s" % [String(asset.get("asset_id","<asset>")), String(state), chain])
	_finish()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _find_slot(screens: Dictionary, owner: Dictionary) -> Dictionary:
	var screen: Dictionary = screens.get(String(owner.get("screen", "")), {})
	for raw_region in screen.get("regions", []):
		if not raw_region is Dictionary:
			continue
		var region: Dictionary = raw_region
		if String(region.get("id", "")) != String(owner.get("region", "")):
			continue
		for raw_block in region.get("blocks", []):
			if not raw_block is Dictionary:
				continue
			var block: Dictionary = raw_block
			if String(block.get("id", "")) != String(owner.get("block", "")):
				continue
			for raw_slot in block.get("slots", []):
				if raw_slot is Dictionary and String(raw_slot.get("id", "")) == String(owner.get("slot", "")):
					return raw_slot
	return {}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: canonical complete screen/state/block/slot architecture")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
