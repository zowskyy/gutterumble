#!/usr/bin/env python3
"""
Batch apply all 4 arena texture sets to Godot scene.
Creates 4 floor variants with different textures.
"""

import os
import re

def generate_tscn_with_materials():
	"""Generate updated rumble_arena_back_alley.tscn with all 4 texture sets."""
	
	# Base scene structure
	tscn_content = """[gd_scene load_steps=6 format=3 uid="uid://gutterumble_arena_back_alley"]

[ext_resource type="Script" path="res://scenes/arenas/back_alley/rumble_arena_back_alley.gd" id="1"]

[sub_resource type="ShaderMaterial" id="Material_01"]
shader = SubResource("Shader1")
shader_parameter/albedo_texture = ExtResource("Albedo_01")
shader_parameter/normal_texture = ExtResource("Normal_01")
shader_parameter/tint_color = Vector3(1, 1, 1)

[sub_resource type="ShaderMaterial" id="Material_02"]
shader = SubResource("Shader1")
shader_parameter/albedo_texture = ExtResource("Albedo_02")
shader_parameter/normal_texture = ExtResource("Normal_02")
shader_parameter/tint_color = Vector3(1, 1, 1)

[sub_resource type="ShaderMaterial" id="Material_03"]
shader = SubResource("Shader1")
shader_parameter/albedo_texture = ExtResource("Albedo_03")
shader_parameter/normal_texture = ExtResource("Normal_03")
shader_parameter/tint_color = Vector3(1, 1, 1)

[sub_resource type="ShaderMaterial" id="Material_04"]
shader = SubResource("Shader1")
shader_parameter/albedo_texture = ExtResource("Albedo_04")
shader_parameter/normal_texture = ExtResource("Normal_04")
shader_parameter/tint_color = Vector3(1, 1, 1)

[ext_resource type="Shader" path="res://assets/shaders/cel_shaded.gdshader" id="Shader1"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_01_albedo.webp" id="Albedo_01"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_01_normal.png" id="Normal_01"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_02_albedo.webp" id="Albedo_02"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_02_normal.png" id="Normal_02"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_03_albedo.webp" id="Albedo_03"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_03_normal.png" id="Normal_03"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_04_albedo.webp" id="Albedo_04"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_04_normal.png" id="Normal_04"]

[sub_resource type="BoxMesh" id="BoxMesh_floor"]
size = Vector3(24, 0.5, 16)

[sub_resource type="BoxShape3D" id="BoxShape3D_floor"]
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

[node name="FloorMesh_01" type="MeshInstance3D" parent="Floor"]
mesh = SubResource("BoxMesh_floor")
material_override = SubResource("Material_01")

[node name="FloorMesh_02" type="MeshInstance3D" parent="Floor"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 30, 0, 0)
mesh = SubResource("BoxMesh_floor")
material_override = SubResource("Material_02")

[node name="FloorMesh_03" type="MeshInstance3D" parent="Floor"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -30, 0, 0)
mesh = SubResource("BoxMesh_floor")
material_override = SubResource("Material_03")

[node name="FloorMesh_04" type="MeshInstance3D" parent="Floor"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 30)
mesh = SubResource("BoxMesh_floor")
material_override = SubResource("Material_04")

[node name="FloorCollision" type="CollisionShape3D" parent="Floor"]
shape = SubResource("BoxShape3D_floor")

[node name="SpawnPoints" type="Node3D" parent="."]

[node name="Spawn1" type="Marker3D" parent="SpawnPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -10, 0.5, -6)

[node name="Spawn2" type="Marker3D" parent="SpawnPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 10, 0.5, 6)
"""
	
	output_path = "scenes/arenas/back_alley/rumble_arena_back_alley.tscn"
	
	with open(output_path, "w", encoding="utf-8") as f:
		f.write(tscn_content)
	
	print(f"✓ Generated {output_path}")
	print("\nScene now contains 4 floor meshes with different textures:")
	print("  - FloorMesh_01: arena_urban_01")
	print("  - FloorMesh_02: arena_urban_02 (offset X+30)")
	print("  - FloorMesh_03: arena_urban_03 (offset X-30)")
	print("  - FloorMesh_04: arena_urban_04 (offset Z+30)")
	print("\nReload Godot to see the updated scene.")

def main():
	print("\n" + "="*60)
	print("GUTTERUMBLE Batch Arena Texture Applicator")
	print("="*60 + "\n")
	
	# Check if texture files exist
	texture_files = [
		"assets/textures/arena/arena_urban_01_albedo.webp",
		"assets/textures/arena/arena_urban_01_normal.png",
		"assets/textures/arena/arena_urban_02_albedo.webp",
		"assets/textures/arena/arena_urban_02_normal.png",
		"assets/textures/arena/arena_urban_03_albedo.webp",
		"assets/textures/arena/arena_urban_03_normal.png",
		"assets/textures/arena/arena_urban_04_albedo.webp",
		"assets/textures/arena/arena_urban_04_normal.png",
	]
	
	missing = [f for f in texture_files if not os.path.exists(f)]
	
	if missing:
		print("❌ Missing texture files:")
		for f in missing:
			print(f"  - {f}")
		return
	
	print("✓ All 8 texture files found")
	print("\nGenerating scene with 4 textured floor variants...")
	generate_tscn_with_materials()
	
	print("\n" + "="*60)
	print("Done! Next steps:")
	print("  1. Reload Godot (Ctrl+Shift+F5)")
	print("  2. Press Play to see 4 textured floor tiles")
	print("  3. Each tile has different arena_urban textures")
	print("="*60 + "\n")

if __name__ == "__main__":
	main()