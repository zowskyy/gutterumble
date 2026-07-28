extends MeshInstance3D
class_name AttackTrail
# Fist/weapon trail — samples a bone's world position every frame while
# active and draws a fading ribbon behind it via ImmediateMesh.
# Not GPUParticles3D: a hand-drawn ribbon gives exact control over width
# tapering and is far cheaper than a particle trail for a single ribbon.
#
# Usage: instantiate, call attach_to(model_root) once, then toggle
# set_active(true/false) — call it from the same place that flips the
# fighter's hitbox on/off (the ACTIVE attack phase), so the trail only
# appears while the swing can actually connect.

@export var bone_name: String       = "wrist.R"
@export var trail_color: Color      = Color(1.0, 0.95, 0.6, 1.0)
@export var point_lifetime: float   = 0.18
@export var width: float            = 0.12
@export var max_points: int         = 14

var _skeleton: Skeleton3D = null
var _bone_idx: int        = -1
var _active: bool         = false
var _points: Array         = []   # [{pos: Vector3, age: float}, ...]

func _ready() -> void:
	top_level = true   # draw in world space, independent of fighter's own transform
	mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode                 = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test               = true
	mat.disable_receive_shadows     = true
	material_override = mat

func attach_to(model_root: Node) -> void:
	_skeleton = _find_skeleton(model_root)
	if _skeleton:
		_bone_idx = _skeleton.find_bone(bone_name)
		if _bone_idx < 0:
			push_warning("AttackTrail: bone '%s' not found in skeleton" % bone_name)

func set_active(active: bool) -> void:
	_active = active
	if not active:
		_points.clear()

func _process(delta: float) -> void:
	if _skeleton == null or _bone_idx < 0:
		return

	for p in _points:
		p.age += delta
	_points = _points.filter(func(p) -> bool: return p.age < point_lifetime)

	if _active:
		var bone_pose: Transform3D = _skeleton.get_bone_global_pose(_bone_idx)
		var world_pos: Vector3     = _skeleton.global_transform * bone_pose.origin
		_points.append({"pos": world_pos, "age": 0.0})
		if _points.size() > max_points:
			_points.pop_front()

	_rebuild_ribbon()

func _rebuild_ribbon() -> void:
	var im := mesh as ImmediateMesh
	im.clear_surfaces()
	if _points.size() < 2:
		return

	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(_points.size()):
		var p: Dictionary  = _points[i]
		var age_t: float   = 1.0 - (p.age / point_lifetime)
		var w: float        = width * age_t

		var dir: Vector3
		if i < _points.size() - 1:
			dir = (_points[i + 1].pos - p.pos)
		elif i > 0:
			dir = (p.pos - _points[i - 1].pos)
		else:
			dir = Vector3.FORWARD

		var right: Vector3 = dir.normalized().cross(Vector3.UP)
		if right.length_squared() < 0.0001:
			right = Vector3.RIGHT
		right = right.normalized() * w

		var col := Color(trail_color.r, trail_color.g, trail_color.b, age_t)
		im.surface_set_color(col)
		im.surface_add_vertex(p.pos - right)
		im.surface_set_color(col)
		im.surface_add_vertex(p.pos + right)
	im.surface_end()

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null
