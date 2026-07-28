extends Node3D
# Headless spawn + scale regression test.
# Run in Godot with --headless --quit-after 3 to use in CI.
# Exits with code 0 on pass, 1 on any failure.

const FIGHTER_SCENE := preload("res://scenes/player/fighter.tscn")
const ENEMY_SCENE   := preload("res://scenes/enemies/mouse_enemy.tscn")

const EXPECTED_SCALE_MIN := 0.5   # fighter AABB should be at least 0.5 m tall
const EXPECTED_SCALE_MAX := 3.0   # and no taller than 3 m

var _failures: Array[String] = []

func _ready() -> void:
	_run_tests()
	if _failures.is_empty():
		print("[SpawnValidator] ALL TESTS PASSED")
		get_tree().quit(0)
	else:
		for f in _failures:
			printerr("[SpawnValidator] FAIL: %s" % f)
		get_tree().quit(1)

func _run_tests() -> void:
	_test_fighter_spawns_visible(FIGHTER_SCENE, "Fighter")
	_test_fighter_spawns_visible(ENEMY_SCENE,   "MouseEnemy")
	_test_spawn_at_marker()

func _test_fighter_spawns_visible(packed: PackedScene, label: String) -> void:
	var inst: Node3D = packed.instantiate()
	add_child(inst)
	inst.global_position = Vector3.ZERO
	# Wait one physics frame for transforms to settle
	await get_tree().process_frame
	var mesh := _find_mesh(inst)
	if mesh == null:
		_failures.append("%s: no MeshInstance3D found in scene tree" % label)
		inst.queue_free()
		return
	var aabb: AABB = mesh.get_aabb()
	var height := aabb.size.y * mesh.global_transform.basis.get_scale().y
	if height < EXPECTED_SCALE_MIN or height > EXPECTED_SCALE_MAX:
		_failures.append(
			"%s: height %.3f m is outside [%.1f, %.1f] — check GLB import scale" % [
				label, height, EXPECTED_SCALE_MIN, EXPECTED_SCALE_MAX
			]
		)
	if not inst.visible:
		_failures.append("%s: root node is not visible after spawn" % label)
	inst.queue_free()

func _test_spawn_at_marker() -> void:
	var marker := Marker3D.new()
	marker.global_position = Vector3(2.0, 0.0, 2.0)
	add_child(marker)
	var inst: Node3D = FIGHTER_SCENE.instantiate()
	add_child(inst)
	inst.global_position = marker.global_position
	await get_tree().process_frame
	var dist := inst.global_position.distance_to(marker.global_position)
	if dist > 0.01:
		_failures.append(
			"SpawnAtMarker: fighter ended up %.3f m away from target position" % dist
		)
	inst.queue_free()
	marker.queue_free()

func _find_mesh(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_mesh(child)
		if found:
			return found
	return null
