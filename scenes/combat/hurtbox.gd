extends Area3D
class_name Hurtbox
# Marker component for damage-receiving Area3D nodes. Hitbox.gd accepts areas
# that carry this script or belong to the "hurtbox" group.

func _ready() -> void:
	add_to_group("hurtbox")
