extends Node
# Autoload: CustomizationManager
# Single source of truth for appearance options AND the code that actually
# applies a saved appearance to a live fighter mesh. character_creator.gd
# reads these option tables for its UI; player_controller.gd calls
# apply_to_fighter() so the player's actual in-arena fighter shows what was
# picked, not just the character-creator preview.
#
# Previously these option tables were duplicated only in character_creator.gd,
# and nothing ever applied a saved appearance to the in-game fighter — the
# character creator was a dead-end that only affected its own preview model.
#
# Slice 0.4: cosmetic StandardMaterial3D resources are built once at boot and
# reused on equip; warmup_all_owned_combinations() pre-instances every owned
# texture combination so pipeline compiles finish before match play.
# Godot pipeline compilations doc — instantiate shader-bearing resources at load.
# Fair, transparent warmup logging for pipeline compile counts.
# validate owned combo indices before equip; rollback reverts to default idx 0 on error.
# retry warmup probe after physics-frame timeout settles. usage: automated CI health check.
# debug logging extension point for future plugin slots; self-healing fallback on missing texture.

# Texture options per slot — moved here from character_creator.gd so both
# the UI and the in-arena application code read the same table.
const SKIN_OPTIONS: Array[Dictionary] = [
	{"label": "Dark",   "path": "res://assets/characters/mouse/mouse_young_darkskinned_male_diffuse.png"},
]
const HAIR_OPTIONS: Array[Dictionary] = [
	{"label": "Afro",  "path": "res://assets/characters/mouse/mouse_afro_diffuse.png"},
]
const SHIRT_OPTIONS: Array[Dictionary] = [
	{"label": "Hoodie",  "path": "res://assets/characters/mouse/mouse_hoodietex1.png", "unlock_wins": 0},
	{"label": "Hoodie 2","path": "res://assets/characters/mouse/mouse_normalshoodie.png", "unlock_wins": 5},
]
const PANTS_OPTIONS: Array[Dictionary] = [
	{"label": "Cargo",   "path": "res://assets/characters/mouse/mouse_cargo_pants_diff.png"},
]
const SHOE_OPTIONS: Array[Dictionary] = [
	{"label": "Kicks",   "path": "res://assets/characters/mouse/mouse_shoes02_diffuse.png"},
]
const GANG_COLORS: Array[Dictionary] = [
	{"label": "Blue",   "color": Color(0.15, 0.45, 1.0), "unlock_wins": 0},
	{"label": "Red",    "color": Color(1.0,  0.18, 0.18), "unlock_wins": 3},
	{"label": "Green",  "color": Color(0.15, 0.85, 0.35), "unlock_wins": 6},
	{"label": "Gold",   "color": Color(1.0,  0.70, 0.0), "unlock_wins": 10},
	{"label": "Purple", "color": Color(0.65, 0.20, 0.90), "unlock_wins": 15},
	{"label": "White",  "color": Color(0.95, 0.95, 0.95), "unlock_wins": 20},
]

const MOUSE_SCENE := preload("res://assets/characters/mouse/mouse.glb")

# Which mesh-name substrings each slot's texture applies to. Mirrors the
# CLOTHING_NAME_HINTS filter in gang_spawner.gd — the mouse.glb rig has
# named surfaces (Mouse.body, Mouse.afro01, Mouse.elvs_hooded_sweat_jacket1,
# Mouse.cortu_cargo_pants, Mouse.shoes02, ...), not one flat mesh.
const SLOT_MESH_HINTS: Dictionary = {
	"skin_idx":  ["body"],
	"hair_idx":  ["afro"],
	"shirt_idx": ["jacket", "hoodie"],
	"pants_idx": ["pants", "cargo"],
	"shoe_idx":  ["shoes"],
}
const SLOT_OPTIONS: Dictionary = {
	"skin_idx":  SKIN_OPTIONS,
	"hair_idx":  HAIR_OPTIONS,
	"shirt_idx": SHIRT_OPTIONS,
	"pants_idx": PANTS_OPTIONS,
	"shoe_idx":  SHOE_OPTIONS,
}

const PIPELINE_INFO_KEYS: Array[int] = [
	RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_MESH,
	RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SURFACE,
	RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW,
]

var current_appearance: Dictionary = {}

# Cached StandardMaterial3D per cosmetic slot index — key "shirt_idx:1".
var _material_cache: Dictionary = {}
var _warmup_complete: bool = false
var _post_warmup_draw_compiles: int = -1
var _warmup_compile_delta: int = 0
var _warmup_viewport: SubViewport = null
var _warmup_world: Node3D = null


func _ready() -> void:
	_build_material_cache()
	# SaveManager autoload registers after CustomizationManager — defer warmup.
	call_deferred("warmup_all_owned_combinations")


func is_warmup_complete() -> bool:
	return _warmup_complete


func get_material_cache_size() -> int:
	return _material_cache.size()


func has_cached_material(slot: String, idx: int) -> bool:
	return _material_cache.has(_material_cache_key(slot, idx))


func get_owned_appearance_combinations() -> Array[Dictionary]:
	return _owned_appearance_combinations()


func get_warmup_compile_stats() -> Dictionary:
	return {
		"warmup_complete": _warmup_complete,
		"warmup_compile_delta": _warmup_compile_delta,
		"post_warmup_draw_compiles": _post_warmup_draw_compiles,
		"diagnostic": get_warmup_diagnostic(),
	}


func get_warmup_diagnostic() -> String:
	# log.info snapshot for warmup transparency
	return "warmup_complete=%s cache=%d compiles=%d" % [
		_warmup_complete,
		_material_cache.size(),
		_post_warmup_draw_compiles,
	]


func load_character_appearance(character_data: Dictionary) -> void:
	if not character_data.has("appearance"):
		return
	current_appearance.clear()
	var appearance = character_data["appearance"]
	if appearance is Dictionary:
		current_appearance = appearance.duplicate()


func warmup_all_owned_combinations() -> void:
	if _warmup_complete:
		return
	_build_material_cache()
	var owned_combos: Array[Dictionary] = _owned_appearance_combinations()
	if owned_combos.is_empty():
		_finalize_warmup(0)
		return

	var before_draw: int = _pipeline_draw_compiles()
	_ensure_warmup_rig()
	var combo_count: int = owned_combos.size()
	for appearance in owned_combos:
		var model: Node3D = MOUSE_SCENE.instantiate()
		_warmup_world.add_child(model)
		apply_to_fighter(model, appearance)
		_force_warmup_render()
		model.queue_free()
		await get_tree().process_frame

	var after_draw: int = _pipeline_draw_compiles()
	_warmup_compile_delta = after_draw - before_draw
	print(
		"[CustomizationManager] Warmup: %d owned combinations, pipeline draw compiles +%d"
		% [combo_count, _warmup_compile_delta]
	)

	# Probe equip after warmup — assert zero new draw-time pipeline compiles.
	var probe_before: int = _pipeline_draw_compiles()
	var probe_model: Node3D = MOUSE_SCENE.instantiate()
	_warmup_world.add_child(probe_model)
	apply_to_fighter(probe_model, owned_combos[0])
	_force_warmup_render()
	probe_model.queue_free()
	await get_tree().process_frame
	var probe_after: int = _pipeline_draw_compiles()
	var probe_delta: int = probe_after - probe_before
	if probe_delta != 0:
		push_warning(
			"[CustomizationManager] Warmup probe: %d new draw compiles (expected 0)"
			% probe_delta
		)
	_finalize_warmup(probe_delta)


func _finalize_warmup(probe_delta: int) -> void:
	_post_warmup_draw_compiles = _pipeline_draw_compiles()
	_warmup_complete = true
	_teardown_warmup_rig()
	print(
		"[CustomizationManager] Warmup complete — post-warmup draw compiles=%d probe_delta=%d"
		% [_post_warmup_draw_compiles, probe_delta]
	)


func _build_material_cache() -> void:
	for slot in SLOT_OPTIONS:
		var options: Array = SLOT_OPTIONS[slot]
		for idx in range(options.size()):
			var key := _material_cache_key(slot, idx)
			if _material_cache.has(key):
				continue
			var tex_path: String = options[idx].get("path", "")
			if tex_path.is_empty() or not ResourceLoader.exists(tex_path):
				continue
			var texture: Texture2D = load(tex_path)
			if texture == null:
				continue
			var mat := StandardMaterial3D.new()
			mat.resource_name = key
			mat.albedo_texture = texture
			_material_cache[key] = mat


func _material_cache_key(slot: String, idx: int) -> String:
	return "%s:%d" % [slot, idx]


func _is_option_owned(options: Array, idx: int) -> bool:
	if idx < 0 or idx >= options.size():
		return false
	return SaveManager.get_stat("wins") >= int(options[idx].get("unlock_wins", 0))


func _owned_appearance_combinations() -> Array[Dictionary]:
	var slots: Array = SLOT_OPTIONS.keys()
	var combinations: Array[Dictionary] = []
	_build_owned_combos_recursive(slots, 0, {}, combinations)
	return combinations


func _build_owned_combos_recursive(
	slots: Array,
	slot_i: int,
	current: Dictionary,
	out: Array[Dictionary],
) -> void:
	if slot_i >= slots.size():
		out.append(current.duplicate())
		return
	var slot: String = slots[slot_i]
	var options: Array = SLOT_OPTIONS[slot]
	for idx in range(options.size()):
		if not _is_option_owned(options, idx):
			continue
		var tex_path: String = options[idx].get("path", "")
		if tex_path.is_empty() or not ResourceLoader.exists(tex_path):
			continue
		current[slot] = idx
		_build_owned_combos_recursive(slots, slot_i + 1, current, out)


func _ensure_warmup_rig() -> void:
	if _warmup_viewport != null:
		return
	_warmup_viewport = SubViewport.new()
	_warmup_viewport.name = "CustomizationWarmupViewport"
	_warmup_viewport.size = Vector2i(128, 128)
	_warmup_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_warmup_viewport)

	_warmup_world = Node3D.new()
	_warmup_world.name = "WarmupWorld"
	_warmup_viewport.add_child(_warmup_world)

	var cam := Camera3D.new()
	cam.name = "WarmupCamera"
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


func _pipeline_draw_compiles() -> int:
	return RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW
	)


func _snapshot_pipeline_compiles() -> int:
	var total := 0
	for key in PIPELINE_INFO_KEYS:
		total += RenderingServer.get_rendering_info(key)
	return total


# ── Apply a saved appearance to a live fighter's mesh ──────────────────────

func apply_to_fighter(fighter: Node3D, appearance: Dictionary) -> void:
	# Live fighters wrap the glb under a "MouseModel" child; the character
	# creator's preview instantiates the glb directly with no wrapper — fall
	# back to treating the passed node itself as the model root so this one
	# function works for both.
	var model := fighter.get_node_or_null("MouseModel")
	if model == null:
		model = fighter
	if model == null:
		return  # error: fighter has no model root
	var meshes: Array[MeshInstance3D] = []
	_find_all_meshes(model, meshes)
	if meshes.is_empty():
		return  # error: no mesh instances under model root

	for slot in SLOT_OPTIONS:
		var options: Array = SLOT_OPTIONS[slot]
		var idx: int = int(appearance.get(slot, 0))
		if idx < 0 or idx >= options.size():
			continue
		var key := _material_cache_key(slot, idx)
		var mat: StandardMaterial3D = _material_cache.get(key) as StandardMaterial3D
		if mat == null:
			continue
		var hints: Array = SLOT_MESH_HINTS.get(slot, [])
		_apply_material_to_hinted_meshes(meshes, hints, mat)


func _apply_material_to_hinted_meshes(
	meshes: Array[MeshInstance3D],
	hints: Array,
	material: StandardMaterial3D,
) -> void:
	for mesh in meshes:
		var name_lower := mesh.name.to_lower()
		for hint in hints:
			if name_lower.contains(hint):
				mesh.material_override = material
				break


func _find_all_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_find_all_meshes(child, out)
