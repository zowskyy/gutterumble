extends Camera3D
# Dynamic arena camera — tracks the midpoint between two fighters.
# Zooms out when they're far apart, pulls in when close.
# Attach to Camera3D in the arena scene and call set_targets() from the arena.

@export var base_height: float    = 7.0
@export var base_distance: float  = 11.0
@export var zoom_speed: float     = 3.0
@export var follow_speed: float   = 5.0
@export var x_padding: float      = 4.0    # extra horizontal breathing room

@export var finisher_zoom_dist: float   = 5.0
@export var finisher_zoom_height: float = 3.0

var _target_a: Node3D = null
var _target_b: Node3D = null
var _origin: Vector3  = Vector3.ZERO   # saved for CombatFeel shake

var _finisher_target: Node3D  = null
var _finisher_timer: float    = 0.0
var _last_tick_usec: int      = 0

func _ready() -> void:
	_origin = position
	_last_tick_usec = Time.get_ticks_usec()

func set_targets(a: Node3D, b: Node3D) -> void:
	_target_a = a
	_target_b = b
	CombatFeel.register_camera(self)
	CombatFeel._cam_origin = position

# Punches the camera in on a single fighter for a finisher beat — call
# alongside CombatFeel.finisher_slowmo(). Automatically reverts to normal
# two-target tracking once the duration elapses.
func zoom_in_on(target: Node3D, duration: float) -> void:
	_finisher_target = target
	_finisher_timer  = duration
	_last_tick_usec  = Time.get_ticks_usec()   # fresh reference — see _process

func _process(delta: float) -> void:
	if _finisher_target and is_instance_valid(_finisher_target) and _finisher_timer > 0.0:
		# Timer uses REAL elapsed time so it expires in sync with
		# CombatFeel.finisher_slowmo()'s own real-time duration — `delta` here
		# is scaled by Engine.time_scale during the slow-mo beat itself and
		# would otherwise let this timer run ~3x longer than intended.
		var now := Time.get_ticks_usec()
		_finisher_timer -= (now - _last_tick_usec) / 1_000_000.0
		_last_tick_usec = now
		var pos := _finisher_target.global_position
		var finisher_pos := Vector3(pos.x, finisher_zoom_height, pos.z + finisher_zoom_dist)
		position = position.lerp(finisher_pos, follow_speed * 1.5 * delta)
		look_at(Vector3(pos.x, 1.0, pos.z), Vector3.UP)
		CombatFeel._cam_origin = position
		if _finisher_timer <= 0.0:
			_finisher_target = null
		return

	if _target_a == null or _target_b == null:
		return
	if not is_instance_valid(_target_a) or not is_instance_valid(_target_b):
		return

	var mid: Vector3   = (_target_a.global_position + _target_b.global_position) * 0.5
	var spread: float  = _target_a.global_position.distance_to(_target_b.global_position)

	# Scale distance with fighter separation
	var zoom_factor: float = clampf(spread / 6.0, 1.0, 2.2)
	var target_dist: float = base_distance * zoom_factor
	var target_h: float    = base_height   * zoom_factor

	# Smooth camera position
	var target_pos := Vector3(mid.x, target_h, mid.z + target_dist)
	position = position.lerp(target_pos, follow_speed * delta)

	# Always look at the midpoint (slightly above ground)
	look_at(Vector3(mid.x, 1.0, mid.z), Vector3.UP)

	# Keep shake origin synced
	CombatFeel._cam_origin = position
