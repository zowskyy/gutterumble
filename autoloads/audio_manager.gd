extends Node
# Autoload: AudioManager
# Centralised sound playback. Plays from a pool of AudioStreamPlayers so
# multiple sounds can overlap (e.g. two hits in the same frame).
# Drop .ogg / .wav files into res://assets/audio/ and reference them here.
#
# Usage:
#   AudioManager.play_sfx("hit_light")
#   AudioManager.play_music("arena_theme")

const SFX_POOL_SIZE := 8

const SFX_PATHS: Dictionary = {
	"hit_light":   "res://assets/audio/sfx/hit_light.ogg",
	"hit_heavy":   "res://assets/audio/sfx/hit_heavy.ogg",
	"hit_ko":      "res://assets/audio/sfx/hit_ko.ogg",
	"dodge":       "res://assets/audio/sfx/dodge.ogg",
	"ui_confirm":  "res://assets/audio/sfx/ui_confirm.ogg",
	"ui_back":     "res://assets/audio/sfx/ui_back.ogg",
	"countdown":   "res://assets/audio/sfx/countdown.ogg",
	"fight_start": "res://assets/audio/sfx/fight_start.ogg",
	"win":         "res://assets/audio/sfx/win.ogg",
	"lose":        "res://assets/audio/sfx/lose.ogg",
	"combo_milestone": "res://assets/audio/sfx/combo_milestone.ogg",
	"special_activate": "res://assets/audio/sfx/special_activate.ogg",
}

const MUSIC_PATHS: Dictionary = {
	"arena_theme": "res://assets/audio/music/arena_theme.ogg",
	"menu_theme":  "res://assets/audio/music/menu_theme.ogg",
}

# Crowd barks — ambient taunts/grunts from fighters not currently in the thick
# of it. Multiple variations so the same line doesn't repeat back-to-back.
const BARK_PATHS: Array[String] = [
	"res://assets/audio/sfx/barks/bark_01.ogg",
	"res://assets/audio/sfx/barks/bark_02.ogg",
	"res://assets/audio/sfx/barks/bark_03.ogg",
]
const BARK_COOLDOWN_SECS := 4.0   # global — one bark at a time regardless of wave size

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int                     = 0
var _music_player: AudioStreamPlayer    = null
var _sfx_vol_db: float                  = 0.0
var _music_vol_db: float                = -6.0

var _bark_player: AudioStreamPlayer3D = null
var _last_bark_usec: int              = 0

func _ready() -> void:
	for _i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = _music_vol_db
	add_child(_music_player)

	# Single shared 3D emitter — barks are cooldown-gated to one at a time,
	# so there's never a need for a pool here.
	_bark_player = AudioStreamPlayer3D.new()
	_bark_player.bus = "SFX"
	add_child(_bark_player)

func play_sfx(key: String, pitch_rand: float = 0.08) -> void:
	if not SFX_PATHS.has(key):
		return
	var path: String = SFX_PATHS[key]
	if not ResourceLoader.exists(path):
		return   # audio file not added yet — silent until assets arrive
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_pool[_sfx_index % SFX_POOL_SIZE]
	_sfx_index += 1
	player.stream          = stream
	player.volume_db       = _sfx_vol_db
	player.pitch_scale     = 1.0 + randf_range(-pitch_rand, pitch_rand)
	player.play()

func play_bark(source: Node3D) -> void:
	if BARK_PATHS.is_empty():
		return
	var now := Time.get_ticks_usec()
	if (now - _last_bark_usec) < int(BARK_COOLDOWN_SECS * 1_000_000):
		return   # global cooldown — keeps a big wave from turning into noise
	var path: String = BARK_PATHS[randi() % BARK_PATHS.size()]
	if not ResourceLoader.exists(path):
		return   # bark clips not added yet — silent until assets arrive
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_last_bark_usec = now
	_bark_player.global_position = source.global_position
	_bark_player.stream          = stream
	_bark_player.pitch_scale     = 1.0 + randf_range(-0.1, 0.1)
	_bark_player.play()

func play_music(key: String, _fade_time: float = 1.0) -> void:
	if not MUSIC_PATHS.has(key):
		return
	var path: String = MUSIC_PATHS[key]
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func set_sfx_volume(linear: float) -> void:
	_sfx_vol_db = linear_to_db(clampf(linear, 0.0, 1.0))

func set_music_volume(linear: float) -> void:
	_music_vol_db = linear_to_db(clampf(linear, 0.0, 1.0))
	_music_player.volume_db = _music_vol_db
