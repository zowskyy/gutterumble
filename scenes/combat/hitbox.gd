extends Area3D
class_name Hitbox
# Reusable fighter hitbox component. Uses Area3D.area_entered (not per-frame
# polling), per-swing dedup via _hit_this_swing, and a short active window
# counted in physics frames. Callers extend the window with set_active_frames()
# before begin_swing() when AttackConfig active_time warrants more frames.

signal hit_landed(target: Node3D, hurtbox: Area3D)

@export var active_physics_frames: int = 3

var _hit_this_swing: Dictionary = {}
var _active_frames_remaining: int = 0
var _collision_shape: CollisionShape3D

func _ready() -> void:
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	monitoring = false
	area_entered.connect(_on_area_entered)

func set_active_frames(frame_count: int) -> void:
	active_physics_frames = maxi(3, frame_count)

func begin_swing(_damage: float, _knockback: float) -> void:
	_hit_this_swing.clear()
	_active_frames_remaining = active_physics_frames
	monitoring = true
	if _collision_shape:
		_collision_shape.disabled = false

func end_swing() -> void:
	_active_frames_remaining = 0
	monitoring = false
	if _collision_shape:
		_collision_shape.disabled = true

func _physics_process(_delta: float) -> void:
	if _active_frames_remaining <= 0:
		return
	_active_frames_remaining -= 1
	if _active_frames_remaining <= 0:
		end_swing()

func _on_area_entered(area: Area3D) -> void:
	if not _is_hurtbox(area):
		return
	var target := area.get_parent() as Node3D
	if target == null:
		return
	var target_id: int = target.get_instance_id()
	if _hit_this_swing.has(target_id):
		return
	_hit_this_swing[target_id] = true
	hit_landed.emit(target, area)

func _is_hurtbox(area: Area3D) -> bool:
	if area.is_in_group("hurtbox"):
		return true
	var area_script: Script = area.get_script()
	if area_script != null and area_script.resource_path.ends_with("hurtbox.gd"):
		return true
	return false
