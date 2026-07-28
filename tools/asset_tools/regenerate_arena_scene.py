#!/usr/bin/env python3
"""
Regenerate a working arena scene without errors.
"""

def generate_clean_arena():
	"""Generate a minimal, working arena scene."""
	
	tscn = """[gd_scene load_steps=3 format=3 uid="uid://gutterumble_arena_back_alley"]

[ext_resource type="Script" path="res://scenes/arenas/back_alley/rumble_arena_back_alley.gd" id="1"]

[sub_resource type="BoxMesh" id="BoxMesh_1"]
size = Vector3(24, 0.5, 16)

[sub_resource type="BoxShape3D" id="BoxShape3D_1"]
size = Vector3(24, 0.5, 16)

[node name="RumbleArenaBackAlley" type="Node3D"]
script = ExtResource("1")

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 10, 12)
current = true

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 8, 0)
light_energy = 0.7
shadow_enabled = true

[node name="Floor" type="StaticBody3D" parent="."]

[node name="FloorMesh" type="MeshInstance3D" parent="Floor"]
mesh = SubResource("BoxMesh_1")

[node name="FloorCollision" type="CollisionShape3D" parent="Floor"]
shape = SubResource("BoxShape3D_1")

[node name="SpawnPoints" type="Node3D" parent="."]

[node name="Spawn1" type="Marker3D" parent="SpawnPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -10, 0.5, -6)

[node name="Spawn2" type="Marker3D" parent="SpawnPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 10, 0.5, 6)
"""
	
	output_path = "scenes/arenas/back_alley/rumble_arena_back_alley.tscn"
	
	with open(output_path, "w", encoding="utf-8") as f:
		f.write(tscn)
	
	print(f"✓ Regenerated {output_path}")
	print("\nScene restored to working state:")
	print("  - FloorMesh (no material assigned yet)")
	print("  - Camera3D")
	print("  - DirectionalLight3D")
	print("  - 2 spawn points")
	print("\nNext: Assign a material to FloorMesh in Godot")

def main():
	print("\n" + "="*60)
	print("GUTTERUMBLE Arena Scene Regenerator")
	print("="*60 + "\n")
	generate_clean_arena()
	print("="*60 + "\n")

if __name__ == "__main__":
	main()