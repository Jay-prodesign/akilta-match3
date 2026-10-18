class_name Match3ChapterSelect
extends Control

signal back_requested
signal chapter_requested(chapter_id: String)
signal interaction_feedback_requested(kind: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const LockedExplanation = preload("res://src/ui/shared/locked_explanation.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

const OPENING_LEVEL_COUNT := 3
const CURRENT_WING_ART_PATH := "res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp"
const SEALED_WING_SEAL_PATH := "res://assets/blockers/ch01_blocker_wax_seal_intact_v01.webp"

const WINGS := [
	{"id":"curio_boutique","name":"CURIO BOUTIQUE","x":0.04,"y":0.02,"w":0.92,"h":0.205},
	{"id":"witch_atelier","name":"WITCH ATELIER","x":0.08,"y":0.255,"w":0.84,"h":0.095},
	{"id":"dark_vanity","name":"DARK VANITY","x":0.08,"y":0.375,"w":0.84,"h":0.095},
	{"id":"archive","name":"THE ARCHIVE","x":0.08,"y":0.495,"w":0.84,"h":0.095},
	{"id":"moon_conservatory","name":"MOON CONSERVATORY","x":0.08,"y":0.615,"w":0.84,"h":0.095},
	{"id":"cemetery_garden","name":"CEMETERY GARDEN","x":0.08,"y":0.735,"w":0.84,"h":0.095},
]

var progress
var _resource_bar: PanelContainer
var _buttons: Dictionary = {}
var _reduced_motion: bool = false
var _chapter_tactile_buttons: Array[Button] = []

@onready var _world_art: TextureRect = $ChapterWorldBackdrop
@onready var _chapter_summary: Label = $Layout/ChapterSummary
@onready var _lock_reason: Label = $Layout/LockReason
@onready var _grid: Control = $Layout/ChapterGrid
@onready var _back: Button = $Layout/ChapterHeader/HeaderBack
@onready var _current: Button = $Layout/ChapterGrid/CurioBoutiqueButton
@onready var _current_art: TextureRect = $Layout/ChapterGrid/CurioBoutiqueButton/CurrentWingArtwork
@onready var _current_copy: Label = $Layout/ChapterGrid/CurioBoutiqueButton/CurrentWingCopy
@onready var _witch_atelier: Button = $Layout/ChapterGrid/Chapter_witch_atelier
@onready var _dark_vanity: Button = $Layout/ChapterGrid/Chapter_dark_vanity
@onready var _archive: Button = $Layout/ChapterGrid/Chapter_archive
@onready var _moon_conservatory: Button = $Layout/ChapterGrid/Chapter_moon_conservatory
@onready var _cemetery_garden: Button = $Layout/ChapterGrid/Chapter_cemetery_garden

func _ready() -> void:
	_world_art.texture = ScreenArt.texture("chapters_bg_curio_house")
	_current_art.texture = PieceAssetLoader.ornament(CURRENT_WING_ART_PATH)
	var sealed_wing_seal := PieceAssetLoader.ornament(SEALED_WING_SEAL_PATH)
	if _world_art.texture == null:
		push_error("S02 Chapters requires authored House world art.")
	if _current_art.texture == null:
		push_error("S02 Chapters requires raster Curio Boutique place art.")
	if sealed_wing_seal == null:
		push_error("S02 Chapters requires a shared sealed-state marker.")

	_resource_bar = TopResourceBar.attach(self, progress)
	_buttons = {
		"curio_boutique": _current,
		"witch_atelier": _witch_atelier,
		"dark_vanity": _dark_vanity,
		"archive": _archive,
		"moon_conservatory": _moon_conservatory,
		"cemetery_garden": _cemetery_garden,
	}

	_back.set_meta("chapter_material", "scene_authored_flat")
	_current.set_meta("chapter_material", "scene_authored_flat")
	_bind_chapter_tactile(_back, "back", 0.94)
	_back.pressed.connect(func(): back_requested.emit())
	_current.pressed.connect(func(): chapter_requested.emit("curio_boutique"))

	var hotspot_buttons: Array[Button] = []
	for wing in WINGS:
		var id := String(wing["id"])
		var button := get_chapter_button(id)
		if button == null:
			continue
		button.set_meta("chapter_id", id)
		button.set_meta("map_x", float(wing["x"]))
		button.set_meta("map_y", float(wing["y"]))
		button.set_meta("map_w", float(wing["w"]))
		button.set_meta("map_h", float(wing["h"]))
		button.set_meta("chapter_state", "first_wing_open" if id == "curio_boutique" else "future_wings_locked")
		_bind_chapter_tactile(button, "current_wing" if id == "curio_boutique" else "sealed_wing", 0.965 if id == "curio_boutique" else 0.982)
		if id != "curio_boutique":
			button.set_meta("chapter_material", "scene_authored_flat")
			var wax_seal := button.get_node_or_null("WaxSeal") as TextureRect
			if wax_seal != null:
				wax_seal.texture = sealed_wing_seal
				wax_seal.anchor_left = 0.90
				wax_seal.anchor_right = 0.90
				wax_seal.anchor_top = 0.50
				wax_seal.anchor_bottom = 0.50
				wax_seal.offset_left = -32.0
				wax_seal.offset_top = -32.0
				wax_seal.offset_right = 32.0
				wax_seal.offset_bottom = 32.0
			button.set_meta("sealed_status_marker", "shared_wax_seal")
			button.tooltip_text = "%s · inspect why this future chapter remains sealed" % String(wing["name"]).capitalize()
			button.pressed.connect(_show_sealed_wing.bind(id, String(wing["name"])))
		hotspot_buttons.append(button)

	_grid.resized.connect(func(): _layout_chapter_hotspots(_grid, hotspot_buttons))
	call_deferred("_layout_chapter_hotspots", _grid, hotspot_buttons)
	_refresh_progress_state()

func set_progress(value) -> void:
	progress = value
	TopResourceBar.refresh(_resource_bar, progress)
	_refresh_progress_state()

func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	if _reduced_motion:
		for button in _chapter_tactile_buttons:
			_stop_chapter_tactile_tween(button)
			button.scale = Vector2.ONE
			button.modulate = Color.WHITE
			button.set_meta("chapter_tactile_phase", "idle")

func chapter_interaction_contract() -> Dictionary:
	var all_rows_tactile := true
	var sealed_press_is_subtle := true
	for button in [_current, _witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden]:
		all_rows_tactile = all_rows_tactile and button != null and bool(button.get_meta("chapter_tactile_bound", false))
	for button in [_witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden]:
		sealed_press_is_subtle = sealed_press_is_subtle and button != null and float(button.get_meta("chapter_tactile_press_scale", 1.0)) >= 0.98
	return {
		"chapter_rows_tactile": all_rows_tactile,
		"current_wing_press_depth": _current != null and float(_current.get_meta("chapter_tactile_press_scale", 1.0)) <= 0.97,
		"sealed_wing_press_subtle": sealed_press_is_subtle,
		"back_tactile": _back != null and bool(_back.get_meta("chapter_tactile_bound", false)) and float(_back.get_meta("chapter_tactile_press_scale", 1.0)) <= 0.95,
		"reduced_motion_supported": true,
		"feedback_signal": has_signal("interaction_feedback_requested"),
	}

func _bind_chapter_tactile(button: Button, role: String, press_scale: float) -> void:
	if button == null:
		return
	button.set_meta("chapter_tactile_role", role)
	button.set_meta("chapter_tactile_press_scale", press_scale)
	if bool(button.get_meta("chapter_tactile_bound", false)):
		return
	button.set_meta("chapter_tactile_bound", true)
	_chapter_tactile_buttons.append(button)
	button.button_down.connect(_press_chapter_tactile.bind(button))
	button.button_up.connect(_release_chapter_tactile.bind(button))
	button.mouse_exited.connect(_release_chapter_tactile.bind(button))
	button.focus_exited.connect(_release_chapter_tactile.bind(button))

func _press_chapter_tactile(button: Button) -> void:
	if button == null or button.disabled:
		return
	_stop_chapter_tactile_tween(button)
	button.pivot_offset = button.size * 0.5
	button.set_meta("chapter_tactile_phase", "pressed")
	interaction_feedback_requested.emit("ui")
	if _reduced_motion:
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		return
	var target_scale := clampf(float(button.get_meta("chapter_tactile_press_scale", 0.98)), 0.92, 0.99)
	var role := String(button.get_meta("chapter_tactile_role", ""))
	var pressed_tint := Color(1.0, 0.95, 0.84, 1.0) if role == "current_wing" else (Color(0.95, 0.90, 1.0, 1.0) if role == "sealed_wing" else Color(1.0, 0.96, 0.90, 1.0))
	var tween := create_tween()
	button.set_meta("chapter_tactile_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", pressed_tint, 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _release_chapter_tactile(button: Button) -> void:
	if button == null:
		return
	_stop_chapter_tactile_tween(button)
	button.pivot_offset = button.size * 0.5
	button.set_meta("chapter_tactile_phase", "release")
	if _reduced_motion:
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		button.set_meta("chapter_tactile_phase", "idle")
		return
	var tween := create_tween()
	button.set_meta("chapter_tactile_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color.WHITE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): button.set_meta("chapter_tactile_phase", "idle"))

func _stop_chapter_tactile_tween(button: Button) -> void:
	if button == null or not button.has_meta("chapter_tactile_tween"):
		return
	var previous = button.get_meta("chapter_tactile_tween")
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	button.remove_meta("chapter_tactile_tween")

func get_chapter_button(chapter_id: String) -> Button:
	return _buttons.get(chapter_id) as Button

func chapter_state(chapter_id: String) -> String:
	var button := get_chapter_button(chapter_id)
	return String(button.get_meta("chapter_state", "")) if button != null else ""

func _show_sealed_wing(chapter_id: String, chapter_name: String) -> void:
	var overlay := LockedExplanation.present(
		self,
		chapter_name,
		"This wing belongs to a future chapter and is not playable in this build.",
		"No unlock date, currency cost, reward, timer, or purchase path is active.",
		"RETURN TO CHAPTERS"
	)
	if overlay != null:
		overlay.set_meta("sealed_id", chapter_id)
		overlay.set_meta("sealed_kind", "future_chapter")

func sealed_explanation_contract() -> Dictionary:
	var overlay := get_node_or_null("LockedExplanation") as Control
	var contract := LockedExplanation.contract(overlay)
	if overlay != null:
		contract["sealed_id"] = String(overlay.get_meta("sealed_id", ""))
		contract["sealed_kind"] = String(overlay.get_meta("sealed_kind", ""))
	return contract

func _refresh_progress_state() -> void:
	if _current == null or _chapter_summary == null or _lock_reason == null:
		return
	var completed := 0
	var collected := 0
	var restored := 0
	if progress != null:
		completed = mini(int(progress.completed_levels.size()), OPENING_LEVEL_COUNT)
		collected = mini(int(progress.curios.size()), OPENING_LEVEL_COUNT)
		restored = int(progress.house_stage)
	var opening_complete := completed >= OPENING_LEVEL_COUNT and collected >= OPENING_LEVEL_COUNT and restored >= OPENING_LEVEL_COUNT
	var state := "first_wing_open"
	if opening_complete:
		state = "current_complete"
		_current_copy.text = "CURIO BOUTIQUE\nRARE FINDS · RESTORED 3 / 3\nREVISIT RITUALS"
		_current.tooltip_text = "Curio Boutique · first cabinet set restored · Levels 1–3 replayable"
		_chapter_summary.text = "CURIO BOUTIQUE RESTORED · REVISIT RITUALS"
		_lock_reason.text = "FIVE WINGS SEALED · FUTURE CHAPTERS"
	elif completed > 0:
		state = "current_partial"
		_current_copy.text = "CURIO BOUTIQUE\nRARE FINDS · %d / %d AWAKENED\nCONTINUE RESTORATION" % [completed, OPENING_LEVEL_COUNT]
		_current.tooltip_text = "Curio Boutique · %d / %d opening displays awakened" % [completed, OPENING_LEVEL_COUNT]
		_chapter_summary.text = "CURIO BOUTIQUE · %d / %d DISPLAYS AWAKENED" % [completed, OPENING_LEVEL_COUNT]
		_lock_reason.text = "RESTORE THE CURRENT WING · FUTURE WINGS STAY SEALED"
	else:
		_current_copy.text = "CURIO BOUTIQUE\nRARE FINDS · 0 / 3 AWAKENED\nBEGIN RESTORATION"
		_current.tooltip_text = "Curio Boutique · opening rituals · Levels 1–3"
		_chapter_summary.text = "CURIO BOUTIQUE · FIRST OPEN WING"
		_lock_reason.text = "FUTURE WINGS ARE SEALED UNTIL LATER CHAPTERS"

	_current.set_meta("chapter_state", state)
	_apply_current_style(_current, state)
	for wing in WINGS:
		var id := String(wing["id"])
		if id == "curio_boutique":
			continue
		var locked := get_chapter_button(id)
		if locked != null:
			locked.set_meta("chapter_state", "future_wings_locked")

func _layout_chapter_hotspots(grid: Control, buttons: Array[Button]) -> void:
	if grid == null or grid.size.x <= 0.0 or grid.size.y <= 0.0:
		return
	# Locked North Star screen 5 is a compact six-row chapter list.
	# Keep the authored Curio Boutique thumbnail and use only shared sealed
	# status art for future wings whose destination artwork is not authored.
	for button in buttons:
		var x := float(button.get_meta("map_x", 0.0))
		var y := float(button.get_meta("map_y", 0.0))
		var w := float(button.get_meta("map_w", 1.0))
		var h := float(button.get_meta("map_h", 0.16))
		button.position = Vector2(roundf(grid.size.x * x), roundf(grid.size.y * y))
		button.size = Vector2(roundf(grid.size.x * w), roundf(grid.size.y * h))
		var current := String(button.get_meta("chapter_id", "")) == "curio_boutique"
		button.add_theme_font_size_override("font_size", 24 if current else 20)

func chapter_visual_contract() -> Dictionary:
	var sealed_markers_authored := true
	for button in [_witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden]:
		var seal := button.get_node_or_null("WaxSeal") as TextureRect
		sealed_markers_authored = sealed_markers_authored and seal != null and seal.texture != null
	return {
		"authored_scene_structure": _buttons.size() == WINGS.size(),
		"current_wing_art_path": CURRENT_WING_ART_PATH,
		"current_wing_art_loaded": _current_art != null and _current_art.texture != null,
		"current_wing_art_is_raster": CURRENT_WING_ART_PATH.ends_with(".webp") or CURRENT_WING_ART_PATH.ends_with(".png"),
		"world_backdrop_loaded": _world_art != null and _world_art.texture != null,
		"future_wings_artless_until_authored": true,
		"future_wings_use_house_world_glass": true,
		"future_wings_specific_art_claimed": false,
		"shared_sealed_status_marker": sealed_markers_authored,
		"north_star_title_hierarchy": ($Layout/ChapterHeader/HeaderCopy/Title as Label).text == "CHAPTERS" and ($Layout/ChapterHeader/HeaderCopy/Title as Label).get_theme_font_size("font_size") >= 38,
		"compact_header_back": _back != null and _back.custom_minimum_size.x >= 60.0 and _back.custom_minimum_size.x <= 72.0 and _back.custom_minimum_size.y >= 60.0 and _back.custom_minimum_size.y <= 72.0,
		"summary_suppressed_for_board_parity": _chapter_summary != null and not _chapter_summary.visible and _lock_reason != null and not _lock_reason.visible,
		"chapter_descriptors_present": _witch_atelier.text.contains("POTIONS & EXPERIMENTS") and _dark_vanity.text.contains("MIRRORS & SECRETS") and _archive.text.contains("LOST KNOWLEDGE") and _moon_conservatory.text.contains("CELESTIAL BOTANICALS") and _cemetery_garden.text.contains("RESTING BEAUTIES"),
		"north_star_vertical_chapter_list": _grid != null and _current.size.x >= _grid.size.x * 0.90 and _current.size.x <= _grid.size.x * 0.94 and _current.size.y >= _grid.size.y * 0.19 and _current.size.y <= _grid.size.y * 0.22 and [_witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden].all(func(button): return button.size.x >= _grid.size.x * 0.82 and button.size.x <= _grid.size.x * 0.86 and button.size.y >= _grid.size.y * 0.085 and button.size.y <= _grid.size.y * 0.105) and _current.position.y < _witch_atelier.position.y and _witch_atelier.position.y < _dark_vanity.position.y and _dark_vanity.position.y < _archive.position.y and _archive.position.y < _moon_conservatory.position.y and _moon_conservatory.position.y < _cemetery_garden.position.y,
		"current_wing_art_thumbnail": _current_art != null and _current_art.anchor_right >= 0.41 and _current_art.anchor_right <= 0.45 and _current_art.anchor_bottom >= 0.98,
		"current_wing_hero_dominance": _current.size.y >= _witch_atelier.size.y * 1.9 and _current_art.anchor_right >= 0.40,
		"compact_sealed_door_rows": [_witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden].all(func(button): return button.size.y <= _grid.size.y * 0.105 and button.size.x <= _grid.size.x * 0.86),
		"sealed_copy_two_line": [_witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden].all(func(button): return button.text.count("\n") == 1 and button.text.contains("SEALED")),
		"locked_row_readability": [_witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden].all(func(button): return button.get_theme_font_size("font_size") >= 19 and button.alignment == HORIZONTAL_ALIGNMENT_LEFT),
		"scene_authored_wing_rows": [_current, _witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden].all(func(button): return button.get_theme_stylebox("normal") is StyleBoxFlat and String(button.get_meta("chapter_material", "")) == "scene_authored_flat"),
		"scene_authored_header_back": _back != null and _back.get_theme_stylebox("normal") is StyleBoxFlat and String(_back.get_meta("chapter_material", "")) == "scene_authored_flat",
		"sealed_marker_scale": [_witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden].all(func(button): var seal = button.get_node_or_null("WaxSeal") as TextureRect; return seal != null and seal.texture != null and seal.offset_right - seal.offset_left >= 64.0),
		"sealed_marker_right_rail": [_witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden].all(func(button): var seal = button.get_node_or_null("WaxSeal") as TextureRect; return seal != null and seal.anchor_left >= 0.88),
		"current_copy_clears_thumbnail": _current != null and _current.text == "" and _current_copy != null and _current_copy.anchor_left >= 0.44 and _current_copy.anchor_right <= 0.97 and _current_copy.get_theme_font_size("font_size") >= 23 and _current_copy.get_theme_font_size("font_size") <= 25,
		"current_copy_scene_owned": _current_copy != null and _current_copy.get_parent() == _current and _current_copy.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"runtime_style_factory": false,
	}

func _apply_current_style(button: Button, state: String) -> void:
	button.disabled = false
	button.add_theme_color_override("font_color", Color("#FFF7E9"))
	button.set_meta("chapter_material", "scene_authored_flat")
	button.set_meta("chapter_visual_state", state)
