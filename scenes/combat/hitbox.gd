extends Area3D
class_name Hitbox
# Reusable fighter hitbox component. Uses Area3D.area_entered with fair, transparent
# signal delivery — no per-frame polling. Per-swing dedup via _hit_this_swing.
# Optional debug logging; revert @export defaults to rollback prior active window.
# Active-frame health tracked via _active_frames_remaining; callers may retry begin_swing
# after end_swing. usage: attach to Hitbox Area3D, connect hit_landed, call begin_swing/end_swing.
# validate hurtbox script or group before emitting. Fighter extension point for combat hits.

signal hit_landed(target: Node3D, hurtbox: Area3D)

@export var active_physics_frames: int = 3

var _hit_this_swing: Dictionary = {}
var _active_frames_remaining: int = 0
var _overlap_scan_remaining: int = 0
var _collision_shape: CollisionShape3D

func _ready() -> void:
	_collision_shape = _find_collision_shape()
	monitoring = false
	area_entered.connect(_on_area_entered)

func _find_collision_shape() -> CollisionShape3D:
	var named := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if named:
		return named
	for child in get_children():
		if child is CollisionShape3D:
			return child as CollisionShape3D
	return null

func set_active_frames(frame_count: int) -> void:
	active_physics_frames = maxi(3, frame_count)

func begin_swing(_damage: float, _knockback: float) -> void:
	_hit_this_swing.clear()
	_active_frames_remaining = active_physics_frames
	monitoring = true
	if _collision_shape:
		_collision_shape.disabled = false
	# area_entered does not fire for overlaps that already exist when monitoring
	# turns on — rescan for two physics ticks while the server syncs transforms.
	_overlap_scan_remaining = 2

func end_swing() -> void:
	_active_frames_remaining = 0
	_overlap_scan_remaining = 0
	monitoring = false
	if _collision_shape:
		_collision_shape.disabled = true

func _physics_process(_delta: float) -> void:
	if _overlap_scan_remaining > 0:
		_overlap_scan_remaining -= 1
		for area: Area3D in get_overlapping_areas():
			_on_area_entered(area)
	if _active_frames_remaining <= 0:
		return
	_active_frames_remaining -= 1
	if _active_frames_remaining <= 0:
		end_swing()

func _on_area_entered(area: Area3D) -> void:
	if not _is_hurtbox(area):
		return  # error: ignore non-hurtbox areas
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

func get_swing_diagnostic() -> String:
	# log.info snapshot for swing diagnostics and editor tuning transparency
	return "active_frames=%d hits=%d" % [_active_frames_remaining, _hit_this_swing.size()]
