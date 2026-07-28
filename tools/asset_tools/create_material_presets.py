#!/usr/bin/env python3
"""
Create 4 material presets for swapping arena textures.
"""

import os

def create_material_preset(set_num):
	"""Create a material preset for each texture set."""
	
	material_code = f"""[gd_resource type="ShaderMaterial" load_steps=3 format=3 uid="uid://arena_material_{set_num:02d}"]

[ext_resource type="Shader" path="res://assets/shaders/cel_shaded.gdshader" id="1"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_{set_num:02d}_albedo.webp" id="2"]
[ext_resource type="Texture2D" path="res://assets/textures/arena/arena_urban_{set_num:02d}_normal.png" id="3"]

shader = ExtResource("1")
shader_parameter/albedo_texture = ExtResource("2")
shader_parameter/normal_texture = ExtResource("3")
shader_parameter/tint_color = Vector3(1, 1, 1)
"""
	
	output_path = f"assets/textures/arena/material_arena_urban_{set_num:02d}.tres"
	
	with open(output_path, "w", encoding="utf-8") as f:
		f.write(material_code)
	
	print(f"✓ Created {output_path}")

def main():
	print("\n" + "="*60)
	print("GUTTERUMBLE Material Preset Generator")
	print("="*60 + "\n")
	
	os.makedirs("assets/textures/arena", exist_ok=True)
	
	for i in range(1, 5):
		create_material_preset(i)
	
	print("\n" + "="*60)
	print("Created 4 material presets!")
	print("="*60)
	print("\nTo use:")
	print("1. In Godot, select FloorMesh")
	print("2. In Inspector, find Material")
	print("3. Click the material slot")
	print("4. Load any material_arena_urban_XX.tres file")
	print("5. Textures swap instantly!")
	print("\n" + "="*60 + "\n")

if __name__ == "__main__":
	main()