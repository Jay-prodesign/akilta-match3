class_name Match3ChapterSelect
extends Control

signal back_requested
signal chapter_requested(chapter_id: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const LockedExplanation = preload("res://src/ui/shared/locked_explanation.gd")

const OPENING_LEVEL_COUNT := 3
const CURRENT_WING_ART_PATH := "res://assets/world/ch01_curio_boutique/prestart_curio_boutique_shared.webp"

const WINGS := [
	{"id":"curio_boutique","name":"CURIO BOUTIQUE","x":0.08,"y":0.04,"w":0.84,"h":0.20},
	{"id":"witch_atelier","name":"WITCH ATELIER","x":0.03,"y":0.32,"w":0.45,"h":0.14},
	{"id":"dark_vanity","name":"DARK VANITY","x":0.52,"y":0.32,"w":0.45,"h":0.14},
	{"id":"archive","name":"THE ARCHIVE","x":0.03,"y":0.51,"w":0.45,"h":0.14},
	{"id":"moon_conservatory","name":"MOON CONSERVATORY","x":0.52,"y":0.51,"w":0.45,"h":0.14},
	{"id":"cemetery_garden","name":"CEMETERY GARDEN","x":0.28,"y":0.70,"w":0.44,"h":0.14},
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
		_current.text = "CURIO BOUTIQUE\nRESTORED WING · 3 / 3 DISPLAYS\nREVISIT RITUALS"
		_current.tooltip_text = "Curio Boutique · first cabinet set restored · Levels 1–3 replayable"
		_chapter_summary.text = "The opening wing is restored. Revisit its rituals while the deeper House remains sealed."
		_lock_reason.text = "FIVE WINGS REMAIN SEALED · FUTURE CHAPTERS"
	elif completed > 0:
		state = "current_partial"
		_current.text = "CURIO BOUTIQUE\nCURRENT WING · %d / %d DISPLAYS\nCONTINUE RESTORATION" % [completed, OPENING_LEVEL_COUNT]
		_current.tooltip_text = "Curio Boutique · %d / %d opening displays awakened" % [completed, OPENING_LEVEL_COUNT]
		_chapter_summary.text = "%d of %d displays are awake. Continue the Curio Boutique restoration." % [completed, OPENING_LEVEL_COUNT]
		_lock_reason.text = "RESTORE THE CURRENT WING · FUTURE WINGS STAY SEALED"
	else:
		_current.text = "CURIO BOUTIQUE\nCURRENT WING · 0 / 3 DISPLAYS\nBEGIN RESTORATION"
		_current.tooltip_text = "Curio Boutique · opening rituals · Levels 1–3"
		_chapter_summary.text = "The Curio Boutique is the House's first open wing. Begin its three opening rituals."
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
	var compact := grid.size.x < 680.0
	var count := buttons.size()
	for i in range(count):
		var button := buttons[i]
		var current := String(button.get_meta("chapter_id", "")) == "curio_boutique"
		if compact:
			var spacing := 8.0
			var card_height := maxf(58.0, (grid.size.y - spacing * float(count - 1)) / float(count))
			button.position = Vector2(0, float(i) * (card_height + spacing))
			button.size = Vector2(grid.size.x, card_height)
			button.add_theme_font_size_override("font_size", 17 if current else 16)
		else:
			button.position = Vector2(grid.size.x * float(button.get_meta("map_x")), grid.size.y * float(button.get_meta("map_y")))
			button.size = Vector2(grid.size.x * float(button.get_meta("map_w")), grid.size.y * float(button.get_meta("map_h")))
			button.add_theme_font_size_override("font_size", 29 if current else 24)

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
	}

func _apply_current_style(button: Button, state: String) -> void:
	button.disabled = false
	button.add_theme_color_override("font_color", Color("#FFF7E9"))
	var source := button.get_theme_stylebox("normal")
	var box := source.duplicate() as StyleBoxFlat if source is StyleBoxFlat else StyleBoxFlat.new()
	if state == "current_partial":
		box.bg_color = Color("#30203A", 0.86)
		box.border_color = Color("#F2D49A", 0.98)
	elif state == "current_complete":
		box.bg_color = Color("#182027", 0.82)
		box.border_color = Color("#E4C67F", 0.98)
	else:
		box.bg_color = Color("#25172C", 0.84)
		box.border_color = Color("#F2D49A", 0.98)
	button.add_theme_stylebox_override("normal", box)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = box.bg_color.lightened(0.08)
	hover.border_color = Color("#FFF0B8")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
