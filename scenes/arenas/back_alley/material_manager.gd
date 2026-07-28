extends Node

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
	if set_index < 0 or set_index >= MATERIAL_SETS.size():
		push_error(ERROR_FORMAT(
			"apply_material_set",
			set_index,
			"MaterialApplication",
			"Invalid material set index: %d (valid: 0-%d)" % [set_index, MATERIAL_SETS.size() - 1]
		))
		return false

	var material_data: Dictionary = MATERIAL_SETS[set_index]

	var shader: Shader = load("res://assets/shaders/cel_shaded.gdshader")
	if shader == null:
		push_error(ERROR_FORMAT(
			"cel_shaded.gdshader",
			1,
			"ShaderLoad[set_%d]" % set_index,
			"Failed to load shader"
		))
		return false

	var material := ShaderMaterial.new()
	material.shader = shader

	var albedo: Texture2D = load(material_data["albedo"])
	if albedo == null:
		push_error(ERROR_FORMAT(
			material_data["albedo"],
			1,
			"TextureLoad[set_%d]" % set_index,
			"Failed to load albedo texture"
		))
		return false

	var normal: Texture2D = load(material_data["normal"])
	if normal == null:
		push_error(ERROR_FORMAT(
			material_data["normal"],
			1,
			"TextureLoad[set_%d]" % set_index,
			"Failed to load normal texture"
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
