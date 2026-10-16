extends Control
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

signal close_requested
signal view_house_requested(curio_id: String)
signal interaction_feedback_requested(kind: String)

var _curio_id: String = ""
var _reduced_motion: bool = false
var _closing: bool = false
var _presented: bool = false
var _intro_tween: Tween
var _exit_tween: Tween
var _detail_tactile_buttons: Array[Button] = []

@onready var veil: ColorRect = $Veil
@onready var card: PanelContainer = $CurioDetailCard
@onready var hero_art: TextureRect = $CurioDetailCard/Content/HeroArt
@onready var title: Label = $CurioDetailCard/Content/Name
@onready var state: Label = $CurioDetailCard/Content/State
@onready var origin: Label = $CurioDetailCard/Content/Origin
@onready var lore: Label = $CurioDetailCard/Content/Lore
@onready var view_house: Button = $CurioDetailCard/Content/ViewInHouse
@onready var close: Button = $CurioDetailCard/Content/Close

func _ready() -> void:
	# The shared 9-slice ritual frame visibly seams at this modal aspect ratio.
	# Keep the authored flat gold frame as the detail surface material.
	card.set_meta("detail_material", "scene_authored_flat")
	ProductionChrome.apply_action_button(view_house, "primary", "curio_view_house")
	ProductionChrome.apply_action_button(close, "utility", "curio_return_reliquary")
	_bind_detail_tactile(view_house, "view_house", 0.955)
	_bind_detail_tactile(close, "close", 0.97)
	close.pressed.connect(_request_close)
	view_house.pressed.connect(func(): view_house_requested.emit(_curio_id))

func configure(curio_id: String, data: Dictionary, awakened: bool, texture: Texture2D) -> bool:
	_curio_id = curio_id
	if data.is_empty() or texture == null:
		return false
	hero_art.texture = texture
	hero_art.modulate = Color.WHITE if awakened else Color(0.58, 0.54, 0.62, 0.62)
	title.text = String(data.get("name", "UNKNOWN CURIO"))
	state.text = "AWAKENED · OWNED" if awakened else "LOCKED · NOT YET RECOVERED"
	state.add_theme_color_override("font_color", Color("#F2D08B") if awakened else Color("#A995B0"))
	origin.text = String(data.get("origin_owned" if awakened else "origin_locked", ""))
	lore.text = String(data.get("lore" if awakened else "requirement", ""))
	view_house.visible = awakened
	card.set_meta("curio_id", curio_id)
	card.set_meta("ownership_state", "awakened" if awakened else "locked")
	call_deferred("_play_intro")
	return true

func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	for button in _detail_tactile_buttons:
		button.set_meta("detail_tactile_reduced_motion", _reduced_motion)
		if _reduced_motion:
			_stop_detail_tactile_tween(button)
			button.scale = Vector2.ONE
			button.modulate = Color.WHITE
	if _reduced_motion and _presented:
		_settle_modal()

func _bind_detail_tactile(button: Button, role: String, press_scale: float) -> void:
	if button == null:
		return
	button.set_meta("detail_tactile_role", role)
	button.set_meta("detail_tactile_press_scale", press_scale)
	button.set_meta("detail_tactile_reduced_motion", _reduced_motion)
	if bool(button.get_meta("detail_tactile_bound", false)):
		return
	button.set_meta("detail_tactile_bound", true)
	_detail_tactile_buttons.append(button)
	button.button_down.connect(_press_detail_tactile.bind(button))
	button.button_up.connect(_release_detail_tactile.bind(button))
	button.mouse_exited.connect(_release_detail_tactile.bind(button))
	button.focus_exited.connect(_release_detail_tactile.bind(button))

func _press_detail_tactile(button: Button) -> void:
	if button == null or button.disabled or not button.visible:
		return
	_stop_detail_tactile_tween(button)
	button.pivot_offset = button.size * 0.5
	button.set_meta("detail_tactile_phase", "pressed")
	interaction_feedback_requested.emit("ui")
	if bool(button.get_meta("detail_tactile_reduced_motion", false)):
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		return
	var target_scale := clampf(float(button.get_meta("detail_tactile_press_scale", 0.97)), 0.94, 0.985)
	var tween := create_tween()
	button.set_meta("detail_tactile_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.0, 0.95, 0.86, 1.0), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _release_detail_tactile(button: Button) -> void:
	if button == null:
		return
	_stop_detail_tactile_tween(button)
	button.pivot_offset = button.size * 0.5
	button.set_meta("detail_tactile_phase", "release")
	if bool(button.get_meta("detail_tactile_reduced_motion", false)):
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		button.set_meta("detail_tactile_phase", "idle")
		return
	var tween := create_tween()
	button.set_meta("detail_tactile_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color.WHITE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): button.set_meta("detail_tactile_phase", "idle"))

func _stop_detail_tactile_tween(button: Button) -> void:
	if button == null or not button.has_meta("detail_tactile_tween"):
		return
	var previous = button.get_meta("detail_tactile_tween")
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	button.remove_meta("detail_tactile_tween")

func _play_intro() -> void:
	if _presented or card == null or veil == null:
		return
	_presented = true
	set_meta("modal_phase", "opening")
	card.pivot_offset = card.size * 0.5
	var rest_position := card.position
	card.set_meta("modal_rest_position", rest_position)
	if _reduced_motion:
		_settle_modal()
		return
	veil.modulate = Color(1, 1, 1, 0)
	card.modulate = Color(1, 1, 1, 0)
	card.scale = Vector2(0.94, 0.94)
	card.position = rest_position + Vector2(0, 24)
	var content := card.get_node_or_null("Content") as Control
	if content != null:
		for child in content.get_children():
			if child is CanvasItem:
				(child as CanvasItem).modulate = Color(1, 1, 1, 0)
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	_intro_tween.tween_property(veil, "modulate", Color.WHITE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(card, "modulate", Color.WHITE, 0.18).set_delay(0.035).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(card, "scale", Vector2.ONE, 0.24).set_delay(0.035).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(card, "position", rest_position, 0.22).set_delay(0.035).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if content != null:
		var child_index := 0
		for child in content.get_children():
			if child is CanvasItem:
				_intro_tween.tween_property(child, "modulate", Color.WHITE, 0.15).set_delay(0.09 + float(child_index) * 0.025).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				child_index += 1
	_intro_tween.finished.connect(func(): set_meta("modal_phase", "idle"))

func _request_close() -> void:
	if _closing:
		return
	_closing = true
	set_meta("modal_phase", "closing")
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	if _reduced_motion:
		close_requested.emit()
		return
	var rest_position: Vector2 = card.get_meta("modal_rest_position", card.position)
	_exit_tween = create_tween()
	_exit_tween.set_parallel(true)
	_exit_tween.tween_property(veil, "modulate", Color(1, 1, 1, 0), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_exit_tween.tween_property(card, "modulate", Color(1, 1, 1, 0), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_exit_tween.tween_property(card, "scale", Vector2(0.96, 0.96), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_exit_tween.tween_property(card, "position", rest_position + Vector2(0, 18), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_exit_tween.finished.connect(func(): close_requested.emit())

func _settle_modal() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	if _exit_tween != null and _exit_tween.is_valid():
		_exit_tween.kill()
	var rest_position: Vector2 = card.get_meta("modal_rest_position", card.position)
	veil.modulate = Color.WHITE
	card.modulate = Color.WHITE
	card.scale = Vector2.ONE
	card.position = rest_position
	var content := card.get_node_or_null("Content") as Control
	if content != null:
		for child in content.get_children():
			if child is CanvasItem:
				(child as CanvasItem).modulate = Color.WHITE
	if not _closing:
		set_meta("modal_phase", "idle")

func detail_contract() -> Dictionary:
	return {
		"curio_id": _curio_id,
		"art_loaded": hero_art != null and hero_art.texture != null,
		"view_in_house_visible": view_house != null and view_house.visible,
		"north_star_actions": view_house != null and view_house.custom_minimum_size.y >= 70.0 and close != null and close.custom_minimum_size.y >= 60.0,
		"asset_backed_actions": view_house != null and view_house.get_theme_stylebox("normal") is StyleBoxTexture and close != null and close.get_theme_stylebox("normal") is StyleBoxTexture and String(view_house.get_meta("production_chrome_kind", "")) == "action_primary_curio_view_house" and String(close.get_meta("production_chrome_kind", "")) == "action_utility_curio_return_reliquary",
		"content_bounded_card": card != null and card.anchor_bottom - card.anchor_top <= 0.71 and card.size.y <= get_viewport_rect().size.y * 0.74,
		"modal_veil_strength": ($Veil as ColorRect).color.a >= 0.74,
		"seam_free_card_material": card != null and card.get_theme_stylebox("panel") is StyleBoxFlat and String(card.get_meta("detail_material", "")) == "scene_authored_flat",
		"modal_choreography": has_meta("modal_phase") and _presented,
		"tactile_actions": close != null and bool(close.get_meta("detail_tactile_bound", false)) and view_house != null and bool(view_house.get_meta("detail_tactile_bound", false)),
		"reduced_motion_supported": true,
		"feedback_signal": has_signal("interaction_feedback_requested"),
		"authored_scene": true,
	}
