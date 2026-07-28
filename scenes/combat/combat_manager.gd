extends Node

var active_hitboxes: Dictionary = {}

func register_hitbox(hitbox_id: String, attacker_id: int, damage: float, range_val: float) -> void:
	active_hitboxes[hitbox_id] = {
		"attacker": attacker_id,
		"damage": damage,
		"range": range_val,
		"active": true,
	}

func check_hit(attacker_pos: Vector3, target_pos: Vector3, range_val: float) -> bool:
	return attacker_pos.distance_to(target_pos) <= range_val

func apply_damage(_target_id: int, _damage: float) -> void:
	pass

func apply_knockback(target: Node3D, direction: Vector3, force: float) -> void:
	if target is CharacterBody3D:
		target.velocity += direction.normalized() * force
