extends Node
# Autoload: VFXPool
# Pooled hit-spark flashes. Deliberately simple: a pooled MeshInstance3D quad
# per flash, not GPUParticles3D (Godot 4.4 has an open bug where
# GPUParticles3D billboard mode doesn't rotate correctly — godot#102697 —
# and particles are overkill for a single flash anyway).
#
# Uses a plain StandardMaterial3D with billboard_mode = BILLBOARD_ENABLED
# rather than a custom shader. An earlier version tried `render_mode
# billboard;` in a custom .gdshader — that is NOT a real render mode; Godot
# has no such keyword for spatial shaders (confirmed by the actual engine
# error: "Invalid render mode: 'billboard'. Shader compilation failed.").
# Billboarding a quad is an engine-native BaseMaterial3D feature, not
# something a custom shader needs to hand-roll at all.
#
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
var _active: Array[Dictionary]   = []   # {mesh, timer, duration, color}

func _ready() -> void:
	for _i in range(POOL_SIZE):
		var mesh := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.0, 1.0)
		mesh.mesh = quad

		var mat := StandardMaterial3D.new()
		mat.shading_mode                = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency                 = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode                    = BaseMaterial3D.BLEND_MODE_ADD
		mat.billboard_mode                = BaseMaterial3D.BILLBOARD_ENABLED
		mat.cull_mode                     = BaseMaterial3D.CULL_DISABLED
		mat.no_depth_test                  = true
		mat.disable_receive_shadows        = true
		mesh.material_override = mat

		mesh.visible = false
		add_child(mesh)
		_pool.append(mesh)

func spark(world_pos: Vector3, severity: String = "light") -> void:
	if _pool.is_empty():
		return   # all in use — drop silently, a missed flash is not worth a stall
	var mesh: MeshInstance3D = _pool.pop_back()
	var mat := mesh.material_override as StandardMaterial3D
	var color: Color = SEVERITY_COLOR.get(severity, Color.WHITE)
	var scale: float  = SEVERITY_SCALE.get(severity, 0.35)

	mesh.global_position = world_pos
	mesh.scale            = Vector3.ONE * scale
	mesh.visible           = true
	mat.albedo_color        = color

	_active.append({"mesh": mesh, "timer": 0.0, "duration": LIFETIME, "color": color})

func _process(delta: float) -> void:
	for i in range(_active.size() - 1, -1, -1):
		var entry: Dictionary = _active[i]
		entry.timer += delta
		var mesh: MeshInstance3D = entry.mesh
		var mat := mesh.material_override as StandardMaterial3D
		var fade: float = 1.0 - clampf(entry.timer / entry.duration, 0.0, 1.0)
		var base_color: Color = entry.color
		mat.albedo_color = Color(base_color.r, base_color.g, base_color.b, fade * fade)
		if entry.timer >= entry.duration:
			mesh.visible = false
			_pool.append(mesh)
			_active.remove_at(i)
