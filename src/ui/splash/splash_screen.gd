class_name Match3SplashScreen
extends Control

signal continue_requested

const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")
const Typography = preload("res://src/ui/theme/typography.gd")
const HapticsController = preload("res://src/feedback/haptics_controller.gd")

const BRAND_SEAL_PATH := "res://assets/ui/cat_coven_launch.png"
const SPLASH_WORLD_BASELINE_PATH := "res://assets/world/ch01_curio_boutique/chapter_route_curio_boutique.webp"

@onready var enter_button: Button = $Layout/Enter
@onready var progress_label: Label = $Layout/BootState/StateContent/Progress
@onready var load_track: ProgressBar = $Layout/BootState/StateContent/LoadTrack
@onready var recovery_message: Label = $Layout/BootState/StateContent/RecoveryMessage
@onready var boot_state_panel: PanelContainer = $Layout/BootState
@onready var splash_world_art: TextureRect = $SplashWorldArt
@onready var brand_seal: TextureRect = $Layout/BrandSeal
@onready var brand_label: Label = $Layout/Brand
@onready var subtitle_label: Label = $Layout/Subtitle
@onready var tagline_label: Label = $Layout/Tagline

var _boot_state: String = "loading"
var _ambient_tween: Tween
var _loading_tween: Tween
var _intro_tween: Tween
var _reduced_motion := false
var haptics = HapticsController.new()

func _ready() -> void:
	splash_world_art.texture = ScreenArt.texture("splash_bg_curio_boutique")
	brand_seal.texture = PieceAssetLoader.ornament(BRAND_SEAL_PATH)
	var display_font := Typography.display_font()
	if display_font != null:
		brand_label.add_theme_font_override("font", display_font)
		subtitle_label.add_theme_font_override("font", display_font)
	ProductionChrome.apply_compact_panel(boot_state_panel, "splash_boot_state")
	ProductionChrome.apply_action_button(enter_button, "primary", "splash_enter")
	_wire_tactile_button(enter_button)
	enter_button.pressed.connect(func(): continue_requested.emit())
	set_boot_state("loading")
	call_deferred("_play_intro")
	_start_ambient_motion()

func apply_presentation_settings(state: Dictionary) -> void:
	_reduced_motion = bool(state.get("reduced_motion", false))
	haptics.apply_settings(state)
	if _reduced_motion:
		_stop_loading_pulse()
		if _boot_state == "loading":
			load_track.value = 52.0
		if _ambient_tween != null and _ambient_tween.is_valid():
			_ambient_tween.kill()
			_ambient_tween = null
		splash_world_art.scale = Vector2.ONE
		splash_world_art.modulate = Color.WHITE

func _start_loading_pulse() -> void:
	if _loading_tween != null and _loading_tween.is_valid():
		_loading_tween.kill()
		_loading_tween = null
	progress_label.modulate.a = 1.0
	if _reduced_motion:
		load_track.value = 52.0
		return
	load_track.value = 22.0
	_loading_tween = create_tween().set_loops()
	_loading_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_loading_tween.tween_property(load_track, "value", 78.0, 1.15)
	_loading_tween.parallel().tween_property(progress_label, "modulate:a", 0.64, 1.15)
	_loading_tween.tween_property(load_track, "value", 34.0, 0.92)
	_loading_tween.parallel().tween_property(progress_label, "modulate:a", 1.0, 0.92)

func _stop_loading_pulse() -> void:
	if _loading_tween != null and _loading_tween.is_valid():
		_loading_tween.kill()
	_loading_tween = null
	progress_label.modulate.a = 1.0

func _start_ambient_motion() -> void:
	if splash_world_art == null or _reduced_motion:
		return
	if _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()
	splash_world_art.pivot_offset = size * 0.5
	splash_world_art.scale = Vector2(1.018, 1.018)
	_ambient_tween = create_tween().set_loops()
	_ambient_tween.set_parallel(true)
	_ambient_tween.tween_property(splash_world_art, "scale", Vector2(1.034, 1.034), 4.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient_tween.tween_property(splash_world_art, "modulate", Color(0.91, 0.94, 1.0, 1.0), 4.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient_tween.chain().set_parallel(true)
	_ambient_tween.tween_property(splash_world_art, "scale", Vector2(1.018, 1.018), 4.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient_tween.tween_property(splash_world_art, "modulate", Color.WHITE, 4.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_intro() -> void:
	if _reduced_motion:
		return
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	var reveal_nodes: Array[Control] = [brand_seal, brand_label, subtitle_label, boot_state_panel, enter_button, tagline_label]
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	for index in range(reveal_nodes.size()):
		var node := reveal_nodes[index]
		if node == null:
			continue
		node.pivot_offset = node.size * 0.5
		var rest_position := node.position
		node.set_meta("splash_rest_position", rest_position)
		node.position = rest_position + Vector2(0, 18 if index < 3 else 12)
		node.modulate.a = 0.0 if node != enter_button or _boot_state != "loading" else 0.0
		node.scale = Vector2(0.96, 0.96)
		var delay := float(index) * 0.045
		var target_modulate := Color.WHITE
		if node == enter_button and _boot_state == "loading":
			target_modulate.a = 0.0
		_intro_tween.tween_property(node, "position", rest_position, 0.30).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(node, "scale", Vector2.ONE, 0.34).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(node, "modulate", target_modulate, 0.22).set_delay(delay)

func _wire_tactile_button(button: Button) -> void:
	if button == null:
		return
	button.button_down.connect(func(): _press_tactile_button(button))
	button.button_up.connect(func(): _release_tactile_button(button))
	button.mouse_exited.connect(func(): _release_tactile_button(button))

func _press_tactile_button(button: Button) -> void:
	if button == null or button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	haptics.request_ui()
	button.modulate = Color(1.04, 1.02, 1.06, 1.0)
	if _reduced_motion:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.065)

func _release_tactile_button(button: Button) -> void:
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	if _reduced_motion:
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color.WHITE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func boot_state() -> String:
	return _boot_state

func set_boot_state(state: String, message: String = "", can_continue: bool = true) -> void:
	if state not in ["loading", "ready", "recoverable_error"]:
		return
	_boot_state = state
	if state == "loading":
		_start_loading_pulse()
	else:
		_stop_loading_pulse()
	match state:
		"loading":
			progress_label.visible = true
			progress_label.text = "WAKING THE HOUSE…"
			load_track.value = 42.0 if _reduced_motion else load_track.value
			recovery_message.visible = false
			enter_button.text = "ENTER THE HOUSE"
			enter_button.visible = true
			enter_button.disabled = true
			enter_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			enter_button.modulate = Color(1, 1, 1, 0)
		"ready":
			progress_label.visible = true
			progress_label.text = "THE HOUSE IS READY"
			load_track.value = 100.0
			recovery_message.visible = false
			enter_button.text = "ENTER THE HOUSE"
			enter_button.visible = true
			enter_button.disabled = false
			enter_button.mouse_filter = Control.MOUSE_FILTER_STOP
			_reveal_enter()
		"recoverable_error":
			progress_label.visible = true
			progress_label.text = "THE HOUSE NEEDS ATTENTION" if not can_continue else "THE HOUSE RECOVERED SAFELY"
			load_track.value = 100.0
			recovery_message.visible = true
			recovery_message.text = message if message != "" else "A local save issue was recovered. Review the restored state before continuing."
			enter_button.text = "UPDATE REQUIRED" if not can_continue else "CONTINUE TO THE HOUSE"
			enter_button.visible = true
			enter_button.disabled = not can_continue
			enter_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if enter_button.disabled else Control.MOUSE_FILTER_STOP
			_reveal_enter()

func _reveal_enter() -> void:
	enter_button.pivot_offset = enter_button.size * 0.5
	if _reduced_motion:
		enter_button.scale = Vector2.ONE
		enter_button.modulate = Color.WHITE
		return
	var tween := create_tween()
	enter_button.scale = Vector2(0.965, 0.965)
	enter_button.modulate = Color(1, 1, 1, 0)
	tween.set_parallel(true)
	tween.tween_property(enter_button, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(enter_button, "modulate", Color.WHITE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func splash_authored_contract() -> Dictionary:
	return {
		"authored_world_art": splash_world_art != null and splash_world_art.texture != null,
		"world_art_source": ScreenArt.path("splash_bg_curio_boutique"),
		"dedicated_splash_master": ScreenArt.path("splash_bg_curio_boutique") != SPLASH_WORLD_BASELINE_PATH,
		"shared_moonlit_castle_baseline": ScreenArt.path("splash_bg_curio_boutique") == SPLASH_WORLD_BASELINE_PATH,
		"authored_brand_seal": brand_seal != null and brand_seal.texture != null,
		"authored_boot_panel": boot_state_panel != null and boot_state_panel.get_theme_stylebox("panel") is StyleBoxTexture,
		"authored_enter_cta": enter_button != null and enter_button.custom_minimum_size.y >= 96.0 and enter_button.get_theme_stylebox("normal") is StyleBoxTexture,
		"north_star_brand_hierarchy": brand_label != null and brand_label.get_theme_font_size("font_size") >= 68 and brand_seal != null and brand_seal.custom_minimum_size.y >= 120.0,
		"north_star_entry_stack": boot_state_panel != null and boot_state_panel.custom_minimum_size.y >= 100.0 and load_track != null and load_track.custom_minimum_size.y >= 16.0 and tagline_label != null,
		"stable_loading_geometry": enter_button != null and enter_button.visible,
		"story_subordinate": ($Layout/Story as Label) != null and not ($Layout/Story as Label).visible,
		"runtime_ui_factory": false,
	}
