extends Node
# =============================================================================
# QUARANTINE / REPLACE CANDIDATE — NOT AUTHORITATIVE
# Canonical damage path: Hitbox (hit_landed) → target.take_damage(...)
#   scenes/combat/hitbox.gd → scenes/player/player_controller.gd / enemy_ai.gd
# This autoload is NOT on the live combat path. Do not call apply_damage() for
# production combat. See docs/engineering/CANONICAL_ARCHITECTURE.md.
# Command 02: annotate only; deletion deferred to Command 13 after ref count = 0.
# =============================================================================

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

## Stub — NOT the damage authority. Live combat uses Hitbox → take_damage.
func apply_damage(_target_id: int, _damage: float) -> void:
	pass

func apply_knockback(target: Node3D, direction: Vector3, force: float) -> void:
	if target is CharacterBody3D:
		target.velocity += direction.normalized() * force
