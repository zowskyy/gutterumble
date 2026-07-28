extends Camera3D
# Dynamic arena camera — tracks the midpoint between two fighters.
# Zooms out when they're far apart, pulls in when close.
# Attach to Camera3D in the arena scene and call set_targets() from the arena.

@export var base_height: float    = 7.0
@export var base_distance: float  = 11.0
@export var zoom_speed: float     = 3.0
@export var follow_speed: float   = 5.0
@export var x_padding: float      = 4.0    # extra horizontal breathing room

var _target_a: Node3D = null
var _target_b: Node3D = null
var _origin: Vector3  = Vector3.ZERO   # saved for CombatFeel shake

func _ready() -> void:
	_origin = position

func set_targets(a: Node3D, b: Node3D) -> void:
	_target_a = a
	_target_b = b
	CombatFeel.register_camera(self)
	CombatFeel._cam_origin = position

func _process(delta: float) -> void:
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
