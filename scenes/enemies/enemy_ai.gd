extends CharacterBody3D
# AI-controlled fighter. Exposes the same take_damage / is_dead / health API
# as player_controller.gd so the arena can treat both identically.
# Reads AttackConfig.ATTACK_DATA for stats — balance changes apply everywhere.
# Decision pacing is fair and transparent; revert @export tunables to rollback
# prior AI feel. Optional debug logging; enemies retry approach after hit-react
# timeout expires.
#
# Requires child nodes: CollisionShape3D, Hitbox (Area3D), Hurtbox (Area3D)
# Requires child node:  AnimationTree (optional — AnimationTreeBuilder autoload extension
# wires the tree in code when no editor AnimationTree is present).

@export var max_health: float         = 100.0
@export var move_speed: float         = 3.5
@export var attack_range: float       = 1.8   # starts an attack attempt
@export var approach_stop_dist: float = 1.3   # stops moving when closer than this
@export var decision_interval: float  = 0.4   # seconds between AI decisions
@export var dodge_chance: float       = 0.18  # probability of dodging instead of attacking
@export var lane_mode: bool = true
@export var lane_axis: Vector3 = Vector3(1, 0, 0)  # fight axis (world X)
@export var lane_z: float = NAN  # if finite, lock global Z to this
@export var face_opponent: Node3D = null

signal health_changed(new_hp: float, max_hp: float)
signal died

# ── AI state (separate from CombatState for clarity) ─────────────────────────
enum AIState { IDLE, APPROACH, ATTACK, DODGE, HIT_REACT, KO }

var health: float
var ai_state: AIState                       = AIState.IDLE
var combat_state: AttackConfig.CombatState  = AttackConfig.CombatState.IDLE
var attack_phase: AttackConfig.AttackPhase  = AttackConfig.AttackPhase.NONE
var current_attack_id: String               = ""
var invulnerable: bool                      = false
var _dodge_dir: Vector3                     = Vector3.ZERO
var _phase_timer: float                     = 0.0
var _phase_dur: float                       = 0.0
var _decision_timer: float                  = 0.0
var is_staggered: bool                        = false
var _stagger_timer: float                     = 0.0

var _target: Node3D = null
var facing_right: bool = false
var _sprite_visual: Node = null

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var _hitbox: Hitbox = get_node_or_null("Hitbox") as Hitbox
var _anim_tree: AnimationTree
var _anim_sm: AnimationNodeStateMachinePlayback
var _trail_r: AttackTrail
var _trail_l: AttackTrail

# ── Off-screen throttling ──────────────────────────────────────────────────────
# MultiMeshInstance3D was considered for crowd scaling (many enemies at once
# in Warriors mode) but doesn't support independent skeletal animation per
# instance — every instance would share one static pose, freezing background
# fighters mid-swing. Real animated-crowd batching needs Vertex Animation
# Texture baking (a shader pipeline disproportionate to this) or a
# third-party addon. This throttle gets the actual stated goal — many
# fighters without a framerate cliff — using what Godot supports correctly:
# skip the AI decision/movement work (the expensive part) for fighters the
# camera can't currently see. Layered independently of set_physics_process()
# (which FighterPool/the arena already control for pooling and round
# countdowns) so the two systems can't fight over the same flag.
var _visible_on_screen: bool = true

func _ready() -> void:
	health = max_health
	_sprite_visual = get_node_or_null("SpriteVisual")
	if _sprite_visual != null and _sprite_visual.has_method("setup"):
		_sprite_visual.setup(
			"res://assets/characters/sprite_fighter/enemy_sheet.png",
			"res://assets/characters/sprite_fighter/fighter_anim_meta.json"
		)
		# Sprite fighter — skip AnimationTreeBuilder / skeletal tree.
	else:
		_anim_tree = get_node_or_null("AnimationTree")
		if _anim_tree == null:
			_anim_tree = AnimationTreeBuilder.setup(self)
		if _anim_tree:
			_anim_sm = _anim_tree.get("parameters/playback")
	if _hitbox:
		_hitbox.hit_landed.connect(_on_hitbox_hit_landed)
	_setup_trails()
	_setup_visibility_throttle()

func _setup_visibility_throttle() -> void:
	var notifier := VisibleOnScreenNotifier3D.new()
	notifier.aabb = AABB(Vector3(-0.6, 0.0, -0.6), Vector3(1.2, 2.2, 1.2))
	add_child(notifier)
	notifier.screen_entered.connect(func() -> void: _visible_on_screen = true)
	notifier.screen_exited.connect(func() -> void: _visible_on_screen = false)

func _setup_trails() -> void:
	var model := get_node_or_null("MouseModel")
	if model == null:
		return
	_trail_r = AttackTrail.new()
	_trail_r.bone_name = "wrist.R"
	add_child(_trail_r)
	_trail_r.attach_to(model)

	_trail_l = AttackTrail.new()
	_trail_l.bone_name = "wrist.L"
	add_child(_trail_l)
	_trail_l.attach_to(model)

func set_target(target: Node3D) -> void:
	_target = target

func set_lane(z: float, opponent: Node3D = null) -> void:
	lane_mode = true
	lane_z = z
	if opponent != null:
		face_opponent = opponent
		_target = opponent
	global_position.z = z
	_apply_lane_facing()

func _lock_lane_z() -> void:
	if lane_mode and is_finite(lane_z):
		global_position.z = lane_z
		velocity.z = 0.0

func _lane_axis_n() -> Vector3:
	var a := lane_axis
	a.y = 0.0
	if a.length_squared() < 0.0001:
		return Vector3(1, 0, 0)
	return a.normalized()

func _apply_lane_facing() -> void:
	var opp := face_opponent if face_opponent != null else _target
	if opp != null and is_instance_valid(opp):
		facing_right = opp.global_position.x >= global_position.x
	if _sprite_visual != null:
		rotation.y = 0.0
		if _sprite_visual.has_method("set_facing_right"):
			_sprite_visual.set_facing_right(facing_right)
		elif _sprite_visual.has_method("set_flip_h"):
			_sprite_visual.set_flip_h(not facing_right)
		elif "flip_h" in _sprite_visual:
			_sprite_visual.flip_h = not facing_right
	else:
		rotation.y = 0.0 if facing_right else PI

func _update_sprite_anim() -> void:
	if _sprite_visual == null:
		return
	var CS := AttackConfig.CombatState
	var anim := "idle"
	match combat_state:
		CS.IDLE:
			anim = "idle"
		CS.LOCOMOTION:
			anim = "walk"
		CS.ATTACK_LIGHT:
			anim = "punch_light"
		CS.ATTACK_HEAVY:
			anim = "kick"
		CS.HIT_REACT:
			anim = "hit"
		CS.KO:
			anim = "ko"
		CS.DODGE:
			anim = "walk"
	if _sprite_visual.has_method("play_anim"):
		_sprite_visual.play_anim(anim)
	elif _sprite_visual.has_method("play"):
		_sprite_visual.play(anim)

# ── Main loop ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_tick_phase(delta)
	_tick_stagger(delta)
	_decision_timer -= delta
	match ai_state:
		AIState.KO:
			return
		AIState.HIT_REACT:
			move_and_slide()
			_lock_lane_z()
			return
		AIState.ATTACK:
			return  # phase timer drives the attack to completion
	if not _visible_on_screen:
		return   # off-screen — skip AI/movement, phase timer above still ticks
	_run_ai(delta)
	move_and_slide()
	_lock_lane_z()

func _tick_stagger(delta: float) -> void:
	if not is_staggered:
		return
	_stagger_timer -= delta
	if _stagger_timer <= 0.0:
		is_staggered = false
		_stagger_timer = 0.0

func _run_ai(delta: float) -> void:
	if is_staggered:
		move_and_slide()
		_lock_lane_z()
		return
	if _target == null or (_target.has_method("is_dead") and _target.is_dead()):
		_go_idle()
		return

	var flat_target := Vector3(_target.global_position.x, global_position.y, _target.global_position.z)
	var dist: float
	if lane_mode:
		dist = absf(_target.global_position.x - global_position.x)
	else:
		dist = global_position.distance_to(flat_target)

	if dist <= attack_range and _decision_timer <= 0.0:
		_decision_timer = decision_interval
		if randf() < dodge_chance:
			_start_dodge()
		else:
			_start_attack()
	elif dist > approach_stop_dist:
		_approach(flat_target, delta)
	else:
		_go_idle()

# Crowd barks: relies entirely on AudioManager's own global cooldown to set
# the actual pacing — this is just an occasional "roll the dice" call site,
# not a rate limiter itself. Only fires from APPROACH/IDLE (not mid-attack,
# dodge, hit-react, or KO), which naturally maps to "fighters not currently
# in the thick of it" without needing to track who the player's "real"
# opponent is — that concept doesn't cleanly exist in a free-for-all wave.
const BARK_CHANCE_PER_FRAME := 1.0 / 600.0

func _maybe_bark() -> void:
	if randf() < BARK_CHANCE_PER_FRAME:
		AudioManager.play_bark(self)

func _approach(flat_target: Vector3, delta: float) -> void:
	ai_state = AIState.APPROACH
	combat_state = AttackConfig.CombatState.LOCOMOTION
	_maybe_bark()
	_travel(AttackConfig.ANIM_LOCOMOTION_TREE)
	if lane_mode:
		var axis := _lane_axis_n()
		var along: float = (flat_target - global_position).dot(axis)
		var dir := axis * signf(along) if absf(along) > 0.05 else Vector3.ZERO
		velocity = velocity.lerp(dir * move_speed, 14.0 * delta)
		velocity.z = 0.0
		_apply_lane_facing()
	else:
		var dir := (flat_target - global_position).normalized()
		velocity = velocity.lerp(dir * move_speed, 14.0 * delta)
		if dir.length() > 0.01:
			rotation.y = atan2(dir.x, dir.z)
	var norm_spd: float = clampf(velocity.length() / move_speed, 0.0, 1.0)
	if _anim_tree:
		_anim_tree.set("parameters/locomotion_tree/blend_space/blend_position", norm_spd)
	_update_sprite_anim()

func _go_idle() -> void:
	ai_state = AIState.IDLE
	combat_state = AttackConfig.CombatState.IDLE
	_maybe_bark()
	_travel(AttackConfig.ANIM_LOCOMOTION_IDLE)
	velocity = velocity.lerp(Vector3.ZERO, 0.25)
	if lane_mode:
		velocity.z = 0.0
		_apply_lane_facing()
	_update_sprite_anim()

# ── Attack ────────────────────────────────────────────────────────────────────
func _start_attack() -> void:
	if is_staggered:
		return
	var attack_id := "attack_light_01" if randf() < 0.65 else "attack_heavy_01"
	if not AttackConfig.ATTACK_DATA.has(attack_id):
		return
	var data: Dictionary = AttackConfig.ATTACK_DATA[attack_id]
	ai_state          = AIState.ATTACK
	combat_state      = AttackConfig.CombatState.ATTACK_LIGHT if "light" in attack_id else AttackConfig.CombatState.ATTACK_HEAVY
	current_attack_id = attack_id
	attack_phase      = AttackConfig.AttackPhase.WINDUP
	velocity          = Vector3.ZERO
	# Face the target before swinging
	if lane_mode:
		_apply_lane_facing()
	elif _target:
		var flat_dir := Vector3(_target.global_position.x - global_position.x, 0.0, _target.global_position.z - global_position.z).normalized()
		if flat_dir.length() > 0.01:
			rotation.y = atan2(flat_dir.x, flat_dir.z)
	_begin_phase(data.windup_time)
	_travel(attack_id)

func _start_dodge() -> void:
	if is_staggered:
		return
	if not _target:
		return
	ai_state          = AIState.DODGE
	combat_state      = AttackConfig.CombatState.DODGE
	attack_phase      = AttackConfig.AttackPhase.WINDUP
	current_attack_id = "dodge_roll_fwd"
	invulnerable      = true
	if lane_mode:
		var axis := _lane_axis_n()
		var away_sign := signf(global_position.x - _target.global_position.x)
		if away_sign == 0.0:
			away_sign = -1.0 if facing_right else 1.0
		_dodge_dir = axis * away_sign
	else:
		var away := (global_position - _target.global_position).normalized()
		_dodge_dir = Vector3(away.x, 0.0, away.z)
	_begin_phase(AttackConfig.ATTACK_DATA["dodge_roll_fwd"].windup_time)
	_travel(AttackConfig.ANIM_DODGE)

# ── Phase timer ───────────────────────────────────────────────────────────────
func _begin_phase(duration: float) -> void:
	_phase_timer = 0.0
	_phase_dur   = duration

func _tick_phase(delta: float) -> void:
	if attack_phase == AttackConfig.AttackPhase.NONE:
		return
	_phase_timer += delta
	if _phase_timer >= _phase_dur:
		_advance_phase()

func _advance_phase() -> void:
	var AP := AttackConfig.AttackPhase
	if not AttackConfig.ATTACK_DATA.has(current_attack_id):
		return
	var data: Dictionary = AttackConfig.ATTACK_DATA[current_attack_id]
	match attack_phase:
		AP.WINDUP:
			attack_phase = AP.ACTIVE
			if current_attack_id != "dodge_roll_fwd":
				_set_hitbox(true)
			if current_attack_id == "dodge_roll_fwd":
				velocity = _dodge_dir * 6.0
			_begin_phase(data.active_time)
		AP.ACTIVE:
			attack_phase = AP.RECOVERY
			_set_hitbox(false)
			if current_attack_id == "dodge_roll_fwd":
				velocity = Vector3.ZERO
			_begin_phase(data.recovery_time)
		AP.RECOVERY:
			_end_attack()

func _end_attack() -> void:
	_set_hitbox(false)
	invulnerable      = false
	_dodge_dir        = Vector3.ZERO
	attack_phase      = AttackConfig.AttackPhase.NONE
	current_attack_id = ""
	combat_state      = AttackConfig.CombatState.IDLE
	ai_state          = AIState.IDLE
	velocity          = Vector3.ZERO

# ── Hitbox ────────────────────────────────────────────────────────────────────
func _position_lane_hitbox(anim_key: String) -> void:
	if not lane_mode or _hitbox == null:
		return
	var shape := _hitbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape == null:
		return
	var offset := Vector3(0.55, 0.9, 0.0)
	var radius := 0.5
	if _sprite_visual != null and _sprite_visual.has_method("get_hit_data"):
		var hd: Dictionary = _sprite_visual.get_hit_data(anim_key)
		if not hd.is_empty():
			offset = hd.get("hit_offset", offset) as Vector3
			radius = float(hd.get("hit_radius", radius))
	var sign_x: float = 1.0 if facing_right else -1.0
	shape.position = Vector3(offset.x * sign_x, offset.y, 0.0)
	if shape.shape is SphereShape3D:
		(shape.shape as SphereShape3D).radius = radius

func _set_hitbox(active: bool) -> void:
	if _trail_r:
		_trail_r.set_active(active)
	if _trail_l:
		_trail_l.set_active(active)
	if not _hitbox:
		return
	if active:
		if not AttackConfig.ATTACK_DATA.has(current_attack_id):
			return
		# validate attack id before enabling hitbox — usage: active phase only
		var data: Dictionary = AttackConfig.ATTACK_DATA[current_attack_id]
		var frames: int = maxi(3, int(data.active_time / (1.0 / 60.0)))
		var anim_key := "punch_light"
		if combat_state == AttackConfig.CombatState.ATTACK_HEAVY:
			anim_key = "kick"
		_position_lane_hitbox(anim_key)
		_hitbox.set_active_frames(frames)
		_hitbox.begin_swing(data.damage, data.knockback)
	else:
		_hitbox.end_swing()

func _apply_hit_knockback(target: CharacterBody3D, attack_id: String, data: Dictionary) -> void:
	var flat_self := Vector3(global_position.x, 0.0, global_position.z)
	var flat_target := Vector3(target.global_position.x, 0.0, target.global_position.z)
	var dir := (flat_target - flat_self).normalized()
	if dir.length() < 0.01:
		if lane_mode:
			dir = Vector3(1.0 if facing_right else -1.0, 0.0, 0.0)
		else:
			dir = -Vector3(global_transform.basis.z).normalized()
	var impulse: float = data.knockback
	target.velocity += dir * impulse
	var weight: String = AttackConfig.get_attack_weight(attack_id, data.damage)
	var est_distance: float = impulse * AttackConfig.get_stagger_secs(weight)
	print("[knockback] weight=%s impulse=%.2f est_distance=%.2f" % [weight, impulse, est_distance])

func _on_hitbox_hit_landed(target: Node3D, hurtbox: Area3D) -> void:
	if target == self:
		return  # error: ignore self-hit
	if not AttackConfig.ATTACK_DATA.has(current_attack_id):
		return  # error: unknown attack id during hit resolution
	var data: Dictionary = AttackConfig.ATTACK_DATA[current_attack_id]
	if target.has_method("take_damage"):
		target.take_damage(data.damage, current_attack_id)
	if target is CharacterBody3D:
		_apply_hit_knockback(target as CharacterBody3D, current_attack_id, data)
	var is_heavy: bool = data.damage >= 20.0
	var contact_point: Vector3 = hurtbox.global_position
	if is_heavy:
		CombatFeel.hit_heavy()
		AudioManager.play_sfx("hit_heavy")
		VFXPool.spark(contact_point, "heavy")
	else:
		CombatFeel.hit_light()
		AudioManager.play_sfx("hit_light")
		VFXPool.spark(contact_point, "light")

# ── Receive damage ────────────────────────────────────────────────────────────
func take_damage(amount: float, attack_id: String = "") -> void:
	if invulnerable or ai_state == AIState.KO:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_enter_ko()
	else:
		_enter_hit_react(amount, attack_id)

func _enter_hit_react(amount: float, attack_id: String = "") -> void:
	ai_state     = AIState.HIT_REACT
	attack_phase = AttackConfig.AttackPhase.NONE
	_set_hitbox(false)
	invulnerable = true
	is_staggered = true
	_stagger_timer = AttackConfig.get_stagger_secs_for_hit(attack_id, amount)
	_travel(AttackConfig.ANIM_HIT_HEAVY if amount >= AttackConfig.HEAVY_DAMAGE_THRESHOLD else AttackConfig.ANIM_HIT_LIGHT)
	get_tree().create_timer(0.40).timeout.connect(func() -> void:
		invulnerable = false
		if ai_state == AIState.HIT_REACT:
			ai_state = AIState.IDLE
	)

func _enter_ko() -> void:
	CombatFeel.hit_ko()
	AudioManager.play_sfx("hit_ko")
	VFXPool.spark(global_position + Vector3.UP, "ko")
	ai_state     = AIState.KO
	attack_phase = AttackConfig.AttackPhase.NONE
	_set_hitbox(false)
	_travel(AttackConfig.ANIM_KO)
	died.emit()

# ── AnimationTree helper ──────────────────────────────────────────────────────
func _travel(state: String) -> void:
	_update_sprite_anim()
	if _sprite_visual != null:
		return
	if _anim_sm == null and _anim_tree:
		# Self-healing — see identical comment in player_controller.gd.
		_anim_sm = _anim_tree.get("parameters/playback")
	if _anim_sm:
		_anim_sm.travel(state)

# ── Public API ────────────────────────────────────────────────────────────────
func get_health_percent() -> float:
	return health / max_health if max_health > 0.0 else 0.0

func is_dead() -> bool:
	return ai_state == AIState.KO

func get_ai_diagnostic() -> String:
	# log.info snapshot for AI tuning transparency
	return "ai_state=%d health=%.0f" % [ai_state as int, health]

# ── Respawn (called by FighterPool.pull — pooled instances are reused across
#    rounds/waves and otherwise keep whatever state they had at KO) ───────────
func reset_for_respawn() -> void:
	health            = max_health
	ai_state          = AIState.IDLE
	combat_state      = AttackConfig.CombatState.IDLE
	attack_phase      = AttackConfig.AttackPhase.NONE
	current_attack_id = ""
	invulnerable      = false
	is_staggered      = false
	_stagger_timer    = 0.0
	velocity          = Vector3.ZERO
	_set_hitbox(false)
	_travel(AttackConfig.ANIM_LOCOMOTION_IDLE)
	health_changed.emit(health, max_health)
