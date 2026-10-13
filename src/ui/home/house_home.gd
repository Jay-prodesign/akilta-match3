class_name Match3HouseHome
extends Control

signal play_requested(level_number: int)
signal collection_requested
signal map_requested
signal settings_requested
signal events_requested
signal shop_requested
signal profile_requested
signal restoration_finished

const HouseState = preload("res://src/world/house_state.gd")
const ProductNavigation = preload("res://src/ui/shared/product_navigation.gd")
const TopResourceBar = preload("res://src/ui/shared/top_resource_bar.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const HouseCurioInspectScene = preload("res://src/ui/home/house_curio_inspect.tscn")
const KeeperRoleScene = preload("res://src/ui/home/keeper_role_panel.tscn")
const RestorationOverlayScene = preload("res://src/ui/home/restoration_overlay.tscn")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

@onready var room_view = $RoomView
@onready var headline: Label = $Layout/Headline
@onready var detail: Label = $Layout/Detail
@onready var curio_label: Label = $Layout/CurioChip/Label
@onready var collection_button: Button = $Layout/ActionDock/Actions/CollectionButton
@onready var settings_button: Button = $Layout/ActionDock/Actions/SettingsButton
@onready var play_button: Button = $Layout/PlayButton
@onready var _completion_banner: PanelContainer = $Layout/ChapterCompletionBanner
@onready var _completion_label: Label = $Layout/ChapterCompletionBanner/Label
@onready var _returning_banner: PanelContainer = $Layout/ReturningPlayerBanner
@onready var _returning_label: Label = $Layout/ReturningPlayerBanner/Label
@onready var _first_ritual_panel: PanelContainer = $Layout/FirstRitualGuide
@onready var _first_ritual_copy: Label = $Layout/FirstRitualGuide/GuideRow/CopyColumn/Copy
@onready var _first_ritual_dismiss: Button = $Layout/FirstRitualGuide/GuideRow/Dismiss
@onready var _first_ritual_keeper_art: TextureRect = $Layout/FirstRitualGuide/GuideRow/KeeperArt
@onready var _hotspot_layer: Control = $RoomView/CurioHotspots
@onready var _keeper_hotspot: Button = $RoomView/CurioHotspots/KeeperHotspot

var progress
var available_level_count: int = 1
var _resource_bar: PanelContainer
var _returning_player: bool = false
var _first_ritual_dismissed: bool = false
var _reduced_motion: bool = false
var _restoration_vfx_play_count: int = 0
var _restoration_vfx_last_stage: int = 0
var _restoration_vfx_last_curio_id: String = ""
var _restoration_vfx_active: bool = false
var _restoration_vfx_echo_spawned: bool = false
var _hotspot_buttons: Dictionary = {}
var _house_curio_overlay: Control
var _keeper_overlay: Control
const KEEPER_ART_PATH := "res://assets/pieces/black_cat.webp"

func _ready() -> void:
	ProductionChrome.apply_action_button(play_button, "primary", "house_next_level_or_map")
	play_button.pressed.connect(_on_play_pressed)
	collection_button.pressed.connect(func(): collection_requested.emit())
	settings_button.pressed.connect(func(): settings_requested.emit())
	_resource_bar = TopResourceBar.attach(self, progress, Callable(self, "_open_profile"))
	ProductNavigation.attach(self, "house", Callable(self, "_navigate_dock"), NodePath("Layout"))
	_first_ritual_keeper_art.texture = PieceAssetLoader.ornament(KEEPER_ART_PATH)
	_keeper_hotspot.icon = PieceAssetLoader.ornament(KEEPER_ART_PATH)
	_first_ritual_dismiss.pressed.connect(_dismiss_first_ritual_guide)
	_hotspot_buttons = {
		"moon_cameo": $RoomView/CurioHotspots/MoonHotspot,
		"moth_reliquary": $RoomView/CurioHotspots/MothHotspot,
		"thorned_locket": $RoomView/CurioHotspots/ThornHotspot,
	}
	for curio_id in _hotspot_buttons:
		var hotspot := _hotspot_buttons[curio_id] as Button
		hotspot.tooltip_text = "Inspect %s" % _curio_name(String(curio_id)).capitalize()
		hotspot.pressed.connect(_open_house_curio_inspect.bind(String(curio_id)))
	_keeper_hotspot.tooltip_text = "Meet the Keeper"
	_keeper_hotspot.pressed.connect(_open_keeper_card)

func set_available_level_count(value: int) -> void:
	available_level_count = max(0, value)
	if progress != null:
		_refresh()

func set_progress(value) -> void:
	progress = value
	_refresh()

func set_returning_player(value: bool) -> void:
	_returning_player = value
	_refresh()

func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	if room_view != null and room_view.has_method("apply_presentation_settings"):
		room_view.apply_presentation_settings(state)

func _refresh() -> void:
	var stage: int = 0
	var owned_curios: Array[String] = []
	if progress != null:
		stage = int(progress.house_stage)
		for curio in progress.curios:
			owned_curios.append(String(curio))

	var state: Dictionary = HouseState.descriptor(stage)
	headline.text = String(state.get("headline", "The Curio Boutique sleeps."))
	detail.text = String(state.get("detail", ""))
	room_view.set_house_state(stage, owned_curios)
	TopResourceBar.refresh(_resource_bar, progress)
	_refresh_room_hotspots()

	if stage >= 3:
		curio_label.text = "FIRST CABINET SET · 3 / 3 CURIOS"
	elif stage >= 2:
		curio_label.text = "FIRST CABINET · 2 / 3 CURIOS"
	elif stage >= 1:
		curio_label.text = "MOON CAMEO · FIRST CURIO AWAKENED"
	else:
		curio_label.text = "THE HOUSE AWAITS · 0 / 3 CURIOS"

	collection_button.text = "RELIQUARY · %d / 3" % owned_curios.size()
	var finished: int = mini(progress.completed_levels.size(), available_level_count) if progress != null else 0
	var has_started: bool = progress != null and not progress.completed_levels.is_empty()
	var opening_complete := available_level_count > 0 and finished >= available_level_count and owned_curios.size() >= available_level_count and stage >= available_level_count
	if _returning_banner != null:
		_returning_banner.visible = _returning_player and has_started
	if _returning_label != null:
		if opening_complete:
			_returning_label.text = "WELCOME BACK · FIRST CABINET RESTORED"
		else:
			_returning_label.text = "WELCOME BACK · %d / %d CURIOS AWAKENED" % [owned_curios.size(), available_level_count]
	if _completion_banner != null:
		_completion_banner.visible = opening_complete and not _returning_player
	if _completion_label != null:
		_completion_label.text = "OPENING CABINET SET COMPLETE · %d / %d" % [finished, available_level_count]

	var first_ritual: bool = progress != null and progress.completed_levels.is_empty() and progress.curios.is_empty() and stage == 0 and not _returning_player
	if _first_ritual_panel != null:
		_first_ritual_panel.visible = first_ritual and not _first_ritual_dismissed

	var next_level := int(progress.highest_level_unlocked) if progress != null else 1
	var level1_completed: bool = progress != null and progress.completed_levels.has("ch01_level_001")
	play_button.disabled = available_level_count < 1
	if has_started and next_level > 1 and next_level <= available_level_count:
		play_button.text = "PLAY LEVEL %d" % next_level
	elif opening_complete:
		play_button.text = "EXPLORE CURIO BOUTIQUE"
	elif level1_completed and next_level > available_level_count:
		play_button.text = "EXPLORE CURIO BOUTIQUE"
	elif next_level > available_level_count:
		play_button.text = "EXPLORE CURIO BOUTIQUE"
	else:
		play_button.text = "PLAY LEVEL 1"

func north_star_home_contract() -> Dictionary:
	return {
		"primary_cta_height": play_button.custom_minimum_size.y if play_button != null else 0.0,
		"primary_cta_width": play_button.custom_minimum_size.x if play_button != null else 0.0,
		"primary_cta_centered": play_button != null and (play_button.size_flags_horizontal & Control.SIZE_SHRINK_CENTER) != 0,
		"bottom_nav_reserved": ($Layout.offset_bottom <= -90.0),
		"world_underlays_home_ui": room_view != null and room_view.get_parent() == self and $Layout/WorldSpacer != null,
		"direct_level_cta": play_button != null and (play_button.text.begins_with("PLAY LEVEL") or play_button.text.begins_with("EXPLORE")),
	}

func _on_play_pressed() -> void:
	if available_level_count < 1:
		return
	var next_level := int(progress.highest_level_unlocked) if progress != null else 1
	var has_started: bool = progress != null and not progress.completed_levels.is_empty()
	if has_started and next_level > 1 and next_level <= available_level_count:
		play_requested.emit(next_level)
	elif next_level == 1 and not has_started:
		play_requested.emit(1)
	else:
		map_requested.emit()

func _open_profile() -> void:
	profile_requested.emit()

func _navigate_dock(action: String) -> void:
	match action:
		"house":
			_refresh()
		"curios":
			collection_requested.emit()
		"map":
			map_requested.emit()
		"events":
			events_requested.emit()
		"shop":
			shop_requested.emit()

func _dismiss_first_ritual_guide() -> void:
	_first_ritual_dismissed = true
	if _first_ritual_panel != null:
		_first_ritual_panel.visible = false

func ftue_house_contract() -> Dictionary:
	var active := _first_ritual_panel != null and _first_ritual_panel.visible
	return {
		"active": active,
		"dismissed": _first_ritual_dismissed,
		"copy": _first_ritual_copy.text if _first_ritual_copy != null else "",
		"play_cta": play_button.text if play_button != null else "",
		"keeper_available": _keeper_hotspot != null and not _keeper_hotspot.disabled,
		"first_time_truth": progress != null and progress.completed_levels.is_empty() and progress.curios.is_empty() and int(progress.house_stage) == 0,
	}

func _refresh_room_hotspots() -> void:
	if _hotspot_buttons.is_empty():
		return
	var owned: Array = progress.curios if progress != null else []
	for curio_id in _hotspot_buttons.keys():
		var button := _hotspot_buttons[curio_id] as Button
		if button == null:
			continue
		var awakened := owned.has(String(curio_id))
		button.disabled = not awakened
		button.text = "✦" if awakened else "◇"
		button.set_meta("curio_id", String(curio_id))
		button.set_meta("ownership_state", "owned" if awakened else "locked")

func house_hotspot_contract() -> Dictionary:
	var states := {}
	for curio_id in _hotspot_buttons.keys():
		var button := _hotspot_buttons[curio_id] as Button
		states[String(curio_id)] = {
			"disabled": button.disabled if button != null else true,
			"state": String(button.get_meta("ownership_state", "missing")) if button != null else "missing",
			"visible": button.visible if button != null else false,
		}
	return {
		"states": states,
		"owned_count": progress.curios.size() if progress != null else 0,
		"overlay_open": _house_curio_overlay != null and is_instance_valid(_house_curio_overlay),
	}

func open_curio_inspect(curio_id: String) -> bool:
	if progress == null or not progress.curios.has(curio_id):
		return false
	_open_house_curio_inspect(curio_id)
	return _house_curio_overlay != null and is_instance_valid(_house_curio_overlay)

func _open_house_curio_inspect(curio_id: String) -> void:
	if progress == null or not progress.curios.has(curio_id):
		return
	_close_house_curio_inspect()
	var data := _house_curio_data(curio_id)
	var texture := _curio_texture(curio_id)
	if data.is_empty() or texture == null:
		return
	var overlay := HouseCurioInspectScene.instantiate()
	add_child(overlay)
	_house_curio_overlay = overlay
	if not bool(overlay.configure(curio_id, _curio_name(curio_id), String(data.get("origin", "")), String(data.get("effect", "")), texture, _reduced_motion)):
		overlay.queue_free()
		_house_curio_overlay = null
		return
	overlay.close_requested.connect(_close_house_curio_inspect)

func _close_house_curio_inspect() -> void:
	if _house_curio_overlay != null and is_instance_valid(_house_curio_overlay):
		_house_curio_overlay.queue_free()
	_house_curio_overlay = null

func _house_curio_data(curio_id: String) -> Dictionary:
	match curio_id:
		"moon_cameo":
			return {
				"origin": "RECOVERED FROM · MOONLIT CABINET · LEVEL 1",
				"effect": "Moonlight now remains visible in the first restored cabinet niche."
			}
		"moth_reliquary":
			return {
				"origin": "RECOVERED FROM · SEALED DISPLAY · LEVEL 2",
				"effect": "The side display stays open and the Moth Reliquary remains part of the House."
			}
		"thorned_locket":
			return {
				"origin": "RECOVERED FROM · THORNLIGHT ARRANGEMENT · LEVEL 3",
				"effect": "The third restored niche completes the opening cabinet set."
			}
		_:
			return {}

func _open_keeper_card() -> void:
	_close_keeper_card()
	var texture := PieceAssetLoader.ornament(KEEPER_ART_PATH)
	if texture == null:
		return
	var overlay := KeeperRoleScene.instantiate()
	add_child(overlay)
	_keeper_overlay = overlay
	if not bool(overlay.configure(texture, _reduced_motion)):
		overlay.queue_free()
		_keeper_overlay = null
		return
	overlay.close_requested.connect(_close_keeper_card)

func _close_keeper_card() -> void:
	if _keeper_overlay != null and is_instance_valid(_keeper_overlay):
		_keeper_overlay.queue_free()
	_keeper_overlay = null

func keeper_house_contract() -> Dictionary:
	return {
		"role": "non_mutating_legal_move_guide",
		"asset": KEEPER_ART_PATH,
		"raster_runtime": KEEPER_ART_PATH.ends_with(".webp") or KEEPER_ART_PATH.ends_with(".png"),
		"hotspot_visible": _keeper_hotspot != null and _keeper_hotspot.visible,
		"touch_target_ok": _keeper_hotspot != null and _keeper_hotspot.custom_minimum_size.x >= 56.0 and _keeper_hotspot.custom_minimum_size.y >= 56.0,
		"spends_resources": false,
		"changes_board": false,
		"adds_moves": false,
	}

func show_restoration_ceremony(curio_id: String, stage: int) -> void:
	if get_node_or_null("RestorationOverlay") != null:
		return
	var motif_texture := _restoration_motif_texture(curio_id)
	var curio_texture := _curio_texture(curio_id)
	if motif_texture == null or curio_texture == null:
		return
	var overlay := RestorationOverlayScene.instantiate()
	add_child(overlay)
	if not bool(overlay.configure(_curio_name(curio_id), _restoration_copy(stage), motif_texture, curio_texture)):
		overlay.queue_free()
		return

	var product_nav := get_node_or_null("ProductNavigation") as Control
	var room_view_bottom_before_ceremony: float = float(room_view.offset_bottom)
	room_view.offset_bottom = 0.0
	if room_view.has_method("set_restoration_full_bleed"):
		room_view.set_restoration_full_bleed(true)
	if product_nav != null:
		product_nav.visible = false
	play_button.visible = false
	curio_label.get_parent().visible = false
	headline.visible = false
	detail.visible = false
	if _completion_banner != null:
		_completion_banner.visible = false

	var current_curios: Array[String] = []
	if progress != null:
		for item in progress.curios:
			current_curios.append(String(item))
	var previous_curios := current_curios.duplicate()
	previous_curios.erase(curio_id)
	room_view.set_house_state(maxi(0, stage - 1), previous_curios)

	overlay.continue_requested.connect(func():
		if is_instance_valid(overlay):
			overlay.queue_free()
		play_button.visible = true
		curio_label.get_parent().visible = true
		headline.visible = true
		detail.visible = true
		if room_view.has_method("set_restoration_full_bleed"):
			room_view.set_restoration_full_bleed(false)
		room_view.offset_bottom = room_view_bottom_before_ceremony
		if product_nav != null:
			product_nav.visible = true
		_refresh()
		restoration_finished.emit()
	)
	_animate_restoration_state(curio_id, stage, current_curios)

func _animate_restoration_state(curio_id: String, stage: int, current_curios: Array[String]) -> void:
	await get_tree().process_frame
	if not is_instance_valid(self):
		return
	_restoration_vfx_play_count += 1
	_restoration_vfx_last_stage = stage
	_restoration_vfx_last_curio_id = curio_id
	_restoration_vfx_active = false
	_restoration_vfx_echo_spawned = false
	room_view.set_house_state(stage, current_curios)
	room_view.modulate = Color.WHITE
	if _reduced_motion:
		return

	_restoration_vfx_active = true
	room_view.modulate = Color(0.70, 0.64, 0.82, 1)
	var restored_curio := room_view.get_node_or_null("MoonCameoOverlay") as Control
	if restored_curio != null and restored_curio.visible and stage == 1:
		restored_curio.pivot_offset = restored_curio.size * 0.5
		restored_curio.scale = Vector2(0.52, 0.52)
		restored_curio.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var awakening_echo: TextureRect
	if stage >= 2:
		awakening_echo = TextureRect.new()
		_restoration_vfx_echo_spawned = true
		awakening_echo.name = "RestorationAwakeningEcho"
		awakening_echo.texture = _curio_texture(curio_id)
		awakening_echo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		awakening_echo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		awakening_echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		awakening_echo.z_index = 8
		var room_margin: float = float(room_view.size.x) * 0.035
		var world_room: Rect2 = Rect2(
			Vector2(room_margin, room_view.size.y * 0.025),
			Vector2(room_view.size.x - room_margin * 2.0, room_view.size.y * 0.93)
		)
		var side: float = world_room.size.x * 0.15
		awakening_echo.size = Vector2(side, side)
		var y_ratio: float = 0.38 if stage == 2 else 0.49
		var center: Vector2 = Vector2(
			world_room.position.x + world_room.size.x * 0.84,
			world_room.position.y + world_room.size.y * y_ratio
		)
		awakening_echo.position = center - awakening_echo.size * 0.5
		awakening_echo.pivot_offset = awakening_echo.size * 0.5
		awakening_echo.scale = Vector2(0.82, 0.82)
		awakening_echo.modulate = Color(1.0, 0.94, 0.78, 0.0)
		room_view.add_child(awakening_echo)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(room_view, "modulate", Color.WHITE, 0.55)
	if restored_curio != null and restored_curio.visible and stage == 1:
		tween.parallel().tween_property(restored_curio, "modulate", Color.WHITE, 0.34)
		tween.parallel().tween_property(restored_curio, "scale", Vector2.ONE, 0.56).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if awakening_echo != null:
		tween.parallel().tween_property(awakening_echo, "modulate", Color(1.0, 0.94, 0.78, 0.72), 0.28)
		tween.parallel().tween_property(awakening_echo, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(awakening_echo, "modulate", Color(1.0, 0.94, 0.78, 0.0), 0.26)
		tween.tween_callback(awakening_echo.queue_free)
	tween.finished.connect(func():
		if is_instance_valid(self):
			_restoration_vfx_active = false
	)

func restoration_vfx_contract() -> Dictionary:
	return {
		"slot": "S07/house_hero/awakening_fx",
		"mode": "runtime_house_curio_awaken",
		"play_count": _restoration_vfx_play_count,
		"last_stage": _restoration_vfx_last_stage,
		"last_curio_id": _restoration_vfx_last_curio_id,
		"active": _restoration_vfx_active,
		"echo_spawned": _restoration_vfx_echo_spawned,
		"world_fills_hidden_nav_region": room_view != null and room_view.offset_bottom >= -1.0,
		"world_art_full_bleed": room_view != null and bool(room_view.living_house_contract().get("restoration_full_bleed", false)),
		"reduced_motion": _reduced_motion,
		"reduced_motion_supported": true,
		"exact_curio_identity_preserved": true,
	}

func house_presentation_contract() -> Dictionary:
	return {
		"persistent_slots_authored": _first_ritual_panel != null and _returning_banner != null and _completion_banner != null,
		"hotspots_authored": _hotspot_layer != null and _hotspot_buttons.size() == 3 and _keeper_hotspot != null,
		"curio_inspect_authored": true,
		"keeper_role_authored": true,
		"restoration_authored": true,
		"runtime_overlay_factory": false,
	}

func _restoration_motif_texture(curio_id: String) -> Texture2D:
	# The large transient awakening layer communicates each relic's motif using
	# the accepted production piece family. Exact Curio identity remains on the
	# item card and the persistent House niche; the motif is never a substitute
	# for ownership/progression truth.
	var path := "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp"
	if curio_id == "moth_reliquary":
		path = "res://assets/pieces/luna_moth.webp"
	elif curio_id == "thorned_locket":
		path = "res://assets/pieces/thorn_rose.webp"
	return PieceAssetLoader.ornament(path)

func _curio_texture(curio_id: String) -> Texture2D:
	var path := "res://assets/curios/ch01_curio_moon_cameo_awakened_v01.webp"
	if curio_id == "moth_reliquary":
		path = "res://assets/curios/ch01_curio_moth_reliquary.png"
	elif curio_id == "thorned_locket":
		path = "res://assets/curios/ch01_curio_thorned_locket.png"
	return PieceAssetLoader.ornament(path)

func _curio_name(curio_id: String) -> String:
	match curio_id:
		"moth_reliquary": return "MOTH RELIQUARY"
		"thorned_locket": return "THORNED LOCKET"
		_: return "MOON CAMEO"

func _restoration_copy(stage: int) -> String:
	match stage:
		1: return "Moonlight returns to the first cabinet. The Moon Cameo now lives in the House."
		2: return "The side display opens for the Moth Reliquary."
		3: return "The Thorned Locket completes the opening cabinet set."
		_: return "A recovered Curio takes its place in the House."
