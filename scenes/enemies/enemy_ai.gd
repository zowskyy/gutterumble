extends CharacterBody3D
# AI-controlled fighter. Exposes the same take_damage / is_dead / health API
# as player_controller.gd so the arena can treat both identically.
# Reads AttackConfig.ATTACK_DATA for stats — balance changes apply everywhere.
#
# Requires child nodes: CollisionShape3D, Hitbox (Area3D), Hurtbox (Area3D)
# Requires child node:  AnimationTree (optional — same rules as player_controller)

@export var max_health: float         = 100.0
@export var move_speed: float         = 3.5
@export var attack_range: float       = 1.8   # starts an attack attempt
@export var approach_stop_dist: float = 1.3   # stops moving when closer than this
@export var decision_interval: float  = 0.4   # seconds between AI decisions
@export var dodge_chance: float       = 0.18  # probability of dodging instead of attacking

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

var _target: Node3D = null

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var _hitbox: Area3D = get_node_or_null("Hitbox")
var _anim_tree: AnimationTree
var _anim_sm: AnimationNodeStateMachinePlayback

func _ready() -> void:
	health = max_health
	_anim_tree = get_node_or_null("AnimationTree")
	if _anim_tree == null:
		_anim_tree = AnimationTreeBuilder.setup(self)
	if _anim_tree:
		_anim_sm = _anim_tree.get("parameters/playback")
	if _hitbox:
		_hitbox.monitoring = false
		_hitbox.area_entered.connect(_on_hitbox_area_entered)

func set_target(target: Node3D) -> void:
	_target = target

# ── Main loop ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_tick_phase(delta)
	_decision_timer -= delta
	match ai_state:
		AIState.KO, AIState.HIT_REACT:
			return
		AIState.ATTACK:
			return  # phase timer drives the attack to completion
	_run_ai(delta)
	move_and_slide()

func _run_ai(delta: float) -> void:
	if _target == null or (_target.has_method("is_dead") and _target.is_dead()):
		_go_idle()
		return

	var flat_target := Vector3(_target.global_position.x, global_position.y, _target.global_position.z)
	var dist := global_position.distance_to(flat_target)

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

func _approach(flat_target: Vector3, delta: float) -> void:
	ai_state = AIState.APPROACH
	_travel(AttackConfig.ANIM_LOCOMOTION_TREE)
	var dir := (flat_target - global_position).normalized()
	velocity = velocity.lerp(dir * move_speed, 14.0 * delta)
	if dir.length() > 0.01:
		rotation.y = atan2(dir.x, dir.z)
	var norm_spd: float = clampf(velocity.length() / move_speed, 0.0, 1.0)
	if _anim_tree:
		_anim_tree.set("parameters/locomotion_tree/blend_space/blend_position", norm_spd)

func _go_idle() -> void:
	ai_state = AIState.IDLE
	combat_state = AttackConfig.CombatState.IDLE
	_travel(AttackConfig.ANIM_LOCOMOTION_IDLE)
	velocity = velocity.lerp(Vector3.ZERO, 0.25)

# ── Attack ────────────────────────────────────────────────────────────────────
func _start_attack() -> void:
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
	if _target:
		var flat_dir := Vector3(_target.global_position.x - global_position.x, 0.0, _target.global_position.z - global_position.z).normalized()
		if flat_dir.length() > 0.01:
			rotation.y = atan2(flat_dir.x, flat_dir.z)
	_begin_phase(data.windup_time)
	_travel(attack_id)

func _start_dodge() -> void:
	if not _target:
		return
	ai_state          = AIState.DODGE
	combat_state      = AttackConfig.CombatState.DODGE
	attack_phase      = AttackConfig.AttackPhase.WINDUP
	current_attack_id = "dodge_roll_fwd"
	invulnerable      = true
	var away := (global_position - _target.global_position).normalized()
	_dodge_dir        = Vector3(away.x, 0.0, away.z)
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
func _set_hitbox(active: bool) -> void:
	if not _hitbox:
		return
	_hitbox.monitoring = active
	var shape := _hitbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape:
		shape.disabled = not active

func _on_hitbox_area_entered(area: Area3D) -> void:
	var target := area.get_parent()
	if target == self or not AttackConfig.ATTACK_DATA.has(current_attack_id):
		return
	var data: Dictionary = AttackConfig.ATTACK_DATA[current_attack_id]
	if target.has_method("take_damage"):
		target.take_damage(data.damage)
	if target is CharacterBody3D:
		var dir: Vector3 = ((target as Node3D).global_position - global_position).normalized()
		(target as CharacterBody3D).velocity += dir * data.knockback
	var is_heavy: bool = data.damage >= 20.0
	var contact_point: Vector3 = (area as Node3D).global_position
	if is_heavy:
		CombatFeel.hit_heavy()
		AudioManager.play_sfx("hit_heavy")
		VFXPool.spark(contact_point, "heavy")
	else:
		CombatFeel.hit_light()
		AudioManager.play_sfx("hit_light")
		VFXPool.spark(contact_point, "light")

# ── Receive damage ────────────────────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if invulnerable or ai_state == AIState.KO:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_enter_ko()
	else:
		_enter_hit_react()

func _enter_hit_react() -> void:
	ai_state     = AIState.HIT_REACT
	attack_phase = AttackConfig.AttackPhase.NONE
	_set_hitbox(false)
	invulnerable = true
	_travel(AttackConfig.ANIM_HIT_LIGHT)
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
	if _anim_sm:
		_anim_sm.travel(state)

# ── Public API ────────────────────────────────────────────────────────────────
func get_health_percent() -> float:
	return health / max_health if max_health > 0.0 else 0.0

func is_dead() -> bool:
	return ai_state == AIState.KO
