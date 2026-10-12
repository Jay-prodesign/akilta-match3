class_name Match3AudioDirector
extends Node

## Match-3-owned audio feedback director.
## Uses only provenance-cleared CC0 candidate audio stored in assets/audio.
## UserSettings owns bus volume/mute state; this node owns semantic playback.

const AMBIENT_PATH := "res://assets/audio/music/curio_house_ambient.ogg"
const CHIME_PATH := "res://assets/audio/sfx/ritual_chime.wav"

const FEEDBACK := {
	"ui": {"pitch": 0.82, "gain_db": -38.0},
	"match": {"pitch": 0.88, "gain_db": -34.0},
	"special": {"pitch": 0.94, "gain_db": -32.0},
	"win": {"pitch": 0.98, "gain_db": -28.0},
	"fail": {"pitch": 0.80, "gain_db": -35.0},
	"retry": {"pitch": 0.86, "gain_db": -34.0},
}

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var match_player: AudioStreamPlayer
var _soft_match_stream: AudioStreamWAV
var _ambient_stream: AudioStream
var _chime_stream: AudioStream
var _play_sink: Callable = Callable()
var _feedback_counts: Dictionary = {}

func _ready() -> void:
	_ensure_players()
	_soft_match_stream = _make_soft_match_stream()
	if match_player != null:
		match_player.stream = _soft_match_stream
	_load_candidates()
	start_ambient()

func _ensure_players() -> void:
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.name = "CurioAmbient"
		music_player.bus = &"Music"
		add_child(music_player)
	if match_player == null:
		match_player = AudioStreamPlayer.new()
		match_player.name = "SoftMatchTap"
		match_player.bus = &"SFX"
		add_child(match_player)
	if sfx_player == null:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "RitualChime"
		sfx_player.bus = &"SFX"
		add_child(sfx_player)

func _load_candidates() -> void:
	# Load source audio directly so clean CI/device installs do not depend on an
	# editor-generated import cache existing before the first app boot.
	if FileAccess.file_exists(AMBIENT_PATH):
		_ambient_stream = AudioStreamOggVorbis.load_from_file(AMBIENT_PATH)
	if FileAccess.file_exists(CHIME_PATH):
		_chime_stream = AudioStreamWAV.load_from_file(CHIME_PATH)
	if music_player != null:
		music_player.stream = _ambient_stream
	if sfx_player != null:
		sfx_player.stream = _chime_stream

func start_ambient() -> bool:
	_ensure_players()
	if _ambient_stream == null:
		_load_candidates()
	if _ambient_stream == null:
		return false
	music_player.stream = _ambient_stream
	music_player.volume_db = -34.0
	if not music_player.playing:
		music_player.play()
	return true

func stop_ambient() -> void:
	if music_player != null:
		music_player.stop()

func request_feedback(kind: String) -> bool:
	if not FEEDBACK.has(kind):
		return false
	_ensure_players()
	if kind not in ["match", "ui"] and _chime_stream == null:
		_load_candidates()
	if kind not in ["match", "ui"] and _chime_stream == null:
		return false
	var profile: Dictionary = FEEDBACK[kind]
	_feedback_counts[kind] = int(_feedback_counts.get(kind, 0)) + 1
	if _play_sink.is_valid():
		_play_sink.call(kind, profile.duplicate(true))
		return true
	if kind in ["match", "ui"]:
		if _soft_match_stream == null:
			_soft_match_stream = _make_soft_match_stream()
		match_player.stream = _soft_match_stream
		var variation: float = 0.86 if kind == "ui" else float([0.94, 1.0, 1.035][int(_feedback_counts[kind]) % 3])
		match_player.pitch_scale = variation
		match_player.volume_db = -38.0 if kind == "ui" else -34.0
		match_player.play()
		return true
	sfx_player.stream = _chime_stream
	sfx_player.pitch_scale = float(profile["pitch"])
	sfx_player.volume_db = float(profile["gain_db"])
	sfx_player.play()
	return true

func set_play_sink(sink: Callable) -> void:
	_play_sink = sink

func get_feedback_count(kind: String) -> int:
	return int(_feedback_counts.get(kind, 0))

func contract() -> Dictionary:
	return {
		"ambient_path": AMBIENT_PATH,
		"chime_path": CHIME_PATH,
		"ambient_loaded": _ambient_stream != null,
		"chime_loaded": _chime_stream != null,
		"soft_match_loaded": _soft_match_stream != null,
		"match_feedback": "procedural_soft_wood_glass_tap",
		"ui_feedback": "procedural_soft_ui_tap",
		"mix_profile": "restrained_dark_cabinet_v3",
		"ambient_gain_db": -34.0,
		"match_gain_db": -34.0,
		"ui_gain_db": -38.0,
		"music_bus": String(music_player.bus) if music_player != null else "",
		"sfx_bus": String(sfx_player.bus) if sfx_player != null else "",
		"feedback": FEEDBACK.duplicate(true),
		"license": "CC0",
	}

func _make_soft_match_stream() -> AudioStreamWAV:
	# Short, low-amplitude wooden-glass tap: intentionally gentler than the repeated bell.
	var rate := 22050
	var duration := 0.12
	var count := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(rate)
		var envelope := (1.0 - exp(-t * 110.0)) * exp(-t * 36.0)
		var tone := sin(TAU * 360.0 * t) * 0.74 + sin(TAU * 540.0 * t) * 0.20 + sin(TAU * 720.0 * t) * 0.06
		var sample := clampf(tone * envelope * 0.12, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream
