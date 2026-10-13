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

	var geometry_system: Dictionary = data.get("geometry_system", {})
	_expect(int((geometry_system.get("design_viewport", {}) as Dictionary).get("width", 0)) == 1080 and int((geometry_system.get("design_viewport", {}) as Dictionary).get("height", 0)) == 1920, "canonical geometry must target the 1080x1920 portrait design viewport")
	_expect(Array(geometry_system.get("minimum_touch_target", [])) == [88,88], "canonical geometry must preserve an 88x88 logical minimum touch target")
	_expect(Array(geometry_system.get("top_resource_zone_range", [])) == [96,112], "canonical top resource zone range drifted")
	_expect(Array(geometry_system.get("bottom_navigation_zone_range", [])) == [128,144], "canonical bottom navigation zone range drifted")
	var geometry_profiles: Dictionary = data.get("geometry_profiles", {})
	_expect(not geometry_profiles.is_empty(), "canonical geometry profiles missing")

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
					_expect(slot.has("layer"), "%s layer missing" % owner)
					if slot.has("layer"):
						_expect(ALLOWED_LAYERS.has(String(slot.get("layer",""))), "%s invalid layer" % owner)
					_validate_geometry(slot, owner, geometry_profiles)

	var overlays: Dictionary = data.get("overlays", {})
	for expected in EXPECTED_OVERLAYS:
		_expect(overlays.has(expected), "missing canonical overlay %s" % expected)
	for oid in overlays:
		var overlay: Dictionary = overlays[oid]
		_expect(not Array(overlay.get("states", [])).is_empty(), "%s missing overlay states" % oid)
		_expect(not Array(overlay.get("blocks", [])).is_empty(), "%s missing overlay blocks" % oid)
		for raw_block in overlay.get("blocks", []):
			if not raw_block is Dictionary:
				_fail("%s overlay block must be dictionary" % oid)
				continue
			var block: Dictionary = raw_block
			_expect(not Array(block.get("slots", [])).is_empty(), "%s/%s missing overlay slots" % [oid, String(block.get("id", ""))])
			for raw_slot in block.get("slots", []):
				if not raw_slot is Dictionary:
					_fail("%s overlay slot must be dictionary" % oid)
					continue
				var slot: Dictionary = raw_slot
				var owner := "%s -> %s -> %s" % [oid, String(block.get("id", "")), String(slot.get("id", ""))]
				_expect(String(slot.get("id", "")).strip_edges() != "", "%s slot id missing" % owner)
				_expect(not Array(slot.get("states", [])).is_empty(), "%s states missing" % owner)
				_expect(ALLOWED_LAYERS.has(String(slot.get("layer", ""))), "%s layer missing or invalid" % owner)
				_validate_geometry(slot, owner, geometry_profiles)

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
		_expect(String(gate.get("status", "")) == "BLOCKED_PENDING_CANONICAL_SLOT_GEOMETRY_AND_VISUAL_AUDIT", "asset production must stay blocked until slot geometry and visual audit are complete")
		_expect(Array(gate.get("golden_loop", [])) == GOLDEN, "asset gate must preserve the canonical Golden Loop lineage")
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

func _validate_geometry(slot: Dictionary, owner: String, geometry_profiles: Dictionary) -> void:
	var geometry: Dictionary = slot.get("geometry", {})
	_expect(not geometry.is_empty(), "%s geometry missing" % owner)
	if geometry.is_empty():
		return
	var profile := String(geometry.get("profile", ""))
	_expect(profile != "" and geometry_profiles.has(profile), "%s geometry profile missing or unknown" % owner)
	var min_size: Array = geometry.get("min_size", [])
	var preferred_size: Array = geometry.get("preferred_size", [])
	_expect(min_size.size() == 2 and float(min_size[0]) > 0.0 and float(min_size[1]) > 0.0, "%s min_size must be explicit and positive" % owner)
	_expect(preferred_size.size() == 2 and float(preferred_size[0]) > 0.0 and float(preferred_size[1]) > 0.0, "%s preferred_size must be explicit and positive" % owner)
	_expect(String(geometry.get("placement", "")).strip_edges() != "", "%s placement missing" % owner)
	_expect(String(geometry.get("aspect_policy", "")).strip_edges() != "", "%s aspect policy missing" % owner)
	_expect(String(geometry.get("fit", "")).strip_edges() != "", "%s fit policy missing" % owner)
	_expect(String(geometry.get("safe_area", "")).strip_edges() != "", "%s safe-area policy missing" % owner)
	_expect(String(geometry.get("z_policy", "")).strip_edges() != "", "%s z policy missing" % owner)
	if geometry.has("touch_target"):
		var touch: Array = geometry.get("touch_target", [])
		_expect(touch.size() == 2 and float(touch[0]) >= 88.0 and float(touch[1]) >= 88.0, "%s touch target must be at least 88x88 logical px" % owner)


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
