extends CharacterBody3D
# Human-controlled fighter. Reads AttackConfig for all combat data.
# Requires child nodes: CollisionShape3D, Hitbox (Area3D), Hurtbox (Area3D)
# Requires child node: AnimationTree (optional — combat is mechanically correct
# even without animations; wire it up after importing mouse.glb)
#
# Input actions to define in Project → Settings → Input Map:
#   attack_light  (default: Z key)
#   attack_heavy  (default: X key)
#   dodge         (default: Space)
# Falls back to key checks if actions are not defined.

@export var max_health: float  = 100.0
@export var run_speed: float   = 5.0
@export var acceleration: float = 20.0
@export var friction: float    = 15.0
@export var dodge_speed: float = 9.0

signal health_changed(new_hp: float, max_hp: float)
signal died
signal hit_landed(target: Node3D, attack_id: String, damage: float)

# ── Runtime state ─────────────────────────────────────────────────────────────
var health: float
var combat_state: AttackConfig.CombatState = AttackConfig.CombatState.IDLE
var attack_phase: AttackConfig.AttackPhase = AttackConfig.AttackPhase.NONE
var current_combo_step: int  = 0
var current_attack_id: String = ""
var buffered_light: bool = false
var buffered_heavy: bool = false
var invulnerable: bool   = false
var _dodge_dir: Vector3  = Vector3.ZERO
var _phase_timer: float  = 0.0
var _phase_dur: float    = 0.0

# ── Node refs (null-safe) ─────────────────────────────────────────────────────
@onready var _anim_tree: AnimationTree = get_node_or_null("AnimationTree")
@onready var _hitbox: Area3D           = get_node_or_null("Hitbox")
var _anim_sm: AnimationNodeStateMachinePlayback

func _ready() -> void:
	health = max_health
	if _anim_tree:
		_anim_sm = _anim_tree.get("parameters/playback")
	if _hitbox:
		_hitbox.monitoring = false
		_hitbox.area_entered.connect(_on_hitbox_area_entered)

# ── Main loop ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_tick_phase(delta)
	_collect_input()
	_update_fsm(delta)
	move_and_slide()

func _collect_input() -> void:
	# Only buffer during cancelable frames of an ongoing attack
	if attack_phase not in [AttackConfig.AttackPhase.ACTIVE, AttackConfig.AttackPhase.RECOVERY]:
		return
	if _action_just_pressed("attack_light", KEY_Z):
		buffered_light = true
	if _action_just_pressed("attack_heavy", KEY_X):
		buffered_heavy = true

# ── FSM top level ─────────────────────────────────────────────────────────────
func _update_fsm(delta: float) -> void:
	var CS := AttackConfig.CombatState
	match combat_state:
		CS.KO:
			_travel(AttackConfig.ANIM_KO)
			return
		CS.HIT_REACT:
			return
		CS.DODGE:
			velocity = _dodge_dir * dodge_speed
			return
		CS.ATTACK_LIGHT, CS.ATTACK_HEAVY:
			_handle_active_attack()
			return
	_try_start_attack()
	_handle_locomotion(delta)

# ── Locomotion ────────────────────────────────────────────────────────────────
func _handle_locomotion(delta: float) -> void:
	var iv := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if _action_just_pressed("dodge", KEY_SPACE) and iv.length() > 0.05:
		_start_dodge(Vector3(iv.x, 0.0, iv.y))
		return

	if iv.length() > 0.05:
		velocity = velocity.lerp(Vector3(iv.x, 0.0, iv.y) * run_speed, acceleration * delta)
		combat_state = AttackConfig.CombatState.LOCOMOTION
		_travel(AttackConfig.ANIM_LOCOMOTION_TREE)
	else:
		velocity = velocity.lerp(Vector3.ZERO, friction * delta)
		if velocity.length() < 0.05:
			combat_state = AttackConfig.CombatState.IDLE
			_travel(AttackConfig.ANIM_LOCOMOTION_IDLE)

	var norm_spd: float = clampf(Vector2(velocity.x, velocity.z).length() / run_speed, 0.0, 1.0)
	if _anim_tree:
		_anim_tree.set("parameters/locomotion_tree/blend_space/blend_position", norm_spd)

# ── Attack initiation ─────────────────────────────────────────────────────────
func _try_start_attack() -> void:
	if buffered_light or _action_just_pressed("attack_light", KEY_Z):
		buffered_light = false
		_start_light_combo()
	elif buffered_heavy or _action_just_pressed("attack_heavy", KEY_X):
		buffered_heavy = false
		_start_attack("attack_heavy_01", AttackConfig.CombatState.ATTACK_HEAVY)

func _start_light_combo() -> void:
	current_combo_step = (current_combo_step % 3) + 1
	_start_attack("attack_light_%02d" % current_combo_step, AttackConfig.CombatState.ATTACK_LIGHT)

func _start_attack(attack_id: String, new_state: AttackConfig.CombatState) -> void:
	if not AttackConfig.ATTACK_DATA.has(attack_id):
		return
	var data: Dictionary = AttackConfig.ATTACK_DATA[attack_id]
	current_attack_id = attack_id
	combat_state      = new_state
	attack_phase      = AttackConfig.AttackPhase.WINDUP
	buffered_light    = false
	buffered_heavy    = false
	velocity          = Vector3.ZERO
	_begin_phase(data.windup_time)
	_travel(attack_id)

# ── Cancel window check ───────────────────────────────────────────────────────
func _handle_active_attack() -> void:
	if attack_phase not in [AttackConfig.AttackPhase.ACTIVE, AttackConfig.AttackPhase.RECOVERY]:
		return
	var next_light := "attack_light_%02d" % ((current_combo_step % 3) + 1)
	if buffered_light and _can_cancel_into(next_light):
		buffered_light = false
		_start_light_combo()
		return
	if buffered_heavy and _can_cancel_into("attack_heavy_01"):
		buffered_heavy = false
		_start_attack("attack_heavy_01", AttackConfig.CombatState.ATTACK_HEAVY)

func _can_cancel_into(next_id: String) -> bool:
	if not AttackConfig.ATTACK_DATA.has(current_attack_id):
		return false
	var d: Dictionary = AttackConfig.ATTACK_DATA[current_attack_id]
	if attack_phase < d.cancel_start_phase or attack_phase > d.cancel_end_phase:
		return false
	return d.can_cancel_into.has(next_id)

# ── Dodge ─────────────────────────────────────────────────────────────────────
func _start_dodge(direction: Vector3) -> void:
	combat_state     = AttackConfig.CombatState.DODGE
	attack_phase     = AttackConfig.AttackPhase.WINDUP
	current_attack_id = "dodge_roll_fwd"
	_dodge_dir       = direction.normalized()
	invulnerable     = true
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
			_begin_phase(data.active_time)
		AP.ACTIVE:
			attack_phase = AP.RECOVERY
			_set_hitbox(false)
			_begin_phase(data.recovery_time)
		AP.RECOVERY:
			_end_attack()

func _end_attack() -> void:
	_set_hitbox(false)
	invulnerable  = false
	_dodge_dir    = Vector3.ZERO
	attack_phase  = AttackConfig.AttackPhase.NONE
	if combat_state != AttackConfig.CombatState.ATTACK_LIGHT:
		current_combo_step = 0
	current_attack_id = ""
	combat_state = AttackConfig.CombatState.IDLE

# ── Hitbox enable/disable ─────────────────────────────────────────────────────
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
	hit_landed.emit(target, current_attack_id, data.damage)

# ── Receive damage ────────────────────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if invulnerable or combat_state == AttackConfig.CombatState.KO:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_enter_ko()
	else:
		_enter_hit_react(amount)

func _enter_hit_react(amount: float) -> void:
	combat_state = AttackConfig.CombatState.HIT_REACT
	attack_phase = AttackConfig.AttackPhase.NONE
	_set_hitbox(false)
	invulnerable = true
	_travel(AttackConfig.ANIM_HIT_HEAVY if amount >= 20.0 else AttackConfig.ANIM_HIT_LIGHT)
	get_tree().create_timer(0.45).timeout.connect(func() -> void:
		invulnerable = false
		if combat_state == AttackConfig.CombatState.HIT_REACT:
			combat_state = AttackConfig.CombatState.IDLE
	)

func _enter_ko() -> void:
	combat_state = AttackConfig.CombatState.KO
	attack_phase = AttackConfig.AttackPhase.NONE
	_set_hitbox(false)
	_travel(AttackConfig.ANIM_KO)
	died.emit()

# ── AnimationTree helpers ─────────────────────────────────────────────────────
func _travel(state: String) -> void:
	if _anim_sm:
		_anim_sm.travel(state)

# Call Method Track hooks — wire these to AnimationPlayer tracks once
# combat animations are exported from Blender. Until then the phase
# timer drives transitions automatically.
func anim_enter_active() -> void:
	if attack_phase == AttackConfig.AttackPhase.WINDUP:
		_advance_phase()

func anim_enter_recovery() -> void:
	if attack_phase == AttackConfig.AttackPhase.ACTIVE:
		_advance_phase()

func anim_attack_end() -> void:
	if attack_phase == AttackConfig.AttackPhase.RECOVERY:
		_advance_phase()

# ── Input helpers ─────────────────────────────────────────────────────────────
func _action_just_pressed(action: String, fallback_key: Key) -> bool:
	if InputMap.has_action(action):
		return Input.is_action_just_pressed(action)
	return Input.is_key_pressed(fallback_key)

# ── Public API ────────────────────────────────────────────────────────────────
func get_health_percent() -> float:
	return health / max_health if max_health > 0.0 else 0.0

func is_dead() -> bool:
	return combat_state == AttackConfig.CombatState.KO
