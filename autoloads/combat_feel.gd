extends Node
# Autoload: CombatFeel
# Hit-stop (freeze frames) + camera screen shake + finisher slow-mo.
# Call CombatFeel.hit_light()/hit_heavy()/hit_ko() on any landed hit — arena/
# player/AI all use this. Camera must be registered via register_camera().
#
# IMPORTANT — never set Engine.time_scale to exactly 0.0: Godot's own docs
# warn "it's recommended to keep this property above 0.0, as the game may
# behave unexpectedly otherwise." time_scale also scales the delta passed to
# EVERY _process()/_physics_process() in the game (confirmed against Godot's
# Engine class reference), including this autoload's own _process — so a
# countdown driven by `delta` or get_process_delta_time() while time_scale=0
# would receive a delta of ~0 every frame and never resolve, freezing the
# game permanently on the very first hit. Both timers below are driven by
# Time.get_ticks_usec() (real wall-clock time, immune to time_scale) instead,
# and HITSTOP_TIME_SCALE stays just above zero rather than hitting it exactly.

signal hit_stop_ended

const HITSTOP_LIGHT      := 0.06   # seconds — light attack freeze
const HITSTOP_HEAVY      := 0.14   # seconds — heavy attack / KO freeze
const HITSTOP_TIME_SCALE := 0.02   # near-freeze, not exactly 0.0

const FINISHER_SLOWMO_SCALE    := 0.3
const FINISHER_SLOWMO_DURATION := 0.6   # real seconds

var _cam: Camera3D         = null
var _cam_origin: Vector3   = Vector3.ZERO
var _shake_time: float     = 0.0
var _shake_strength: float = 0.0

var _hitstop_remaining: float  = 0.0
var _was_paused: bool          = false
var _finisher_active: bool     = false
var _finisher_remaining: float = 0.0

var _last_tick_usec: int = 0

func _ready() -> void:
	_last_tick_usec = Time.get_ticks_usec()

func register_camera(cam: Camera3D) -> void:
	_cam = cam
	if _cam:
		_cam_origin = _cam.position

func hit_light() -> void:
	_do_hitstop(HITSTOP_LIGHT)
	_do_shake(0.04, 0.18)

func hit_heavy() -> void:
	_do_hitstop(HITSTOP_HEAVY)
	_do_shake(0.09, 0.30)

func hit_ko() -> void:
	_do_hitstop(HITSTOP_HEAVY * 1.5)
	_do_shake(0.14, 0.50)

# ── Finisher cinematic — the KO that ends a round/match ───────────────────────
# A softer, longer beat than the per-hit freeze above: real slow motion
# (not a near-freeze) so the falling animation stays visible. The arena calls
# this after the initiating hit's own hit-stop has resolved (see
# rumble_arena_back_alley.gd's _play_finisher_beat).
func finisher_slowmo() -> void:
	if _finisher_active:
		return   # don't stack
	_finisher_active    = true
	_finisher_remaining = FINISHER_SLOWMO_DURATION
	Engine.time_scale   = FINISHER_SLOWMO_SCALE

# ── Internal ──────────────────────────────────────────────────────────────────

func _do_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return
	_hitstop_remaining = duration
	Engine.time_scale  = HITSTOP_TIME_SCALE
	_was_paused        = true

func _do_shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_time     = duration

func _real_delta() -> float:
	var now := Time.get_ticks_usec()
	var dt  := (now - _last_tick_usec) / 1_000_000.0
	_last_tick_usec = now
	return dt

func _process(_delta: float) -> void:
	var rdt := _real_delta()

	if _was_paused:
		_hitstop_remaining -= rdt
		if _hitstop_remaining <= 0.0:
			Engine.time_scale = 1.0
			_was_paused        = false
			hit_stop_ended.emit()

	if _finisher_active:
		_finisher_remaining -= rdt
		if _finisher_remaining <= 0.0:
			_finisher_active   = false
			Engine.time_scale  = 1.0

	if _cam and _shake_time > 0.0:
		_shake_time -= rdt
		if _shake_time > 0.0:
			var offset := Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0),
				0.0
			) * _shake_strength
			_cam.position = _cam_origin + offset
		else:
			_cam.position   = _cam_origin
			_shake_time     = 0.0
			_shake_strength = 0.0

func _notification(what: int) -> void:
	# Safety: always restore time scale on scene change
	if what == NOTIFICATION_PREDELETE:
		Engine.time_scale = 1.0
