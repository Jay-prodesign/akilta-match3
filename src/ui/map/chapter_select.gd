class_name Match3ChapterSelect
extends Control

signal back_requested
signal chapter_requested(chapter_id: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const LockedExplanation = preload("res://src/ui/shared/locked_explanation.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

const OPENING_LEVEL_COUNT := 3
const CURRENT_WING_ART_PATH := "res://assets/world/ch01_curio_boutique/prestart_curio_boutique_shared.webp"

const WINGS := [
	{"id":"curio_boutique","name":"CURIO BOUTIQUE","x":0.07,"y":0.03,"w":0.86,"h":0.23},
	{"id":"witch_atelier","name":"WITCH ATELIER","x":0.03,"y":0.31,"w":0.46,"h":0.16},
	{"id":"dark_vanity","name":"DARK VANITY","x":0.51,"y":0.31,"w":0.46,"h":0.16},
	{"id":"archive","name":"THE ARCHIVE","x":0.03,"y":0.51,"w":0.46,"h":0.16},
	{"id":"moon_conservatory","name":"MOON CONSERVATORY","x":0.51,"y":0.51,"w":0.46,"h":0.16},
	{"id":"cemetery_garden","name":"CEMETERY GARDEN","x":0.27,"y":0.72,"w":0.46,"h":0.16},
]

var progress
var _resource_bar: PanelContainer
var _buttons: Dictionary = {}

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
	if _world_art.texture == null:
		push_error("S02 Chapters requires authored House world art.")
	if _current_art.texture == null:
		push_error("S02 Chapters requires raster Curio Boutique place art.")

	_resource_bar = TopResourceBar.attach(self, progress)
	_buttons = {
		"curio_boutique": _current,
		"witch_atelier": _witch_atelier,
		"dark_vanity": _dark_vanity,
		"archive": _archive,
		"moon_conservatory": _moon_conservatory,
		"cemetery_garden": _cemetery_garden,
	}

	ProductionChrome.apply_action_button(_back, "utility", "chapter_back")
	ProductionChrome.apply_interactive_button(_current, true, "chapter_current")
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
		if id != "curio_boutique":
			ProductionChrome.apply_interactive_button(button, false, "chapter_locked")
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
	# The North Star chapter chooser is a portrait list, not a dashboard grid.
	# Keep all six wing identities in one scan path even on high-resolution phones.
	var spacing := 10.0
	var current_height := clampf(grid.size.y * 0.235, 150.0, 238.0)
	var locked_height := maxf(88.0, (grid.size.y - current_height - spacing * 5.0) / 5.0)
	var y := 0.0
	for button in buttons:
		var current := String(button.get_meta("chapter_id", "")) == "curio_boutique"
		var height := current_height if current else locked_height
		button.position = Vector2(0.0, y)
		button.size = Vector2(grid.size.x, height)
		button.add_theme_font_size_override("font_size", 27 if current else 20)
		y += height + spacing

func chapter_visual_contract() -> Dictionary:
	return {
		"authored_scene_structure": _buttons.size() == WINGS.size(),
		"current_wing_art_path": CURRENT_WING_ART_PATH,
		"current_wing_art_loaded": _current_art != null and _current_art.texture != null,
		"current_wing_art_is_raster": CURRENT_WING_ART_PATH.ends_with(".webp") or CURRENT_WING_ART_PATH.ends_with(".png"),
		"world_backdrop_loaded": _world_art != null and _world_art.texture != null,
		"future_wings_artless_until_authored": true,
		"future_wings_use_house_world_glass": true,
		"future_wings_specific_art_claimed": false,
		"north_star_title_hierarchy": ($Layout/ChapterHeader/HeaderCopy/Title as Label).get_theme_font_size("font_size") >= 50,
		"compact_header_back": _back != null and _back.custom_minimum_size.x >= 88.0 and _back.custom_minimum_size.x <= 96.0 and _back.custom_minimum_size.y >= 88.0,
		"summary_plate": _chapter_summary != null and _chapter_summary.get_theme_stylebox("normal") != null,
		"chapter_descriptors_present": _witch_atelier.text.contains("POTIONS & EXPERIMENTS") and _dark_vanity.text.contains("MIRRORS & SECRETS") and _archive.text.contains("LOST KNOWLEDGE") and _moon_conservatory.text.contains("CELESTIAL BOTANICALS") and _cemetery_garden.text.contains("RESTING BEAUTIES"),
		"north_star_vertical_wing_list": _grid != null and _current.size.x >= _grid.size.x * 0.95 and _witch_atelier.size.x >= _grid.size.x * 0.95 and _current.position.y < _witch_atelier.position.y and _witch_atelier.position.y < _dark_vanity.position.y and _dark_vanity.position.y < _archive.position.y and _archive.position.y < _moon_conservatory.position.y and _moon_conservatory.position.y < _cemetery_garden.position.y,
		"current_wing_art_subordinate": _current_art != null and _current_art.anchor_right <= 0.31,
		"asset_backed_wing_rows": [_current, _witch_atelier, _dark_vanity, _archive, _moon_conservatory, _cemetery_garden].all(func(button): return button.get_theme_stylebox("normal") is StyleBoxTexture),
		"asset_backed_header_back": _back != null and _back.get_theme_stylebox("normal") is StyleBoxTexture and String(_back.get_meta("production_chrome_kind", "")) == "action_utility_chapter_back",
		"current_copy_clears_thumbnail": _current != null and _current.text == "" and _current_copy != null and _current_copy.anchor_left >= 0.30 and _current_copy.anchor_right <= 0.97 and _current_copy.get_theme_font_size("font_size") <= 24,
		"current_copy_scene_owned": _current_copy != null and _current_copy.get_parent() == _current and _current_copy.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"runtime_style_factory": false,
	}

func _apply_current_style(button: Button, state: String) -> void:
	button.disabled = false
	button.add_theme_color_override("font_color", Color("#FFF7E9"))
	ProductionChrome.apply_interactive_button(button, true, "chapter_current")
	button.set_meta("chapter_visual_state", state)
