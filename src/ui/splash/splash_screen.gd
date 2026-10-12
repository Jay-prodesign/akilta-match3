class_name Match3SplashScreen
extends Control

signal continue_requested

const ScreenArt = preload("res://src/ui/shared/screen_art_registry.gd")

@onready var enter_button: Button = $Layout/Enter
@onready var progress_label: Label = $Layout/BootState/StateContent/Progress
@onready var recovery_message: Label = $Layout/BootState/StateContent/RecoveryMessage
@onready var boot_state_panel: PanelContainer = $Layout/BootState

var _boot_state: String = "loading"
var _ambient_tween: Tween

func _ready() -> void:
	_install_splash_art()
	_start_ambient_motion()
	_style_enter_button()
	_style_boot_state()
	enter_button.pressed.connect(func(): continue_requested.emit())
	set_boot_state("loading")

func _start_ambient_motion() -> void:
	var art := get_node_or_null("SplashWorldArt") as TextureRect
	if art == null:
		return
	art.pivot_offset = size * 0.5
	_ambient_tween = create_tween().set_loops()
	_ambient_tween.tween_property(art, "modulate", Color(0.84, 0.86, 1.0, 1.0), 2.8).set_trans(Tween.TRANS_SINE)
	_ambient_tween.tween_property(art, "modulate", Color.WHITE, 2.8).set_trans(Tween.TRANS_SINE)

func boot_state() -> String:
	return _boot_state

func set_boot_state(state: String, message: String = "", can_continue: bool = true) -> void:
	if state not in ["loading", "ready", "recoverable_error"]:
		return
	_boot_state = state
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

func _install_splash_art() -> void:
	var texture := ScreenArt.texture("splash_bg_curio_boutique")
	if texture == null:
		return
	var art := TextureRect.new()
	art.name = "SplashWorldArt"
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	move_child(art, 0)
	var shade := get_node_or_null("Backdrop")
	if shade is ColorRect:
		(shade as ColorRect).color = Color(0.018, 0.012, 0.026, 0.44)

func _style_enter_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#48244A")
	normal.border_color = Color("#D5AD70")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	normal.shadow_size = 12
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#633265")
	enter_button.add_theme_stylebox_override("normal", normal)
	enter_button.add_theme_stylebox_override("hover", hover)
	enter_button.add_theme_stylebox_override("pressed", hover)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#1B1420", 0.94)
	disabled.border_color = Color("#A88B66", 0.72)
	enter_button.add_theme_stylebox_override("disabled", disabled)
	enter_button.add_theme_color_override("font_color", Color("#F4E5D3"))
	enter_button.add_theme_color_override("font_disabled_color", Color("#E7D2BC"))
	enter_button.add_theme_color_override("font_hover_color", Color("#FFF1D9"))
	enter_button.add_theme_font_size_override("font_size", 25)
	enter_button.custom_minimum_size.y = maxf(enter_button.custom_minimum_size.y, 64.0)


func _style_boot_state() -> void:
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#0D0912", 0.82)
	shell.border_color = Color("#9B6FA6", 0.58)
	shell.set_border_width_all(1)
	shell.set_corner_radius_all(12)
	shell.content_margin_left = 18
	shell.content_margin_right = 18
	shell.content_margin_top = 12
	shell.content_margin_bottom = 12
	boot_state_panel.add_theme_stylebox_override("panel", shell)
