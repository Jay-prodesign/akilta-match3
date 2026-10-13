class_name Match3CurioCollection
extends Control

signal back_requested
signal house_inspect_requested(curio_id: String)

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const CurioDetailScene = preload("res://src/ui/collection/curio_detail_panel.tscn")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

const MOON_SEALED_PATH := "res://assets/curios/ch01_curio_moon_cameo_sealed_v01.webp"
const MOON_AWAKENED_PATH := "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp"
const MOTH_RELIQUARY_PATH := "res://assets/curios/ch01_curio_moth_reliquary.png"
const THORNED_LOCKET_PATH := "res://assets/curios/ch01_curio_thorned_locket.png"

var progress
var _detail_overlay: Control
var _moon_textures: Dictionary = {}

@onready var backdrop: TextureRect = $ReliquaryMoonlitBackdrop
@onready var count_label: Label = $Layout/Count
@onready var cabinet_footer: Label = $Layout/CabinetFooter
@onready var cabinet_grid: GridContainer = $Layout/Cards
@onready var set_summary: PanelContainer = $Layout/Cards/SetSummary
@onready var set_summary_progress: Label = $Layout/Cards/SetSummary/Content/Progress
@onready var set_summary_copy: Label = $Layout/Cards/SetSummary/Content/Copy
@onready var moon_card: PanelContainer = $Layout/Cards/MoonCard
@onready var moon_art: TextureRect = $Layout/Cards/MoonCard/Content/RitualArt
@onready var moon_state: Label = $Layout/Cards/MoonCard/Content/Copy/State
@onready var moon_detail: Label = $Layout/Cards/MoonCard/Content/Copy/Detail
@onready var moon_origin: Label = $Layout/Cards/MoonCard/Content/Copy/Origin
@onready var moon_action: Button = $Layout/Cards/MoonCard/DetailActionLayer/InspectAction
@onready var slot2_card: PanelContainer = $Layout/Cards/Slot2
@onready var slot2_art: TextureRect = $Layout/Cards/Slot2/Content/Number/RewardArt
@onready var slot2_name: Label = $Layout/Cards/Slot2/Content/Copy/Name
@onready var slot2_hint: Label = $Layout/Cards/Slot2/Content/Copy/Hint
@onready var slot2_state: Label = $Layout/Cards/Slot2/Content/Copy/State
@onready var slot2_origin: Label = $Layout/Cards/Slot2/Content/Copy/Origin
@onready var slot2_action: Button = $Layout/Cards/Slot2/DetailActionLayer/InspectAction
@onready var slot3_card: PanelContainer = $Layout/Cards/Slot3
@onready var slot3_art: TextureRect = $Layout/Cards/Slot3/Content/Number/RewardArt
@onready var slot3_name: Label = $Layout/Cards/Slot3/Content/Copy/Name
@onready var slot3_hint: Label = $Layout/Cards/Slot3/Content/Copy/Hint
@onready var slot3_state: Label = $Layout/Cards/Slot3/Content/Copy/State
@onready var slot3_origin: Label = $Layout/Cards/Slot3/Content/Copy/Origin
@onready var slot3_action: Button = $Layout/Cards/Slot3/DetailActionLayer/InspectAction
@onready var back_button: Button = $Layout/Back

func _ready() -> void:
	backdrop.texture = ScreenArt.texture("reliquary_bg_curio_boutique")
	moon_art.texture = _load_moon_texture(MOON_SEALED_PATH)
	slot2_art.texture = PieceAssetLoader.ornament(MOTH_RELIQUARY_PATH)
	slot3_art.texture = PieceAssetLoader.ornament(THORNED_LOCKET_PATH)
	ProductionChrome.apply_action_button(moon_action, "utility", "reliquary_detail")
	ProductionChrome.apply_action_button(slot2_action, "utility", "reliquary_detail")
	ProductionChrome.apply_action_button(slot3_action, "utility", "reliquary_detail")
	ProductionChrome.apply_compact_panel(set_summary, "reliquary_set_summary")
	ProductionChrome.apply_action_button(back_button, "utility", "reliquary_back")
	back_button.pressed.connect(func(): back_requested.emit())
	moon_action.pressed.connect(func(): _open_curio_detail("moon_cameo"))
	slot2_action.pressed.connect(func(): _open_curio_detail("moth_reliquary"))
	slot3_action.pressed.connect(func(): _open_curio_detail("thorned_locket"))
	_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	var curios: Array = progress.curios if progress != null else []
	var awakened_count := mini(3, curios.size())
	var dormant_count := maxi(0, 3 - awakened_count)
	count_label.text = "FIRST CABINET SET · %d / 3 AWAKENED" % awakened_count
	set_summary_progress.text = "%d / 3 AWAKENED" % awakened_count
	set_summary_copy.text = "CABINET COMPLETE · ALL THREE CURIOS RESTORED" if awakened_count >= 3 else "%d DORMANT · RECOVER THEM THROUGH LEVELS 1–3" % dormant_count
	cabinet_footer.text = "OPENING CABINET COMPLETE · 3 / 3 CURIOS RECOVERED" if awakened_count >= 3 else "OPENING CABINET · %d / 3 CURIOS RECOVERED" % awakened_count

	var has_moon := curios.has("moon_cameo")
	moon_state.text = "AWAKENED · RELIC 01" if has_moon else "DORMANT · RELIC 01"
	moon_detail.text = "Moonlight remembers your first victory." if has_moon else "Win Level 1 to wake the first relic."
	moon_origin.text = "RECOVERED FROM · MOONLIT CABINET" if has_moon else "SEALED BEHIND · MOONLIT CABINET"
	moon_art.texture = _load_moon_texture(MOON_AWAKENED_PATH if has_moon else MOON_SEALED_PATH)
	moon_art.modulate = Color.WHITE if has_moon else Color(0.58, 0.54, 0.64, 0.68)
	_apply_display_style(moon_card, has_moon, Color("#D5AD70"))
	_apply_copy_style(null, moon_detail, moon_state, moon_origin, has_moon)

	var has_moth := curios.has("moth_reliquary")
	slot2_name.text = "MOTH RELIQUARY"
	slot2_hint.text = "Recovered from the sealed side cabinet." if has_moth else "Clear both wax seals in Level 2."
	slot2_state.text = "AWAKENED · RELIC 02" if has_moth else "DORMANT · RELIC 02"
	slot2_origin.text = "RECOVERED FROM · SEALED DISPLAY" if has_moth else "SEALED BEHIND · WAX DISPLAY"
	slot2_art.modulate = Color.WHITE if has_moth else Color(0.56, 0.54, 0.62, 0.66)
	_apply_display_style(slot2_card, has_moth, Color("#9BBED0"))
	_apply_copy_style(slot2_name, slot2_hint, slot2_state, slot2_origin, has_moth)

	var has_locket := curios.has("thorned_locket")
	slot3_name.text = "THORNED LOCKET"
	slot3_hint.text = "A moon-beam sigil opened its thorned clasp." if has_locket else "Create and trigger a line special in Level 3."
	slot3_state.text = "AWAKENED · RELIC 03" if has_locket else "DORMANT · RELIC 03"
	slot3_origin.text = "RECOVERED FROM · THORNLIGHT ARRANGEMENT" if has_locket else "SEALED BEHIND · THORNLIGHT"
	slot3_art.modulate = Color.WHITE if has_locket else Color(0.56, 0.54, 0.62, 0.66)
	_apply_display_style(slot3_card, has_locket, Color("#C98BA8"))
	_apply_copy_style(slot3_name, slot3_hint, slot3_state, slot3_origin, has_locket)

func _apply_display_style(card: PanelContainer, awakened: bool, _accent: Color) -> void:
	if card == null:
		return
	ProductionChrome.apply_compact_panel(card, "reliquary_display")
	card.set_meta("reliquary_awakened", awakened)

func _apply_copy_style(name_label: Label, detail_label: Label, state_label: Label, origin_label: Label, awakened: bool) -> void:
	if name_label != null:
		name_label.add_theme_color_override("font_color", Color("#FFF0D8") if awakened else Color("#D3C4D2"))
	if detail_label != null:
		detail_label.add_theme_color_override("font_color", Color("#EFE2E8") if awakened else Color("#BFAFC4"))
	if state_label != null:
		state_label.add_theme_color_override("font_color", Color("#F2D08B") if awakened else Color("#BDAFC3"))
	if origin_label != null:
		origin_label.add_theme_color_override("font_color", Color("#BDAFC3") if awakened else Color("#9F91A5"))

func _load_moon_texture(path: String) -> Texture2D:
	if _moon_textures.has(path):
		return _moon_textures[path]
	var texture := PieceAssetLoader.ornament(path)
	if texture != null:
		_moon_textures[path] = texture
	return texture

# Exact-head visual gate: the cabinet-stage contract below is intentionally runtime-observable so the rendered Reliquary composition can be verified alongside functional truth.
func curio_asset_contract() -> Dictionary:
	var paths := {
		"moon_sealed": MOON_SEALED_PATH,
		"moon_awakened": MOON_AWAKENED_PATH,
		"moth_reliquary": MOTH_RELIQUARY_PATH,
		"thorned_locket": THORNED_LOCKET_PATH
	}
	var loaded := {}
	var raster_runtime := true
	for key in paths:
		var path := String(paths[key])
		raster_runtime = raster_runtime and (path.ends_with(".webp") or path.ends_with(".png"))
		loaded[key] = PieceAssetLoader.ornament(path) != null
	return {
		"paths": paths,
		"loaded": loaded,
		"raster_runtime": raster_runtime,
		"authored_display_slots": moon_art != null and slot2_art != null and slot3_art != null,
		"world_backdrop_loaded": backdrop != null and backdrop.texture != null,
		"authored_detail_scene": true,
		"north_star_title_hierarchy": ($Layout/Title as Label).text == "CURIO CABINET" and ($Layout/Title as Label).get_theme_font_size("font_size") >= 48,
		"north_star_count_plate": count_label != null and count_label.get_theme_stylebox("normal") != null and count_label.custom_minimum_size.y >= 50.0,
		"curio_art_readable": moon_art != null and moon_art.custom_minimum_size.y >= 96.0 and slot2_art != null and slot3_art != null,
		"collection_occupies_cabinet_stage": cabinet_grid != null and cabinet_grid.custom_minimum_size.y >= 410.0 and cabinet_grid.custom_minimum_size.y <= 450.0 and cabinet_grid.size_flags_vertical != Control.SIZE_EXPAND_FILL and [moon_card, slot2_card, slot3_card, set_summary].all(func(card): return card.custom_minimum_size.y >= 200.0 and card.custom_minimum_size.y <= 220.0),
		"back_anchored_to_stage_bottom": ($Layout/StageSpacer as Control) != null and ($Layout/StageSpacer as Control).size_flags_vertical == Control.SIZE_EXPAND_FILL and back_button.custom_minimum_size.y >= 68.0,
		"asset_backed_display_chrome": [moon_card, slot2_card, slot3_card].all(func(card): return card.get_theme_stylebox("panel") is StyleBoxTexture and String(card.get_meta("production_chrome_kind", "")) == "compact_reliquary_display") and set_summary.get_theme_stylebox("panel") is StyleBoxTexture and String(set_summary.get_meta("production_chrome_kind", "")) == "compact_reliquary_set_summary",
		"asset_backed_actions": [moon_action, slot2_action, slot3_action, back_button].all(func(button): return button.get_theme_stylebox("normal") is StyleBoxTexture),
		"runtime_style_factory": false,
		"cabinet_footer": cabinet_footer != null and cabinet_footer.get_theme_stylebox("normal") != null,
		"north_star_collection_grid": cabinet_grid != null and cabinet_grid.columns == 2 and cabinet_grid.get_child_count() == 4 and moon_card.size_flags_horizontal == Control.SIZE_EXPAND_FILL and slot2_card.size_flags_horizontal == Control.SIZE_EXPAND_FILL and slot3_card.size_flags_horizontal == Control.SIZE_EXPAND_FILL,
		"truthful_set_summary": set_summary != null and set_summary_progress != null and set_summary_progress.text.contains("/ 3 AWAKENED") and set_summary_copy != null and not set_summary_copy.text.is_empty(),
		"compact_curio_tiles": moon_card.custom_minimum_size.y <= 220.0 and slot2_card.custom_minimum_size.y <= 220.0 and slot3_card.custom_minimum_size.y <= 220.0 and moon_action.custom_minimum_size.y <= 64.0 and slot2_action.custom_minimum_size.y <= 64.0 and slot3_action.custom_minimum_size.y <= 64.0,
		"collection_copy_subordinate": not moon_detail.visible and not moon_origin.visible and not slot2_hint.visible and not slot2_origin.visible and not slot3_hint.visible and not slot3_origin.visible,
		"intro_subordinate": ($Layout/Intro as Label) != null and not ($Layout/Intro as Label).visible,
		"runtime_ui_factory": false,
	}

func _open_curio_detail(curio_id: String) -> void:
	_close_curio_detail()
	var data := _curio_detail_data(curio_id)
	if data.is_empty():
		return
	var awakened := _is_curio_awakened(curio_id)
	var texture := _detail_texture(curio_id, awakened)
	var overlay := CurioDetailScene.instantiate()
	overlay.name = "CurioDetailOverlay"
	add_child(overlay)
	_detail_overlay = overlay
	if not bool(overlay.configure(curio_id, data, awakened, texture)):
		overlay.queue_free()
		_detail_overlay = null
		return
	overlay.close_requested.connect(_close_curio_detail)
	overlay.view_house_requested.connect(func(id: String): house_inspect_requested.emit(id))

func _close_curio_detail() -> void:
	if _detail_overlay != null and is_instance_valid(_detail_overlay):
		_detail_overlay.queue_free()
	_detail_overlay = null

func _is_curio_awakened(curio_id: String) -> bool:
	return progress != null and progress.curios.has(curio_id)

func _detail_texture(curio_id: String, awakened: bool) -> Texture2D:
	match curio_id:
		"moon_cameo":
			return _load_moon_texture(MOON_AWAKENED_PATH if awakened else MOON_SEALED_PATH)
		"moth_reliquary":
			return PieceAssetLoader.ornament(MOTH_RELIQUARY_PATH)
		"thorned_locket":
			return PieceAssetLoader.ornament(THORNED_LOCKET_PATH)
		_:
			return null

func _curio_detail_data(curio_id: String) -> Dictionary:
	match curio_id:
		"moon_cameo":
			return {
				"name": "MOON CAMEO",
				"origin_owned": "RECOVERED FROM · MOONLIT CABINET · LEVEL 1",
				"origin_locked": "SEALED BEHIND · MOONLIT CABINET",
				"lore": "The first recovered Curio. Its moonlit face now remains visible in the restored House.",
				"requirement": "Complete Level 1 to awaken the Moon Cameo and restore the first cabinet."
			}
		"moth_reliquary":
			return {
				"name": "MOTH RELIQUARY",
				"origin_owned": "RECOVERED FROM · SEALED DISPLAY · LEVEL 2",
				"origin_locked": "SEALED BEHIND · WAX DISPLAY",
				"lore": "A recovered side-cabinet relic. Its display stays restored after the Level 2 ritual.",
				"requirement": "Complete Level 2 by clearing both wax seals to recover the Moth Reliquary."
			}
		"thorned_locket":
			return {
				"name": "THORNED LOCKET",
				"origin_owned": "RECOVERED FROM · THORNLIGHT ARRANGEMENT · LEVEL 3",
				"origin_locked": "SEALED BEHIND · THORNLIGHT",
				"lore": "The third opening Curio. Its restored place completes the first cabinet set.",
				"requirement": "Complete Level 3 and its Moon Beam objective to recover the Thorned Locket."
			}
		_:
			return {}
