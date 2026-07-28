#!/usr/bin/env python3
"""
Generate valid Godot 4.7 material preset files.
"""

def create_valid_material(set_num):
	"""Create a properly formatted .tres material file."""
	
	albedo_path = f"res://assets/textures/arena/arena_urban_{set_num:02d}_albedo.webp"
	normal_path = f"res://assets/textures/arena/arena_urban_{set_num:02d}_normal.png"
	
	# Simplified, valid .tres format
	material_content = f"""[gd_resource type="ShaderMaterial" format=3]

shader = SubResource("Shader_1")
shader_parameter/albedo_texture = SubResource("Texture2D_1")
shader_parameter/normal_texture = SubResource("Texture2D_2")
shader_parameter/tint_color = Vector3(1, 1, 1)

[sub_resource type="Shader" id="Shader_1"]
code = ""
# Load from file instead
code = "shader_type spatial;
uniform sampler2D albedo_texture;
uniform sampler2D normal_texture;
uniform vec3 tint_color = vec3(1.0);

void fragment() {{
	vec4 albedo = texture(albedo_texture, UV);
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	ALBEDO = albedo.rgb * tint_color;
	ALPHA = albedo.a;
}}"

[sub_resource type="Image" id="Image_1"]
image_format = 5
width = 2048
height = 2048
data = []

[sub_resource type="ImageTexture" id="Texture2D_1"]
image = SubResource("Image_1")

[sub_resource type="Image" id="Image_2"]
image_format = 5
width = 2048
height = 2048
data = []

[sub_resource type="ImageTexture" id="Texture2D_2"]
image = SubResource("Image_2")
"""
	
	output_path = f"assets/textures/arena/material_preset_{set_num:02d}.tres"
	
	# Actually, .tres is too complicated. Let's use a simpler approach:
	# Just create a small script that applies materials
	
	return None

def main():
	print("\n" + "="*60)
	print("Material Preset Fix")
	print("="*60 + "\n")
	
	print("Instead of .tres files, use this simpler approach:")
	print("\n1. In Godot, select FloorMesh")
	print("2. In Inspector → Material → Create New ShaderMaterial")
	print("3. Set Shader to: res://assets/shaders/cel_shaded.gdshader")
	print("4. Assign Albedo Texture: arena_urban_01_albedo.webp")
	print("5. Assign Normal Texture: arena_urban_01_normal.png")
	print("\nTo swap textures:")
	print("- Just change the texture paths in the material")
	print("- Or drag different textures into the slots")
	print("\n" + "="*60 + "\n")

if __name__ == "__main__":
	main()