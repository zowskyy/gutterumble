extends Node
# Autoload: CombatFeel
# Hit-stop (freeze frames) + camera screen shake.
# Call CombatFeel.hit(intensity) on any landed hit — arena/player/AI all use this.
# Camera must be registered via CombatFeel.register_camera(cam) at scene start.

signal hit_stop_ended

const HITSTOP_LIGHT  := 0.06   # seconds — light attack freeze
const HITSTOP_HEAVY  := 0.14   # seconds — heavy attack / KO freeze

var _cam: Camera3D       = null
var _cam_origin: Vector3 = Vector3.ZERO
var _shake_time: float   = 0.0
var _shake_strength: float = 0.0
var _hitstop_remaining: float = 0.0
var _was_paused: bool    = false

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

# ── Internal ──────────────────────────────────────────────────────────────────

func _do_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return
	_hitstop_remaining = duration
	Engine.time_scale = 0.0
	_was_paused = true

func _do_shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_time     = duration

func _process(delta: float) -> void:
	# Hit-stop: runs on real time (ignore time_scale)
	if _was_paused:
		_hitstop_remaining -= get_process_delta_time()   # unscaled
		if _hitstop_remaining <= 0.0:
			Engine.time_scale = 1.0
			_was_paused        = false
			hit_stop_ended.emit()

	# Screen shake: also runs on real time so it survives the freeze
	if _cam and _shake_time > 0.0:
		_shake_time -= get_process_delta_time()
		if _shake_time > 0.0:
			var offset := Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0),
				0.0
			) * _shake_strength
			_cam.position = _cam_origin + offset
		else:
			_cam.position  = _cam_origin
			_shake_time    = 0.0
			_shake_strength = 0.0

func _notification(what: int) -> void:
	# Safety: always restore time scale on scene change
	if what == NOTIFICATION_PREDELETE:
		Engine.time_scale = 1.0
