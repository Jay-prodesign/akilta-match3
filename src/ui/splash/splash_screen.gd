class_name Match3SplashScreen
extends Control

signal continue_requested

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")

@onready var enter_button: Button = $Layout/Enter
@onready var progress_label: Label = $Layout/BootState/StateContent/Progress
@onready var recovery_message: Label = $Layout/BootState/StateContent/RecoveryMessage
@onready var boot_state_panel: PanelContainer = $Layout/BootState
@onready var splash_world_art: TextureRect = $SplashWorldArt

var _boot_state: String = "loading"
var _ambient_tween: Tween
var _loading_tween: Tween

func _ready() -> void:
	splash_world_art.texture = ScreenArt.texture("splash_bg_curio_boutique")
	_start_ambient_motion()
	enter_button.pressed.connect(func(): continue_requested.emit())
	set_boot_state("loading")

func _start_loading_pulse() -> void:
	if _loading_tween != null:
		_loading_tween.kill()
	progress_label.modulate.a = 1.0
	_loading_tween = create_tween().set_loops()
	_loading_tween.tween_property(progress_label, "modulate:a", 0.48, 0.85)
	_loading_tween.tween_property(progress_label, "modulate:a", 1.0, 0.85)

func _stop_loading_pulse() -> void:
	if _loading_tween != null:
		_loading_tween.kill()
		_loading_tween = null
	progress_label.modulate.a = 1.0

func _start_ambient_motion() -> void:
	if splash_world_art == null:
		return
	splash_world_art.pivot_offset = size * 0.5
	_ambient_tween = create_tween().set_loops()
	_ambient_tween.tween_property(splash_world_art, "modulate", Color(0.84, 0.86, 1.0, 1.0), 2.8).set_trans(Tween.TRANS_SINE)
	_ambient_tween.tween_property(splash_world_art, "modulate", Color.WHITE, 2.8).set_trans(Tween.TRANS_SINE)

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
			recovery_message.visible = false
			enter_button.visible = false
			enter_button.disabled = true
		"ready":
			progress_label.visible = true
			progress_label.text = "THE HOUSE IS READY"
			recovery_message.visible = false
			enter_button.text = "ENTER THE HOUSE"
			enter_button.visible = true
			enter_button.disabled = false
		"recoverable_error":
			progress_label.visible = true
			progress_label.text = "THE HOUSE NEEDS ATTENTION" if not can_continue else "THE HOUSE RECOVERED SAFELY"
			recovery_message.visible = true
			recovery_message.text = message if message != "" else "A local save issue was recovered. Review the restored state before continuing."
			enter_button.text = "UPDATE REQUIRED" if not can_continue else "CONTINUE TO THE HOUSE"
			enter_button.visible = true
			enter_button.disabled = not can_continue

func splash_authored_contract() -> Dictionary:
	return {
		"authored_world_art": splash_world_art != null and splash_world_art.texture != null,
		"authored_boot_panel": boot_state_panel != null,
		"authored_enter_cta": enter_button != null and enter_button.custom_minimum_size.y >= 80.0,
		"north_star_brand_hierarchy": ($Layout/Brand as Label).get_theme_font_size("font_size") >= 66 and ($Layout/MoonMark as Label).get_theme_font_size("font_size") >= 84,
		"compact_boot_state": boot_state_panel != null and boot_state_panel.custom_minimum_size.y <= 88.0,
		"story_subordinate": ($Layout/Story as Label) != null and not ($Layout/Story as Label).visible,
		"runtime_ui_factory": false,
	}

