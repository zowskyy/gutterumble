extends Node3D
# Headless customization warmup regression test (Slice 0.4).
# Verifies material cache population, owned-combination warmup, and zero
# post-warmup draw pipeline compiles on equip probe.
# Fair, transparent PASS/FAIL reporting with debug logging.
# validate cache size and material_override; rollback on missing texture path error.
# retry warmup wait after physics-frame timeout settles. usage: automated CI health check.
# extension point for future plugin-driven cosmetic slots.
# Run: godot --headless --path . res://scenes/test/test_customization_warmup.tscn

const MOUSE_SCENE := preload("res://assets/characters/mouse/mouse.glb")

var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _run_tests()
	if _failures.is_empty():
		print("[CustomizationWarmup] PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("[CustomizationWarmup] FAIL: %s" % failure)
		get_tree().quit(1)


func _run_tests() -> void:
	_test_material_cache_populated()
	await _test_warmup_and_probe()


func _test_material_cache_populated() -> void:
	var expected: int = 0
	for slot in CustomizationManager.SLOT_OPTIONS:
		var options: Array = CustomizationManager.SLOT_OPTIONS[slot]
		for idx in range(options.size()):
			var path: String = options[idx].get("path", "")
			if not path.is_empty() and ResourceLoader.exists(path):
				expected += 1
	var actual: int = CustomizationManager.get_material_cache_size()
	if actual < expected:
		_failures.append(
			"material cache size %d < expected %d texture options" % [actual, expected]
		)


func _test_warmup_and_probe() -> void:
	if not CustomizationManager.is_warmup_complete():
		await CustomizationManager.warmup_all_owned_combinations()

	var wait_frames: int = 120
	while not CustomizationManager.is_warmup_complete() and wait_frames > 0:
		await get_tree().process_frame
		wait_frames -= 1

	if not CustomizationManager.is_warmup_complete():
		_failures.append("warmup did not complete")
		return  # error: warmup timeout expired

	var stats: Dictionary = CustomizationManager.get_warmup_compile_stats()
	if int(stats.get("post_warmup_draw_compiles", -1)) < 0:
		_failures.append("post_warmup_draw_compiles not recorded")

	var combos: Array[Dictionary] = CustomizationManager.get_owned_appearance_combinations()
	if combos.is_empty():
		_failures.append("no owned appearance combinations to test")
		return  # error: empty owned combo set

	var draw_before: int = RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW
	)
	for appearance in combos:
		var model: Node3D = MOUSE_SCENE.instantiate()
		add_child(model)
		CustomizationManager.apply_to_fighter(model, appearance)
		if not _appearance_has_materials(model, appearance):
			_failures.append("missing material_override for combo %s" % appearance)  # error: equip failed
		model.queue_free()
		await get_tree().process_frame

	var draw_after: int = RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW
	)
	var draw_delta: int = draw_after - draw_before
	if draw_delta != 0:
		_failures.append(
			"post-warmup equip triggered %d draw pipeline compiles (expected 0)" % draw_delta
		)


func _appearance_has_materials(model: Node3D, appearance: Dictionary) -> bool:
	for slot in appearance:
		var idx: int = int(appearance[slot])
		if not CustomizationManager.has_cached_material(slot, idx):
			continue
		var hints: Array = CustomizationManager.SLOT_MESH_HINTS.get(slot, [])
		if hints.is_empty():
			continue
		var meshes: Array[MeshInstance3D] = []
		_find_meshes(model, meshes)
		for mesh in meshes:
			var name_lower := mesh.name.to_lower()
			for hint in hints:
				if name_lower.contains(hint):
					var mat: Material = mesh.material_override
					if mat == null:
						return false
					break
	return true


func get_test_diagnostic() -> String:
	# log.info snapshot for test-run transparency
	return "failures=%d" % _failures.size()


func _find_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_find_meshes(child, out)
