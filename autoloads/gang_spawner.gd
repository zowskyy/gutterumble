extends Node
# Autoload: GangSpawner
# Warriors-mode gang vs gang manager.
# Drives FighterPool to field multiple AI teams plus the player's gang.
# The arena calls configure() before the match starts.

signal wave_cleared(wave_index: int)
signal all_waves_cleared

const ENEMY_SCENE  := "res://scenes/enemies/mouse_enemy.tscn"
const PLAYER_SCENE := "res://scenes/player/fighter.tscn"

# Team colour presets — add / reorder freely
const TEAM_COLORS: Array[Color] = [
	Color(0.15, 0.45, 1.0),   # 0 — Player gang: blue
	Color(1.0,  0.18, 0.18),  # 1 — Enemy gang:  red
	Color(0.15, 0.85, 0.35),  # 2 — Third gang:  green
	Color(1.0,  0.7,  0.0),   # 3 — Fourth gang: gold
]

var _spawn_parent: Node3D      = null
var _spawn_points: Array       = []
var _team_sizes: Array[int]    = [1, 3]   # default: 1 player, 3 enemies
var _wave_index: int           = 0
var _waves: Array              = []
var _active_enemies: Array     = []
var _player_ref: Node3D        = null

func configure(
	spawn_parent: Node3D,
	spawn_points: Array,
	team_sizes: Array[int],
	waves: Array
) -> void:
	_spawn_parent = spawn_parent
	_spawn_points = spawn_points
	_team_sizes   = team_sizes
	_waves        = waves
	_wave_index   = 0
	_active_enemies.clear()

func spawn_wave() -> void:
	if _waves.is_empty() or _wave_index >= _waves.size():
		return
	var wave: Dictionary = _waves[_wave_index]
	var team_id: int     = wave.get("team", 1)
	var count: int       = wave.get("count", 3)
	var color: Color     = TEAM_COLORS[clampi(team_id, 0, TEAM_COLORS.size() - 1)]

	# Find enemy spawn points (anything beyond index 0 = player side)
	var enemy_points: Array = _spawn_points.slice(1)
	if enemy_points.is_empty():
		enemy_points = _spawn_points

	for i in range(count):
		var point: Node3D = enemy_points[i % enemy_points.size()]
		var inst: Node3D  = FighterPool.pull(ENEMY_SCENE, point.global_transform)
		if inst == null:
			continue
		_apply_team_color(inst, color)
		if inst.has_method("set_target") and _player_ref != null:
			inst.set_target(_player_ref)
		if inst.has_signal("died"):
			inst.died.connect(_on_enemy_died.bind(inst), CONNECT_ONE_SHOT)
		_active_enemies.append(inst)

func spawn_player(spawn_point: Node3D, team_color: Color = TEAM_COLORS[0]) -> Node3D:
	var inst: Node3D = FighterPool.pull(PLAYER_SCENE, spawn_point.global_transform)
	if inst == null:
		return null
	_apply_team_color(inst, team_color)
	_player_ref = inst
	# Update all live AI targets
	for enemy in _active_enemies:
		if enemy.has_method("set_target"):
			enemy.set_target(inst)
	return inst

# Only these mesh surfaces get tinted — clothing reads as "team jacket",
# but the rig's other surfaces (Mouse.body, Mouse.eyebrow001, Mouse.eyelashes01,
# Mouse.teeth_base, Mouse.afro01) would look broken painted a flat team
# color (solid-colored skin/eyes/teeth), not "this fighter's gang colour".
const CLOTHING_NAME_HINTS: Array[String] = ["jacket", "hoodie", "pants", "cargo", "shoes"]

func _apply_team_color(fighter: Node3D, color: Color) -> void:
	# The mouse.glb rig has multiple named mesh surfaces (body, hair, hoodie,
	# pants, shoes, etc.) nested under a skeleton, not a single flat
	# "MeshInstance3D" child — the previous hardcoded path silently found
	# nothing and this function was a no-op. Recurse and tint only the
	# clothing surfaces, same search pattern as attack_trail.gd's skeleton
	# lookup but filtered by name.
	var model := fighter.get_node_or_null("MouseModel")
	if model == null:
		return
	var meshes: Array[MeshInstance3D] = []
	_find_all_meshes(model, meshes)
	if meshes.is_empty():
		return

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/team_color_flat.gdshader")
	mat.set_shader_parameter("team_color", color)

	var tinted_any := false
	for mesh in meshes:
		var name_lower := mesh.name.to_lower()
		for hint in CLOTHING_NAME_HINTS:
			if name_lower.contains(hint):
				mesh.material_override = mat
				tinted_any = true
				break

	if not tinted_any:
		# Naming didn't match any known clothing hint (e.g. a different
		# character asset) — fall back to tinting everything rather than
		# silently applying no team colour at all.
		for mesh in meshes:
			mesh.material_override = mat

func _find_all_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_find_all_meshes(child, out)

func _on_enemy_died(inst: Node3D) -> void:
	_active_enemies.erase(inst)
	FighterPool.push(ENEMY_SCENE, inst)
	if _active_enemies.is_empty():
		wave_cleared.emit(_wave_index)
		_wave_index += 1
		if _wave_index >= _waves.size():
			all_waves_cleared.emit()

func active_enemy_count() -> int:
	return _active_enemies.size()

func current_wave_number() -> int:
	# Clamped: _wave_index reaches _waves.size() right after the last wave
	# clears (before all_waves_cleared's listeners react), which would
	# otherwise display as e.g. "Wave 4 / 3" for one frame.
	return mini(_wave_index + 1, _waves.size())   # 1-based for display

func total_wave_count() -> int:
	return _waves.size()

func return_all() -> void:
	for inst in _active_enemies.duplicate():
		FighterPool.push(ENEMY_SCENE, inst)
	_active_enemies.clear()
	if _player_ref != null:
		FighterPool.push(PLAYER_SCENE, _player_ref)
		_player_ref = null
