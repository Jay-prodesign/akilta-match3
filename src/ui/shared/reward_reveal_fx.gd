class_name Match3RewardRevealFx
extends Control

var _progress: float = 1.0
var _active: bool = false
var _play_count: int = 0
var _last_reduced_motion: bool = false
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func play(reduced_motion: bool = false) -> void:
	_play_count += 1
	_last_reduced_motion = reduced_motion
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if reduced_motion:
		_active = false
		_progress = 1.0
		visible = false
		queue_redraw()
		return
	_active = true
	_progress = 0.0
	visible = true
	queue_redraw()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_progress, 0.0, 1.0, 0.92)
	_tween.finished.connect(_finish)

func stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_active = false
	_progress = 1.0
	visible = false
	queue_redraw()

func contract() -> Dictionary:
	return {
		"slot": "S06/result_panel/reward_fx",
		"mode": "runtime_relic_reveal",
		"active": _active,
		"play_count": _play_count,
		"last_reduced_motion": _last_reduced_motion,
		"reduced_motion_supported": true
	}

func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()

func _finish() -> void:
	_progress = 1.0
	_active = false
	visible = false
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	var center := size * Vector2(0.5, 0.48)
	var short := minf(size.x, size.y)
	var pulse := sin(clampf(_progress, 0.0, 1.0) * PI)
	var fade := 1.0 - clampf(_progress, 0.0, 1.0)
	var gold := Color("#D5AD70", 0.58 * pulse)
	var lilac := Color("#BFA5D8", 0.32 * pulse)
	var inner_radius := short * (0.09 + _progress * 0.08)
	var outer_radius := short * (0.16 + _progress * 0.12)
	draw_arc(center, inner_radius, -PI * 0.15, PI * 1.15, 64, gold, 2.5 + 2.0 * fade)
	draw_arc(center, outer_radius, PI * 0.75, PI * 2.05, 64, lilac, 2.0 + 1.5 * fade)
	for i in range(12):
		var angle := TAU * float(i) / 12.0 + 0.15
		var direction := Vector2(cos(angle), sin(angle))
		var start := center + direction * short * (0.12 + _progress * 0.05)
		var finish := center + direction * short * (0.17 + _progress * 0.12)
		var ray := gold if i % 2 == 0 else lilac
		ray.a *= 0.72
		draw_line(start, finish, ray, 1.5 + 1.5 * fade)
	for i in range(8):
		var angle := TAU * float(i) / 8.0 - 0.25
		var orbit := short * (0.13 + _progress * (0.10 + 0.012 * float(i % 3)))
		var mote := center + Vector2(cos(angle), sin(angle)) * orbit
		var mote_color := Color("#FFF0C7", 0.64 * pulse)
		draw_circle(mote, maxf(1.5, short * 0.0045 * fade), mote_color)
