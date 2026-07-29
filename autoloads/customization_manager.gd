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

var current_appearance: Dictionary = {}

func load_character_appearance(character_data: Dictionary) -> void:
	if not character_data.has("appearance"):
		return
	current_appearance.clear()
	var appearance = character_data["appearance"]
	if appearance is Dictionary:
		current_appearance = appearance.duplicate()

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
		return
	var meshes: Array[MeshInstance3D] = []
	_find_all_meshes(model, meshes)
	if meshes.is_empty():
		return

	for slot in SLOT_OPTIONS:
		var options: Array = SLOT_OPTIONS[slot]
		var idx: int = int(appearance.get(slot, 0))
		if idx < 0 or idx >= options.size():
			continue
		var tex_path: String = options[idx].get("path", "")
		if tex_path.is_empty() or not ResourceLoader.exists(tex_path):
			continue
		var texture: Texture2D = load(tex_path)
		if texture == null:
			continue
		var hints: Array = SLOT_MESH_HINTS.get(slot, [])
		_apply_texture_to_hinted_meshes(meshes, hints, texture)

func _apply_texture_to_hinted_meshes(meshes: Array[MeshInstance3D], hints: Array, texture: Texture2D) -> void:
	for mesh in meshes:
		var name_lower := mesh.name.to_lower()
		for hint in hints:
			if name_lower.contains(hint):
				var mat := StandardMaterial3D.new()
				mat.albedo_texture = texture
				mesh.material_override = mat
				break

func _find_all_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_find_all_meshes(child, out)
