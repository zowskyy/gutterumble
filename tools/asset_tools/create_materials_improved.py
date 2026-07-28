#!/usr/bin/env python3
"""
Improved Material Preset Generator with Direct Error Logging.
Follows: explicit errors, standardized format, contextual info, no wrappers.
"""

import os

# Error message format: "file:line - Context: Error message"
ERROR_FORMAT = "{file}:{line} - {context}: {message}"
WARN_FORMAT = "{file}:{line} - {context}: {message}"

class MaterialGenerator:
	"""Direct material creation with explicit error logging."""
	
	def __init__(self):
		self.error_count = 0
		self.warning_count = 0
		self.success_count = 0
	
	def validate_textures(self, set_num):
		"""Validate required textures exist. Return (valid, error_msg)."""
		
		albedo_path = f"assets/textures/arena/arena_urban_{set_num:02d}_albedo.webp"
		normal_path = f"assets/textures/arena/arena_urban_{set_num:02d}_normal.png"
		
		if not os.path.exists(albedo_path):
			error_msg = ERROR_FORMAT.format(
				file=albedo_path,
				line=1,
				context=f"TextureValidation[set_{set_num}]",
				message=f"Albedo texture not found"
			)
			print(f"✗ {error_msg}")
			self.error_count += 1
			return False, error_msg
		
		if not os.path.exists(normal_path):
			error_msg = ERROR_FORMAT.format(
				file=normal_path,
				line=1,
				context=f"TextureValidation[set_{set_num}]",
				message=f"Normal texture not found"
			)
			print(f"✗ {error_msg}")
			self.error_count += 1
			return False, error_msg
		
		return True, None
	
	def create_gdscript_helper(self):
		"""Create a GDScript helper that applies materials at runtime.
		This is more robust than trying to write .tres files manually."""
		
		script_content = '''extends Node

# Material preset paths
const MATERIAL_SETS = [
	{
		"name": "Arena Urban 01",
		"albedo": "res://assets/textures/arena/arena_urban_01_albedo.webp",
		"normal": "res://assets/textures/arena/arena_urban_01_normal.png",
	},
	{
		"name": "Arena Urban 02",
		"albedo": "res://assets/textures/arena/arena_urban_02_albedo.webp",
		"normal": "res://assets/textures/arena/arena_urban_02_normal.png",
	},
	{
		"name": "Arena Urban 03",
		"albedo": "res://assets/textures/arena/arena_urban_03_albedo.webp",
		"normal": "res://assets/textures/arena/arena_urban_03_normal.png",
	},
	{
		"name": "Arena Urban 04",
		"albedo": "res://assets/textures/arena/arena_urban_04_albedo.webp",
		"normal": "res://assets/textures/arena/arena_urban_04_normal.png",
	},
]

func apply_material_set(mesh: MeshInstance3D, set_index: int) -> bool:
	"""Apply a material preset to a mesh. Returns success status with context."""
	
	if set_index < 0 or set_index >= MATERIAL_SETS.size():
		push_error(ERROR_FORMAT.format(
			file="apply_material_set",
			line=set_index,
			context="MaterialApplication",
			message="Invalid material set index: %d (valid: 0-%d)" % [set_index, MATERIAL_SETS.size() - 1]
		))
		return false
	
	var material_data = MATERIAL_SETS[set_index]
	
	# Create shader material
	var shader = load("res://assets/shaders/cel_shaded.gdshader")
	if shader == null:
		push_error(ERROR_FORMAT.format(
			file="cel_shaded.gdshader",
			line=1,
			context="ShaderLoad[set_%d]" % set_index,
			message="Failed to load shader"
		))
		return false
	
	var material = ShaderMaterial.new()
	material.shader = shader
	
	# Load textures
	var albedo = load(material_data["albedo"])
	if albedo == null:
		push_error(ERROR_FORMAT.format(
			file=material_data["albedo"],
			line=1,
			context="TextureLoad[set_%d]" % set_index,
			message="Failed to load albedo texture"
		))
		return false
	
	var normal = load(material_data["normal"])
	if normal == null:
		push_error(ERROR_FORMAT.format(
			file=material_data["normal"],
			line=1,
			context="TextureLoad[set_%d]" % set_index,
			message="Failed to load normal texture"
		))
		return false
	
	# Assign to material
	material.set_shader_parameter("albedo_texture", albedo)
	material.set_shader_parameter("normal_texture", normal)
	material.set_shader_parameter("tint_color", Vector3(1.0, 1.0, 1.0))
	
	# Apply to mesh
	mesh.set_surface_override_material(0, material)
	
	print("[%s] Material set %d applied successfully" % [
		material_data["name"],
		set_index
	])
	return true

# Helper for consistent error formatting
func ERROR_FORMAT(file: String, line: int, context: String, message: String) -> String:
	return "%s:%d - %s: %s" % [file, line, context, message]
'''
		
		output_path = "scenes/arenas/back_alley/material_manager.gd"
		
		with open(output_path, "w", encoding="utf-8") as f:
			f.write(script_content)
		
		print(f"✓ Created GDScript helper: {output_path}")
		print("  Use: material_manager.apply_material_set(floormesh, 0)")
		print("  to swap between 4 material presets at runtime")
		return output_path
	
	def generate_validation_report(self):
		"""Generate a validation checklist with explicit status."""
		
		print("\n" + "="*70)
		print("MATERIAL VALIDATION REPORT")
		print("="*70)
		
		all_valid = True
		
		for set_num in range(1, 5):
			valid, error_msg = self.validate_textures(set_num)
			if not valid:
				all_valid = False
		
		print("\n" + "-"*70)
		print(f"Summary: {self.success_count} valid, {self.error_count} errors, {self.warning_count} warnings")
		print("="*70 + "\n")
		
		return all_valid

def main():
	print("\n" + "="*70)
	print("GUTTERUMBLE Material Preset Generator (Improved)")
	print("="*70 + "\n")
	
	generator = MaterialGenerator()
	
	# Validate all texture sets
	print("Validating texture files...")
	all_valid = generator.generate_validation_report()
	
	if not all_valid:
		print("❌ Texture validation failed. Cannot proceed.")
		print("\nFix: Ensure all 8 texture files exist in assets/textures/arena/")
		return
	
	print("✓ All textures valid\n")
	
	# Create GDScript helper instead of .tres files
	print("Creating runtime material manager...\n")
	helper_path = generator.create_gdscript_helper()
	
	print("\n" + "="*70)
	print("NEXT STEPS")
	print("="*70)
	print("\n1. In Godot, create a Node and attach material_manager.gd to it")
	print("2. Call: material_manager.apply_material_set(floormesh, 0)")
	print("3. Pass set index 0-3 to swap materials at runtime")
	print("\nOR use the simple approach:")
	print("1. Select FloorMesh")
	print("2. In Inspector → Material → New ShaderMaterial")
	print("3. Shader: res://assets/shaders/cel_shaded.gdshader")
	print("4. Drag textures into Albedo/Normal slots")
	print("5. Press Play\n")
	print("="*70 + "\n")

if __name__ == "__main__":
	main()