extends Node
# Autoload: FighterPool
# Pre-allocates fighter and enemy scenes to eliminate per-spawn allocation spikes.
# Call pull() to get an instance, push() to return it when despawned.
# Sized for Warriors-mode: up to 24 fighters total (2 teams of 12).

const POOL_SIZE_PER_SCENE := 12

var _pools: Dictionary = {}   # scene_path -> Array[Node3D]
var _active: Dictionary = {}  # scene_path -> Array[Node3D]

func preload_scene(scene_path: String, parent: Node) -> void:
	if _pools.has(scene_path):
		return
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("FighterPool: cannot load %s" % scene_path)
		return
	_pools[scene_path] = []
	_active[scene_path] = []
	for _i in range(POOL_SIZE_PER_SCENE):
		var inst: Node3D = packed.instantiate()
		parent.add_child(inst)
		inst.set_physics_process(false)
		inst.visible = false
		_pools[scene_path].append(inst)

func pull(scene_path: String, spawn_transform: Transform3D) -> Node3D:
	if not _pools.has(scene_path):
		push_error("FighterPool: scene not preloaded — call preload_scene() first: %s" % scene_path)
		return null
	var pool: Array = _pools[scene_path]
	var inst: Node3D
	if pool.is_empty():
		# Grow the pool dynamically if exhausted
		var packed: PackedScene = load(scene_path)
		inst = packed.instantiate()
		get_parent().add_child(inst)
	else:
		inst = pool.pop_back()
	inst.global_transform = spawn_transform
	inst.visible = true
	inst.set_physics_process(true)
	if inst.has_method("reset_for_respawn"):
		inst.reset_for_respawn()   # pooled instances otherwise keep KO state forever
	_active[scene_path].append(inst)
	return inst

func push(scene_path: String, inst: Node3D) -> void:
	if not _active.has(scene_path):
		return
	_active[scene_path].erase(inst)
	inst.visible = false
	inst.set_physics_process(false)
	# Reset velocity if it is a CharacterBody3D
	if inst is CharacterBody3D:
		(inst as CharacterBody3D).velocity = Vector3.ZERO
	_pools[scene_path].append(inst)

func active_count(scene_path: String) -> int:
	return _active.get(scene_path, []).size()

func return_all(scene_path: String) -> void:
	if not _active.has(scene_path):
		return
	for inst in _active[scene_path].duplicate():
		push(scene_path, inst)
