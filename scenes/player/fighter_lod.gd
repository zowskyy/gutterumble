extends Node
# Attach as a child of any CharacterBody3D fighter.
# Swaps between High / Med / Low mesh children based on distance to camera.
# Node names expected under a "Visuals" child: "High", "Med", "Low".
# If only one mesh exists (no LODs yet), the script is a no-op.

@export var lod_distances: Array[float] = [8.0, 18.0]   # High→Med, Med→Low

var _cam: Camera3D
var _cur_lod: int = 0
var _lod_nodes: Array[Node3D] = []

func _ready() -> void:
	_cam = get_viewport().get_camera_3d()
	var visuals := get_parent().get_node_or_null("Visuals")
	if visuals == null:
		set_process(false)
		return
	for name in ["High", "Med", "Low"]:
		var n := visuals.get_node_or_null(name) as Node3D
		if n:
			_lod_nodes.append(n)
	if _lod_nodes.size() < 2:
		set_process(false)   # nothing to switch

func _process(_delta: float) -> void:
	if _cam == null:
		_cam = get_viewport().get_camera_3d()
		return
	var dist := get_parent().global_position.distance_to(_cam.global_position)
	var target: int = 0
	for i in range(lod_distances.size()):
		if dist > lod_distances[i]:
			target = i + 1
	target = clampi(target, 0, _lod_nodes.size() - 1)
	if target == _cur_lod:
		return
	_cur_lod = target
	for i in range(_lod_nodes.size()):
		_lod_nodes[i].visible = (i == _cur_lod)
