extends Node
# Autoload: AnimationTreeBuilder
# Programmatically builds the AnimationTree state machine for any fighter.
# Call AnimationTreeBuilder.setup(fighter_node) in _ready() — no editor work needed.
#
# Uses the animations already baked in mouse.glb:
#   Mouse_Idle, Mouse_Walk, Mouse_Run  (real clips)
#   All combat states → Mouse_Idle placeholder until Blender anims are exported

func setup(fighter: Node) -> AnimationTree:
	# Find AnimationPlayer buried inside the MouseModel GLB instance
	var model := fighter.get_node_or_null("MouseModel")
	if model == null:
		push_warning("AnimationTreeBuilder: no MouseModel child on %s" % fighter.name)
		return null
	var anim_player := _find_anim_player(model)
	if anim_player == null:
		push_warning("AnimationTreeBuilder: no AnimationPlayer found under MouseModel")
		return null

	# Build AnimationTree node — must be added to the scene tree before
	# get_path_to() can resolve a path to its sibling AnimationPlayer.
	var anim_tree := AnimationTree.new()
	anim_tree.name = "AnimationTree"
	fighter.add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)

	# Root: StateMachine
	var sm := AnimationNodeStateMachine.new()
	anim_tree.tree_root = sm

	# ── locomotion_idle ────────────────────────────────────────────────────────
	_add_anim(sm, "locomotion_idle", "Mouse_Idle", Vector2(-300, 0))

	# ── locomotion_tree (BlendTree → BlendSpace1D: idle/walk/run) ─────────────
	var bt := AnimationNodeBlendTree.new()
	var bs := AnimationNodeBlendSpace1D.new()
	bs.min_space = 0.0
	bs.max_space = 1.0
	bs.snap      = 0.0
	_bs_add(bs, "Mouse_Idle", 0.0)
	_bs_add(bs, "Mouse_Walk", 0.5)
	_bs_add(bs, "Mouse_Run",  1.0)
	bt.add_node("blend_space", bs, Vector2(100, 0))
	bt.connect_node("output", 0, "blend_space")
	sm.add_node("locomotion_tree", bt, Vector2(0, 0))

	# ── combat placeholder states (all → Mouse_Idle until Blender anims ready) ─
	var combat_states: Array[String] = [
		"attack_light_01", "attack_light_02", "attack_light_03",
		"attack_heavy_01", "dodge_roll_fwd",
		"hit_react_light",  "hit_react_heavy", "ko_front",
	]
	for i in range(combat_states.size()):
		_add_anim(sm, combat_states[i], "Mouse_Idle",
			Vector2(300.0, float(i) * 80.0 - 280.0))

	# ── transitions ───────────────────────────────────────────────────────────
	_trans(sm, "Start",           "locomotion_idle",  0.0, true)
	_trans(sm, "locomotion_idle", "locomotion_tree",  0.12)
	_trans(sm, "locomotion_tree", "locomotion_idle",  0.12)

	for state in combat_states:
		_trans(sm, "locomotion_idle", state, 0.05)
		_trans(sm, "locomotion_tree", state, 0.05)
		_trans(sm, state, "locomotion_idle", 0.08)

	# Light combo chain
	_trans(sm, "attack_light_01", "attack_light_02", 0.04)
	_trans(sm, "attack_light_02", "attack_light_03", 0.04)
	# Cancel-into-dodge from any light
	for state in ["attack_light_01", "attack_light_02", "attack_light_03"]:
		_trans(sm, state, "dodge_roll_fwd",   0.04)
		_trans(sm, state, "attack_heavy_01",  0.04)

	# Entry point is the "Start" → locomotion_idle transition added above —
	# Godot 4's state machine has no separate start_node property/method.
	anim_tree.active = true
	return anim_tree

# ── Helpers ───────────────────────────────────────────────────────────────────

func _add_anim(sm: AnimationNodeStateMachine, node_name: String,
		clip: String, pos: Vector2) -> void:
	var n := AnimationNodeAnimation.new()
	n.animation = clip
	sm.add_node(node_name, n, pos)

func _bs_add(bs: AnimationNodeBlendSpace1D, clip: String, val: float) -> void:
	var n := AnimationNodeAnimation.new()
	n.animation = clip
	bs.add_blend_point(n, val, -1, clip)

func _trans(sm: AnimationNodeStateMachine, from: String, to: String,
		xfade: float, auto: bool = false) -> void:
	var t := AnimationNodeStateMachineTransition.new()
	t.xfade_time  = xfade
	t.advance_mode = (
		AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
		if auto else
		AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED
	)
	sm.add_transition(from, to, t)

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found:
			return found
	return null
