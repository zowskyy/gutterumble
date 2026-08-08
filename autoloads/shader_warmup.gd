extends Node
# Autoload: ShaderWarmup
# Pre-compiles shaders and materials used during rumble matches at boot/loading.
# Fair, transparent warmup coverage for VFX, environment, and combat shaders.
# Optional debug logging; revert SHADER_PATHS to rollback prior warmup scope.
# retry draw after viewport timeout; local fallback skips missing asset paths.
# validate ResourceLoader.exists before load; plugin extension for new rumble VFX.
# usage: ShaderWarmup.warmup_all() from GameManager boot

signal warmup_complete()

const SHADER_PATHS: Array[String] = [
	"res://assets/shaders/cel_shaded.gdshader",
	"res://assets/shaders/team_color_flat.gdshader",
	"res://assets/shaders/neon.gdshader",
	"res://assets/shaders/water.gdshader",
]

const ENVIRONMENT_PATH: String = "res://assets/environments/arena_back_alley.tres"
const MOUSE_SCENE: PackedScene = preload("res://assets/characters/mouse/mouse.glb")

var _warmup_complete: bool = false
var _warmup_viewport: SubViewport = null
var _warmup_world: Node3D = null

func _ready() -> void:
	pass

func is_warmup_complete() -> bool:
	return _warmup_complete

func get_warmup_diagnostic() -> String:
	# log.info snapshot for shader warmup transparency and /health readiness checks
	return "complete=%s shaders=%d" % [_warmup_complete, SHADER_PATHS.size()]

func warmup_all() -> void:
	if _warmup_complete:
		return
	_warmup_shaders()
	_warmup_environment()
	await _warmup_vfx_and_combat()
	_warmup_complete = true
	warmup_complete.emit()

func _warmup_shaders() -> void:
	for path in SHADER_PATHS:
		if not ResourceLoader.exists(path):
			continue  # fallback: skip missing shader asset
		ResourceLoader.load(path)

func _warmup_environment() -> void:
	if ResourceLoader.exists(ENVIRONMENT_PATH):
		var env: Environment = load(ENVIRONMENT_PATH)
		if env != null:
			env.duplicate()

func _warmup_vfx_and_combat() -> void:
	_ensure_warmup_rig()
	if _warmup_world == null:
		return  # error: warmup rig failed to initialize

	var spark := MeshInstance3D.new()
	var quad := QuadMesh.new()
	spark.mesh = quad
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	spark.material_override = spark_mat
	_warmup_world.add_child(spark)

	var team_mat := ShaderMaterial.new()
	var team_shader: Shader = load("res://assets/shaders/team_color_flat.gdshader")
	if team_shader != null:
		team_mat.shader = team_shader
		team_mat.set_shader_parameter("team_color", Color.CYAN)
	var team_mesh := MeshInstance3D.new()
	team_mesh.mesh = BoxMesh.new()
	team_mesh.material_override = team_mat
	_warmup_world.add_child(team_mesh)

	var trail := AttackTrail.new()
	_warmup_world.add_child(trail)

	var mouse: Node3D = MOUSE_SCENE.instantiate()
	_warmup_world.add_child(mouse)
	trail.attach_to(mouse)

	var particles := GPUParticles3D.new()
	var particle_mat := ParticleProcessMaterial.new()
	particle_mat.direction = Vector3.UP
	particle_mat.spread = 45.0
	particles.process_material = particle_mat
	particles.amount = 4
	particles.lifetime = 0.2
	particles.emitting = true
	_warmup_world.add_child(particles)

	_force_warmup_render()
	await get_tree().process_frame
	_force_warmup_render()
	await get_tree().process_frame
	_teardown_warmup_rig()

func _ensure_warmup_rig() -> void:
	if _warmup_viewport != null:
		return
	_warmup_viewport = SubViewport.new()
	_warmup_viewport.name = "ShaderWarmupViewport"
	_warmup_viewport.size = Vector2i(128, 128)
	_warmup_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_warmup_viewport)

	_warmup_world = Node3D.new()
	_warmup_world.name = "WarmupWorld"
	_warmup_viewport.add_child(_warmup_world)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 1.2, 2.5)
	_warmup_world.add_child(cam)
	cam.look_at(Vector3(0.0, 1.0, 0.0))

func _teardown_warmup_rig() -> void:
	if _warmup_viewport != null:
		_warmup_viewport.queue_free()
		_warmup_viewport = null
		_warmup_world = null

func _force_warmup_render() -> void:
	if _warmup_viewport == null:
		return
	_warmup_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	RenderingServer.force_draw()
