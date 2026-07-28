extends Node
# Autoload: VFXPool
# Pooled hit-spark flashes. Deliberately simple: a pooled MeshInstance3D quad
# per flash, not GPUParticles3D (see hit_spark.gdshader header comment for why).
# Call VFXPool.spark(world_pos, severity) — "light" | "heavy" | "ko".

const POOL_SIZE := 16
const LIFETIME  := 0.18   # seconds — matches CombatFeel's hit-stop window

const SEVERITY_COLOR: Dictionary = {
	"light": Color(1.0, 1.0, 1.0, 1.0),
	"heavy": Color(1.0, 0.55, 0.15, 1.0),
	"ko":    Color(1.0, 0.85, 0.1, 1.0),
}
const SEVERITY_SCALE: Dictionary = {
	"light": 0.35,
	"heavy": 0.55,
	"ko":    0.9,
}

var _pool: Array[MeshInstance3D] = []
var _active: Array[Dictionary]   = []   # {mesh, timer, duration}
var _shader: Shader = preload("res://assets/shaders/hit_spark.gdshader")

func _ready() -> void:
	for _i in range(POOL_SIZE):
		var mesh := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.0, 1.0)
		mesh.mesh = quad
		var mat := ShaderMaterial.new()
		mat.shader = _shader
		mesh.material_override = mat
		mesh.visible = false
		add_child(mesh)
		_pool.append(mesh)

func spark(world_pos: Vector3, severity: String = "light") -> void:
	if _pool.is_empty():
		return   # all in use — drop silently, a missed flash is not worth a stall
	var mesh: MeshInstance3D = _pool.pop_back()
	var mat := mesh.material_override as ShaderMaterial
	var color: Color = SEVERITY_COLOR.get(severity, Color.WHITE)
	var scale: float  = SEVERITY_SCALE.get(severity, 0.35)

	mesh.global_position = world_pos
	mesh.scale            = Vector3.ONE * scale
	mesh.visible           = true
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("progress", 0.0)

	_active.append({"mesh": mesh, "timer": 0.0, "duration": LIFETIME})

func _process(delta: float) -> void:
	for i in range(_active.size() - 1, -1, -1):
		var entry: Dictionary = _active[i]
		entry.timer += delta
		var mesh: MeshInstance3D = entry.mesh
		var mat := mesh.material_override as ShaderMaterial
		mat.set_shader_parameter("progress", clampf(entry.timer / entry.duration, 0.0, 1.0))
		if entry.timer >= entry.duration:
			mesh.visible = false
			_pool.append(mesh)
			_active.remove_at(i)
