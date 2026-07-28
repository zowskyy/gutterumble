extends Area3D
# Standalone hitbox component (kept for arena props and future use).
# player_controller.gd and enemy_ai.gd manage their own Hitbox children
# directly — this script is for hitboxes that need to exist independently
# of a fighter script (e.g. hazard zones, projectiles).

@export var damage: float    = 10.0
@export var knockback: float = 5.0

signal hit_target(target: Node3D, damage: float)

var _hit_ids: Array[int] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func reset() -> void:
	_hit_ids.clear()

func _on_area_entered(area: Area3D) -> void:
	var target := area.get_parent()
	if target == null:
		return
	var id := target.get_instance_id()
	if id in _hit_ids:
		return
	_hit_ids.append(id)
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if target is CharacterBody3D:
		var dir: Vector3 = ((target as Node3D).global_position - global_position).normalized()
		target.velocity += dir * knockback
	hit_target.emit(target, damage)
