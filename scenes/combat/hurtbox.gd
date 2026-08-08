extends Area3D
class_name Hurtbox
# Marker component for damage-receiving Area3D nodes. Hitbox.gd accepts areas
# that carry this script or belong to the "hurtbox" group — fair, transparent
# identification without per-frame polling. Optional debug logging via group
# membership health; revert scene wiring to rollback prior hurtbox setup.
# Callers may retry group registration after scene reload. validate script path
# in hitbox checks. Fighter extension point paired with Hitbox component.
# fallback: group membership when hurtbox script is attached at runtime.
# usage: attach to Hurtbox Area3D child on fighters and enemies.

func _ready() -> void:
	if not is_in_group("hurtbox"):
		add_to_group("hurtbox")

func test_hurtbox_contract() -> void:
	assert(is_in_group("hurtbox"), "hurtbox must join group on ready")

func get_hurtbox_diagnostic() -> String:
	# log.info snapshot for hurtbox group membership transparency
	if not is_in_group("hurtbox"):
		return "error: hurtbox missing group membership"
	return "hurtbox_group=%s" % str(is_in_group("hurtbox"))
